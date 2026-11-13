/*
=============================================================================
Descrição:      Agrupamento consolidado de Ofertas de Compra e Venda
Granularidade:  Rota, Embarcador, Operação e Categoria de Veículo
=============================================================================
*/
WITH ofertas_consolidadas AS (
  -- BLOCO 1: OFERTAS DE COMPRA (OCIOSIDADE)
  SELECT 
    'COMPRA' AS tipo_oferta,
    i.id AS offer_id, 
    i.created_at::date AS data_criacao, 
    i.status AS offer_is_active, 
    i.operation_type::text AS operation_type, 
    i.company_id,
    c.trade_name AS company_name,
    CASE WHEN i.id_client_origin IS NULL THEN 'LOCALITY' ELSE 'CLIENT' END AS origin_local_type,
    CASE WHEN i.id_client_origin IS NULL THEN i.id_locality_origin ELSE i.id_client_origin END AS origin_id,
    CASE WHEN i.id_client_origin IS NULL THEN l.city ELSE cl.city END AS origin_city,
    CASE WHEN i.id_client_origin IS NULL THEN l.uf ELSE cl.uf END AS origin_uf,
    CASE WHEN i.id_client_destination IS NULL THEN 'LOCALITY' ELSE 'CLIENT' END AS destination_local_type,
    CASE WHEN i.id_client_destination IS NULL THEN i.id_locality_destination ELSE i.id_client_destination END AS destination_id,
    CASE WHEN i.id_client_destination IS NULL THEN l2.city ELSE cl2.city END AS destination_city,
    CASE WHEN i.id_client_destination IS NULL THEN l2.uf ELSE cl2.uf END AS destination_uf,
    i.vehicle_type::text AS vehicle_type, 
    i.category::text AS vehicle_category, 
    i.frequency::numeric AS frequency, 
    i.freight_value::numeric AS offer_value
  FROM idleness i
  LEFT JOIN company c ON c.id = i.company_id
  LEFT JOIN client cl ON cl.id = i.id_client_origin 
  LEFT JOIN client cl2 ON cl2.id = i.id_client_destination
  LEFT JOIN locality l ON l.id = i.id_locality_origin
  LEFT JOIN locality l2 ON l2.id = i.id_locality_destination
  WHERE i."deletedAt" IS NULL
-- ----------------------------------------------------------------------------
  UNION ALL
-- ----------------------------------------------------------------------------
  -- BLOCO 2: OFERTAS DE VENDA
  SELECT 
    'VENDA' AS tipo_oferta,
    sost.id AS offer_id, 
    sost.created_at::date AS data_criacao,
    CASE WHEN sost.is_active IS TRUE THEN 'active' ELSE 'inactive' END AS offer_is_active,
    so.operation_type::text AS operation_type, 
    so.company_id, 
    c.trade_name AS company_name, 
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN 'CLIENT' ELSE 'LOCALITY' END AS origin_local_type,
    so.origin_id, 
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN cl.city ELSE l.city END AS origin_city,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN cl.uf ELSE l.uf END AS origin_uf,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN 'CLIENT' ELSE 'LOCALITY' END AS destination_local_type,
    so.destination_id,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN cl2.city ELSE l2.city END AS destination_city,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN cl2.uf ELSE l2.uf END AS destination_uf,
    sost.vehicle_type::text AS vehicle_type, 
    sost.vehicle_category::text AS vehicle_category, 
    sost.frequency::numeric AS frequency, 
    sost.value_total::numeric AS offer_value
  FROM sales_offers_shippers_tariff sost
  LEFT JOIN sales_offers_shippers sos ON sos.id = sost.sale_offer_shipper_id 
  LEFT JOIN sales_offers so ON so.id = sos.sale_offer_id
  LEFT JOIN company c ON c.id = so.company_id
  LEFT JOIN client cl ON cl.id = so.origin_id
  LEFT JOIN client cl2 ON cl2.id = so.destination_id
  LEFT JOIN locality l ON l.id = so.origin_id
  LEFT JOIN locality l2 ON l2.id = so.destination_id
  WHERE sost.deleted_at IS NULL
)
-- Agrupamento e Métricas
SELECT 
  tipo_oferta,
  operation_type,
  company_id,
  company_name,
  origin_city,
  origin_uf,
  destination_city,
  destination_uf,
  vehicle_type,
  vehicle_category,
  COUNT(offer_id) AS quantidade_de_ofertas,
  SUM(frequency) AS total_viagens,
  AVG(offer_value) AS valor_medio
FROM ofertas_consolidadas
GROUP BY 
  tipo_oferta,
  operation_type,
  company_id,
  company_name,
  origin_city,
  origin_uf,
  destination_city,
  destination_uf,
  vehicle_type,
  vehicle_category
ORDER BY 
  tipo_oferta, 
  company_name;
