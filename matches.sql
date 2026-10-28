-- BLOCO COMPRA COMO REFERÊNCIA
SELECT 
  mor.id as match_id,
  'Compra' as tipo_referencia,
  c.trade_name as embarcador_referencia,
  c2.trade_name as embarcador_com_match,
  mor.updated_at::date as data_atualizacao,
  mor.backhaul_type as tipo_backhaul,
  mor.sale_offer_co2 as co2_evitado,
  mor.vehicle_score as score_veiculo,
  mor.origin_distance_score as score_origem,
  mor.destination_distance_score as destino_score,
  mor.total_distance_origin as desvio_origem,
  mor.total_distance_destination as desvio_destino,
  (mor.total_distance_origin + mor.total_distance_destination) as desvio_total,
  mor.distance_purchase_offer as distancia_oferta_compra,
  mor.distance_sale_offer as distancia_oferta_venda,
  mor.purchase_offer_id as id_oferta_compra,
  i.operation_type as operacao_compra,
  c.trade_name as embarcador_comprador,
  i.frequency as frequencia_compra,
  i.freight_value as valor_compra,
  i.vehicle_type as tipo_veiculo_compra,
  i.category as categoria_veiculo_compra,
  case when i.id_client_origin is null then l.city else cl.city end as cidade_origem_compra,
  case when i.id_client_origin is null then l.uf else cl.uf end as uf_origem_compra,
  case when i.id_client_destination is null then l2.city else cl2.city end as cidade_destino_compra,
  case when i.id_client_destination is null then l2.uf else cl2.uf end as uf_destino_compra,
  mor.sale_offer_shipper_tariff_id as id_oferta_venda,
  so.operation_type as operacao_venda,
  c2.trade_name as embarcador_vendedor,
  sost.frequency as frequencia_venda,
  sost.value_total as valor_venda,
  sost.vehicle_type as tipo_veiculo_venda,
  sost.vehicle_category as categoria_veiculo_venda,
  case when LEFT(so.type_location::text, 2) = 'LO' then l3.city else cl3.city end as cidade_origem_venda,
  case when LEFT(so.type_location::text, 2) = 'LO' then l3.uf else cl3.uf end as uf_origem_venda,
  case when RIGHT(so.type_location::text, 2) = 'TY' then l4.city else cl4.city end as cidade_destino_venda,
  case when RIGHT(so.type_location::text, 2) = 'TY' then l4.uf else cl4.uf end as uf_destino_venda,
  sc."name" as transportadora_venda
FROM match_offers_routes mor 
LEFT JOIN idleness i ON i.id = mor.purchase_offer_id 
LEFT JOIN sales_offers so ON so.id = mor.sale_offer_id 
LEFT JOIN sales_offers_shippers_tariff sost ON sost.id = mor.sale_offer_shipper_tariff_id
LEFT JOIN company c ON i.company_id = c.id
LEFT JOIN company c2 ON so.company_id = c2.id
LEFT JOIN locality l ON l.id = i.id_locality_origin
LEFT JOIN locality l2 ON l2.id = i.id_locality_destination
LEFT JOIN locality l3 ON l3.id = so.origin_id
LEFT JOIN locality l4 ON l4.id = so.destination_id
LEFT JOIN client cl ON cl.id = i.id_client_origin
LEFT JOIN client cl2 ON cl2.id = i.id_client_destination
LEFT JOIN client cl3 ON cl3.id = so.origin_id
LEFT JOIN client cl4 ON cl4.id = so.destination_id
left JOIN shipping_company sc on sc.id = sost.shipping_id
WHERE mor.deleted_at IS NULL AND i."deletedAt" IS NULL AND sost.deleted_at IS null and c.status = 'active' and c2.status = 'active' and i.status = 'active' and sost.is_active = true
UNION ALL
-- BLOCO VENDA COMO REFERÊNCIA
SELECT 
  mor.id as match_id,
  'Venda' as tipo_referencia,
  c2.trade_name as embarcador_referencia,
  c.trade_name as embarcador_com_match,
  mor.updated_at::date as data_atualizacao,
  mor.backhaul_type as tipo_backhaul,
  mor.sale_offer_co2 as co2_evitado,
  mor.vehicle_score as score_veiculo,
  mor.origin_distance_score as score_origem,
  mor.destination_distance_score as destino_score,
  mor.total_distance_origin as desvio_origem,
  mor.total_distance_destination as desvio_destino,
  (mor.total_distance_origin + mor.total_distance_destination) as desvio_total,
  mor.distance_purchase_offer as distancia_oferta_compra,
  mor.distance_sale_offer as distancia_oferta_venda,
  mor.purchase_offer_id as id_oferta_compra,
  i.operation_type as operacao_compra,
  c.trade_name as embarcador_comprador,
  i.frequency as frequencia_compra,
  i.freight_value as valor_compra,
  i.vehicle_type as tipo_veiculo_compra,
  i.category as categoria_veiculo_compra,
  case when i.id_client_origin is null then l.city else cl.city end as cidade_origem_compra,
  case when i.id_client_origin is null then l.uf else cl.uf end as uf_origem_compra,
  case when i.id_client_destination is null then l2.city else cl2.city end as cidade_destino_compra,
  case when i.id_client_destination is null then l2.uf else cl2.uf end as uf_destino_compra,
  mor.sale_offer_shipper_tariff_id as id_oferta_venda,
  so.operation_type as operacao_venda,
  c2.trade_name as embarcador_vendedor,
  sost.frequency as frequencia_venda,
  sost.value_total as valor_venda,
  sost.vehicle_type as tipo_veiculo_venda,
  sost.vehicle_category as categoria_veiculo_venda,
  case when LEFT(so.type_location::text, 2) = 'LO' then l3.city else cl3.city end as cidade_origem_venda,
  case when LEFT(so.type_location::text, 2) = 'LO' then l3.uf else cl3.uf end as uf_origem_venda,
  case when RIGHT(so.type_location::text, 2) = 'TY' then l4.city else cl4.city end as cidade_destino_venda,
  case when RIGHT(so.type_location::text, 2) = 'TY' then l4.uf else cl4.uf end as uf_destino_venda,
  sc."name" as transportadora_venda
FROM match_offers_routes mor 
LEFT JOIN idleness i ON i.id = mor.purchase_offer_id 
LEFT JOIN sales_offers so ON so.id = mor.sale_offer_id 
LEFT JOIN sales_offers_shippers_tariff sost ON sost.id = mor.sale_offer_shipper_tariff_id
LEFT JOIN company c ON i.company_id = c.id
LEFT JOIN company c2 ON so.company_id = c2.id
LEFT JOIN locality l ON l.id = i.id_locality_origin
LEFT JOIN locality l2 ON l2.id = i.id_locality_destination
LEFT JOIN locality l3 ON l3.id = so.origin_id
LEFT JOIN locality l4 ON l4.id = so.destination_id
LEFT JOIN client cl ON cl.id = i.id_client_origin
LEFT JOIN client cl2 ON cl2.id = i.id_client_destination
LEFT JOIN client cl3 ON cl3.id = so.origin_id
LEFT JOIN client cl4 ON cl4.id = so.destination_id
left JOIN shipping_company sc on sc.id = sost.shipping_id
WHERE mor.deleted_at IS NULL AND i."deletedAt" IS NULL AND sost.deleted_at IS NULL and c.status = 'active' and c2.status = 'active' and i.status = 'active' and sost.is_active = true
order by match_id desc