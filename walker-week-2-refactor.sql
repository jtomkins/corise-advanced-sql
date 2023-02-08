with 
    --Start each CTE on its own line, 
    --indented one level more than with (including the first one, and even if there is only one)
    vk_customers as (
        select 
            customer_id,
            first_name || ' ' || last_name as customer_name
        from vk_data.customers.customer_data
    ),

    --Use a single blank line around CTEs to add visual separation.   
    vk_customer_addresses as (
        select
            customer_id,
            customer_city,
            customer_state
        from vk_data.customers.customer_address
    ),

    vk_survey_food_pref_count as (
        select 
            customer_id,
            count(*) as food_pref_count
        from vk_data.customers.customer_survey
        where is_active = true
        group by 1

    ),

    vk_resources_cities as (
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
            --case statements https://github.com/brooklyn-data/co/blob/main/sql_style_guide.md#case-statements
            case 
                when lower(trim(city_name)) = 'chicago' 
                    and lower(trim(state_abbr)) = 'il' 
                    then geo_location 
            end as chicago_geo_location 
        from vk_data.resources.us_cities
        where  lower(trim(city_name)) = 'chicago' and lower(trim(state_abbr)) = 'il'
    ),

    vk_gary_in_geo as (
        select  
            city_id,
            case 
                when lower(trim(city_name)) = 'gary' 
                    and lower(trim(state_abbr)) = 'in' 
                    then geo_location 
            end as gary_geo_location
        from vk_data.resources.us_cities
        where lower(trim(city_name)) = 'gary' and lower(trim(state_abbr)) = 'in'
    )

select 
    --When joining multiple tables, always prefix the column names with the table name/alias.
    vk_customers.customer_id,
    vk_customers.customer_name,
    vk_customer_addresses.customer_city,
    vk_customer_addresses.customer_state,
    vk_chicago_il_geo.chicago_geo_location,
    vk_gary_in_geo.gary_geo_location,
    vk_resources_cities.city_name
from vk_customers
-- Put the initial table being selected from on the same line as from
inner join vk_customer_addresses on vk_customers.customer_id = vk_customer_addresses.customer_id

--cte rather than subselect
-- CTEs will make your queries more straightforward to read/reason about, 
-- can be referenced multiple times, and are easier to adapt/refactor later
-- Put the initial table being selected from on the same line as from
inner join vk_survey_food_pref_count on vk_customer_addresses.customer_id = vk_survey_food_pref_count.customer_id

left outer join vk_resources_cities 
    -- Put the initial table being selected from on the same line as from
    -- replace ltrim/rtrim with trim
    -- changed upper to lower for consistancy in matching on cases
    on lower(trim(vk_resources_cities.state_abbr)) = lower(trim(vk_customer_addresses.customer_state))
        and lower(trim(vk_resources_cities.city_name)) = lower(trim(vk_customer_addresses.customer_city)) 

--cte rather than subselect
-- CTEs will make your queries more straightforward to read/reason about, 
-- can be referenced multiple times, and are easier to adapt/refactor later
cross join vk_chicago_il_geo
cross join vk_gary_in_geo

where 
    (
        lower(customer_state) = 'ky'
        and lower(trim(vk_resources_cities.city_name)) in ('concord','georgetown', 'ashland')
    )
    or
    (
        lower(customer_state) = 'ca'
        and lower(trim(vk_resources_cities.city_name)) in('oakland','pleasant hill')
    )
    or
    (
        lower(customer_state) = 'tx' 
        and lower(trim(vk_resources_cities.city_name)) in('arlington','brownsville')
    -- is this a bug? was it intended to pick up the brownsville in FL and OH?
    --and lower(trim(vk_resources_cities.city_name)) in('arlington') or lower(trim(vk_resources_cities.city_name)) in ('brownsville')
    )