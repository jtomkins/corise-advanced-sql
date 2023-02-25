/*

We need to develop a report to analyze AUTOMOBILE customers who have placed URGENT orders. 
We expect to see one row per customer, with the following columns:
    C_CUSTKEY
    LAST_ORDER_DATE: The date when the last URGENT order was placed
    ORDER_NUMBERS: A comma-separated list of the order_keys for the three highest dollar urgent orders
    TOTAL_SPENT: The total dollar amount of the three highest orders
    PART_1_KEY: The identifier for the part with the highest dollar amount spent, across all urgent orders 
    PART_1_QUANTITY: The quantity ordered
    PART_1_TOTAL_SPENT: Total dollars spent on the part 
    PART_2_KEY: The identifier for the part with the second-highest dollar amount spent, across all urgent orders  
    PART_2_QUANTITY: The quantity ordered
    PART_2_TOTAL_SPENT: Total dollars spent on the part 
    PART_3_KEY: The identifier for the part with the third-highest dollar amount spent, across all urgent orders 
    PART_3_QUANTITY: The quantity ordered
    PART_3_TOTAL_SPENT: Total dollars spent on the part 

*/

--ALTER SESSION SET USE_CACHED_RESULT = FALSE

/*
 auto customers with urgent orders
 ranking the extended price so can get the top values later
 change the order to rank the highest first = 1 so can pluck the top 3
*/
with auto_customers_with_urgent_orders as(
	
    select 
        c_custkey::string  as customer_key,
        o_orderkey::string as order_key,  
        o_custkey as customer_order_key,
        o_orderdate as order_date,
        l_partkey as part_key,
        l_quantity as part_quantity,
        l_extendedprice as part_price,
        rank() over (partition by customer_key order by part_price desc) as top_dollar_rank
    from snowflake_sample_data.tpch_sf1.customer
    inner join snowflake_sample_data.tpch_sf1.orders on customer_key = customer_order_key
    inner join snowflake_sample_data.tpch_sf1.lineitem on orders.o_orderkey = lineitem.l_orderkey
    where c_mktsegment = 'AUTOMOBILE'
        and o_orderpriority = '1-URGENT'
),

/*
per requirements consolidate to one record/row per customer
aggregate on customer key, and use listagg to combine order key values into a comma seperated list
while aggregating might as well grab the last order date and total sum on parts
*/
consolidated_customer_orders as (

	select 
    	customer_key,
        sum(part_price) as part_total_price,
        listagg(order_key, ', ') within group (order by order_key desc) as orders,
		max(order_date) as last_order_date
	from auto_customers_with_urgent_orders
    where top_dollar_rank <= 3
    group by 1
   	
),

/* 
per requirements include part 1, part 2 and part 3 as additional columns
*/
part_1 as (

    select 
        customer_key,
        part_key as part_1_key,
        part_quantity as part_1_quantity,
        part_price as part_1_total_spent
    from auto_customers_with_urgent_orders
    where top_dollar_rank = 1

),

/* 
per requirements include part 1, part 2 and part 3 as additional columns
*/
part_2 as (

    select 
        customer_key,
        part_key as part_2_key,
        part_quantity as part_2_quantity,
        part_price as part_2_total_spent
    from auto_customers_with_urgent_orders
    where top_dollar_rank = 2

),

/* 
per requirements include part 1, part 2 and part 3 as additional columns
*/
part_3 as (

    select 
        customer_key,
        part_key as part_3_key,
        part_quantity as part_3_quantity,
        part_price as part_3_total_spent
    from auto_customers_with_urgent_orders
    where top_dollar_rank = 3

),

/* 
  include consolidated customer orders with the top 3 parts
 in snowflake numeric values like total spent and quantity are data types with two places after the decimal
 noticed that the sample report numeric values like total spent and quantity display both positions
 however in snowflake table and in worksheet the zeros are not being displayed 
*/

result as (
    select
        consolidated_customer_orders.customer_key as c_custkey,
        consolidated_customer_orders.last_order_date as last_order_date ,
        consolidated_customer_orders.orders as order_numbers,
        consolidated_customer_orders.part_total_price as total_spent,
        part_1_key,
        part_1_quantity,
        part_1_total_spent,
        part_2_key,
        part_2_quantity,
        part_2_total_spent,
        part_3_key,
        part_3_quantity,
        part_3_total_spent
    from consolidated_customer_orders
    inner join part_1 on consolidated_customer_orders.customer_key = part_1.customer_key 
    inner join part_2 on part_1.customer_key = part_2.customer_key
    inner join part_3 on part_2.customer_key = part_3.customer_key
    order by last_order_date desc

)

select * 
from result
limit 100