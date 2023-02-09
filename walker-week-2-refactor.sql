-- refactor using ctes rather than subselect
-- CTEs will make your queries more straightforward to read/reason about, 
-- can be referenced multiple times, and are easier to adapt/refactor later
with 
    --Start each CTE on its own line, 
    --indented one level more than with (including the first one, and even if there is only one)
    --Use a single blank line around CTEs to add visual separation.  
    vk_customers as (
        select 
            customer_id,
            first_name || ' ' || last_name as customer_name
        from vk_data.customers.customer_data
    ),

    -- refactor to include the filter on specific customer states and cities
    -- needs more analysis with original developer and/or biz since multiple brownsville cities, 
    -- and not clear intended only for browsnvilee texas
    vk_customer_addresses as (
        select
            customer_id,
            customer_city,
            customer_state
        from vk_data.customers.customer_address
        where (lower(customer_state) = 'ky' and lower(trim(customer_city)) in ('concord','georgetown','ashland'))
           or (lower(customer_state) = 'ca' and lower(trim(customer_city)) in ('oakland','pleasant hill'))
           or (lower(customer_state) = 'tx' and lower(trim(customer_city)) in ('arlington','brownsville'))   
         
    ),

    vk_survey_food_pref_count as (
        select 
            customer_id,
            count(*) as food_pref_count
        from vk_data.customers.customer_survey
        where is_active = true
        group by 1

    ),

    vk_us_cities as (
        select  
            city_id,
            city_name,
            state_abbr,
            geo_location
        from vk_data.resources.us_cities
        
    ),

    vk_chicago_il_geo as (
        select  
            city_id,
            geo_location as chicago_geo_location 
        from vk_data.resources.us_cities
        where  lower(trim(city_name)) = 'chicago' and lower(trim(state_abbr)) = 'il'
    ),

    vk_gary_in_geo as (
        select  
            city_id,
            geo_location as gary_geo_location
        from vk_data.resources.us_cities
        where lower(trim(city_name)) = 'gary' and lower(trim(state_abbr)) = 'in'
    ),

result as (
    
    select 
    --When joining multiple tables, always prefix the column names with the table name/alias.
    vk_customers.customer_name,
    vk_customer_addresses.customer_city,
    vk_customer_addresses.customer_state,
    vk_survey_food_pref_count.food_pref_count,
    (st_distance(vk_us_cities.geo_location, vk_chicago_il_geo.chicago_geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(vk_us_cities.geo_location, vk_gary_in_geo.gary_geo_location) / 1609)::int as gary_distance_miles
from vk_customers

-- Put the initial table being selected from on the same line as from
inner join vk_customer_addresses on vk_customers.customer_id = vk_customer_addresses.customer_id

-- Put the initial table being selected from on the same line as from
inner join vk_survey_food_pref_count on vk_customer_addresses.customer_id = vk_survey_food_pref_count.customer_id

-- Put the initial table being selected from on the same line as from
-- replace ltrim/rtrim with trim
-- changed upper to lower for consistancy in matching on cases
inner join vk_us_cities 
    on lower(trim(vk_us_cities.state_abbr)) = lower(trim(vk_customer_addresses.customer_state))
        and lower(trim(vk_us_cities.city_name)) = lower(trim(vk_customer_addresses.customer_city)) 
cross join vk_chicago_il_geo
cross join vk_gary_in_geo
)

select *
from result