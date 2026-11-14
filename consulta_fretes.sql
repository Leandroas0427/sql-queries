/*
=============================================================================
Descrição:      Consulta analítica de fretes (SLA, Operacional e Financeiro)
Granularidade:  1 registro por frete (frete_id)
=============================================================================
*/
-- Base Financeiro
WITH finance AS (
  SELECT 
    ss.schedule_id AS frete_id, 
    -- Valores de Receita
    MAX(st.freight) FILTER (WHERE (ss.name = 'COLETA' OR ss.name = 'DEVOLUCAO_DE_PALLET' OR ss.name = 'TRANSFERENCIA') AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER') AS rec_valor_frete,
    SUM(st.total_freight) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER') AS rec_total_frete,
    -- Valores de Despesa
    MAX(st.freight) FILTER (WHERE (ss.name = 'REPASSE' OR ss.name = 'REPASSE LOS') AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER') AS des_valor_frete,
    SUM(st.total_freight) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER') AS des_total_frete
  FROM service_transaction st 
  LEFT JOIN schedule_service ss ON ss.id = st.service_id 
  LEFT JOIN schedule s ON s.id = ss.schedule_id
  LEFT JOIN service_participant sp ON sp.service_id = st.service_id
  WHERE s.operation <> 'TRACKING' 
    AND st.deleted_at IS NULL
  GROUP BY ss.schedule_id
),
-- Datas e Marcos Temporais para SLA
sla_datas AS (
  SELECT
    s.id AS frete_id,
    (sd.levy_initial_date - INTERVAL '3 hours') AS agend_carga,
    (sd.arrival_loading_date - INTERVAL '3 hours') AS chegada_carga,
    (TO_TIMESTAMP(NULLIF(REPLACE(REPLACE(sd.checkout_date, 'T', ' '), 'Z', ''), ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_coleta,
    (sd.delivery_initial_date - INTERVAL '3 hours') AS agend_descarga,
    (sd.arrival_unloading_date - INTERVAL '3 hours') AS chegada_descarga,
    (TO_TIMESTAMP(NULLIF(REPLACE(REPLACE(sd.finish_date, 'T', ' '), 'Z', ''), ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_descarga
  FROM schedule s
  LEFT JOIN schedule_details sd ON sd.id = s.schedule_details_id
  WHERE s."deletedAt" IS NULL
    AND s.operation <> 'TRACKING'
),
-- Métricas e Indicadores de SLA
sla_metrics AS (
  SELECT 
    frete_id,
    -- 1. Load On Time (1 = no prazo, 0 = atrasado)
    CASE 
      WHEN chegada_carga IS NULL OR agend_carga IS NULL THEN NULL 
      WHEN chegada_carga <= agend_carga THEN 1 
      ELSE 0 
    END AS load_on_time,
    -- 2. Load TMO (Horas e Flag <= 5h considerando MAX(chegada, agendamento))
    CASE 
      WHEN (fim_coleta - GREATEST(chegada_carga, agend_carga)) < INTERVAL '0' THEN 0 
      ELSE ROUND(EXTRACT(EPOCH FROM (fim_coleta - GREATEST(chegada_carga, agend_carga))) / 3600.0, 2) 
    END AS load_tmo_horas,
    CASE 
      WHEN fim_coleta IS NULL OR chegada_carga IS NULL OR agend_carga IS NULL THEN NULL 
      WHEN (EXTRACT(EPOCH FROM (fim_coleta - GREATEST(chegada_carga, agend_carga))) / 3600.0) <= 5.0 THEN 1 
      ELSE 0 
    END AS load_tmo,
    -- 3. Unload On Time (1 = no prazo, 0 = atrasado)
    CASE 
      WHEN chegada_descarga IS NULL OR agend_descarga IS NULL THEN NULL 
      WHEN chegada_descarga <= agend_descarga THEN 1 
      ELSE 0 
    END AS unload_on_time,
    -- 4. Unload TMO (Horas e Flag <= 5h considerando MAX(chegada, agendamento))
    CASE 
      WHEN (fim_descarga - GREATEST(chegada_descarga, agend_descarga)) < INTERVAL '0' THEN 0 
      ELSE ROUND(EXTRACT(EPOCH FROM (fim_descarga - GREATEST(chegada_descarga, agend_descarga))) / 3600.0, 2) 
    END AS unload_tmo_horas,
    CASE 
      WHEN fim_descarga IS NULL OR chegada_descarga IS NULL OR agend_descarga IS NULL THEN NULL 
      WHEN (EXTRACT(EPOCH FROM (fim_descarga - GREATEST(chegada_descarga, agend_descarga))) / 3600.0) <= 5.0 THEN 1 
      ELSE 0 
    END AS unload_tmo
  FROM sla_datas
),
-- Histórico e Ordenação de Veículos Alocados (Window Function)
veiculos AS (
  SELECT 
    s.id AS frete_id, 
    avsh.combination_id AS placas_veiculo,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY avsh.created_at DESC) AS ranking_alocacao
  FROM schedule s 
  LEFT JOIN allocated_vehicles_schedules_history avsh ON s.id = avsh.schedule_id 
  LEFT JOIN vehicle v ON v.id = avsh.vehicle_id
  ORDER BY s.id DESC, ranking_alocacao
)
-- Consulta Principal: Informações Consolidadas do Frete
SELECT 
  s.id AS frete_id, 
  CASE 
    WHEN s.operation = 'SPOT' THEN UPPER(c.trade_name) 
    WHEN s.operation = 'TRACKING' THEN UPPER(c.trade_name) 
    ELSE UPPER(cb.trade_name) 
  END AS embarcador_comprador,
  CASE 
    WHEN s.operation = 'SPOT' OR s.operation = 'TRACKING' THEN '' 
    ELSE UPPER(c.name) 
  END AS embarcador_vendedor,
  UPPER(s.operation) AS tipo_operacao,
  UPPER(sc.operation_type) AS tipo_viagem,
  UPPER(COALESCE(lo.city, clo.city)) AS cidade_origem, 
  UPPER(COALESCE(lo.uf, clo.uf)) AS uf_origem,
  UPPER(COALESCE(ld.city, cld.city)) AS cidade_destino, 
  UPPER(COALESCE(ld.uf, cld.uf)) AS uf_destino,
  ROUND(s.distance::numeric, 0) AS distancia_km,
  UPPER(sc2.name) AS transportadora,
  UPPER(d.name) AS motorista,
  UPPER(ve.placas_veiculo) AS placas_veiculo,
  UPPER(sc.vehicle_type) AS tipo_veiculo, 
  UPPER(sc.vehicle_category_type) AS cat_veiculo,
  UPPER(sco.status_code_short_desc) AS status_frete, 
  UPPER(sco.status_code_desc) AS status_frete_detalhado,
  -- Informações sobre Horários
  (s.created_at - INTERVAL '3 hours') AS criado_em,
  (sd.allocation_vehicle_date - INTERVAL '3 hours') AS alocacao_veiculo,
  (sd.allocation_driver_date - INTERVAL '3 hours') AS alocacao_motorista,
  (sd.start_risk_management_date - INTERVAL '3 hours') AS inicio_gerenciamento_risco, 
  (sd.risk_management_date - INTERVAL '3 hours') AS fim_gerenciamento_risco,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.start_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_viagem_carregamento,
  (sd.levy_initial_date - INTERVAL '3 hours') AS agendamento_carregamento, 
  (sd.arrival_loading_date - INTERVAL '3 hours') AS chegada_carregamento,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.checkin_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_coleta,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.checkout_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_coleta,
  (sd.start_trip_unloading_date - INTERVAL '3 hours') AS inicio_viagem_descarga,
  (sd.delivery_initial_date - INTERVAL '3 hours') AS agendamento_descarga,
  (sd.arrival_unloading_date - INTERVAL '3 hours') AS chegada_descarga,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.load_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_descarga,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.finish_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_descarga,
  s.description_cancel AS motivo_cancelamento,
  -- Informações Financeiras
  ROUND(finance.rec_valor_frete::numeric, 1) AS rec_valor_frete,
  ROUND(finance.rec_total_frete::numeric, 1) AS rec_total_frete,
  ROUND(finance.des_valor_frete::numeric, 1) AS des_valor_frete, 
  ROUND(finance.des_total_frete::numeric, 1) AS des_total_frete,
  -- Indicadores de SLA
  sla.load_on_time,
  sla.load_tmo,
  sla.load_tmo_horas,
  sla.unload_on_time,
  sla.unload_tmo,
  sla.unload_tmo_horas
-- Origens dos Dados e Relacionamentos
FROM schedule s 
LEFT JOIN schedule_planned_dates spd ON spd.schedule_id = s.id 
LEFT JOIN schedule_details sd ON sd.id = s.schedule_details_id
LEFT JOIN company c ON s.company_id = c.id 
LEFT JOIN company cb ON s.company_id_buyer = cb.id 
LEFT JOIN shipping_company sc2 ON s.shipping_company_id = sc2.id
LEFT JOIN vehicle v ON s.vehicle_id = v.id 
LEFT JOIN driver d ON s.driver_id = d.id 
LEFT JOIN schedule_cargo sc ON sc.id = s.schedule_cargo_id
LEFT JOIN status_codes sco ON s.status_code = sco.status_code
LEFT JOIN finance ON finance.frete_id = s.id
LEFT JOIN sla_metrics sla ON sla.frete_id = s.id
LEFT JOIN veiculos ve ON ve.frete_id = s.id
-- Origem e Destino do Frete
LEFT JOIN schedule_client sc3 ON s.schedule_client_origin_id = sc3.id 
LEFT JOIN client clo ON sc3.client_id = clo.id 
LEFT JOIN locality lo ON sc3.locality_id = lo.id
LEFT JOIN schedule_client sc4 ON s.schedule_client_destiny_id = sc4.id 
LEFT JOIN client cld ON sc4.client_id = cld.id 
LEFT JOIN locality ld ON sc4.locality_id = ld.id
WHERE s."deletedAt" IS NULL 
  AND s.operation <> 'TRACKING'
  AND s.status_code = 'IN90'
ORDER BY frete_id DESC;
