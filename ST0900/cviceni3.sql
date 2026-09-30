/*
SELECT rating,L.name, count(*) as pocet,
count(1) as pocet_radku_efektivne,
count(film_id) as pocet_film_id,
count(original_language_id) as pocet_ori_lang,
count(DISTINCT original_language_id) as pocet_dist_ori_lang,
count(NULL) as pocetNULL,
count(DISTINCT film_id) as dist_film_id,
count(DISTINCT title) as dist_film_title,
sum(F.length) as sum_lenght,
max(f.length) as max_length,
min(f.length) as min_length,
avg(f.length) as avg_lenght
FROM public.film F
JOIN public.language L ON F.language_id = L.language_id
WHERE F.length>50
GROUP BY rating,L.name
HAVING count(*) < 200;

*/
 /*
SELECT
FROM + JOIN
WHERE
GROUP BY
HAVING
ORDER BY
*/
;



--Vypište počty filmů pro jednotlivé délky (atribut length)



/*SELECT count(length) as pocet,
length
FROM public.film 
Where rating = 'G'
GROUP BY length
order by pocet, length
LIMIT 1000;*/











/*Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem. 
Je ve výsledku něco překvapivého? */


/* SELECT first_name AS FA,
count(first_name)
FROM customer C
GROUP BY first_name
HAVING count(first_name) > 1; */


















/*Vypište součty všech plateb za jednotlivé roky a měsíce.
Výsledek uspořádejte podle roků a měsíc*/

/*
Select
extract(YEAR from payment_date) as year,
EXTRACT(MONTH from payment_date) as month , 
Sum(amount)
from payment as P
GROUP BY extract(YEAR from payment_date), EXTRACT(MONTH from payment_date) 
ORDER BY 1,2,3;
*/


/*Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut
 a celková délka takových filmů v dané klasifikaci je větší než 250 minut.
 Výsledek seřaďte sestupně podle abecedy*/

-- Select rating from film
-- WHERE length < 50
-- GROUP BY rating
-- HAVING sum(length) > 250
-- ORDER BY rating


















/*Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty různých filmů,
 které si vypůjčili*/



/* SELECT customer.customer_id, customer.first_name, customer.last_name, count(F.film_id),
count(DISTINCT F.film_id) as pocet, count(DISTINCT I.inventory_id), sum(I.inventory_id)
FROM customer
LEFT JOIN rental as R ON r.customer_id = customer.customer_id
LEFT JOIN inventory AS I on I.inventory_id = R.inventory_id
LEFT JOIN film AS F on F.film_id = I.film_id

GROUP BY customer.customer_id, customer.first_name, customer.last_name 
ORDER BY pocet */











/*Pro každého herce vypište, v kolika různých kategoriích filmů hraje*/
/*
SELECT actor.actor_id,
count(DISTINCT FC.category_id)

FROM actor
LEFT JOIN film_actor as FA on FA.actor_id = actor.actor_id
LEFT JOIN film as F on F.film_id = FA.film_id AND rating != 'G'
LEFT JOIN film_category as FC on FC.film_id = F.film_id
GROUP BY actor.actor_id*/

/*Pro všechny zákazníky z Polska vypište, do kolika různých kategorií spadají filmy, které si tito zákazníci
vypůjčili*/

SELECT customer.customer_id, count(DISTINCT film_category.category_id)
FROM country
JOIN city ON city.country_id = country.country_id
JOIN address ON address.city_id = city.city_id
JOIN customer ON customer.address_id = address.address_id
LEFT JOIN rental ON rental.customer_id = customer.customer_id
LEFT JOIN inventory ON inventory.inventory_id = rental.inventory_id
LEFT JOIN film ON film.film_id = inventory.film_id
LEFT JOIN film_category ON film_category.film_id = film.film_id
WHERE country = 'India'
GROUP BY customer.customer_id
HAVING count(DISTINCT film_category.category_id) < 16