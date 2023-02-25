### Project 4 Instructions: Evaluate a Candidate's SQL Tech Exercise

## Project 4 Instructions: Evaluate a Candidate's SQL Tech Exercise
Instructions that were provided to the candidate
For this week's project, we will work with another sample tech exercise from the SNOWFLAKE_SAMPLE_DATA database. We will use the TPCH_SF1 schema to complete the exercise.

Instructions that were provided to the candidate
We need to develop a report to analyze AUTOMOBILE customers who have placed URGENT orders. We expect to see one row per customer, with the following columns:

* C_CUSTKEY
* LAST_ORDER_DATE: The date when the last URGENT order was placed
* ORDER_NUMBERS: A comma-separated list of the order_keys for the three highest dollar urgent orders
* TOTAL_SPENT: The total dollar amount of the three highest orders
* PART_1_KEY: The identifier for the part with the highest dollar amount spent, across all urgent orders 
* PART_1_QUANTITY: The quantity ordered
* PART_1_TOTAL_SPENT: Total dollars spent on the part 
* PART_2_KEY: The identifier for the part with the second-highest dollar amount spent, across all urgent orders  
* PART_2_QUANTITY: The quantity ordered
* PART_2_TOTAL_SPENT: Total dollars spent on the part 
* PART_3_KEY: The identifier for the part with the third-highest dollar amount spent, across all urgent orders 
* PART_3_QUANTITY: The quantity ordered
* PART_3_TOTAL_SPENT: Total dollars spent on the part 

The output should be sorted by LAST_ORDER_DATE descending.

There are two parts to this exercise, and you can choose in which order you would like to complete them.  

To submit your work, please create one text file (can live in Google Docs, GitHub, etc.) with the SQL code for Part 1, followed by the answer to Part 2. If you are submitting as a notebook, then you can format Part 2 so that it appears as a comment block.

1. Create a query to provide the report requested. Your query should have a LIMIT 100 when you submit it for review. Remember that you are creating this as a tech exercise for a job evaluation. Your query should be well-formatted, with clear names and comments.


2. Review the candidate's tech exercise below, and provide a one-paragraph assessment of the SQL quality. Provide examples/suggestions for improvement if you think the candidate could have chosen a better approach.

Do you agree with the results returned by the query?

Is it easy to understand?

Could the code be more efficient?