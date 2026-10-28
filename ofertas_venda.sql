select sost.id as offer_id, 
sost.created_at::date as data_criacao,
case when sost.is_active is true then 'active' else 'inactive' end as offer_is_active,
so.operation_type, 
so.company_id, 
c.trade_name as company_name, 
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'CLIENT_LOCALITY' then 'CLIENT' else 'LOCALITY' end as origin_local_type,
so.origin_id, 
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'CLIENT_LOCALITY' then cl.city else l.city end as origin_city,
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'CLIENT_LOCALITY' then cl.uf else l.uf end as origin_uf,
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'LOCALITY_CLIENT' then 'CLIENT' else 'LOCALITY' end as destination_local_type,
so.destination_id,
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'LOCALITY_CLIENT' then cl2.city else l2.city end as destination_city,
case when so.type_location = 'CLIENT_CLIENT' or so.type_location = 'LOCALITY_CLIENT' then cl2.uf else l2.uf end as destination_uf,
sost.vehicle_type, 
sost.vehicle_category, 
sost.frequency, 
sost.value_total as offer_value
from sales_offers_shippers_tariff sost
left join sales_offers_shippers sos on sos.id = sost.sale_offer_shipper_id 
left join sales_offers so on so.id = sos.sale_offer_id
left join company c on c.id = so.company_id
left join client cl on cl.id = so.origin_id
left join client cl2 on cl2.id = so.destination_id
left join locality l on l.id = so.origin_id
left join locality l2 on l2.id = so.destination_id
where sost.deleted_at is null