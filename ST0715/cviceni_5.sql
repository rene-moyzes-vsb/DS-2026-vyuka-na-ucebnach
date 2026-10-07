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

/* SELECT F.film_id,
(SELECT  count(1) FROM film_actor where f.film_id = film_actor.film_id ) as pocet_hercu,
(SELECT count(2) from film_category where f.film_id = film_category.film_id) as pocet_kategorii
 FROM film F */
;




























-- ============================================================
-- Uloha 2
-- Zadani: Pro kazdeho zakaznika vypiste pocet dlouhych
--         mene nez 5 dni a pocet vypujcek dlouhych mene nez
--         7 dni.
-- Napoveda: Pouzijte dva nezavisle korelovane poddotazy v SELECT.
--           Podminku na dobu trvani dejte dovnitr poddotazu, ne
--           do vnejsiho WHERE.
-- ============================================================

  --SELECT extract(DAY from r.return_date-R.rental_date) FROM rental R;
  --SELECT count(1) FROM rental R WHERE extract(DAY from r.return_date-R.rental_date ) < 5
/*
  SELECT c.customer_id,c.first_name, c.last_name,
  (SELECT count(1) FROM rental R WHERE extract(DAY from r.return_date-R.rental_date ) < 5 AND c.customer_id = R.customer_id) as mene_nez_5,
  (SELECT count(1) FROM rental R WHERE extract(DAY from r.return_date-R.rental_date ) < 7 AND c.customer_id = R.customer_id) as mene_nez_7
   FROM customer C;
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

select * from category

SELECT a.first_name || ' ' || a.last_name,
(SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'comedy' and fa.actor_id = a.actor_id),
(SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'horror' and fa.actor_id = a.actor_id)
FROM actor a
WHERE (SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'comedy' and fa.actor_id = a.actor_id)
    >= (2 * (SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'horror' and fa.actor_id = a.actor_id));


SELECT full_name, count_comedy,count_horror FROM

(
SELECT  a.first_name || ' ' || a.last_name as full_name,
(SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'comedy' and fa.actor_id = a.actor_id) count_comedy,
(SELECT count(1) from film_actor fa join film f on fa.film_id = f.film_id join film_category fc on fa.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id where c.name ilike 'horror' and fa.actor_id = a.actor_id) count_horror
FROM actor a
)  RS
WHERE count_comedy >= 2*count_horror ;






























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


  SELECT title FROM film F
  WHERE F.length = 
    (
        SELECT MIN(F.length) FROM film F
    )
;


SELECT customer_id, SUM(amount) sum
FROM payment
GROUP BY customer_id
HAVING SUM(amount)
=
(
SELECT MAX(sum) FROM
(
SELECT customer_id, SUM(amount) sum
FROM payment
GROUP BY customer_id
) T
);





























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





























