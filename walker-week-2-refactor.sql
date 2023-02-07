select 
    first_name || ' ' || last_name as customer_name,
    vk_data.customers.customer_address.customer_city,
    vk_data.customers.customer_address.customer_state,
    s.food_pref_count,
    (st_distance(vk_data.resources.us_cities.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(vk_data.resources.us_cities.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles
from vk_data.customers.customer_address
inner join
    vk_data.customers.customer_data on
        vk_data.customers.customer_address.customer_id = vk_data.customers.customer_data.customer_id
left outer join vk_data.resources.us_cities 
    on
        upper(
            rtrim(ltrim(vk_data.customers.customer_address.customer_state))
        ) = upper(trim(vk_data.resources.us_cities.state_abbr))
        and trim(
            lower(vk_data.customers.customer_address.customer_city)
        ) = trim(lower(vk_data.resources.us_cities.city_name))
inner join (
    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1
) as s on vk_data.customers.customer_data.customer_id = s.customer_id
cross join 
    ( select 
        geo_location
        from vk_data.resources.us_cities 
        where city_name = 'CHICAGO' and state_abbr = 'IL') as chic
cross join 
    ( select 
        geo_location
        from vk_data.resources.us_cities 
        where city_name = 'GARY' and state_abbr = 'IN') as gary
where 
    ((trim(city_name) ilike '%concord%' or trim(city_name) ilike '%georgetown%' or trim(city_name) ilike '%ashland%')
        and customer_state = 'KY')
    or
    (customer_state = 'CA' and (trim(city_name) ilike '%oakland%' or trim(city_name) ilike '%pleasant hill%'))
    or
    (customer_state = 'TX' and (trim(city_name) ilike '%arlington%') or trim(city_name) ilike '%brownsville%')