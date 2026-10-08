-- ============================================================
-- Cviceni 4: Mnozinove operace a kvantifikatory
-- Schema: public (databaze Sakila)
-- Mezi zadanimi je 30 prazdnych radku pro vase reseni.
-- ============================================================

-- ============================================================
-- Uloha 1
-- Zadani: Vypiste ID a nazvy filmu, ve kterych hral herec s ID = 1.
--         Dotaz vyreste bez pouziti JOIN.
-- Napoveda: Pouzijte konstrukci IN (nebo EXISTS) s poddotazem nad
--           tabulkou film_actor.
-- ============================================================


/*
SELECT film_id, title FROM film F
WHERE
film_id IN (

SELECT film_id
FROM film_actor FA
WHERE actor_id=1

);

SELECT film_id, title FROM film F
WHERE EXISTS(
    SELECT 1
    FROM film_actor FA
    WHERE actor_id=1 AND FA.film_id = F.film_id
);



SELECT F.film_id, title FROM film F
INNER JOIN 
(
SELECT film_id
FROM film_actor FA
WHERE actor_id=1
) AS FFA
ON F.film_id=FFA.film_id;

*/

























-- ============================================================
-- Uloha 2
-- Zadani: Vypiste ID filmu, ve kterych hral herec s ID = 1.
-- Napoveda: Zamyslete se, zda vubec potrebujete vnejsi dotaz -
--           mozna staci jen poddotaz nad film_actor.
-- ============================================================





/*
SELECT film_id FROM film F
WHERE
film_id IN (

SELECT film_id
FROM film_actor FA
WHERE actor_id=1

);

SELECT film_id
FROM film_actor FA
WHERE actor_id=1
*/






















-- ============================================================
-- Uloha 3
-- Zadani: Vypiste ID a nazvy filmu, ve kterych hral herec s ID = 1
--         zaroven s hercem s ID = 10.
-- Napoveda: Jde o prunik dvou mnozin filmu - zkuste dvakrat pouzit
--           IN spojene pres AND.
-- ============================================================
/*

SELECT film_id, title FROM film F
WHERE
film_id IN (
    SELECT film_id
    FROM film_actor FA
    WHERE actor_id=1
) AND EXISTS (
    SELECT 1
    FROM film_actor FA
    WHERE actor_id=10 AND F.film_id = FA.film_id
);



SELECT F.film_id, title FROM film F
JOIN film_actor FA ON F.film_id = FA.film_id
JOIN film_actor FA2 ON FA2.film_id = F.film_id
WHERE FA.actor_id=1 AND FA2.actor_id=10;


WHERE
film_id IN (
    SELECT film_id
    FROM film_actor FA
    WHERE actor_id=1
) AND EXISTS (
    SELECT 1
    FROM film_actor FA
    WHERE actor_id=10 AND F.film_id = FA.film_id
);

*/


























-- ============================================================
-- Uloha 4
-- Zadani: Vypiste ID a nazvy filmu, ve kterych hral herec s ID = 1
--         nebo herec s ID = 10.
-- Napoveda: Jde o sjednoceni dvou mnozin - zkuste IN s podminkou OR
--           uvnitr poddotazu, nebo JOIN s DISTINCT.
-- ============================================================



/*

SELECT film_id, title FROM film F
WHERE
film_id IN (
    SELECT film_id
    FROM film_actor FA
    WHERE actor_id=1 OR actor_id=10
)

*/






















-- ============================================================
-- Uloha 5
-- Zadani: Vypiste ID filmu, ve kterych nehral herec s ID = 1.
-- Napoveda: Pozor na past s operatorem != - jde o rozdil mnozin,
--           pouzijte NOT IN nebo NOT EXISTS.
-- ============================================================
/*
SELECT film_id FROM film F
WHERE
film_id NOT IN (
    SELECT film_id
    FROM film_actor FA
    WHERE actor_id=1
)
*/



























-- ============================================================
-- Uloha 7
-- Zadani: Vypiste ID a nazvy filmu, ve kterych hral herec PENELOPE
--         GUINESS zaroven s hercem CHRISTIAN GABLE.
-- Napoveda: Stejny princip jako uloha 3, ale herce musite dohledat
--           podle jmena pres JOIN s tabulkou actor.
-- ============================================================

/*

SELECT film_id, title FROM film F
WHERE
film_id IN (
    SELECT film_id
    FROM film_actor FA
    JOIN actor a on a.actor_id = fa.actor_id
    WHERE (a.first_name ILIKE 'PENELOPE' AND a.last_name ILIKE 'GUINESS')
) AND film_id IN (
    SELECT film_id
    FROM film_actor FA
    JOIN actor a on a.actor_id = fa.actor_id
    WHERE (a.first_name ILIKE 'CHRISTIAN' AND a.last_name ILIKE 'GABLE')
);

*/

























-- ============================================================
-- Uloha 12
-- Zadani: Vypiste jmena filmu, ktere jsou stejne dlouhe, jako
--         nejake jine filmy.
-- Napoveda: Potrebujete porovnat tabulku film samu se sebou -
--           pouzijte dva aliasy a EXISTS (nebo IN).
-- ============================================================


SELECT film_id, title FROM film F
WHERE exists (select fl.length from film fl where f.film_id <> fl.film_id and fl.length = f.length)




























-- ============================================================
-- Uloha 13
-- Zadani: Vypiste nazvy filmu, ktere jsou kratsi nez nejaky film,
--         ve kterem hraje BURT POSEY.
-- Napoveda: Zkuste kvantifikator ANY/SOME, nebo EXISTS s porovnanim
--           delek filmu.
-- ============================================================






























-- ============================================================
-- Uloha 19
-- Zadani: Vypiste nazvy filmu, ktere jsou kratsi nez vsechny filmy,
--         ve kterych hraje BURT POSEY.
-- Napoveda: Podobne jako predchozi uloha, ale pouzijte ALL misto
--           ANY (nebo NOT EXISTS).
-- ============================================================






























-- ============================================================
-- Uloha 22
-- Zadani: Vypiste zakazniky, kteri si pujcovali filmy pouze
--         v letnich mesicich (tj. cerven az srpen vcetne).
-- Napoveda: Slovo "pouze" signalizuje negaci - zkuste NOT EXISTS
--           nebo NOT IN, a nezapomente overit, ze zakaznik ma
--           alespon jednu vypujcku.
-- ============================================================





























