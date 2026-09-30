/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A

UPDATE film SET description=NULL WHERE film_id<=10;
*/

/* SELECT * FROM sakila.film AS F
WHERE F.length>120; */

/*SELECT S.first_name, 
S.last_name,
A.address,
A.address_id,
A.city_id,
C.city,
Y.country
FROM sakila.address AS A
JOIN sakila.city AS C ON A.city_id = C.city_id 
JOIN sakila.country AS Y ON C.country_id = Y.country_id
JOIN sakila.staff AS S ON S.address_id = A.address_id*/

/* SELECT DISTINCT extract(year FROM R.rental_date),
AC.actor_id,
AC.first_name,
AC.last_name, 
Y.country
FROM sakila.address AS A
JOIN sakila.city AS C ON A.city_id = C.city_id 
JOIN sakila.country AS Y ON C.country_id = Y.country_id
JOIN sakila.customer AS C2 ON C2.address_id = A.address_id
JOIN sakila.rental AS R ON R.customer_id = C2.customer_id
JOIN sakila.inventory AS I ON I.inventory_id = R.inventory_id
JOIN sakila.film AS F ON F.film_id = I.film_id
JOIN sakila.film_actor AS FA ON FA.film_id = F.film_id
JOIN sakila.actor AS AC ON AC.actor_id = FA.actor_id
WHERE extract(year FROM R.rental_date) = 2005
ORDER BY AC.actor_id,
Y.country */


/* SELECT F.film_id, F.title, C.name, a.actor_id
FROM sakila.film AS F
JOIN sakila.film_category AS FC ON F.film_id = FC.film_id
JOIN sakila.category AS C ON FC.category_id = C.category_id
JOIN sakila.film_actor as fa on fa.film_id = F.film_id 
JOIN sakila.actor as a on a.actor_id = fa.actor_id and a.actor_id = 1
ORDER BY F.film_id, C.name */

/*SELECT R.rental_id,
R.rental_date,
R.return_date,
P.*
FROM sakila.rental AS R
LEFT JOIN sakila.payment AS P ON R.rental_id = P.rental_id
WHERE P.payment_date IS NOT NULL;*/

/* SELECT C.customer_id, R.rental_id, R.rental_date
FROM sakila.customer AS C
LEFT JOIN sakila.rental AS R ON C.customer_id = R.customer_id
            AND extract(MONTH from R.rental_date) = 8
ORDER BY 1, 2 */

/* SELECT C.customer_id, 
R.rental_id, 
R.rental_date
FROM sakila.rental AS R
RIGHT JOIN sakila.customer AS C ON C.customer_id = R.customer_id
            AND extract(MONTH from R.rental_date) = 8
ORDER BY 1, 2 */

SELECT f.film_id,
sl.name as LANGUAGE,
SLA.NAME as Original

FROM sakila.film AS F 
LEFT JOIN sakila.language AS SL ON SL.language_id = F.language_id
LEFT JOIN sakila.language AS SLA ON SLA.language_id = F.original_language_id AND SLA.name = 'French'



