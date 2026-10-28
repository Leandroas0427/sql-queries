-- Base Financeiro
with finance as (select ss.schedule_id as frete_id, 
-- Valores de Receita
max(st.freight) filter (where (ss.name = 'COLETA' or ss.name = 'DEVOLUCAO_DE_PALLET' or ss.name = 'TRANSFERENCIA') and sp.participant_name = 'LOGSHARE' and sp.participant_type = 'RECEIVER') as rec_valor_frete,
sum(st.total_freight) filter (where sp.participant_name = 'LOGSHARE' and sp.participant_type = 'RECEIVER') as rec_total_frete,
sum(st.total_service) filter (where sp.participant_name = 'LOGSHARE' and sp.participant_type = 'RECEIVER') as rec_total_com_impostos,
-- Valores de Despesa
max(st.freight) filter (where (ss.name = 'REPASSE' or ss.name = 'REPASSE LOS' or ss.name = 'LOS') and sp.participant_name = 'LOGSHARE' and sp.participant_type = 'PAYER') as des_valor_frete,
sum(st.total_freight) filter (where sp.participant_name = 'LOGSHARE' and sp.participant_type = 'PAYER') as des_total_frete,
sum(st.total_service) filter (where sp.participant_name = 'LOGSHARE' and sp.participant_type = 'PAYER') as des_total_com_impostos
from service_transaction st 
left join schedule_service ss on ss.id = st.service_id 
left join schedule s on s.id = ss.schedule_id
left join service_participant sp on sp.service_id = st.service_id
where s.operation <> 'TRACKING' and st.deleted_at is null
group by ss.schedule_id),
-- Guia de GNRE
guia_gnre as (select fm.codigo AS id_frete, 
MAX(CASE WHEN RIGHT(LOWER(file_key), 3) = 'pdf' THEN 'Ok' END) AS emissao_guia, 
MAX(CASE WHEN (RIGHT(LOWER(file_key), 3) = 'jpg' OR RIGHT(LOWER(file_key), 4) = 'jpeg') THEN 'Ok' END) AS comprovante 
FROM file_management fm 
WHERE fm.type_file = 'gnre' 
GROUP BY fm.codigo 
ORDER BY fm.codigo desc)
-- Informacoes sobre o frete
select s.id as frete_id, 
case when s.operation = 'SPOT' THEN c.trade_name when s.operation = 'TRACKING' then c.trade_name else cb.trade_name end as embarcador_comprador,
case when s.operation = 'SPOT' or s.operation = 'TRACKING' THEN '' else c.name end as embarcador_vendedor,
s.operation as tipo_operacao, 
sc.operation_type as tipo_viagem,
UPPER(sc.vehicle_type) as tipo_veiculo, 
UPPER(sc.vehicle_category_type) as cat_veiculo,
UPPER(coalesce(lo.city,clo.city)) as cidade_origem, 
UPPER(coalesce(lo.uf,clo.uf)) as uf_origem,
UPPER(coalesce(ld.city,cld.city)) as cidade_destino, 
UPPER(coalesce(ld.uf,cld.uf)) as uf_destino,
s.distance as distancia_km,
sc.order_number as numero_pedido_cliente,
UPPER(sc2.name) as transportadora,
UPPER(d."name") as motorista,
sco.status_code_short_desc as status_frete, 
sco.status_code_desc as status_frete_detalhado,
-- Informacoes sobre horários
(s.created_at - interval '3 Hours') as criado_em,
sd.allocation_vehicle_date - INTERVAL '3 hours' as alocacao_veiculo,
sd.allocation_driver_date - INTERVAL '3 hours' as alocacao_motorista,
sd.start_risk_management_date - INTERVAL '3 hours' as inicio_gerenciamento_risco, 
sd.risk_management_date - INTERVAL '3 hours' as fim_gerenciamento_risco,
(TO_TIMESTAMP(REPLACE(REPLACE(sd.start_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') as inicio_viagem_carregamento,
sd.levy_initial_date - INTERVAL '3 hours' as agendamento_carregamento, 
sd.arrival_loading_date - INTERVAL '3 hours' as chegada_carregamento,
(TO_TIMESTAMP(REPLACE(REPLACE(sd.checkin_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') as inicio_coleta,
(TO_TIMESTAMP(REPLACE(REPLACE(sd.checkout_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') as fim_coleta,
sd.start_trip_unloading_date - INTERVAL '3 hours' as inicio_viagem_descarga,
sd.delivery_initial_date - INTERVAL '3 hours' as agendamento_descarga,
sd.arrival_unloading_date - INTERVAL '3 hours' as chegada_descarga,
(TO_TIMESTAMP(REPLACE(REPLACE(sd.load_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') as inicio_descarga,
(TO_TIMESTAMP(REPLACE(REPLACE(sd.finish_date, 'T', ' '), 'Z', ''), 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '3 hours') as fim_descarga,
sd.delivery_end_date - INTERVAL '3 hours' as fim_planejado,
S.description_cancel as motivo_cancelamento,
-- Informacoes Financeiras
guia_gnre.emissao_guia,
guia_gnre.comprovante,
finance.rec_valor_frete as rec_valor_frete,
finance.rec_total_frete,
finance.rec_total_com_impostos,
finance.des_valor_frete, 
finance.des_total_frete,
finance.des_total_com_impostos 
-- Origens dos dados
from schedule s 
left join schedule_planned_dates spd on spd.schedule_id = s.id 
left join schedule_details sd on sd.id = s.schedule_details_id
left join company c on s.company_id = c.id 
left join company cb on s.company_id_buyer = cb.id 
left join shipping_company sc2 on s.shipping_company_id = sc2.id
left join vehicle v on s.vehicle_id = v.id 
left join driver d on s.driver_id = d.id 
left join schedule_cargo sc on sc.id = s.schedule_cargo_id
left join status_codes sco on s.status_code = sco.status_code
left join finance on finance.frete_id = s.id
left join guia_gnre on guia_gnre.id_frete = s.id
-- Para extrair origem e destino
LEFT join schedule_client sc3 on s.schedule_client_origin_id  = sc3.id LEFT join client clo ON sc3.client_id = clo.id LEFT join locality lo ON sc3.locality_id = lo.id
LEFT join schedule_client sc4 on s.schedule_client_destiny_id  = sc4.id LEFT join client cld ON sc4.client_id = cld.id LEFT join locality ld ON sc4.locality_id = ld.id
where s."deletedAt" is null and s.operation <> 'TRACKING'
order by 1 desc