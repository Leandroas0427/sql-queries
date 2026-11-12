-- Base Financeiro
WITH finance AS (
  SELECT 
    ss.schedule_id AS frete_id, 
    -- Valores de Receita
    MAX(st.freight) FILTER (WHERE (ss.name = 'COLETA' OR ss.name = 'DEVOLUCAO_DE_PALLET' OR ss.name = 'TRANSFERENCIA') AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER') AS rec_valor_frete,
    SUM(st.total_freight) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER') AS rec_total_frete,
    SUM(st.total_service) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER') AS rec_total_com_impostos,
    -- Valores de Despesa
    MAX(st.freight) FILTER (WHERE (ss.name = 'REPASSE' OR ss.name = 'REPASSE LOS' OR ss.name = 'LOS') AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER') AS des_valor_frete,
    SUM(st.total_freight) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER') AS des_total_frete,
    SUM(st.total_service) FILTER (WHERE sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER') AS des_total_com_impostos
  FROM service_transaction st 
  LEFT JOIN schedule_service ss ON ss.id = st.service_id 
  LEFT JOIN schedule s ON s.id = ss.schedule_id
  LEFT JOIN service_participant sp ON sp.service_id = st.service_id
  WHERE s.operation <> 'TRACKING' AND st.deleted_at IS NULL
  GROUP BY ss.schedule_id
),
-- Guia de GNRE
guia_gnre AS (
  SELECT 
    fm.codigo AS id_frete, 
    MAX(CASE WHEN RIGHT(LOWER(file_key), 3) = 'pdf' THEN 'Ok' END) AS emissao_guia, 
    MAX(CASE WHEN (RIGHT(LOWER(file_key), 3) = 'jpg' OR RIGHT(LOWER(file_key), 4) = 'jpeg') THEN 'Ok' END) AS comprovante 
  FROM file_management fm 
  WHERE fm.type_file = 'gnre' 
  GROUP BY fm.codigo 
  ORDER BY fm.codigo DESC
)
-- Informacoes sobre o frete
SELECT 
  s.id AS frete_id, 
  CASE WHEN s.operation = 'SPOT' THEN c.trade_name WHEN s.operation = 'TRACKING' THEN c.trade_name ELSE cb.trade_name END AS embarcador_comprador,
  CASE WHEN s.operation = 'SPOT' OR s.operation = 'TRACKING' THEN '' ELSE c.name END AS embarcador_vendedor,
  s.operation AS tipo_operacao, 
  sc.operation_type AS tipo_viagem,
  UPPER(sc.vehicle_type) AS tipo_veiculo, 
  UPPER(sc.vehicle_category_type) AS cat_veiculo,
  UPPER(COALESCE(lo.city, clo.city)) AS cidade_origem, 
  UPPER(COALESCE(lo.uf, clo.uf)) AS uf_origem,
  UPPER(COALESCE(ld.city, cld.city)) AS cidade_destino, 
  UPPER(COALESCE(ld.uf, cld.uf)) AS uf_destino,
  s.distance AS distancia_km,
  sc.order_number AS numero_pedido_cliente,
  UPPER(sc2.name) AS transportadora,
  UPPER(d."name") AS motorista,
  sco.status_code_short_desc AS status_frete, 
  sco.status_code_desc AS status_frete_detalhado,
  -- Informacoes sobre horários
  (s.created_at - INTERVAL '3 hours') AS criado_em,
  sd.allocation_vehicle_date - INTERVAL '3 hours' AS alocacao_veiculo,
  sd.allocation_driver_date - INTERVAL '3 hours' AS alocacao_motorista,
  sd.start_risk_management_date - INTERVAL '3 hours' AS inicio_gerenciamento_risco, 
  sd.risk_management_date - INTERVAL '3 hours' AS fim_gerenciamento_risco,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.start_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_viagem_carregamento,
  sd.levy_initial_date - INTERVAL '3 hours' AS agendamento_carregamento, 
  sd.arrival_loading_date - INTERVAL '3 hours' AS chegada_carregamento,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.checkin_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_coleta,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.checkout_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_coleta,
  sd.start_trip_unloading_date - INTERVAL '3 hours' AS inicio_viagem_descarga,
  sd.delivery_initial_date - INTERVAL '3 hours' AS agendamento_descarga,
  sd.arrival_unloading_date - INTERVAL '3 hours' AS chegada_descarga,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.load_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS inicio_descarga,
  (TO_TIMESTAMP(REPLACE(REPLACE(sd.finish_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') AS fim_descarga,
  sd.delivery_end_date - INTERVAL '3 hours' AS fim_planejado,
  s.description_cancel AS motivo_cancelamento,
  -- Informacoes Financeiras
  guia_gnre.emissao_guia,
  guia_gnre.comprovante,
  finance.rec_valor_frete AS rec_valor_frete,
  finance.rec_total_frete,
  finance.rec_total_com_impostos,
  finance.des_valor_frete, 
  finance.des_total_frete,
  finance.des_total_com_impostos 
-- Origens dos dados
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
LEFT JOIN guia_gnre ON guia_gnre.id_frete = s.id
-- Para extrair origem e destino
LEFT JOIN schedule_client sc3 ON s.schedule_client_origin_id = sc3.id 
LEFT JOIN client clo ON sc3.client_id = clo.id 
LEFT JOIN locality lo ON sc3.locality_id = lo.id
LEFT JOIN schedule_client sc4 ON s.schedule_client_destiny_id = sc4.id 
LEFT JOIN client cld ON sc4.client_id = cld.id 
LEFT JOIN locality ld ON sc4.locality_id = ld.id
WHERE s."deletedAt" IS NULL 
  AND s.operation <> 'TRACKING'
ORDER BY frete_id DESC
