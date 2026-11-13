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
    i.id AS oferta_id, 
    i.created_at::date AS data_criacao, 
    UPPER(i.status) AS oferta_ativa, 
    UPPER(i.operation_type::text) AS tipo_operacao, 
    i.company_id AS empresa_id,
    UPPER(c.trade_name) AS empresa_nome,
    CASE WHEN i.id_client_origin IS NULL THEN 'LOCALITY' ELSE 'CLIENT' END AS tipo_local_origem,
    CASE WHEN i.id_client_origin IS NULL THEN i.id_locality_origin ELSE i.id_client_origin END AS origem_id,
    UPPER(CASE WHEN i.id_client_origin IS NULL THEN l.city ELSE cl.city END) AS cidade_origem,
    UPPER(CASE WHEN i.id_client_origin IS NULL THEN l.uf ELSE cl.uf END) AS uf_origem,
    CASE WHEN i.id_client_destination IS NULL THEN 'LOCALITY' ELSE 'CLIENT' END AS tipo_local_destino,
    CASE WHEN i.id_client_destination IS NULL THEN i.id_locality_destination ELSE i.id_client_destination END AS destino_id,
    UPPER(CASE WHEN i.id_client_destination IS NULL THEN l2.city ELSE cl2.city END) AS cidade_destino,
    UPPER(CASE WHEN i.id_client_destination IS NULL THEN l2.uf ELSE cl2.uf END) AS uf_destino,
    UPPER(i.vehicle_type::text) AS tipo_veiculo, 
    UPPER(i.category::text) AS categoria_veiculo, 
    i.frequency::numeric AS frequencia, 
    i.freight_value::numeric AS valor_oferta
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
    sost.id AS oferta_id, 
    sost.created_at::date AS data_criacao, 
    CASE WHEN sost.is_active IS TRUE THEN 'ACTIVE' ELSE 'INACTIVE' END AS oferta_ativa, 
    UPPER(so.operation_type::text) AS tipo_operacao, 
    so.company_id AS empresa_id,
    UPPER(c.trade_name) AS empresa_nome,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN 'CLIENT' ELSE 'LOCALITY' END AS tipo_local_origem,
    so.origin_id AS origem_id,
    UPPER(CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN cl.city ELSE l.city END) AS cidade_origem,
    UPPER(CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'CLIENT_LOCALITY' THEN cl.uf ELSE l.uf END) AS uf_origem,
    CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN 'CLIENT' ELSE 'LOCALITY' END AS tipo_local_destino,
    so.destination_id AS destino_id,
    UPPER(CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN cl2.city ELSE l2.city END) AS cidade_destino,
    UPPER(CASE WHEN so.type_location = 'CLIENT_CLIENT' OR so.type_location = 'LOCALITY_CLIENT' THEN cl2.uf ELSE l2.uf END) AS uf_destino,
    UPPER(sost.vehicle_type::text) AS tipo_veiculo, 
    UPPER(sost.vehicle_category::text) AS categoria_veiculo, 
    sost.frequency::numeric AS frequencia, 
    sost.value_total::numeric AS valor_oferta
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
  tipo_operacao,
  empresa_id,
  empresa_nome,
  cidade_origem,
  uf_origem,
  cidade_destino,
  uf_destino,
  tipo_veiculo,
  categoria_veiculo,
  COUNT(oferta_id) AS quantidade_de_ofertas,
  SUM(frequencia) AS total_viagens,
  AVG(valor_oferta) AS valor_medio
FROM ofertas_consolidadas
GROUP BY 
  tipo_oferta,
  tipo_operacao,
  empresa_id,
  empresa_nome,
  cidade_origem,
  uf_origem,
  cidade_destino,
  uf_destino,
  tipo_veiculo,
  categoria_veiculo
ORDER BY 
  tipo_oferta, 
  empresa_nome;
