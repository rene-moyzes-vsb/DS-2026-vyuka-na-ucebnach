
/*
SELECT 
rating,
COUNT(*) as pocet_r,
COUNT(1) as pocet_1,
COUNT(NULL) as pocet_NULL,
COUNT(1+NULL) as pocet_NULL1,
COUNT(film_id) as pocet_key,
COUNT(original_language_id) as pocet_oli,
COUNT(DISTINCT original_language_id) as pocet_dist_oli,
SUM(length) as celkova_delka,
SUM(length)/60/24 as delka_ve_dnech,
SUM(CAST(length AS NUMERIC)/60/24) as delka_ve_dnech2,
MAX(length) as nejdelsi,
MIN(length) as nejkratsi,
AVG(length) as prumer
FROM film F
WHERE length<60
GROUP BY rating
HAVING AVG(length)>52;

SELECT
FROM + JOIN ON
WHERE
GROUP BY
HAVING
ORDER BY
*/






























/* Vypište počty filmů pro jednotlivé délky (atribut length). */


/* SELECT length,
COUNT(film_id) as pocet
from film 
GROUP BY length 
order by length */














/* Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem. */


/* SELECT first_name, COUNT(first_name) as Jmeno 
from customer
GROUP BY first_name
HAVING COUNT(first_name) > 1
ORDER BY first_name; */



















/* Vypište součty všech plateb za jednotlivé roky a měsíce.
   Výsledek uspořádejte podle roků a měsíců. */

/*
SELECT EXTRACT(year FROM payment_date) as YEAR, 
EXTRACT(month FROM payment_date) as MONTH,
SUM(amount)
FROM payment
GROUP BY EXTRACT(year FROM payment_date), 
EXTRACT(month FROM payment_date)
ORDER BY 1, 2;
*/























/* Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut
   a celková délka takových filmů v dané klasifikaci je větší než 250 minut.
   Výsledek seřaďte sestupně podle abecedy. 




SELECT rating,SUM(length)
FROM public.film
WHERE length <50
GROUP BY rating
HAVING SUM(length) >250;
*/












/* Vypište ID a názvy všech jazyků a k nim počty filmů v daném jazyce,
   které jsou delší než 350 minut. */


/*

SELECT language.language_id, name, count (film_id)
FROM language
LEFT JOIN film on language.language_id = film.language_id AND length > 350
GROUP BY language.language_id, name
ORDER BY language.language_id;

*/






















/* Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty
   různých filmů, které si vypůjčili. */

/*
SELECT customer.customer_id, 
customer.first_name, 
customer.last_name, 
COUNT(DISTINCT film.film_id), 
COUNT( film.film_id)
from customer
LEFT JOIN rental ON rental.customer_id = customer.customer_id
LEFT JOIN inventory ON inventory.inventory_id = rental.inventory_id
LEFT join film ON film.film_id = inventory.film_id
group by customer.customer_id, customer.first_name, customer.last_name
order by 4;
*/



























/* Pro každého herce vypište, v kolika různých kategoriích filmů hraje. */

/*
SELECT film_actor.actor_id, COUNT(DISTINCT film_category.category_id) 
FROM film_actor
JOIN film_category ON film_actor.film_id = film_category.film_id
GROUP BY film_actor.actor_id

*/































/* Pro všechny zákazníky z Polska vypište, do kolika různých kategorií spadají
   filmy, které si tito zákazníci vypůjčili. */