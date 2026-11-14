/*
Descrição:      Consulta analítica de fretes (SLA, Operacional e Financeiro)
Granularidade:  1 registro por frete (frete_id)
*/
-- Base Financeiro
WITH finance AS (
SELECT 
ss.schedule_id AS frete_id, 
-- Valores de Receita
MAX(CASE WHEN (ss.name = 'COLETA' OR ss.name = 'DEVOLUCAO_DE_PALLET' OR ss.name = 'TRANSFERENCIA') 
	AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER' THEN st.freight END) AS rec_valor_frete,
SUM(CASE WHEN sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'RECEIVER' THEN st.total_freight END) AS rec_total_frete,
-- Valores de Despesa
MAX(CASE WHEN (ss.name = 'REPASSE' OR ss.name = 'REPASSE LOS') 
	AND sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER' THEN st.freight END) AS des_valor_frete,
SUM(CASE WHEN sp.participant_name = 'LOGSHARE' AND sp.participant_type = 'PAYER' THEN st.total_freight END) AS des_total_frete
FROM service_transaction st 
LEFT JOIN schedule_service ss ON ss.id = st.service_id 
LEFT JOIN schedule s ON s.id = ss.schedule_id
LEFT JOIN service_participant sp ON sp.service_id = st.service_id
WHERE s.operation <> 'TRACKING' AND st.deleted_at IS NULL
GROUP BY ss.schedule_id
),
-- Datas e Marcos Temporais para SLA
sla_datas AS (
SELECT
s.id AS frete_id,
(s.created_at - INTERVAL '3' HOUR) AS criado_em,
(sd.allocation_vehicle_date - INTERVAL '3' HOUR) AS alocacao_veiculo,
(sd.allocation_driver_date - INTERVAL '3' HOUR) AS alocacao_motorista,
CAST(sd.start_risk_management_date AS TIMESTAMP) AS inicio_gerenciamento_risco, 
CAST(sd.risk_management_date AS TIMESTAMP) AS fim_gerenciamento_risco,
(CAST(NULLIF(REPLACE(REPLACE(sd.start_date, 'T', ' '), 'Z', ''), '') AS TIMESTAMP) - INTERVAL '3' HOUR) AS inicio_viagem_carregamento,
(sd.levy_initial_date - INTERVAL '3' HOUR) AS agendamento_carregamento, 
(sd.arrival_loading_date - INTERVAL '3' HOUR) AS chegada_carregamento,
(CAST(NULLIF(REPLACE(REPLACE(sd.checkin_date, 'T', ' '), 'Z', ''), '') AS TIMESTAMP) - INTERVAL '3' HOUR) AS inicio_coleta,
(CAST(NULLIF(REPLACE(REPLACE(sd.checkout_date, 'T', ' '), 'Z', ''), '') AS TIMESTAMP) - INTERVAL '3' HOUR) AS fim_coleta,
(sd.start_trip_unloading_date - INTERVAL '3' HOUR) AS inicio_viagem_descarga,
(sd.delivery_initial_date - INTERVAL '3' HOUR) AS agendamento_descarga,
(sd.arrival_unloading_date - INTERVAL '3' HOUR) AS chegada_descarga,
(CAST(NULLIF(REPLACE(REPLACE(sd.load_date, 'T', ' '), 'Z', ''), '') AS TIMESTAMP) - INTERVAL '3' HOUR) AS inicio_descarga,
(CAST(NULLIF(REPLACE(REPLACE(sd.finish_date, 'T', ' '), 'Z', ''), '') AS TIMESTAMP) - INTERVAL '3' HOUR) AS fim_descarga
FROM schedule s
LEFT JOIN schedule_details sd ON sd.id = s.schedule_details_id
WHERE s."deletedAt" IS NULL AND s.operation <> 'TRACKING'
),
-- Cálculo auxiliar do maior marco
sla_intervalos AS (
SELECT
frete_id, agendamento_carregamento, chegada_carregamento, fim_coleta, agendamento_descarga, chegada_descarga, fim_descarga,
-- Maior data entre chegada e agendamento (Carga)
CASE 
	WHEN chegada_carregamento >= agendamento_carregamento THEN chegada_carregamento 
	ELSE agendamento_carregamento 
	END AS ref_inicio_carga,
-- Maior data entre chegada e agendamento (Descarga)
CASE 
	WHEN chegada_descarga >= agendamento_descarga THEN chegada_descarga 
	ELSE agendamento_descarga 
	END AS ref_inicio_descarga
FROM sla_datas
),
-- Métricas e Indicadores de SLA
sla_metrics AS (
SELECT 
frete_id,
-- 1. Load On Time (1 = no prazo, 0 = atrasado)
CASE 
	WHEN chegada_carregamento IS NULL OR agendamento_carregamento IS NULL THEN NULL 
	WHEN chegada_carregamento <= agendamento_carregamento THEN 1 
	ELSE 0 
	END AS load_on_time,
-- 2. Load TMO (Horas e Flag <= 5h)
-- TMO: Converte dias (*86400), horas (*3600), minutos (*60) e segundos do intervalo em total de segundos  e divide por 3600.0.
CASE
	WHEN (fim_coleta - ref_inicio_carga) < INTERVAL '0' SECOND THEN 0
	ELSE ROUND((EXTRACT(DAY FROM (fim_coleta - ref_inicio_carga)) * 86400.0 + 
	EXTRACT(HOUR FROM (fim_coleta - ref_inicio_carga)) * 3600.0 + 
	EXTRACT(MINUTE FROM (fim_coleta - ref_inicio_carga)) * 60.0 + 
	EXTRACT(SECOND FROM (fim_coleta - ref_inicio_carga))) / 3600.0, 2)
    END AS load_tmo_horas,
CASE 
	WHEN fim_coleta IS NULL OR chegada_carregamento IS NULL OR agendamento_carregamento IS NULL THEN NULL 
    WHEN ((EXTRACT(DAY FROM (fim_coleta - ref_inicio_carga)) * 86400.0 + 
    EXTRACT(HOUR FROM (fim_coleta - ref_inicio_carga)) * 3600.0 + 
    EXTRACT(MINUTE FROM (fim_coleta - ref_inicio_carga)) * 60.0 + 
    EXTRACT(SECOND FROM (fim_coleta - ref_inicio_carga))) / 3600.0) <= 5.0 THEN 1 
    ELSE 0 
    END AS load_tmo,
-- 3. Unload On Time (1 = no prazo, 0 = atrasado)
CASE 
	WHEN chegada_descarga IS NULL OR agendamento_descarga IS NULL THEN NULL 
	WHEN chegada_descarga <= agendamento_descarga THEN 1 
	ELSE 0 
	END AS unload_on_time,
-- 4. Unload TMO (Horas e Flag <= 5h)
-- TMO: Converte dias (*86400), horas (*3600), minutos (*60) e segundos do intervalo em total de segundos  e divide por 3600.0.
CASE 
	WHEN (fim_descarga - ref_inicio_descarga) < INTERVAL '0' SECOND THEN 0 
    ELSE ROUND((EXTRACT(DAY FROM (fim_descarga - ref_inicio_descarga)) * 86400.0 + 
    EXTRACT(HOUR FROM (fim_descarga - ref_inicio_descarga)) * 3600.0 + 
    EXTRACT(MINUTE FROM (fim_descarga - ref_inicio_descarga)) * 60.0 + 
    EXTRACT(SECOND FROM (fim_descarga - ref_inicio_descarga))) / 3600.0, 2)
    END AS unload_tmo_horas,
CASE 
	WHEN fim_descarga IS NULL OR chegada_descarga IS NULL OR agendamento_descarga IS NULL THEN NULL 
	WHEN ((EXTRACT(DAY FROM (fim_descarga - ref_inicio_descarga)) * 86400.0 + 
	EXTRACT(HOUR FROM (fim_descarga - ref_inicio_descarga)) * 3600.0 + 
	EXTRACT(MINUTE FROM (fim_descarga - ref_inicio_descarga)) * 60.0 + 
	EXTRACT(SECOND FROM (fim_descarga - ref_inicio_descarga))) / 3600.0) <= 5.0 THEN 1 
	ELSE 0 
    END AS unload_tmo
FROM sla_intervalos
),
-- Histórico e Ordenação de Veículos Alocados
veiculos AS (
SELECT 
s.id AS frete_id, 
avsh.combination_id AS placas_veiculo,
ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY avsh.created_at DESC) AS ranking_alocacao
FROM schedule s 
LEFT JOIN allocated_vehicles_schedules_history avsh ON s.id = avsh.schedule_id 
LEFT JOIN vehicle v ON v.id = avsh.vehicle_id
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
ROUND(CAST(s.distance AS DECIMAL(18, 4)), 0) AS distancia_km,
UPPER(sc2.name) AS transportadora,
UPPER(d.name) AS motorista,
UPPER(ve.placas_veiculo) AS placas_veiculo,
UPPER(sc.vehicle_type) AS tipo_veiculo, 
UPPER(sc.vehicle_category_type) AS cat_veiculo,
UPPER(sco.status_code_short_desc) AS status_frete, 
UPPER(sco.status_code_desc) AS status_frete_detalhado,
-- Informações sobre Horários
sld.criado_em,
sld.alocacao_veiculo,
sld.alocacao_motorista,
sld.inicio_gerenciamento_risco, 
sld.fim_gerenciamento_risco,
sld.inicio_viagem_carregamento,
sld.agendamento_carregamento, 
sld.chegada_carregamento,
sld.inicio_coleta,
sld.fim_coleta,
sld.inicio_viagem_descarga,
sld.agendamento_descarga,
sld.chegada_descarga,
sld.inicio_descarga,
sld.fim_descarga,
s.description_cancel AS motivo_cancelamento,
-- Informações Financeiras
ROUND(CAST(finance.rec_valor_frete AS DECIMAL(18, 4)), 1) AS rec_valor_frete,
ROUND(CAST(finance.rec_total_frete AS DECIMAL(18, 4)), 1) AS rec_total_frete,
ROUND(CAST(finance.des_valor_frete AS DECIMAL(18, 4)), 1) AS des_valor_frete, 
ROUND(CAST(finance.des_total_frete AS DECIMAL(18, 4)), 1) AS des_total_frete,
-- Indicadores de SLA
sla.load_on_time, 
sla.load_tmo, 
sla.load_tmo_horas,
sla.unload_on_time, 
sla.unload_tmo, 
sla.unload_tmo_horas
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
LEFT JOIN sla_datas sld ON sld.frete_id = s.id
LEFT JOIN sla_metrics sla ON sla.frete_id = s.id
LEFT JOIN veiculos ve ON ve.frete_id = s.id
LEFT JOIN schedule_client sc3 ON s.schedule_client_origin_id = sc3.id 
LEFT JOIN client clo ON sc3.client_id = clo.id 
LEFT JOIN locality lo ON sc3.locality_id = lo.id
LEFT JOIN schedule_client sc4 ON s.schedule_client_destiny_id = sc4.id 
LEFT JOIN client cld ON sc4.client_id = cld.id 
LEFT JOIN locality ld ON sc4.locality_id = ld.id
WHERE s."deletedAt" IS NULL 
AND s.operation <> 'TRACKING'
ORDER BY frete_id DESC