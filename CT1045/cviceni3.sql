/*
SELECT 
count(*) pocet_radku,
count(1) pocet_radku1,
count(film_id) pocet_fid,
count(original_language_id) pocet_oli,
count(DISTINCT original_language_id ) pocet_uni_oli,
count(NULL) as pocet_N,
count(DISTINCT NULL) as pocet_DN,
SUM(CAST(length AS NUMERIC)/60/24)  as celkem_delka,
MAX(length) as max_delka,
MIN(length) as min_delka,
AVG(length) as avg_delka
FROM Film
WHERE length > 60;

SELECT rating, count(1) pocet
FROM film
GROUP BY rating
HAVING count(1)>200
ORDER BY rating;


*/






 /*
SELECT
FROM + JOIN ON
WHERE
GROUP BY
HAVING
ORDER BY
*/

/* Vypište počty filmů pro jednotlivé délky 
(atribut length). */

/*
SELECT length, count(1)
FROM film
GROUP BY length
ORDER BY length;
*/









/* Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem. */


/* SELECT first_name, count(1)
FROM customer
WHERE first_name LIKE 'T%'
GROUP BY first_name
HAVING count(1)>1; */













/* Vypište součty všech plateb za jednotlivé roky a měsíce.
   Výsledek uspořádejte podle roků a měsíců. */


/* SELECT extract(year from payment_date) as year, extract(month from payment_date) as month, SUM(amount)
FROM payment
GROUP BY extract(year from payment_date), extract(month from payment_date)
ORDER BY year, month; */


















/* Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut
        a celková délka takových filmů v dané klasifikaci je větší než 250 minut.
        Výsledek seřaďte sestupně podle abecedy. */


/* SELECT rating, SUM(length)
FROM film
WHERE length < 50
GROUP BY rating 
HAVING SUM(length) > 250
ORDER BY rating ASC; */








/* Vypište ID a názvy všech jazyků a k nim počty filmů v daném jazyce,
        které jsou delší než 350 minut. */

/* SELECT language.language_id, language.name, COUNT(film_id)
FROM language
LEFT JOIN film ON language.language_id = film.language_id AND film.length > 350
GROUP BY language.language_id, language.name
 */
























/* Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty
         různých filmů, které si vypůjčili. */
/*
SELECT customer.customer_id, customer.first_name, customer.last_name, count(film.film_id), count(DISTINCT film.film_id), count(inventory.inventory_id)
FROM customer
LEFT JOIN rental ON customer.customer_id = rental.customer_id
LEFT JOIN inventory ON rental.inventory_id = inventory.inventory_id
LEFT JOIN film ON inventory.film_id = film.film_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
HAVING count(DISTINCT film.film_id) = 0
*/



















/* Pro každého herce vypište, v kolika různých kategoriích filmů hraje. */

SELECT actor.actor_id, count(DISTINCT film_category.category_id)
FROM actor
JOIN film_actor ON film_actor.actor_id = actor.actor_id
JOIN film ON film.film_id = film_actor.film_id
JOIN film_category ON film_category.film_id = film.film_id
GROUP BY actor.actor_id



















/* Pro všechny zákazníky z Polska vypište, do kolika různých kategorií spadají
         filmy, které si tito zákazníci vypůjčili. */