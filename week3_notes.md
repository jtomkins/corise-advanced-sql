
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
