/* Set 1 question 1 (Slide 2):
We want to understand more about the movies that families are watching. 
The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music.

Create a query that lists the 5 movies with the highest number of rentals from the family categories, naming each movie, the film category it is classified in, and the number of times it has been rented out.*/



WITH categories AS (
    SELECT 
        category_id, 
        name
    FROM 
        category
    WHERE 
        name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    ORDER BY 
        category_id
),
categorized_rentals AS (
    SELECT 
        c.category_id AS category_id, 
        c.name AS name,
        f.title AS movie_title, 
        i.inventory_id, 
        r.*
    FROM 
        categories c
    JOIN film_category fc USING (category_id)
    JOIN film f USING (film_id)
    JOIN inventory i USING (film_id)
    JOIN rental r USING (inventory_id)
    ORDER BY 
        c.category_id
)

SELECT 
    COUNT(*) times_rented,
    cr.movie_title, 
    cr.name
FROM 
    categorized_rentals cr
GROUP BY 
    2,
    3
ORDER BY 
    1 DESC
LIMIT
    5;

/* Set 1 question 2 (Slide 3):
Now we need to know how the length of rental duration of these top 5 family-friendly movies compares to the duration that all movies are rented for. 
Can you provide a table with the movie titles and divide them into 4 levels 
(first_quarter, second_quarter, third_quarter, and final_quarter) based on the quartiles (25%, 50%, 75%) of the rental duration for movies across all categories? 
Make sure to also indicate the category that these family-friendly movies fall into. */

WITH categories AS (
    SELECT 
        category_id, 
        name
    FROM 
        category
    WHERE 
        name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    ORDER BY 
        category_id
),
categorized_rentals AS (
    SELECT 
        c.category_id AS category_id, 
        c.name AS name, 
        f.title AS movie_title, 
        f.rental_duration
    FROM 
        categories c
    JOIN film_category fc USING (category_id)
    JOIN film f USING (film_id)
    ORDER BY 
        c.category_id
),
quartile AS (
    SELECT
        cr.name,
        cr.movie_title,
        cr.category_id,
        cr.rental_duration,
        NTILE(4) OVER (PARTITION BY cr.name ORDER BY rental_duration) AS rental_quartile
    FROM
        categorized_rentals cr
),
top_five AS (
    SELECT
        cr.movie_title, 
        cr.name,
        cr.category_id
    FROM 
        categorized_rentals cr
    WHERE 
        cr.movie_title IN ('Scalawag Duck', 'Juggler Hardly', 'Timberland Sky', 'Robbers Joon', 'Rush Goodfellas')
    ORDER BY 
        1 DESC
)

SELECT
    tf.name, 
    tf.movie_title, 
    q.rental_duration,
    CASE 
        WHEN q.rental_quartile = 1 THEN 'first_quarter'
        WHEN q.rental_quartile = 2 THEN 'second_quarter'
        WHEN q.rental_quartile = 3 THEN 'third_quarter'
        WHEN q.rental_quartile = 4 THEN 'final_quarter'
        ELSE '?' END AS rental_quarter
FROM 
    top_five tf
JOIN quartile q USING (movie_title);

/* Set 1 question 3 (Slide 4):
Provide a table with the family-friendly film category, each of the quartiles, and the corresponding count of movies within 
each combination of film category for each corresponding rental duration category. The resulting table should have three columns:

Category
Rental length category
Count

One way to solve this question requires the use of Percentiles, Window functions and Case statements. */

WITH categories AS (
    SELECT
        category_id,
        name
    FROM
        category
    WHERE
        name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    ORDER BY
        category_id),
categorized_rentals AS (
    SELECT
        c.category_id AS category_id,
        c.name AS name,
        f.title AS movie_title,
        f.rental_duration
    FROM
        categories c
        JOIN film_category fc USING (category_id)
        JOIN film f USING (film_id)
    ORDER BY
        c.category_id),
quartiles AS (
    SELECT
        category_id,
        ntile(4)
        OVER (PARTITION BY
                cr.category_id
            ORDER BY
                rental_duration) AS rental_quartile
        FROM
            categorized_rentals cr
        ORDER BY
            1,
            2
)
SELECT
    category_id,
    c.name,
    rental_quartile,
    count(c.name) AS num_movies
FROM
    quartiles
    JOIN categories c USING (category_id)
GROUP BY
    category_id, c.name, rental_quartile
ORDER BY
    category_id, rental_quartile;

/* Set 2 question 3 (Slide 5):
We would like to know who were our top 10 paying customers, how many payments they made on a monthly basis during 2007, and what was the amount of the monthly payments. 
Can you write a query to capture the customer name, month and year of payment, and total payment amount for each month by these top 10 paying customers?

Finally, for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007. 
Please go ahead and write a query to compare the payment amounts in each successive month. Repeat this for each of these 10 paying customers. 
Also, it will be tremendously helpful if you can identify the customer name who paid the most difference in terms of payments.

*/
WITH cust_months AS (
    SELECT 
        c.first_name || ' ' || c.last_name AS full_name,
        c.customer_id AS id, 
        p.amount AS amount,
        DATE_TRUNC('month', p.payment_date) AS payment_month
    FROM 
        customer c
    JOIN payment p ON p.customer_id = c.customer_id
    GROUP BY 
        1, 
        2, 
        3, 
        p.payment_date
    HAVING 
        DATE_PART('year', payment_date) = '2007'
),
top_custs AS (
    SELECT
        id,
        SUM(amount)
    FROM 
        cust_months
    GROUP BY 
        1
    ORDER BY
        2 DESC
    LIMIT 
        10
),
top_totals AS (
    SELECT 
        cm.payment_month AS payment_month,
        cm.full_name AS full_name,
        SUM(cm.amount) AS total_paid,
        COUNT(*) AS num_rentals
    FROM 
        top_custs tc
    JOIN cust_months cm USING (id)
    GROUP BY 1, 2
    ORDER BY 2, 3 DESC
)

SELECT 
    payment_month,
    full_name,
    total_paid,
    LEAD(total_paid) OVER (PARTITION BY full_name ORDER BY payment_month) - total_paid AS monthly_difference
FROM 
    top_totals
ORDER BY
    4 DESC;