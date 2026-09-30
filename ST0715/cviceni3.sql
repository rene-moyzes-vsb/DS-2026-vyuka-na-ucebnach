 /*SELECT 
    category.name,language.name as lang,
    count(*) as pocet_radku,
    count(1) as pocet_radku_efektivne,
    count(F.film_id) as pocet_id,
    count(original_language_id) as pocet_ori_lang,
    count(DISTINCT original_language_id) distinct_pocet_ori_lang,
    SUM(F.length),
    MAX(F.length),
    MIN(F.length),
    AVG(F.length)
FROM public.film F
JOIN public.film_category ON film_category.film_id = F.film_id
JOIN public.category ON category.category_id = film_category.category_id
JOIN public.language ON language.language_id = F.language_id
--WHERE category.name = 'Comedy'
GROUP BY category.name,F.language_id,language.name
HAVING  count(1) > 80 ;

SELECT
FROM + JOIN
WHERE
GROUP BY
HAVING
ORDER BY
*/

--Vypište počty filmů pro jednotlivé klasifikace (atribut rating)


/* SELECT rating, count(film_id) as pocet
FROM film
GROUP BY rating
HAVING count(film_id) > 200
ORDER BY rating; */

/*
Pro každé jméno zákazníka vypište počet zákazníků s tímto jménem. Je ve výsledku něco překvapivého? */
/*
SELECT first_name, last_name, count(1)
FROM customer
GROUP BY first_name, last_name
-- HAVING count(1) > 1
ORDER BY first_name;

SELECT count(DISTINCT first_name || ' ' || last_name), count(1)
FROM customer;
*/

/*Vypište součty všech plateb za jednotlivé roky a měsíce. Výsledek uspořádejte podle roků a měsíc*/

/* SELECT extract(YEAR FROM payment_date) as year, extract(MONTH FROM payment_date) as month, sum(amount)
FROM payment
GROUP BY extract(YEAR FROM payment_date), extract(MONTH FROM payment_date)
ORDER BY year, 2; */

/*Vypište klasifikace filmů (atribut rating), jejichž délka je menší než 50 minut a celková délka takových filmů v
dané klasifikaci je větší než 250 minut. Výsledek seřaďte sestupně podle abecedy*/
/*
SELECT rating, sum(length)
FROM film
WHERE length < 50
GROUP BY rating
HAVING sum(length) > 250
ORDER BY sum(length) ASC;
*/

/*Vypište pro jednotlivé zákazníky (jejich ID, jméno a příjmení) počty různých filmů, které si vypůjčili*/

/*
SELECT customer.customer_id,customer.first_name, customer.last_name, COUNT(DISTINCT film_id) as pocet 
FROM customer 
left JOIN rental r on r.customer_id = customer.customer_id
left JOIN inventory i on i.inventory_id = r.inventory_id
GROUP BY customer.customer_id,customer.first_name, customer.last_name 
--HAVING COUNT(DISTINCT film_id) = 0;
ORDER BY pocet DESC;
*/

/*Pro každého herce vypište, v kolika různých kategoriích filmů hraje*/

SELECT a.first_name,a.last_name,COUNT(DISTINCT c.category_id)

FROM actor as a
join film_actor as fa on a.actor_id = fa.actor_id
join film  as f on fa.film_id = f.film_id
join film_category as fc ON f.film_id = fc.film_id
join category as c on  fc.category_id = c.category_id
GROUP BY a.first_name,a.last_name 

; 