--ALTER SESSION UNSET USE_CACHED_RESULT=FALSE

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