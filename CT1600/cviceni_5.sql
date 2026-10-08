-- ============================================================
-- Cviceni 5: Poddotazy
-- Schema: public (databaze Sakila)
-- Mezi zadanimi je 30 prazdnych radku pro vase reseni.
-- ============================================================

-- ============================================================
-- Uloha 1
-- Zadani: Pro kazdy film vypiste, kolik v nem hraje hercu a
--         v kolika kategoriich se nachazi.
-- Napoveda: Pozor na kartezsky soucin pri spojeni dvou vazebnich
--           tabulek najednou - zkuste misto toho dva samostatne
--           skalarni poddotazy v SELECT.
-- ============================================================


SELECT 
 fid,
 title,
 (SELECT count(1) FROM film_actor WHERE fid = film_actor.film_id) as pocet_hercu,
 (SELECT count(1) FROM film_category WHERE fid = film_id) as pocet_kategorii
FROM 
(SELECT film_id as fid, title 
 FROM film)
film



























-- ============================================================
-- Uloha 2
-- Zadani: Pro kazdeho zakaznika vypiste pocet vypujcek trvajicich
--         mene nez 5 dni a pocet vypujcek trvajicich mene nez
--         7 dni.
-- Napoveda: Pouzijte dva nezavisle korelovane poddotazy v SELECT.
--           Podminku na dobu trvani dejte dovnitr poddotazu, ne
--           do vnejsiho WHERE.
-- ============================================================
/*
SELECT customer_id,
(
    SELECT count(1)
    FROM rental
    WHERE EXTRACT(DAY FROM COALESCE(return_date,NOW()) - rental_date) < 5
    AND rental.customer_id = customer.customer_id
) as mene5,
(
    SELECT count(1)
    FROM rental
    WHERE EXTRACT(DAY FROM COALESCE(return_date,NOW()) - rental_date) < 7
    AND rental.customer_id = customer.customer_id
) as mene7
FROM customer

SELECT count(1)
FROM rental
GROUP BY EXTRACT(DAY FROM COALESCE(return_date,NOW()) - rental_date) 

--WHERE return_date is null;


*/

























-- ============================================================
-- Uloha 5
-- Zadani: Vypiste zakazniky, kteri v mesici cervnu provedli vice
--         nez 5 plateb a nejdelsi film, ktery si pujcili, ma
--         alespon 185 minut.
-- Napoveda: Poddotazy muzete pouzit i ve WHERE - vysledek poddotazu
--           porovnejte primo s konstantou.
-- ============================================================






























-- ============================================================
-- Uloha 6
-- Zadani: Vypiste zakazniky, jejichz vetsina plateb je o castce
--         vetsi nez 4.
-- Napoveda: "Vetsina" znamena, ze jeden pocet je vetsi nez druhy -
--           porovnejte dva poddotazy s COUNT.
-- ============================================================






























-- ============================================================
-- Uloha 7
-- Zadani: Vypiste herce, kteri hraji vice nez 2x castej v
--         komediich nez v hororech.
-- Napoveda: Pro kazdeho herce spoctete dva pocty (komedie, horor)
--           pomoci poddotazu s IN nad film_category/category
--           a porovnejte je.
-- ============================================================






























-- ============================================================
-- Uloha 11
-- Zadani: Vypiste zakazniky, kteri si pujcovali pouze filmy
--         v anglickem jazyce, a u kazdeho napiste, kolik maji
--         vypujcek.
-- Napoveda: Zkombinujte NOT EXISTS (zadna vypujcka jineho jazyka)
--           s IN (alespon jedna vypujcka) a poddotaz v SELECT
--           pro pocet.
-- ============================================================






























-- ============================================================
-- Uloha 13
-- Zadani: Vypiste nazev nejdelsiho filmu.
-- Napoveda: Nejprve zjistete maximalni delku filmu pomoci MAX,
--           pak vyberte filmy s touto delkou - pozor, LIMIT 1
--           nestaci.
-- ============================================================






























-- ============================================================
-- Uloha 14
-- Zadani: Vypiste nazev nejdelsiho filmu pro kazdou klasifikaci
--         (atribut film.rating).
-- Napoveda: Podobne jako predchozi uloha, ale poddotaz pro MAX
--           musi byt korelovany podle rating.
-- ============================================================






























-- ============================================================
-- Uloha 25
-- Zadani: Vypiste zakazniky s nejvetsim poctem vypujcek.
-- Napoveda: Nejprve spoctete pocet vypujcek pro kazdeho zakaznika
--           (treba pomoci WITH), pak vyberte ty s maximalni
--           hodnotou.
-- ============================================================






























-- ============================================================
-- Uloha 26
-- Zadani: Vypiste nazvy filmu, ktere byly vypujceny nejvicekrat.
--         Pocet vypujcek bude soucasti vypisu.
-- Napoveda: Podobne jako uloha 25, ale pro filmy - spoctete pocet
--           vypujcek a porovnejte s maximem pomoci vnoreneho
--           poddotazu nebo WITH.
-- ============================================================































SELECT film.film_id, title
FROM film
WHERE film.length = (SELECT MAX(length) FROM film);


SELECT customer_id, SUM(amount) as trzba
FROM payment
GROUP BY customer_id
HAVING SUM(amount) = 
(
    SELECT MAX(trzba) FROM
    (
    SELECT customer_id, SUM(amount) as trzba
    FROM payment
    GROUP BY customer_id
    )T
);

WITH T AS(
SELECT customer_id, SUM(amount) as trzba
    FROM payment
    GROUP BY customer_id
)
SELECT * FROM T
WHERE T.trzba = (SELECT MAX(trzba) FROM T)



;