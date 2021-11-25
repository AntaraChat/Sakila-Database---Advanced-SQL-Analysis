USE sakila;

-- Analysis done using Advanced SQL:

--  1. Films which are done by more than ten actors - Display film name, rating , categoryID order by film length 
SELECT title as Film_name,rating,category_id 
FROM 
(
SELECT Count(fa.Actor_id) as More10,fa.Actor_id,f.film_id,f.title,f.rating,fc.category_id 
FROM FILM_Actor as fa
INNER JOIN film as f
ON f.FILM_ID = fa.Film_id
INNER JOIN FILM_CATEGORY as fc
ON f.FILM_ID = fc.FILM_ID
Group By fa.Film_id
having More10 > 10
) AS More10;


-- OR USING CTEs
WITH cteactordetails
AS
(
SELECT Count(fa.Actor_id) as More10,fa.Actor_id,f.film_id,f.title,f.rating,fc.category_id 
FROM FILM_Actor as fa
INNER JOIN film as f
ON f.FILM_ID = fa.Film_id
INNER JOIN FILM_CATEGORY as fc
ON f.FILM_ID = fc.FILM_ID
Group By fa.Film_id
having More10 > 10)
SELECT title as Film_name,rating,category_id
FROM cteactordetails;

-- Or using views
CREATE VIEW morethan10 AS
SELECT Count(fa.Actor_id) as More10,fa.Actor_id,f.film_id,f.title,f.rating,fc.category_id 
FROM FILM_Actor as fa
INNER JOIN film as f
ON f.FILM_ID = fa.Film_id
INNER JOIN FILM_CATEGORY as fc
ON f.FILM_ID = fc.FILM_ID
Group By fa.Film_id
having More10 > 10;
SELECT title as Film_name,rating,category_id
FROM morethan10;

-- 2. Calculate all the customer details (first name, email), payment details(payment id and
-- amount) , address, country , city of all customers having amount > 10 dollar , sort by
-- customer id 
SELECT Name,email,payment_id,address,country,city
FROM
(
 SELECT CONCAT(c.First_name) as Name,c.email,p.payment_id,SUM(p.amount) as More_10_dollar,address,country,ci.city
 FROM customer as c
 INNER Join payment as p
 ON c.customer_id = p.customer_id
 INNER JOIN address as a
 ON c.address_id = a.address_id
 INNER JOIN city as ci
 On a.city_id = ci.city_id
 INNER JOIN country as co
 ON ci.country_id = co.country_id
 GROUP BY Name
 Having More_10_dollar > 10
 ORDER BY c.customer_id ) As Cust_Details;
 
-- 3. Sort by payment date (latest first), calculate the 5 day rolling average of amount.
-- Display amount from row numbers 6-8. Round to 1 decimal places.
WITH payment_avg AS
(
SELECT payment_date,
	   AVG(amount) OVER(ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS Rollingavg5,
       ROW_NUMBER() OVER(ORDER BY payment_date DESC) as row_num
FROM payment
GROUP BY payment_date
)
SELECT payment_date,Rollingavg5,row_num
FROM payment_avg
WHERE row_num BETWEEN 6 AND 8;

-- 4. Display average length of films inventory wise, inventory id.
-- Sort by avg length greatest first, inventory_id smallest first.

SELECT inventory_id,
       AVG(length) AS avg_movie_length
FROM film as f
JOIN inventory as i
Using(film_id)
GROUP BY inventory_id
ORDER BY avg_movie_length DESC,inventory_id ASC;

-- 5. Check which actor has worked for which categories
SELECT CONCAT(first_name,' ',last_name) as Actor_Name,name as Category_name
FROM actor as a
INNER JOIN film_actor as fa
ON fa.actor_id = a.actor_id
INNER JOIN film_category as fc
ON fc.film_id =  fa.film_id
INNER JOIN category as c
ON c.category_id = fc.category_id
GROUP BY Actor_Name,category_name
ORDER BY Actor_name;

-- Analysis done using Intermediate level of SQL

-- 1. Write a query to find the full name of the actor who has acted in the maximum number of movies.
SELECT Name,movie_count
FROM
(
SELECT CONCAT(first_name," ",last_name) as Name,
       COUNT(film_id) as movie_count
FROM actor as a
INNER JOIN film_actor as fa
ON a.actor_id = fa.actor_id
GROUP BY Name
ORDER BY movie_count DESC) As a
LIMIT 1;

-- 2. Write a query to find the full name of the actor who has acted in the third most number of movies.
SELECT * FROM
(
SELECT Full_name,movie_count,
DENSE_RANK() OVER(ORDER BY movie_count DESC) as count_rank
FROM
(
SELECT CONCAT(first_name," ",last_name) as Full_name,
       COUNT(film_id) as movie_count
FROM actor as a
INNER JOIN film_actor as fa
ON fa.actor_id = a.actor_id
GROUP BY full_name
) as a) as b
WHERE count_rank=3;

-- 3. Write a query to find the film which grossed the highest revenue for the video renting organisation.
select TITLE
from FILM inner join INVENTORY
using(FILM_ID) inner join RENTAL
using(INVENTORY_ID)
group by TITLE
order by count(RENTAL_ID) desc
limit 1;

-- 4. Write a query to find the city which generated the maximum revenue for the organisation.
SELECT city,COUNT(rental_id) as max_revenue
FROM city as c
INNER JOIN Address as a
USING(city_id)
INNER JOIN customer as cu
using(address_id)
INNER JOIN rental as r
using(customer_id)
GROUP BY city
ORDER BY max_revenue DESC;

-- 5. Write a query to find out how many times a particular movie category is rented. 
--    Arrange these categories in the decreasing order of the number of times they are rented.
SELECT name, count(rental_id) as rental_count
FROM category as c
INNER JOIN film_category as fc
using(category_id)
INNER JOIN film as f
using(film_id)
JOIN inventory as i
using(film_id)
JOIN Rental as r
using(inventory_id)
GROUP BY name
ORDER BY rental_count DESC
LIMIT 1;

-- 6. Write a query to find the full names of customers who have rented sci-fi movies more than 2 times. 
-- Arrange these names in the alphabetical order.
SELECT CONCAT(first_name , " ", last_name) as Full_Name,
       count(rental_id) as rental_count
FROM customer as c
INNER JOIN rental as r
Using(customer_id)
JOIN inventory as i
using(inventory_id)
JOIN film as f
using(film_id)
JOIN film_category as fc
USING(film_id)
INNER JOIN category as ca
USING(category_id)
WHERE name = "sci-fi"
GROUP BY Full_name
HAVING rental_count>2
ORDER BY Full_name;

-- 7. Write a query to find the full names of those customers who have rented at least one movie 
-- and belong to the city Arlington.
SELECT CONCAT(first_name," ",last_name) as Full_Name,
       COUNT(rental_id) as rental_count,
       city
FROM customer as c
JOIN rental as r
using(customer_id)
JOIN address as a
using(address_id)
JOIN city as ci
using(city_id)
WHERE city="Arlington"
GROUP BY Full_name
HAVING rental_count>1;

-- 8. Write a query to find the number of movies rented across each country. 
-- Display only those countries where at least one movie was rented. 
-- Arrange these countries in the alphabetical order.
SELECT country,
COUNT(rental_id) as rental_count
FROM country as c
JOIN city as ci
USING (country_id)
JOIN address as a
USING (city_id)
JOIN customer as cu
using(address_id)
JOIN rental as r
USING(customer_id)
GROUP BY country
HAVING rental_count >= 1
ORDER BY country;



















