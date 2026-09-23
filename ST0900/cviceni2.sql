/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A


UPDATE film SET description=NULL WHERE film_id<=10;
*/ /*SELECT F.film_id, F.title  || ' - ' || COALESCE(F.description, NULL, 'no descripiton', NULL)


FROM sakila.film AS F
WHERE F.description is NULL;*/
/*
SELECT DISTINCT

       b.country,
       f.film_id

FROM sakila.address AS A
JOIN sakila.city AS C
ON C.city_id = A.city_id
JOIN sakila.country AS B
ON B.country_id = C.country_id
INNER JOIN sakila.customer AS cu
ON cu.address_id = A.address_id
join sakila.rental as r 
on r.customer_id = cu.customer_id
join sakila.inventory as i 
on i.inventory_id = r.inventory_id
join sakila.film as f 
on f.film_id = i.film_id


ORDER BY b.country, f.film_id ;
*/

/*
SELECT DISTINCT
       f.title
FROM sakila.address AS A
JOIN sakila.city AS C
ON C.city_id = A.city_id
JOIN sakila.country AS B
ON B.country_id = C.country_id
INNER JOIN sakila.customer AS cu
ON cu.address_id = A.address_id
join sakila.rental as r 
on r.customer_id = cu.customer_id
join sakila.inventory as i 
on i.inventory_id = r.inventory_id
join sakila.film as f 
on f.film_id = i.film_id


ORDER BY f.title ;

*/

-- SELECT DISTINCT
--     length from sakila.film
--     ORDER BY 1;

-- SELECT DISTINCT
--     A.first_name,
--     A.last_name,
--     C.name
-- FROM sakila.actor AS A
-- JOIN sakila.film_actor AS FA
-- ON A.actor_id = FA.actor_id
-- JOIN sakila.film AS F 
-- ON F.film_id = FA.film_id
-- JOIN sakila.film_category AS FC 
-- ON FC.film_id = F.film_id
-- JOIN sakila.category AS C
-- ON C.category_id = FC.category_id
-- WHERE F.rating = 'G' AND F.length = 120
-- ORDER BY 2,1,3
/*
SELECT R.rental_id,
       P.payment_date

FROM sakila.rental AS R
LEFT JOIN sakila.payment AS P
ON R.rental_id = P.rental_id

WHERE P.payment_date IS NOT NULL

*/
/* 
SELECT cu.customer_id, re.rental_id, re.rental_date
from sakila.customer cu
left join sakila.rental re
    on cu.customer_id = re.customer_id
        and extract(year from re.rental_date) = 2006

SELECT A.actor_id,C.name
FROM sakila.category C CROSS JOIN sakila.actor A
ORDER BY 1,2; */

/*SELECT DISTINCT C.first_name,C.last_name, A.actor_id FROM sakila.customer C
INNER JOIN sakila.rental R
ON C.customer_id = R.customer_id
INNER JOIN sakila.inventory I
ON R.inventory_id = I.inventory_id
INNER JOIN sakila.film F
ON I.film_id = F.film_id
INNER JOIN sakila.film_actor FA 
ON F.film_id = FA.film_id
INNER JOIN sakila.actor A 
ON FA.actor_id = A.actor_id
WHERE (A.first_name = 'SEAN' AND A.last_name='GUINESS')*/

/*
SELECT count(film_id), count(description) CountDescription, count(NULL) countnull, count(rating) countrating,
count(DISTINCT rating), count(DISTINCT film_id), count(DISTINCT title)

FROM sakila.film;
*/

SELECT * FROM sakila.language
WHERE TRIM(name) ILIKE 'Italian';

SELECT
customer_id,
CONCAT_WS(' ', first_name, last_name) AS full_name,
CONCAT_WS(' | ', CONCAT_WS(' ', first_name, last_name), email) AS 
customer_contact
FROM sakila.customer
ORDER BY last_name, first_name
LIMIT 20