##  Week 1 Exersize 1

For our first exercise, we need to determine which customers are eligible to order from Virtual Kitchen, and which distributor will handle the orders that they place. We want to return the following information:

* Customer ID
* Customer first name
* Customer last name
* Customer email
* Supplier ID
* Supplier name
* Shipping distance in kilometers or miles (you choose)

Step 1: We have 10,000 potential customers who have signed up with Virtual Kitchen. If the customer is able to order from us, then their city/state will be present in our database. Create a query in Snowflake that returns all customers that can place an order with Virtual Kitchen.

Step 2: We have 10 suppliers in the United States. Each customer should be fulfilled by the closest distribution center. Determine which supplier is closest to each customer, and how far the shipment needs to travel to reach the customer. There are a few different ways to complete this step. Use the customer's city and state to join to the us_cities resource table. Do not worry about zip code for this exercise.

Order your results by the customer's last name and first name

### Solution
#### Steps to solve
1. inspect data, check customer addresses for any null city or state fields
2. check resource us cities for dupes
3. join customers against resource us cities use set operator to review missing records missing
4. clean up resource us cities by eliminating dupes and trailing white spaces
5. get hung up on what it means for a customer to be eligable and if there is some hidden meaning
6. join suppliers against resource us cities confirm that all 10 records match
7. research functions for calculating distance using geo data, reviewed snowflake Geospatial Functions like haversine and st_distance
8. arrive at conclusion that data sets should be cross joined to be able to evaluate which location is closest
9. review/refresh window functions (not discussed in week 1) decideded to use rank for more clarity 
10. noticed snowflakes newish qualify clause to filter the result of window function, decided not to use becaus newish
    to snowflake and the Snowflake syntax for QUALIFY is not part of the ANSI standard.
11. check final record count

#### Query
[walker-week-1-exercise-1.sql](https://github.com/jtomkins/corise-advanced-sql/blob/advanced-sql-week-1-excersise-1/walker-week-1-exercise-1.sql)

#### First 10 records from result
![image](https://user-images.githubusercontent.com/8420258/216678908-93128d8f-0907-4b29-9ae6-6aafd7e12e8d.png)


##  Week 1 Challenge Exersize 2

Now that we know which customers can order from Virtual Kitchen, we want to launch an email marketing campaign to let these customers know that they can order from our website. If the customer completed a survey about their food interests, then we also want to include up to three of their choices in a personalized email message.

We would like the following information:

* Customer ID
* Customer email
* Customer first name
* Food preference #1
* Food preference #2
* Food preference #3
* One suggested recipe 

Step 1: Create a query to return those customers who are eligible to order and have at least one food preference selected. Include up to three of their food preferences. If the customer has more than three food preferences, then return the first three, sorting in alphabetical order. 

Step 2: Add a column to the query from Step 1 that suggests one recipe that matches food preference #1.  

Order the results by customer email.

### Solution
#### Steps to solve
1. re-use logic for eligable customers
2. If the customer completed a survey about their food interests, 
    then we also want to include up to three of their choices in a personalized email message,
  * join result set from eligable customers on customers.customer_survey, resources.recipe_tags
  * use rank to number customer preferences to be used for logic to include 3 or less choies as well as part of column header
3. pivot data to transform preference choices from rows to columns
4. flatten the array tag list to get all tags for each recipe
5. get suggested recipe to be one recipe where tag_property matches customer preference
6. get final result by joining customer id from pivoted customer details and preferences with suggested recipe data set 

#### Query
[walker-week-1-exercise-2.sql](https://github.com/jtomkins/corise-advanced-sql/blob/advanced-sql-week-1-exercises/walker-week-1-exercise-2.sql)


#### First 10 records from result
![image](https://user-images.githubusercontent.com/8420258/216848537-b7ab7e24-2011-49a2-99e6-1dbd65b00166.png)
