-- BLOCO COMPRA COMO REFERÊNCIA
SELECT 
  mor.id AS match_id,
  'Compra' AS tipo_referencia,
  c.trade_name AS embarcador_referencia,
  c2.trade_name AS embarcador_com_match,
  mor.updated_at::date AS data_atualizacao,
  mor.backhaul_type AS tipo_backhaul,
  mor.sale_offer_co2 AS co2_evitado,
  mor.vehicle_score AS score_veiculo,
  mor.origin_distance_score AS score_origem,
  mor.destination_distance_score AS destino_score,
  mor.total_distance_origin AS desvio_origem,
  mor.total_distance_destination AS desvio_destino,
  (mor.total_distance_origin + mor.total_distance_destination) AS desvio_total,
  mor.distance_purchase_offer AS distancia_oferta_compra,
  mor.distance_sale_offer AS distancia_oferta_venda,
  mor.purchase_offer_id AS id_oferta_compra,
  i.operation_type AS operacao_compra,
  c.trade_name AS embarcador_comprador,
  i.frequency AS frequencia_compra,
  i.freight_value AS valor_compra,
  i.vehicle_type AS tipo_veiculo_compra,
  i.category AS categoria_veiculo_compra,
  CASE WHEN i.id_client_origin IS NULL THEN l.city ELSE cl.city END AS cidade_origem_compra,
  CASE WHEN i.id_client_origin IS NULL THEN l.uf ELSE cl.uf END AS uf_origem_compra,
  CASE WHEN i.id_client_destination IS NULL THEN l2.city ELSE cl2.city END AS cidade_destino_compra,
  CASE WHEN i.id_client_destination IS NULL THEN l2.uf ELSE cl2.uf END AS uf_destino_compra,
  mor.sale_offer_shipper_tariff_id AS id_oferta_venda,
  so.operation_type AS operacao_venda,
  c2.trade_name AS embarcador_vendedor,
  sost.frequency AS frequencia_venda,
  sost.value_total AS valor_venda,
  sost.vehicle_type AS tipo_veiculo_venda,
  sost.vehicle_category AS categoria_veiculo_venda,
  CASE WHEN LEFT(so.type_location::text, 2) = 'LO' THEN l3.city ELSE cl3.city END AS cidade_origem_venda,
  CASE WHEN LEFT(so.type_location::text, 2) = 'LO' THEN l3.uf ELSE cl3.uf END AS uf_origem_venda,
  CASE WHEN RIGHT(so.type_location::text, 2) = 'TY' THEN l4.city ELSE cl4.city END AS cidade_destino_venda,
  CASE WHEN RIGHT(so.type_location::text, 2) = 'TY' THEN l4.uf ELSE cl4.uf END AS uf_destino_venda,
  sc."name" AS transportadora_venda
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
LEFT JOIN shipping_company sc ON sc.id = sost.shipping_id
WHERE mor.deleted_at IS NULL 
  AND i."deletedAt" IS NULL 
  AND sost.deleted_at IS NULL 
  AND c.status = 'active' 
  AND c2.status = 'active' 
  AND i.status = 'active' 
  AND sost.is_active = TRUE

UNION ALL

-- BLOCO VENDA COMO REFERÊNCIA
SELECT 
  mor.id AS match_id,
  'Venda' AS tipo_referencia,
  c2.trade_name AS embarcador_referencia,
  c.trade_name AS embarcador_com_match,
  mor.updated_at::date AS data_atualizacao,
  mor.backhaul_type AS tipo_backhaul,
  mor.sale_offer_co2 AS co2_evitado,
  mor.vehicle_score AS score_veiculo,
  mor.origin_distance_score AS score_origem,
  mor.destination_distance_score AS destino_score,
  mor.total_distance_origin AS desvio_origem,
  mor.total_distance_destination AS desvio_destino,
  (mor.total_distance_origin + mor.total_distance_destination) AS desvio_total,
  mor.distance_purchase_offer AS distancia_oferta_compra,
  mor.distance_sale_offer AS distancia_oferta_venda,
  mor.purchase_offer_id AS id_oferta_compra,
  i.operation_type AS operacao_compra,
  c.trade_name AS embarcador_comprador,
  i.frequency AS frequencia_compra,
  i.freight_value AS valor_compra,
  i.vehicle_type AS tipo_veiculo_compra,
  i.category AS categoria_veiculo_compra,
  CASE WHEN i.id_client_origin IS NULL THEN l.city ELSE cl.city END AS cidade_origem_compra,
  CASE WHEN i.id_client_origin IS NULL THEN l.uf ELSE cl.uf END AS uf_origem_compra,
  CASE WHEN i.id_client_destination IS NULL THEN l2.city ELSE cl2.city END AS cidade_destino_compra,
  CASE WHEN i.id_client_destination IS NULL THEN l2.uf ELSE cl2.uf END AS uf_destino_compra,
  mor.sale_offer_shipper_tariff_id AS id_oferta_venda,
  so.operation_type AS operacao_venda,
  c2.trade_name AS embarcador_vendedor,
  sost.frequency AS frequencia_venda,
  sost.value_total AS valor_venda,
  sost.vehicle_type AS tipo_veiculo_venda,
  sost.vehicle_category AS categoria_veiculo_venda,
  CASE WHEN LEFT(so.type_location::text, 2) = 'LO' THEN l3.city ELSE cl3.city END AS cidade_origem_venda,
  CASE WHEN LEFT(so.type_location::text, 2) = 'LO' THEN l3.uf ELSE cl3.uf END AS uf_origem_venda,
  CASE WHEN RIGHT(so.type_location::text, 2) = 'TY' THEN l4.city ELSE cl4.city END AS cidade_destino_venda,
  CASE WHEN RIGHT(so.type_location::text, 2) = 'TY' THEN l4.uf ELSE cl4.uf END AS uf_destino_venda,
  sc."name" AS transportadora_venda
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
LEFT JOIN shipping_company sc ON sc.id = sost.shipping_id
WHERE mor.deleted_at IS NULL 
  AND i."deletedAt" IS NULL 
  AND sost.deleted_at IS NULL 
  AND c.status = 'active' 
  AND c2.status = 'active' 
  AND i.status = 'active' 
  AND sost.is_active = TRUE
ORDER BY match_id DESC
