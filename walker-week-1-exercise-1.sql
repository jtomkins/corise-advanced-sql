/*
1. inspect data, check customer addresses for any null city or state fields
2. check resource us cities for dupes
3. join customers against resource us cities use set operator to review missing records missing
4. clean up resource us cities by eliminating dupes and trailing white spaces
5. get hung up on what it means for a customer to be eligable and if there is some hidden meaning
6. join suppliers against resource us cities confirm that all 10 records match
7. research functions for calculating distance using geo data, reviewed snowflake Geospatial Functions line haversine and st_distance
8. arrive at conclusion that data sets should be cross joined to be able to evaluate which location is closest
9. review/refresh window functions (not discussed in week 1) decideded to use rank for more clarity 
10. noticed snowflakes newish qualify clause to filter the result of window function, decided not to use becaus newish
    to snowflake and the Snowflake syntax for QUALIFY is not part of the ANSI standard.
11. check final record count  
*/

with 
---------------------------------------------------------------------
-- de dupe, remove white space, and put city and state in lower case
-- decided to do it the old fashion way (not use window functions or qualify clause)
---------------------------------------------------------------------
vk_us_cities as (
    select  
        lower(trim(city_name)) as city,
        lower(state_abbr) as state,
        min(lat) as lat,
        min(long) as long
    from vk_data.resources.us_cities
    group by 1,2
  
),
---------------------------------------------------------------------------------
-- customers only eligible if they have a city in the us cities resources table
---------------------------------------------------------------------------------
vk_customer_address_with_geo as (
    select 
        customer_data.customer_id as customer_id,
        first_name as customer_first_name,
        last_name as customer_last_name,
        email as customer_email,
        customer_city,
        customer_state,
        lat as customer_lat,
        long as customer_long
    from vk_data.customers.customer_address
    inner join
        vk_data.customers.customer_data on
            vk_data.customers.customer_data.customer_id = vk_data.customers.customer_address.customer_id
    inner join vk_us_cities on lower(vk_us_cities.state) = lower(vk_data.customers.customer_address.customer_state)
        and lower(trim(vk_us_cities.city)) = lower(trim(vk_data.customers.customer_address.customer_city))
    where customer_city is not null
        or customer_state is not null
),
---------------------------------------------------------------------------------
-- Include suppliers geo data
---------------------------------------------------------------------------------
vk_supplier_details_with_geo as (
    select   
        supplier_id,
        supplier_name,
        supplier_city,
        supplier_state,
        lat as supplier_lat,
        long as supplier_long 
    from vk_data.suppliers.supplier_info
    inner join vk_us_cities 
        on lower(vk_us_cities.state) = lower(vk_data.suppliers.supplier_info.supplier_state)
            and lower(trim(vk_us_cities.city)) = lower(trim(vk_data.suppliers.supplier_info.supplier_city))
),
---------------------------------------------------------------------------------
-- cross join to include every supplier geo result so can calculate distance against each supplier record
-- use window function A window function is any function that operates over a window of rows
-- use rank function to rank value within the ordered group of values with the window function 
-- could use qualify clause to filter the result of window function however this clause is new to snowflake and the Snowflake syntax for QUALIFY is not part of the ANSI standard.
---------------------------------------------------------------------------------
vk_customer_cross_rank as (
    select
        customer_id,
        customer_first_name,
        customer_last_name,
        customer_email,
        supplier_id,
        supplier_name, 
        st_distance(
            st_makepoint(supplier_long, supplier_lat), st_makepoint(customer_long, customer_lat)
        ) / 1609 as shipping_distance_in_miles,
        rank() over (partition by customer_id order by shipping_distance_in_miles) as distance_rank
    from vk_customer_address_with_geo
    cross join vk_supplier_details_with_geo
    order by shipping_distance_in_miles
),
vk_customer_results as (
    select
        customer_id,
        customer_first_name,
        customer_last_name,
        customer_email,
        supplier_id,
        supplier_name, 
        shipping_distance_in_miles
    from vk_customer_cross_rank
    where distance_rank = 1
    order by 3, 2
)

select *
from vk_customer_results


