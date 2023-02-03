# Corise Advanced Sql
**Virtual Kitchen**

Our exercises will use data from a fictional company called Virtual Kitchen, an interactive meal-delivery service. Virtual Kitchen currently operates in the United States. We need to use the city and state in order to identify the locations of our customers and suppliers.

Virtual Kitchen has three types of users:

Chefs: Chefs upload their favorite recipes and then receive points each time a customer orders one of their recipes.

Customers: Customers order from recipes in the database, and the ingredients for each recipe are shipped to their address.

Suppliers: Suppliers package the ingredients for the recipes and ship them to customers.

![image](https://user-images.githubusercontent.com/8420258/216680965-4a33219a-3993-40bb-8cac-1aced9136539.png)


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
7. research functions for calculating distance using geo data, reviewed snowflake Geospatial Functions line haversine and st_distance
8. arrive at conclusion that data sets should be cross joined to be able to evaluate which location is closest
9. review/refresh window functions (not discussed in week 1) decideded to use rank for more clarity 
10. noticed snowflakes newish qualify clause to filter the result of window function, decided not to use becaus newish
    to snowflake and the Snowflake syntax for QUALIFY is not part of the ANSI standard.
11. check final record count

#### Query
[walker-week-1-exercise-1.sql](https://github.com/jtomkins/corise-advanced-sql/blob/advanced-sql-week-1-excersise-1/walker-week-1-exercise-1.sql)

#### First 10 records from result
![image](https://user-images.githubusercontent.com/8420258/216678908-93128d8f-0907-4b29-9ae6-6aafd7e12e8d.png)
