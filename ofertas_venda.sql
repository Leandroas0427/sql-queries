SELECT 
  sost.id AS offer_id, 
  sost.created_at::date AS data_criacao,
  CASE WHEN sost.is_active IS TRUE THEN 'active' ELSE 'inactive' END AS offer_is_active,
  so.operation_type, 
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
  sost.vehicle_type, 
  sost.vehicle_category, 
  sost.frequency, 
  sost.value_total AS offer_value
FROM sales_offers_shippers_tariff sost
LEFT JOIN sales_offers_shippers sos ON sos.id = sost.sale_offer_shipper_id 
LEFT JOIN sales_offers so ON so.id = sos.sale_offer_id
LEFT JOIN company c ON c.id = so.company_id
LEFT JOIN client cl ON cl.id = so.origin_id
LEFT JOIN client cl2 ON cl2.id = so.destination_id
LEFT JOIN locality l ON l.id = so.origin_id
LEFT JOIN locality l2 ON l2.id = so.destination_id
WHERE sost.deleted_at IS NULL
