/* steps

1. re-use logic for eligable customers
2. If the customer completed a survey about their food interests, 
    then we also want to include up to three of their choices in a personalized email message,
   a. join result set from eligable customers on customers.customer_survey, resources.recipe_tags
   b. use rank to number customer preferences to be used for logic to include 3 or less choies as well as part of column header
3. pivot data to transform preference choices from rows to columns
4. flatten the array tag list to get all tags for each recipe
5. get suggested recipe to be one recipe where tag_property matches customer preference
6. get final result by joining customer id from pivoted customer details and preferences with suggested recipe   

*/


---------------------------------------------------------------------------------
-- clean us cities
-- re-use logic for eligable customers
-- customers only eligible if they have a city in the us cities resources table
---------------------------------------------------------------------------------
with 
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
-- re-use logic for eligable customers
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
-------------------------------------------------------------------
-- If the customer completed a survey about their food interests, 
-- then we also want to include up to three of their choices in a personalized email message.
-- If the customer has more than three food preferences, 
-- then return the first three, sorting in alphabetical order. 
-----------------------------------------------------------------
customer_food_interests as (
    select *
    from (select 
        vk_customer_address_with_geo.customer_id,
        customer_email,
        customer_first_name,
        vk_data.resources.recipe_tags.tag_id,
        lower(trim(vk_data.resources.recipe_tags.tag_property)) as food_preference,
        rank() over (
            partition by vk_customer_address_with_geo.customer_id order by tag_property
        ) as food_preference_sequence
        from  vk_data.customers.customer_survey
        inner join  vk_customer_address_with_geo 
            on vk_customer_address_with_geo.customer_id = vk_data.customers.customer_survey.customer_id
        inner join vk_data.resources.recipe_tags 
            on vk_data.customers.customer_survey.tag_id = vk_data.resources.recipe_tags.tag_id
        where is_active = TRUE )
    where food_preference_sequence <= 3
    order by 5      
),
---------------------------------------------------------------------------------
-- pivot data transforms preference choices data from rows to columns
---------------------------------------------------------------------------------
pivoted_customer_preferences as (
    select *
    from (select 
            customer_food_interests.customer_id,
            customer_email,
            customer_first_name,
            lower(trim(food_preference)) as food_preference,
            'food_preference_'|| food_preference_sequence as title
            from customer_food_interests
        )  
    pivot(  min(food_preference) --legit agg?
        for title in ( 'food_preference_1', 'food_preference_2', 'food_preference_3'))
    as p (customer_id,  customer_email, customer_first_name,food_preference_1, food_preference_2, food_preference_3)
    order by 1
),
----------------------------------------------------------------------
-- flatten the recipe table to get all of the tags for each recipe
--------------------------------------------------------------------
flatten_recipe as (
    select  recipe_id as recipe_id,
            recipe_name,
        lower(trim(flat_tag_list.value))::string as flat_tags
    from chefs.recipe,
        table(flatten(tag_list)) as flat_tag_list
),
----------------------------------------------------------------------
-- only need one recipe where tag_property matches
--------------------------------------------------------------------
suggested_recipe as(
    select
        pivoted_customer_preferences.customer_id,
        min(recipe_name) as recipe_name
    from pivoted_customer_preferences
    inner join flatten_recipe on flat_tags = food_preference_1
    group by 1
),
result as (
    select 
        pivoted_customer_preferences.customer_id,
        pivoted_customer_preferences.customer_email,
        customer_first_name,
        food_preference_1,
        food_preference_2,
        food_preference_3,
        recipe_name
    from  pivoted_customer_preferences
    inner join suggested_recipe on pivoted_customer_preferences.customer_id = suggested_recipe.customer_id
    order by 2
)
select *
from result
