/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A
*/ /* SELECT * FROM film; */ /* SELECT film_id,
       title,
       language_id,
       original_language_id,
       language_id+coalesce(original_language_id, NULL, 100) AS soucet
FROM film
WHERE original_language_id IS NOT NULL; */ /* UPDATE film SET description = NULL WHERE film_id<=10; */ /* SELECT title || ' ' || COALESCE(description, '') AS long_title FROM film
WHERE description IS NOT NULL
LIMIT 100; */
SELECT film_id,
       title,
       film.language_id,

       (SELECT name
        FROM language
        WHERE language.language_id = film.language_id) AS language_ss,
       language.name
FROM film
JOIN language ON language.language_id = film.language_id
WHERE TRIM(language.name) ILIKE 'ITALIAN';


select C.first_name,
       C.last_name,
       R.rental_date
from customer AS C
join rental AS R on R.customer_id = C.customer_id
ORDER by C.customer_id;


SELECT F.film_id,
       F.title,
       FC.category_id,
       FA.actor_id
FROM film F
JOIN film_category FC ON F.film_id=FC.film_id
JOIN film_actor FA ON F.film_id = FA.film_id 
ORDER BY F.film_id, FA.actor_id;

SELECT DISTINCT F.film_id,
       F.title,
       --FC.category_id,
       FA.actor_id
FROM film F
JOIN film_category FC ON F.film_id=FC.film_id
JOIN film_actor FA ON F.film_id = FA.film_id 
ORDER BY F.film_id, FA.actor_id;