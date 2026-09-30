/* SELECT
     F.rating,
    --count(*) as pocet_r,
    --count(1) as pocer_r2,
    --count(original_language_id) pocet_ol,
    --count(NULL) count_null,
    --count(DISTINCT original_language_id) dist_pocet_ol,
    sum(length)/60/24 as soucet_delek_dny,
    min(length) as nejkratsi,
    max(length) as nejdelsi,
    avg(length) as prumer
FROM film F
WHERE f.length>60
GROUP BY F.rating
HAVING  --sum(length)/60/24 > 14
        --soucet_delek_dny>14 --nelze použít
ORDER BY soucet_delek_dny ; */ /* SELECT DISTINCT F.rating, f.length
FROM film F
ORDER BY 1; */ /*

*/ /*
SELECT
FROM + JOIN ON
WHERE
GROUP BY
HAVING
ORDER BY
*/ --Vypište počty filmů pro jednotlivé délky (atribut length)
 /* SELECT f.length || ' ' as x, count(1) as y
FROM film f
GROUP BY f.length
ORDER BY f.length; */ /*Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem.



select c.first_name, COUNT(c.first_name)
from customer c
GROUP BY c.first_name
HAVING COUNT(c.first_name) > 1
ORDER BY COUNT(c.first_name) DESC

*/ /*Vypište součty všech plateb za jednotlivé roky a měsíce.
Výsledek uspořádejte podle roků a měsíc*/
/*SELECT
       
       extract(year
               from payment_date) as year,
       EXTRACT(month
               from payment_date) as month,
               sum(amount) as soucet
FROM payment as p
GROUP BY extract(year
               from payment_date),
       EXTRACT(month
               from payment_date)
ORDER BY YEAR ASC, MONTH ASC;
*/
/*Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut
 a celková délka takových filmů v dané klasifikaci je větší než 250 minut.
 Výsledek seřaďte sestupně podle abecedy*/ 
 
/* SELECT f.rating, SUM(f.length)
FROM film f
WHERE f.length < 50 
GROUP BY f.rating
HAVING SUM(f.length) > 250
ORDER BY f.rating
; */
 
 /*Vypište ID a názvy všech jazyků a k nim počty filmů v daném jazyce, které jsou delší než 350 minut.*/
 
--select l.language_id, l.name, count(f.film_id) from language l LEFT JOIN film f On l.language_id = f.language_id GROUP BY l.name, l.language_id;


 /*Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty různých filmů,
 které si vypůjčili*/ 
/*
SELECT c.customer_id, c.first_name, c.last_name, COUNT(DISTINCT f.film_id), COUNT(f.film_id), COUNT(i.inventory_id)
FROM film f JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON r.inventory_id = i.inventory_id
RIGHT JOIN customer c ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING count(f.film_id)=0;
*/

 
 /*Pro každého herce vypište, v kolika různých kategoriích filmů hraje*/ 
/*SELECT a.actor_id, COUNT(DISTINCT fc.category_id) as pocet
from actor a 
    left join film_actor as fa on fa.actor_id = a.actor_id
    left join film as f on f.film_id = fa.film_id
    left join film_category fc on fc.film_id = f.film_id
GROUP BY a.actor_id
ORDER BY pocet ASC*/












/*Pro všechny zákazníky z Polska vypište, do kolika různých kategorií spadají filmy, které si tito zákazníci
vypůjčili*/



SELECT Cu.customer_id, Cu.first_name, Cu.last_name, COUNT(DISTINCT Fc.category_id)
FROM country Co
JOIN city Ci on Ci.country_id = Co.country_id
JOIN address A on A.city_id = Ci.city_id
JOIN customer Cu on Cu.address_id = A.address_id 
LEFT JOIN rental R on R.customer_id = Cu.customer_id
LEFT JOIN inventory I ON I.inventory_id = R.inventory_id
LEFT JOIN film F on F.film_id = I.film_id
LEFT JOIN film_category Fc on Fc.film_id = F.film_id
WHERE Co.country = 'Poland'
GROUP BY Cu.customer_id, Cu.first_name, Cu.last_name