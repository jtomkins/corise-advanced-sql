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

