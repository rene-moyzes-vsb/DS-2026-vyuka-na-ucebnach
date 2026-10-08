/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A */ /* SELECT * FROM sakila.film;

UPDATE film SET description = NULL WHERE film_id<=10; */ /*SELECT F.title ||'-'|| COALESCE(F.description, NULL, F.title) AS long_name
FROM sakila.film as F
WHERE F.length > 120 and F.description IS NULL*/ /* SELECT DISTINCT cc.country, f.title
FROM sakila.address as a

INNER JOIN sakila.city as c
    ON a.city_id = c.city_id
INNER JOIN sakila.country as cc
    ON cc.country_id = c.country_id
INNER JOIN sakila.customer as cu
    ON cu.address_id = a.address_id
INNER JOIN sakila.rental as r
    ON r.customer_id = cu.customer_id
INNER JOIN sakila.inventory as i
    ON i.inventory_id = r.inventory_id
INNER JOIN sakila.film as f
    ON f.film_id = i.film_id
WHERE f.length > 120 and extract(year from r.rental_date) = 2005
ORDER BY 1  */

/* select DISTINCT F.film_id, F.title -- C.name
from sakila.film as F
JOIN sakila.film_category as FC ON F.film_id = FC.film_id
JOIN sakila.category as C ON C.category_id = FC.category_id
WHERE C.name in('Comedy', 'Drama')
ORDER BY F.title */

/* SELECT r.rental_id,r.rental_date,p.payment_date,r.return_date from sakila.rental as r 
left join sakila.payment as p on p.rental_id = r.rental_id
where p.payment_id is null AND r.return_date is not null; */

/* SELECT F.film_id, L.language_id, L.name, OL.name as OLNAME
FROM sakila.film as F
JOIN sakila.language as L
    on L.language_id = F.language_id
LEFT OUTER JOIN sakila.language as OL
    on OL.language_id = F.original_language_id AND OL.name = 'English'
--WHERE OL.name = 'English' or OL.name is NULL */

select COUNT(1), count(NULL), count(film_id), count(DISTINCT film_id), count(DISTINCT f.title), COUNT(DISTINCT f.rating)
from sakila.film as f

SELECT  DISTINCT f.rating
from sakila.film as f

'Italian             '

SELECT DISTINCT name
FROM sakila.language
WHERE name = 'Italian';
