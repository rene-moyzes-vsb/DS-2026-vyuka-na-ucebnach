/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A
*/ /* SELECT F.title, F.film_id FROM sakila.film AS F
WHERE F.length>120
; */ /* select S.first_name, S.last_name, A.address, C.city, T.country
from sakila.address as A
JOIN sakila.city as C on A.city_id = C.city_id
JOIN sakila.country as T on C.country_id = T.country_id
JOIN sakila.staff as S on S.address_id = A.address_id */

/* select DISTINCT F.title,
       T.country,
       extract(year from R.rental_date) as rental_year
from sakila.address as A
JOIN sakila.city as C on A.city_id = C.city_id
JOIN sakila.country as T on C.country_id = T.country_id
INNER JOIN sakila.customer as P on A.address_id = P.address_id 
INNER JOIN sakila.rental as R on P.customer_id = R.customer_id
INNER JOIN sakila.inventory as I on R.inventory_id = I.inventory_id
INNER JOIN sakila.film as F on I.film_id = F.film_id
WHERE F.length > 120 AND extract(year from R.rental_date) in (2005, 2006)
ORDER BY 1,2  */



-- select P.email, R.rental_id, R.rental_date
-- from sakila.address as A
-- JOIN sakila.city as C on A.city_id = C.city_id
-- JOIN sakila.country as T on C.country_id = T.country_id
-- INNER JOIN sakila.customer as P on A.address_id = P.address_id 
-- INNER JOIN sakila.rental as R on P.customer_id = R.customer_id
-- INNER JOIN sakila.inventory as I on R.inventory_id = I.inventory_id
-- INNER JOIN sakila.film as F on I.film_id = F.film_id
-- WHERE F.length > 120 AND extract(year from R.rental_date) in (2005, 2006)
-- ORDER BY 1,2 

/*
SELECT DISTINCT category.name,T.first_name,T.last_name
FROM film_category
JOIN film ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id 
JOIN sakila.film_actor AS A ON film.film_id = A.film_id
JOIN sakila.actor AS T ON T.actor_id = A.actor_id
ORDER BY category.name,T.first_name,T.last_name;*/

/*
SELECT rental.rental_id, rental_date, return_date, payment.* 
FROM rental 
LEFT OUTER JOIN payment ON rental.rental_id = payment.rental_id
WHERE payment_id is NULL
*/


/* SELECT C.customer_id, R.rental_id
FROM sakila.customer as C
LEFT JOIN sakila.rental as R on R.customer_id = C.customer_id
WHERE R.rental_id is not NULL */
/* 
SELECT F.title, L.name AS Lang, OL.Name AS OLang
FROM sakila.film AS F 
JOIN sakila.language L ON F.language_id = L.language_id
LEFT JOIN sakila.language OL ON F.original_language_id=OL.language_id AND Ol.name = 'Italian' 
--WHERE Ol.name = 'Italian' OR Ol.Name IS NULL; */



SELECT * FROM language WHERE name ILIKE 'ITALIAN%';
