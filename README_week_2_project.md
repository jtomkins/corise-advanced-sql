##  Week 2 Project 2 Instructions: Rework a Query to Improve Its Readability
# Exercise
Virtual Kitchen has an emergency! 

We shipped several meal kits without including fresh parsley, and our customers are starting to complain. We have identified the impacted cities, and we know that 25 of our customers did not get their parsley. That number might seem small, but Virtual Kitchen is committed to providing every customer with a great experience.

Our management has decided to provide a different recipe for free (if the customer has other preferences available), or else use grocery stores in the greater Chicago area to send an overnight shipment of fresh parsley to our customers. We have one store in Chicago, IL and one store in Gary, IN both ready to help out with this request.

Last night, our on-call developer created a query to identify the impacted customers and their attributes in order to compose an offer to these customers to make things right. But the developer was paged at 2 a.m. when the problem occurred, and she created a fast query so that she could go back to sleep.

You review her code today and decide to reformat her query so that she can catch up on sleep.

Here is the query she emailed you. Refactor it to apply a consistent format, and add comments that explain your choices. We are going to review different options in the lecture, so if you are willing to share your refactored query with the class, then let us know!

<details>
    <summary>Click to see Legacy Query with notes for sql format rules</summary>

  ```sql
select 
    first_name || ' ' || last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    s.food_pref_count,
    (st_distance(us.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(us.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles

-- Avoid aliases in from clauses and join conditions.   
from vk_data.customers.customer_address as ca
 
--Join clauses should be fully qualified.  
--Implicit/explicit aliasing of table
--Avoid aliases in from clauses and join conditions
join vk_data.customers.customer_data c on ca.customer_id = c.customer_id

--join clauses should be fully qualified
--Implicit/explicit aliasing of table
--Avoid aliases in from clauses and join conditions
left join vk_data.resources.us_cities us 

--Function names must be lower case
on UPPER(rtrim(ltrim(ca.customer_state))) = upper(TRIM(us.state_abbr))
    and trim(lower(ca.customer_city)) = trim(lower(us.city_name))

--Join clauses should be fully qualified
join (
    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1

--Implicit/explicit aliasing of table    
) s on c.customer_id = s.customer_id
    cross join 
    ( select 
        geo_location
    from vk_data.resources.us_cities 

    --Implicit/explicit aliasing of table
    where city_name = 'CHICAGO' and state_abbr = 'IL') chic
cross join 
    ( select 
        geo_location
    from vk_data.resources.us_cities 

    --Implicit/explicit aliasing of table
    where city_name = 'GARY' and state_abbr = 'IN') gary
where 
    ((trim(city_name) ilike '%concord%' or trim(city_name) ilike '%georgetown%' or trim(city_name) ilike '%ashland%')
    and customer_state = 'KY')
    or
    (customer_state = 'CA' and (trim(city_name) ilike '%oakland%' or trim(city_name) ilike '%pleasant hill%'))
    or
    (customer_state = 'TX' and (trim(city_name) ilike '%arlington%') or trim(city_name) ilike '%brownsville%')

  ```
</details>

### Refactored Query
```sql
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
```

#### Link to Query in Repo
[walker-week-2-refactor.sql](https://github.com/jtomkins/corise-advanced-sql/blob/advanced-sql-week-2-exercises/walker-week-2-refactor.sql)

#### Result set with brownsville in TX returns 19 records instead of 25
![image](https://user-images.githubusercontent.com/8420258/217927170-4a7878b3-ecfe-409b-892c-a50b23384634.png)

