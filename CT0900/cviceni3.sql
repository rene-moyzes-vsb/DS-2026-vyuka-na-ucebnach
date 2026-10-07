
/* SELECT 
        count(*) as pocet_radku,
        count(1) as pocet_radku1,
        1+NULL as jednaNULL,
        count(1+NULL) as pocet_null,
        count(film_id) as pocet_fid,
        count(original_language_id) as pocet_oli,
        count(DISTINCT original_language_id) as pocet_dist_oli,
        sum(length)/60/24 as celk_delka_dny,
        min(length) as nejkratsi,
        max(length) as nejdelsi,
        avg(length) as prumer
 
FROM film F
WHERE length > 60; */
/*
SELECT count(1) 
FROM film F
WHERE length > 60;

SELECT rating,language_id, sum(length), count(1) as pocet,  count(original_language_id) pocet_oli
FROM film F
WHERE length > 60
GROUP BY rating,language_id
--HAVING count(1) >10
ORDER BY rating;*/







 /*
SELECT
FROM + JOIN ON
WHERE
GROUP BY
HAVING
ORDER BY
*/

/* Vypište počty filmů pro jednotlivé délky (atribut length). */

/*select length as delka, count(film_id) as pocet_filmu
from film
group by length; */

/* Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem. */

/*SELECT first_name, count(1) as pocet_zakazniku 
from customer 
GROUP BY first_name
HAVING count(1) > 1
ORDER BY pocet_zakazniku DESC*/
















/* Vypište součty všech plateb za jednotlivé roky a měsíce.
   Výsledek uspořádejte podle roků a měsíců. */

/* SELECT
EXTRACT(YEAR from payment_date) AS pay_year,
EXTRACT(MONTH from payment_date) AS pay_month,
SUM(amount) FROM payment
GROUP BY EXTRACT(YEAR from payment_date),
EXTRACT(MONTH from payment_date)
ORDER BY pay_year, pay_month */









/* Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut
        a celková délka takových filmů v dané klasifikaci je větší než 250 minut.
        Výsledek seřaďte sestupně podle abecedy. */


/* SELECT rating, sum(length) as celkova_delka
FROM film
WHERE length < 50
GROUP BY rating
HAVING sum(length) > 250
ORDER BY rating DESC; */












/* Vypište ID a názvy všech jazyků a k nim počty filmů v daném jazyce,
        které jsou delší než 350 minut. */

/*
SELECT l.language_id, l.name, count(f.film_id)
FROM film f 
RIGHT JOIN language l on l.language_id = f.language_id AND f.length > 350
GROUP BY l.language_id, l.name;
*/




/* Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty
         různých filmů, které si vypůjčili. */


SELECT C.customer_id,
first_name,
last_name,
count(DISTINCT F.film_id) as pocet,
count(F.film_id) as pocet2,
count(I.inventory_id) as pocet3
FROM customer as C
LEFT JOIN rental as R ON C.customer_id = R.customer_id
LEFT JOIN inventory as I ON I.inventory_id = R.inventory_id
LEFT JOIN film AS F ON I.film_id = F.film_id
GROUP BY C.customer_id, C.first_name, C.last_name
HAVING count(DISTINCT F.film_id) = 0












/* Pro každého herce vypište, v kolika různých kategoriích filmů hraje. */












/* Pro všechny zákazníky z Polska vypište, do kolika různých kategorií spadají
         filmy, které si tito zákazníci vypůjčili. */