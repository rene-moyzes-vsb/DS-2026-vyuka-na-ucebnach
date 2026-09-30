/*
SET SEARCH_PATH = "sakila"; --Pouze pro vyučujícího
Označení komentáře ALT+Shift+A */ /* SELECT F.title, F.description FROM sakila.film AS F
WHERE F.length>120; */ /* SELECT F.title,
    F.description
    --F.rating
    FROM sakila.film AS F
WHERE F.length>120;  */ /*
SELECT A.address_id, a.city_id, A.address, city.city
FROM sakila.address as A
JOIN sakila.city on A.city_id = city.city_id
JOIN sakila.country on country.country_id = city.country_id

 */ /*  SELECT A.address_id, a.city_id, A.address, city.city, S.first_name, S.last_name
FROM sakila.address as A
JOIN sakila.city on A.city_id = city.city_id
JOIN sakila.country on country.country_id = city.country_id
JOIN sakila.staff AS S on S.address_id = A.address_id */

/* SELECT DISTINCT film.title,
                country.country,
                extract(year
                        from rental.rental_date) AS rental_year
FROM sakila.address as A
JOIN sakila.city on A.city_id = city.city_id
JOIN sakila.country on country.country_id = city.country_id
JOIN sakila.customer on customer.address_id = A.address_id
JOIN sakila.rental on customer.customer_id = rental.customer_id
JOIN sakila.inventory on inventory.inventory_id = rental.inventory_id
JOIN sakila.film on film.film_ID = inventory.film_id
WHERE extract(year
              from rental.rental_date) = 2005
ORDER BY 1,
/*          2 */

SELECT DISTINCT category.name, actor.first_name || ' ' || actor.last_name
FROM sakila.film 
JOIN sakila.film_category ON film_category.film_id = film.film_id
JOIN sakila.category ON category.category_id = film_category.category_id
JOIN sakila.film_actor ON film_actor.film_id = film_category.film_id
JOIN sakila.actor ON actor.actor_id = film_actor.actor_id
WHERE actor.actor_id = 1
ORDER BY 1,2 */

/* SELECT rental.rental_id, rental.rental_date, payment.payment_date
FROM sakila.rental LEFT JOIN sakila.payment ON rental.rental_id = payment.rental_id
WHERE payment.payment_date IS NULL AND rental.return_date IS NOT NULL; */

/* SELECT rental.rental_id, rental.rental_date, payment.payment_date
FROM  sakila.payment RIGHT JOIN sakila.rental ON rental.rental_id = payment.rental_id
WHERE payment.payment_date IS NULL AND rental.return_date IS NOT NULL;*/

/*SELECT customer.customer_id, rental.*
FROM sakila.customer
LEFT JOIN sakila.rental ON rental.customer_id = customer.customer_id
WHERE rental.rental_id IS NULL*/

/*  SELECT film.film_id, l.name AS L, oL.name
from sakila.film
join sakila.language as L on film.language_id = l.language_id
left join sakila.language as oL on film.original_language_id = oL.language_id and oL.name = 'Italian'*/

SELECT trim(language.name)
FROM sakila.language
WHERE trim(language.name) ILIKE 'italian'