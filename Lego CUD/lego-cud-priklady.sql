-- =============================================================================
-- LEGO: INSERT, UPDATE, DELETE krok za krokem (15 příkladů)
-- =============================================================================
--
-- Výklad a vysvětlení najdeš v souboru lego-cud-vyklad.md. Tento skript je
-- "cvičebnice": každý příklad má situaci, příkaz, kontrolu a poznámku.
--
-- JAK S TÍM PRACOVAT
--   1) Otevři JEDNO SQL okno a celý skript v něm spouštěj po částech.
--      Dočasná tabulka existuje jen v tomhle jednom spojení. Když okno
--      zavřeš nebo se odpojíš, zmizí; pak stačí znovu spustit část 0.
--   2) NESPOUŠTĚJ celý soubor najednou. Spouštěj vždy jen označený blok
--      (jeden příkaz nebo SELECT + příkaz + SELECT) a čti výsledek.
--   3) Před každou změnou si udělej SELECT se stejnou podmínkou WHERE:
--      uvidíš, které řádky se změna dotkne. Po změně SELECT zopakuj.
--
-- PROČ DOČASNÁ TABULKA
--   Pracujeme na kopii "moje_sety" tabulky lego.sets. Originální data se
--   nikdy nezmění a nemůžeš nic rozbít. Kdykoli chceš začít znovu, spusť
--   část 0 (obnovení).
--
-- ŘÁDKY OZNAČENÉ "ZÁMĚRNÁ CHYBA" jsou v komentáři. Odkomentuj je a spusť,
-- abys viděl, co databáze řekne. Chyba nic nerozbije: příkaz se neprovede.
--
-- Počty řádků v komentářích platí pro spuštění od začátku v pořadí.
-- =============================================================================


-- =============================================================================
-- 0. PŘÍPRAVA: dočasná kopie tabulky lego.sets
-- =============================================================================

-- Smaže případnou starou kopii (bezpečné, když ještě neexistuje).
DROP TABLE IF EXISTS pg_temp.moje_sety;

-- Vytvoří prázdnou tabulku se STEJNOU STRUKTUROU jako lego.sets.
-- INCLUDING ALL převezme i primární klíč a NOT NULL, takže se nám kopie
-- chová stejně jako originál. Cizí klíče (FOREIGN KEY) se nekopírují.
CREATE TEMP TABLE moje_sety (LIKE lego.sets INCLUDING ALL);

-- Naplní ji daty z originálu.
INSERT INTO moje_sety
SELECT * FROM lego.sets;

-- Kontrola: musí vyjít stejně (28179).
SELECT
    (SELECT COUNT(*) FROM lego.sets) AS original,
    (SELECT COUNT(*) FROM moje_sety) AS kopie;

-- Jak vypadají sloupce:
--   set_num   VARCHAR(20)   klíč sady, např. '75252-1' (primární klíč)
--   name      VARCHAR(256)  název, povinný (NOT NULL)
--   year      INTEGER       rok vydání
--   theme_id  INTEGER       odkaz na lego.themes(id)
--   num_parts INTEGER       počet dílků
--   img_url   VARCHAR(500)  adresa obrázku
SELECT * FROM moje_sety WHERE set_num = '75252-1';


-- =============================================================================
-- A. INSERT: přidáváme řádky
-- =============================================================================
-- Základní tvar:
--   INSERT INTO tabulka (sloupec1, sloupec2, ...)
--   VALUES (hodnota1, hodnota2, ...);
-- Pořadí hodnot MUSÍ odpovídat pořadí vypsaných sloupců.

-- -----------------------------------------------------------------------------
-- INSERT 1: jedna sada, všechny sloupce vyjmenované
-- -----------------------------------------------------------------------------
-- Situace: vymysleli jsme vlastní sadu a chceme ji přidat.

INSERT INTO moje_sety (set_num, name, year, theme_id, num_parts, img_url)
VALUES ('MOJE-1', 'Moje první sada', 2025, 158, 120, NULL);

-- Kontrola:
SELECT * FROM moje_sety WHERE set_num = 'MOJE-1';

-- Poznámky:
--   * Text patří do apostrofů '...', čísla se píšou bez nich.
--   * NULL znamená "hodnota není známa / chybí". Není to nula ani prázdný text.
--   * 158 je id tématu Star Wars (zjistili jsme ho v lego.themes).
--
-- ZÁMĚRNÁ CHYBA: spusť příkaz INSERT 1 podruhé.
--   Dostaneš: duplicate key value violates unique constraint (23505).
--   set_num je primární klíč a dva stejné klíče existovat nesmí.

-- -----------------------------------------------------------------------------
-- INSERT 2: jen některé sloupce, ostatní zůstanou NULL
-- -----------------------------------------------------------------------------
-- Situace: víme jen klíč a název, zbytek doplníme později.

INSERT INTO moje_sety (set_num, name)
VALUES ('MOJE-2', 'Sada jen s názvem');

SELECT * FROM moje_sety WHERE set_num = 'MOJE-2';
-- Sloupce year, theme_id, num_parts a img_url jsou NULL.

-- Pravidlo: vynechat můžeš jen sloupce, které smí být NULL.
--
-- ZÁMĚRNÁ CHYBA: name je povinné (NOT NULL), tak ho nevynechávej:
-- INSERT INTO moje_sety (set_num, year) VALUES ('MOJE-X', 2025);
--   Dostaneš: null value in column "name" violates not-null constraint (23502).

-- -----------------------------------------------------------------------------
-- INSERT 3: více řádků jedním příkazem
-- -----------------------------------------------------------------------------
-- Situace: chceme přidat tři sady najednou.

INSERT INTO moje_sety (set_num, name, year, theme_id, num_parts)
VALUES
    ('MOJE-3', 'Sada A', 2025, 158, 100),
    ('MOJE-4', 'Sada B', 2025, 246, 200),
    ('MOJE-5', 'Sada C', 2026, 246, 300);

SELECT * FROM moje_sety WHERE set_num LIKE 'MOJE-%' ORDER BY set_num;
-- Očekávej 5 řádků (MOJE-1 až MOJE-5).

-- Poznámka: jeden příkaz je buď celý úspěšný, nebo se neprovede vůbec.
-- Kdyby třetí řádek měl chybu, nevloží se ani první dva.

-- -----------------------------------------------------------------------------
-- INSERT 4: řádky z jiného SELECTu (INSERT ... SELECT)
-- -----------------------------------------------------------------------------
-- Situace: chceme zkopírovat sady Harry Potter z roku 2018 pod novými klíči.
-- Místo VALUES napíšeme SELECT a jeho výsledek se vloží.

-- Nejdřív se podívej, co se zkopíruje (17 řádků):
SELECT 'K-' || set_num AS novy_klic, name || ' (kopie)' AS novy_nazev
FROM lego.sets
WHERE theme_id = 246 AND year = 2018;

-- A teď to vlož:
INSERT INTO moje_sety (set_num, name, year, theme_id, num_parts, img_url)
SELECT 'K-' || set_num,
       name || ' (kopie)',
       year,
       theme_id,
       num_parts,
       img_url
FROM lego.sets
WHERE theme_id = 246 AND year = 2018;

SELECT set_num, name FROM moje_sety WHERE set_num LIKE 'K-%' ORDER BY set_num;

-- Poznámky:
--   * || spojuje texty. Z '75945-1' se stane 'K-75945-1'.
--   * Klíče musí být nové, jinak narazíš na duplicitu (23505).
--   * Předpona musí být krátká: set_num je VARCHAR(20). Nejdelší původní klíč
--     má 15 znaků, takže 'K-' projde, ale 'KOPIE-' už ne (22001).

-- -----------------------------------------------------------------------------
-- INSERT 5: hodnota z poddotazu a RETURNING
-- -----------------------------------------------------------------------------
-- Situace: id tématu si nechceme pamatovat, necháme ho najít podle názvu.
-- RETURNING nám rovnou ukáže, co se vložilo.

INSERT INTO moje_sety (set_num, name, year, theme_id, num_parts)
VALUES (
    'MOJE-6',
    'Moje hvězdná loď',
    2025,
    (SELECT id FROM lego.themes WHERE name = 'Star Wars' AND parent_id IS NULL),
    250
)
RETURNING set_num, name, theme_id;

-- Pozor na past: názvy témat nejsou unikátní! 'Star Wars' existuje 4x
-- (id 18, 158, 209, 261). Proto potřebujeme i parent_id IS NULL.
--
-- ZÁMĚRNÁ CHYBA: bez dodatečné podmínky poddotaz vrátí víc řádků:
-- INSERT INTO moje_sety (set_num, name, theme_id)
-- VALUES ('MOJE-Y', 'x', (SELECT id FROM lego.themes WHERE name = 'Star Wars'));
--   Dostaneš: more than one row returned by a subquery used as an expression.

-- BONUS: co dělat, když řádek už může existovat?
-- a) Nic nedělej (tiše přeskoč):
INSERT INTO moje_sety (set_num, name)
VALUES ('MOJE-1', 'Jiný název')
ON CONFLICT (set_num) DO NOTHING;
-- Výsledek: INSERT 0 0 (nic nevloženo, žádná chyba, název zůstal původní).

-- b) Vlož, a pokud klíč existuje, přepiš název ("upsert"):
INSERT INTO moje_sety (set_num, name)
VALUES ('MOJE-1', 'Přepsaný název')
ON CONFLICT (set_num) DO UPDATE SET name = EXCLUDED.name;
-- EXCLUDED = řádek, který jsme se pokoušeli vložit.

SELECT set_num, name FROM moje_sety WHERE set_num = 'MOJE-1';


-- =============================================================================
-- B. UPDATE: měníme existující řádky
-- =============================================================================
-- Základní tvar:
--   UPDATE tabulka
--   SET sloupec1 = nová_hodnota1, sloupec2 = nová_hodnota2
--   WHERE podmínka;
--
-- !!! WHERE rozhoduje, KTERÝCH řádků se změna týká. Bez WHERE se změní
-- !!! VŠECHNY řádky tabulky. Proto vždy nejdřív SELECT se stejným WHERE.

-- -----------------------------------------------------------------------------
-- UPDATE 1: jeden sloupec, jeden řádek (podle primárního klíče)
-- -----------------------------------------------------------------------------
-- Situace: chceme upřesnit název jedné sady.

-- Před:
SELECT set_num, name FROM moje_sety WHERE set_num = '75252-1';

UPDATE moje_sety
SET name = 'Imperial Star Destroyer (UCS)'
WHERE set_num = '75252-1';
-- Výsledek: UPDATE 1

-- Po:
SELECT set_num, name FROM moje_sety WHERE set_num = '75252-1';

-- Poznámka: podmínka na primární klíč zasáhne nejvýše jeden řádek.
-- Zkontroluj počet řádků ve výsledku: UPDATE 1 je přesně to, co čekáme.

-- -----------------------------------------------------------------------------
-- UPDATE 2: více sloupců najednou
-- -----------------------------------------------------------------------------
-- Situace: u sady opravíme rok i počet dílků naráz.

-- Před:
SELECT set_num, name, year, num_parts FROM moje_sety WHERE set_num = '75192-1';

UPDATE moje_sety
SET year = 2018,
    num_parts = 7500
WHERE set_num = '75192-1';

-- Po:
SELECT set_num, name, year, num_parts FROM moje_sety WHERE set_num = '75192-1';

-- Poznámky:
--   * Sloupce v SET se oddělují čárkou (ne slovem AND!).
--   * Hodnoty se vyhodnocují z původního řádku, takže nezáleží na pořadí.
--   * Nastavit sloupec na NULL jde: SET img_url = NULL.
--
-- ZÁMĚRNÁ CHYBA: špatný datový typ:
-- UPDATE moje_sety SET num_parts = 'abc' WHERE set_num = '75192-1';
--   Dostaneš: invalid input syntax for type integer (22P02).

-- -----------------------------------------------------------------------------
-- UPDATE 3: více řádků a výpočet z původní hodnoty
-- -----------------------------------------------------------------------------
-- Situace: počty dílků u Harry Potter sad z roku 2019 chceme zvýšit o 10 %.

-- Před (8 řádků):
SELECT set_num, name, num_parts
FROM moje_sety
WHERE theme_id = 246 AND year = 2019
ORDER BY set_num;

UPDATE moje_sety
SET num_parts = ROUND(num_parts * 1.1)
WHERE theme_id = 246
  AND year = 2019
RETURNING set_num, num_parts;
-- Výsledek: UPDATE 8, RETURNING rovnou ukáže nové hodnoty.

-- Poznámka: vpravo od = můžeš použít původní hodnotu sloupce (num_parts * 1.1).
-- ROUND zaokrouhlí na celé číslo, protože num_parts je INTEGER.

-- -----------------------------------------------------------------------------
-- UPDATE 4: hodnota z jiné tabulky (UPDATE ... FROM)
-- -----------------------------------------------------------------------------
-- Situace: k názvu sad z roku 1949 chceme připsat název jejich tématu.
-- Název tématu je v tabulce lego.themes, kterou si "připojíme" přes FROM.

-- Před (5 řádků):
SELECT s.set_num, s.name, t.name AS tema
FROM moje_sety s
JOIN lego.themes t ON t.id = s.theme_id
WHERE s.year = 1949
ORDER BY s.set_num;

UPDATE moje_sety s
SET name = s.name || ' [' || t.name || ']'
FROM lego.themes t
WHERE t.id = s.theme_id
  AND s.year = 1949;
-- Výsledek: UPDATE 5

SELECT set_num, name FROM moje_sety WHERE year = 1949 ORDER BY set_num;

-- Poznámky:
--   * FROM přidá další tabulku, WHERE ji propojí (stejně jako JOIN ... ON).
--   * Vlevo od = je název sloupce BEZ aliasu (name), vpravo můžeš aliasy použít.
--   * Změní se jen moje_sety. Tabulka lego.themes zůstane beze změny.

-- -----------------------------------------------------------------------------
-- UPDATE 5: nebezpečí UPDATE bez WHERE a bezpečný postup (transakce)
-- -----------------------------------------------------------------------------
-- Situace: zapomněli jsme WHERE. Naštěstí máme záchrannou síť: transakci.
-- BEGIN otevře "zkoušku", ROLLBACK vrátí všechno zpět, COMMIT by to potvrdil.

BEGIN;

UPDATE moje_sety
SET num_parts = 0;
-- Výsledek: UPDATE 28202. Změnily se VŠECHNY řádky!

SELECT COUNT(*) AS radku, SUM(num_parts) AS soucet_dilku FROM moje_sety;
-- Součet je 0: všechny sady mají 0 dílků. To jsme určitě nechtěli.

ROLLBACK;

SELECT COUNT(*) AS radku, SUM(num_parts) AS soucet_dilku FROM moje_sety;
-- Součet je zase původní. ROLLBACK vzal vše zpět.

-- Zásada, kterou si odnes:
--   1. Nejdřív SELECT se stejným WHERE.
--   2. Počet řádků, který hlásí UPDATE, musí odpovídat očekávání.
--   3. Při pochybnostech: BEGIN, příkaz, kontrola, a teprve pak COMMIT
--      (nebo ROLLBACK).


-- =============================================================================
-- C. DELETE: mažeme řádky
-- =============================================================================
-- Základní tvar:
--   DELETE FROM tabulka
--   WHERE podmínka;
--
-- Sloupce se neuvádí, DELETE maže celé řádky.
-- !!! Bez WHERE smaže VŠECHNY řádky. Stejné pravidlo jako u UPDATE.

-- -----------------------------------------------------------------------------
-- DELETE 1: jeden řádek podle primárního klíče
-- -----------------------------------------------------------------------------
-- Situace: smažeme jednu sadu.

-- Před:
SELECT set_num, name FROM moje_sety WHERE set_num = '700.B-1';

DELETE FROM moje_sety
WHERE set_num = '700.B-1';
-- Výsledek: DELETE 1

-- Po (nic nenajde):
SELECT set_num, name FROM moje_sety WHERE set_num = '700.B-1';

-- -----------------------------------------------------------------------------
-- DELETE 2: více řádků podle podmínky
-- -----------------------------------------------------------------------------
-- Situace: smažeme všechny sady z nejstaršího roku 1949.

-- Před (4 řádky, jednu sadu jsme už smazali):
SELECT set_num, name, year FROM moje_sety WHERE year = 1949 ORDER BY set_num;

DELETE FROM moje_sety
WHERE year = 1949;
-- Výsledek: DELETE 4

-- Poznámka: počet odstraněných řádků vždy porovnej s tím, co ukázal SELECT.

-- -----------------------------------------------------------------------------
-- DELETE 3: podmínka s poddotazem a IN
-- -----------------------------------------------------------------------------
-- Situace: smažeme všechny sady z tématu "Technic". V tabulce sets je jen
-- theme_id (číslo), název tématu je v lego.themes, tak se zeptáme poddotazem.

-- Před: kolik jich bude?
SELECT COUNT(*)
FROM moje_sety
WHERE theme_id IN (SELECT id FROM lego.themes WHERE name = 'Technic');
-- Očekávej 955 (téma Technic má 5 různých id).

DELETE FROM moje_sety
WHERE theme_id IN (SELECT id FROM lego.themes WHERE name = 'Technic');
-- Výsledek: DELETE 955

-- Proč IN a ne =?
--   Poddotaz vrací víc id, protože názvy témat nejsou unikátní. Znak =
--   porovnává s JEDNOU hodnotou, IN s celým seznamem hodnot.

-- -----------------------------------------------------------------------------
-- DELETE 4: mazání podle neexistující souvislosti (NOT EXISTS)
-- -----------------------------------------------------------------------------
-- Situace: uklidíme staré sady (před rokem 1980), které nemají v inventáři
-- žádné dílky. Chceme tedy řádky, ke kterým v jiných tabulkách NIC neexistuje.

-- Před:
SELECT COUNT(*)
FROM moje_sety s
WHERE s.year < 1980
  AND NOT EXISTS (
      SELECT 1
      FROM lego.inventories i
      JOIN lego.inventory_parts ip ON ip.inventory_id = i.id
      WHERE i.set_num = s.set_num
  );
-- Očekávej přibližně 66.

DELETE FROM moje_sety s
WHERE s.year < 1980
  AND NOT EXISTS (
      SELECT 1
      FROM lego.inventories i
      JOIN lego.inventory_parts ip ON ip.inventory_id = i.id
      WHERE i.set_num = s.set_num
  );

-- Poznámka: poddotaz odkazuje na vnější řádek (s.set_num). Pro každou sadu
-- se hledá, jestli má nějaké dílky; NOT EXISTS projde, když žádné nenajde.

-- -----------------------------------------------------------------------------
-- DELETE 5: bezpečný postup s RETURNING a transakcí
-- -----------------------------------------------------------------------------
-- Situace: smažeme sady, které mají v názvu "Test". Chceme se ujistit,
-- že mažeme přesně to, co zamýšlíme, a nechat si možnost couvnout.

BEGIN;

DELETE FROM moje_sety
WHERE name LIKE '%Test%'
RETURNING set_num, name, year;
-- RETURNING vypíše smazané řádky. Zkontroluj je očima (3 až 4 řádky).

-- Teď se rozhodni:
--   Sedí to?    -> COMMIT;
--   Nesedí to?  -> ROLLBACK;
ROLLBACK;

-- Po ROLLBACKu jsou řádky zpět:
SELECT set_num, name FROM moje_sety WHERE name LIKE '%Test%';

-- Totéž s COMMIT by smazalo definitivně:
--   BEGIN;
--   DELETE FROM moje_sety WHERE name LIKE '%Test%';
--   COMMIT;

-- Poznámka: kdybys chtěl vyprázdnit celou tabulku, existuje i TRUNCATE
-- (rychlejší, ale bez WHERE). V ostré databázi s ním buď velmi opatrný.


-- =============================================================================
-- D. ÚKLID A ZNOVU OD ZAČÁTKU
-- =============================================================================

-- Chceš začít od nuly? Spusť znovu část 0 (DROP + CREATE + INSERT).
--
-- Dočasná tabulka zmizí sama, když se odpojíš. Chceš-li ji odstranit hned:
-- DROP TABLE IF EXISTS pg_temp.moje_sety;
