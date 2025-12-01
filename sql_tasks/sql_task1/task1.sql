-- 1 Display the number of films in each category, sorted in descending order.
SELECT 
	c.name,
	COUNT(film_id) AS number_of_films
FROM film_category
	LEFT JOIN category c USING(category_id)
GROUP BY c.name
ORDER BY number_of_films DESC

-- 2 Display the top 10 actors whose films were rented the most, sorted in descending order.
SELECT
	a.first_name,
	a.last_name,
	COUNT(r.rental_id) AS rental_count
FROM actor a
JOIN film_actor USING(actor_id)
JOIN inventory USING(film_id)
JOIN rental r USING(inventory_id)
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY rental_count DESC
LIMIT 10;

-- 3 Display the category of films that generated the highest revenue.
WITH ranked_revenue AS (
    SELECT 
        c.name AS category,
        SUM(p.amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(p.amount) DESC) AS rn
    FROM payment p
        JOIN rental USING(rental_id)
        JOIN inventory USING(inventory_id)
        JOIN film USING(film_id)
        JOIN film_category USING(film_id)
        JOIN category c USING(category_id)
    GROUP BY c.category_id, c.name
)
SELECT category, total_revenue
FROM ranked_revenue
WHERE rn = 1;


-- 4 Display the titles of films not present in the inventory. Write the query without using the IN operator.
SELECT
	title
FROM film
	LEFT JOIN inventory USING(film_id)
WHERE inventory.film_id IS NULL

-- 5 Display the top 3 actors who appeared the most in films within the "Children" category. If multiple actors have the same count, include all.
WITH children_category_actor_count AS(
	SELECT
		a.actor_id,
		a.first_name,
		a.last_name,
		COUNT(film_id) AS film_count
	FROM actor a
		JOIN film_actor USING(actor_id)
		JOIN film USING(film_id)
		JOIN film_category USING(film_id)
		JOIN category c USING(category_id)
	WHERE c.name = 'Children'
	GROUP BY a.actor_id, a.first_name, a.last_name
	ORDER BY film_count DESC
),
ranked_actors AS(
	SELECT
		*,
		DENSE_RANK() OVER(ORDER BY film_count DESC) AS rank_film_count
	FROM children_category_actor_count

)
SELECT
	actor_id,
	first_name,
	last_name,
	film_count
FROM ranked_actors
WHERE rank_film_count <= 3


-- 6 Display cities with the count of active and inactive customers (active = 1). Sort by the count of inactive customers in descending order.

SELECT
	c.city,
	SUM(CASE WHEN cu.active = 1 THEN 1 ELSE 0 END) AS active_count,
	SUM(CASE WHEN cu.active = 1 THEN 0 ELSE 1 END) AS inactive_count
FROM customer cu
	JOIN address a USING(address_id)
	JOIN city c USING(city_id)
GROUP BY c.city
ORDER BY inactive_count DESC

-- 7 Display the film category with the highest total rental hours in cities where customer.address_id belongs to that city and starts with the letter "a". Do the same for cities containing the symbol "-". Write this in a single query.
(
SELECT
    c.name AS category,
    SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600.0) AS rental_hours,
    'Starts with A' AS source
FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city ci ON a.city_id = ci.city_id
WHERE ci.city ILIKE 'a%'
GROUP BY c.category_id, c.name
ORDER BY rental_hours DESC
LIMIT 1
)
UNION ALL
(
SELECT
    c.name AS category,
    SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600.0) AS rental_hours,
    'Contains "-"' AS source
FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city ci ON a.city_id = ci.city_id
WHERE ci.city ILIKE '%-%'
GROUP BY c.category_id, c.name
ORDER BY rental_hours DESC
LIMIT 1
)



