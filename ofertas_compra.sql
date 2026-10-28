select i.id as offer_id, 
i.created_at::date as data_criacao, 
i.status as offer_is_active, 
i.operation_type, 
i.company_id,
c.trade_name as company_name,
case when i.id_client_origin is null then 'LOCALITY' else 'CLIENT' end as origin_local_type,
case when i.id_client_origin is null then i.id_locality_origin else i.id_client_origin end as origin_id,
case when i.id_client_origin is null then l.city else cl.city end as origin_city,
case when i.id_client_origin is null then l.uf else cl.uf end as origin_uf,
case when i.id_client_destination is null then 'LOCALITY' else 'CLIENT' end as destination_local_type,
case when i.id_client_destination is null then i.id_locality_destination else i.id_client_destination end as destination_id,
case when i.id_client_destination is null then l2.city else cl2.city end as destination_city,
case when i.id_client_destination is null then l2.uf else cl2.uf end as destination_uf,
i.vehicle_type, 
i.category as vehicle_category, 
i.frequency, 
i.freight_value as offer_value
from idleness i
left join company c on c.id = i.company_id
left join client cl on cl.id = i.id_client_origin 
left join client cl2 on cl2.id = i.id_client_destination
left join locality l on l.id = i.id_locality_origin
left join locality l2 on l2.id = i.id_locality_destination
where i."deletedAt" is null