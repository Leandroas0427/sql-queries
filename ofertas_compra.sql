SELECT 
  i.id AS offer_id, 
  i.created_at::date AS data_criacao, 
  i.status AS offer_is_active, 
  i.operation_type, 
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
  i.vehicle_type, 
  i.category AS vehicle_category, 
  i.frequency, 
  i.freight_value AS offer_value
FROM idleness i
LEFT JOIN company c ON c.id = i.company_id
LEFT JOIN client cl ON cl.id = i.id_client_origin 
LEFT JOIN client cl2 ON cl2.id = i.id_client_destination
LEFT JOIN locality l ON l.id = i.id_locality_origin
LEFT JOIN locality l2 ON l2.id = i.id_locality_destination
WHERE i."deletedAt" IS NULL
