### Project 3 Instructions: Write an Event-Based Query That Will Scale with Business Growth

The Virtual Kitchen developers are making some changes to the search functionality on the website. After gathering customer feedback, they want to change the recipe suggestion algorithm in order to improve the customer experience.

We have a beta version of the website available and have opened it for use by a small number of customers. Next week we plan to increase this number from 200 customers to 5,000. To ensure everything is ready for the test, we have implemented logging and are saving results to a table in Snowflake called vk_data.events.website_activity.

The table contains: 
event_id: A unique identifier for the user action on the website
* session_id: The identifier for the user session
* user_id: The identifier for the logged-in user
* event_timestamp: Time of the event
* event_details: Details about the event in JSON — what action was performed by the user?

Once we expand the beta version, we expect the website_activity table to grow very quickly. While it is still fairly small, we need to develop a query to measure the impact of the changes to our search algorithm. Please create a query and review the query profile to ensure that the query will be efficient once the activity increases.

We want to create a daily report to track:

* Total unique sessions
* The average length of sessions in seconds
* The average number of searches completed before displaying a recipe 
* The ID of the recipe that was most viewed 

In addition to your query, please submit a short description of what you determined from the query profile and how you structured your query to plan for a higher volume of events once the website tra

## Query

Steps:
1. run query profiler to see the difference when using distinct vs. group by
2. experimented with different queries then came up with this one, to find a balance between how to solve avg searches before displaying a recipe (could only see it as two seperate queries)

``` sql
--ALTER SESSION UNSET USE_CACHED_RESULT = FALSE

with 
--The length of sessions in seconds per day
vk_sessions as (
	select 
        session_id, 
        date(event_timestamp) as event_day,
        min(event_timestamp) as min_event_time,
        max(event_timestamp) as max_event_time
	from vk_data.events.website_activity
	group by 1,2
),
--The average number of searches completed per day before displaying a recipe
--1. find session with recipe
vk_sessions_with_recipe as (
        
    select 
        parse_json(event_details):recipe_id::string, 
        session_id
    from vk_data.events.website_activity
    where parse_json(event_details):recipe_id is not null
    group by 1,2
        
),

--The average number of searches completed per day before displaying a recipe
-- 2. match on session id with recipe where same session id has page and event = search
vk_session_searches as(

    select 
        vk_sessions_with_recipe.session_id,
        count(*) as total_session_searches
    from vk_data.events.website_activity
    inner join
        vk_sessions_with_recipe on vk_sessions_with_recipe.session_id = vk_data.events.website_activity.session_id
    where parse_json(event_details):page::string = 'search'
        and parse_json(event_details):event::string = 'search'
    group by 1

),
--The ID of the recipe that was most viewed
--some recipes are tied, use row number to break tie
vk_top_recipe_views as (

    select 
        parse_json(event_details):recipe_id::string as recipe_id,
        date(event_timestamp) as event_day,
        count(*) as recipe_views_count,
        row_number() over ( partition by date(event_timestamp) order by recipe_views_count desc) as recipe_rank
    from vk_data.events.website_activity
    where parse_json(event_details):event::string = 'view_recipe'
    group by 1,2
    qualify recipe_rank = 1

)

--final report query
-- used left join to include the day that had sessions of 0 seconds and no other metrics
select 
    vk_sessions.event_day,
    vk_top_recipe_views.recipe_id as most_viewed_recipe,
    count(vk_sessions.session_id) as number_of_unique_sessions,
    --the average length of sessions in seconds
    round(
        avg(datediff(seconds,vk_sessions.min_event_time,vk_sessions.max_event_time))
    ) as avg_session_length_in_seconds,
    --The average number of searches completed per day before displaying a recipe
    round(nvl(avg(vk_session_searches.total_session_searches), 0)) as avg_num_searches_before_view_recipe
from vk_sessions
left outer join vk_session_searches on vk_sessions.session_id = vk_session_searches.session_id
left outer join vk_top_recipe_views on vk_sessions.event_day = vk_top_recipe_views.event_day
group by 1,2
```
## Query Results
![image](https://user-images.githubusercontent.com/8420258/219904907-96a3bb3f-525e-4b7b-b2ab-020d4d96cdd7.png)



<details>
    <summary>Click to see final query profile:</summary>

	
![image](https://user-images.githubusercontent.com/8420258/219983406-c72943ac-2df6-47ae-9555-490876890d17.png)

	
	code snippets
```sql
with vk_total_unique_sessions as (
select count(*)
from (select session_id
		from vk_data.events.website_activity
		group by 1)
)
```

select * from vk_total_unique_sessions
![image](https://user-images.githubusercontent.com/8420258/219759651-dc9b042b-6c6e-4601-9cc6-83320e67980c.png)



```sql
with vk_total_unique_sessions as (
	select count(distinct session_id)
	from vk_data.events.website_activity
)
select * from vk_total_unique_sessions
```

![image](https://user-images.githubusercontent.com/8420258/219760854-0f86d785-1db9-4e7f-a4bd-aa9185ff519b.png)
	
</details>	

