-- =============================================================================
-- LEGO: INSERT, UPDATE, DELETE - ZADÁNÍ
-- =============================================================================
--
-- Pod každé zadání napiš vlastní řešení do prázdného místa (je tam 20 řádků).
--
-- PRAVIDLA
--   * Pracuj v JEDNOM SQL okně. Dočasná tabulka existuje jen v tomto spojení.
--   * Měníme výhradně dočasnou kopii "moje_sety", originál lego.sets ne.
--   * Před každou změnou si udělej SELECT se stejnou podmínkou WHERE a po
--     změně ho zopakuj. Zkontroluj počet řádků, který příkaz nahlásí.
--
-- TABULKA moje_sety (kopie lego.sets)
--   set_num   VARCHAR(20)   klíč sady, např. '75252-1' (primární klíč)
--   name      VARCHAR(256)  název (povinný, NOT NULL)
--   year      INTEGER       rok vydání
--   theme_id  INTEGER       odkaz na lego.themes(id)
--   num_parts INTEGER       počet dílků
--   img_url   VARCHAR(500)  adresa obrázku
--
-- Počty řádků v zadání platí při postupném řešení od začátku.
-- =============================================================================


-- =============================================================================
-- 0. PŘÍPRAVA
-- =============================================================================
-- Zadání:
--   a) Odstraň dočasnou tabulku moje_sety, pokud už existuje.
--   b) Vytvoř dočasnou tabulku moje_sety se stejnou strukturou jako lego.sets,
--      včetně primárního klíče a NOT NULL (nápověda: LIKE ... INCLUDING ALL).
--   c) Naplň ji všemi řádky z lego.sets.
--   d) Kontrola: v lego.sets i moje_sety musí být 28179 řádků.


- Smaže případnou starou kopii (bezpečné, když ještě neexistuje).
DROP TABLE IF EXISTS pg_temp.moje_sety;

-- Vytvoří prázdnou tabulku se STEJNOU STRUKTUROU jako lego.sets.
-- INCLUDING ALL převezme i primární klíč a NOT NULL, takže se nám kopie
-- chová stejně jako originál. Cizí klíče (FOREIGN KEY) se nekopírují.
CREATE TEMP TABLE moje_sety (LIKE lego.sets INCLUDING ALL);

-- Naplní ji daty z originálu.
INSERT INTO moje_sety
SELECT * FROM lego.sets;

















-- =============================================================================
-- A. INSERT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- INSERT 1: jedna sada, všechny sloupce vyjmenované
-- -----------------------------------------------------------------------------
-- Zadání:
--   Vlož do moje_sety jednu novou sadu:
--     set_num 'MOJE-1', název 'Moje první sada', rok 2025, theme_id 158,
--     počet dílků 120, img_url bez hodnoty (NULL).
--   Vypiš vložený řádek.
-- Bonus:
--   Spusť INSERT podruhé. Jaká chyba nastane a proč?




















-- -----------------------------------------------------------------------------
-- INSERT 2: jen některé sloupce
-- -----------------------------------------------------------------------------
-- Zadání:
--   Vlož sadu s klíčem 'MOJE-2' a názvem 'Sada jen s názvem'. Zadej POUZE
--   sloupce set_num a name. Vypiš řádek a zkontroluj, které sloupce jsou NULL.
-- Bonus:
--   Zkus vložit sadu 'MOJE-X' s rokem 2025, ale BEZ názvu. Co databáze řekne?




















-- -----------------------------------------------------------------------------
-- INSERT 3: více řádků jedním příkazem
-- -----------------------------------------------------------------------------
-- Zadání:
--   Jedním příkazem vlož tři sady (set_num, name, year, theme_id, num_parts):
--     'MOJE-3', 'Sada A', 2025, 158, 100
--     'MOJE-4', 'Sada B', 2025, 246, 200
--     'MOJE-5', 'Sada C', 2026, 246, 300
--   Kontrola: sady s klíčem MOJE-% by teď měly být 5.




















-- -----------------------------------------------------------------------------
-- INSERT 4: INSERT ... SELECT
-- -----------------------------------------------------------------------------
-- Zadání:
--   Zkopíruj do moje_sety všechny sady z lego.sets, které mají theme_id 246
--   a year 2018 (17 řádků). Nový klíč bude 'K-' + původní set_num, nový
--   název bude původní název + ' (kopie)'. Ostatní sloupce převezmi.
--   Nejdřív si pomocí SELECT ukaž, co se bude vkládat.
-- Pozor:
--   set_num má max. 20 znaků, držet předponu krátkou.




















-- -----------------------------------------------------------------------------
-- INSERT 5: hodnota z poddotazu a RETURNING
-- -----------------------------------------------------------------------------
-- Zadání:
--   Vlož sadu 'MOJE-6' s názvem 'Moje hvězdná loď', rokem 2025 a 250 dílky.
--   theme_id nezadávej číslem: najdi ho poddotazem v lego.themes podle názvu
--   'Star Wars'. Pozor, témat se stejným názvem je víc. Hledej to kořenové
--   (bez nadřazeného tématu). Pomocí RETURNING vypiš vložený řádek.
-- Bonus:
--   a) Zkus vložit klíč 'MOJE-1' znovu tak, aby se při duplicitě nic nestalo
--      (žádná chyba, nic se nevloží).
--   b) Totéž, ale při duplicitě přepiš název na 'Přepsaný název'.




















-- =============================================================================
-- B. UPDATE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- UPDATE 1: jeden řádek, jeden sloupec
-- -----------------------------------------------------------------------------
-- Zadání:
--   U sady '75252-1' změň název na 'Imperial Star Destroyer (UCS)'.
--   Udělej SELECT před a po. Příkaz musí hlásit UPDATE 1.




















-- -----------------------------------------------------------------------------
-- UPDATE 2: více sloupců najednou
-- -----------------------------------------------------------------------------
-- Zadání:
--   U sady '75192-1' nastav rok 2018 a počet dílků 7500 jedním příkazem.
--   Udělej SELECT před a po.
-- Bonus:
--   Zkus nastavit num_parts na text 'abc'. Jakou chybu dostaneš?




















-- -----------------------------------------------------------------------------
-- UPDATE 3: více řádků a výpočet z původní hodnoty
-- -----------------------------------------------------------------------------
-- Zadání:
--   U všech sad s theme_id 246 z roku 2019 zvyš počet dílků o 10 % a výsledek
--   zaokrouhli na celé číslo. Pomocí RETURNING vypiš set_num a nový počet dílků.
--   Nejdřív SELECT, kolik řádků se změní (8).




















-- -----------------------------------------------------------------------------
-- UPDATE 4: hodnota z jiné tabulky (UPDATE ... FROM)
-- -----------------------------------------------------------------------------
-- Zadání:
--   U sad z roku 1949 připiš za název v hranatých závorkách název jejich
--   tématu z lego.themes, např. 'Small Brick Set (ABB) [Basic Set]'.
--   Použij UPDATE ... FROM. Očekávej UPDATE 5.
--   Nejdřív SELECT s JOINem, který ukáže sadu a název jejího tématu.




















-- -----------------------------------------------------------------------------
-- UPDATE 5: UPDATE bez WHERE a záchranná síť
-- -----------------------------------------------------------------------------
-- Zadání:
--   a) Otevři transakci (BEGIN).
--   b) Nastav VŠEM řádkům num_parts na 0 (záměrně bez WHERE).
--      Kolik řádků příkaz hlásí? (očekávej 28202)
--   c) Ověř součet num_parts a počet řádků.
--   d) Vrať vše zpět (ROLLBACK).
--   e) Ověř, že se součet vrátil na původní hodnotu.




















-- =============================================================================
-- C. DELETE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DELETE 1: jeden řádek podle klíče
-- -----------------------------------------------------------------------------
-- Zadání:
--   Smaž sadu s klíčem '700.B-1'. SELECT před (najde 1 řádek) a po (nenajde nic).
--   Příkaz musí hlásit DELETE 1.




















-- -----------------------------------------------------------------------------
-- DELETE 2: více řádků podle podmínky
-- -----------------------------------------------------------------------------
-- Zadání:
--   Smaž všechny sady z roku 1949. Nejdřív zkontroluj SELECTem, kolik jich je
--   (4, jednu už jsi smazal). Příkaz musí hlásit DELETE 4.




















-- -----------------------------------------------------------------------------
-- DELETE 3: poddotaz a IN
-- -----------------------------------------------------------------------------
-- Zadání:
--   Smaž všechny sady z tématu s názvem 'Technic'. Téma Technic má v lego.themes
--   víc různých id, použij proto poddotaz a IN (ne =).
--   Nejdřív zjisti SELECT COUNT(*), kolik řádků se smaže (955).
-- Bonus:
--   Co by se stalo, kdybys použil theme_id = (SELECT ...)? Proč?




















-- -----------------------------------------------------------------------------
-- DELETE 4: NOT EXISTS
-- -----------------------------------------------------------------------------
-- Zadání:
--   Smaž sady z doby před rokem 1980, které nemají v inventáři žádný dílek.
--   (Dílky sady najdeš přes lego.inventories a lego.inventory_parts; použij
--   NOT EXISTS s poddotazem, který odkazuje na vnější sadu.)
--   Nejdřív SELECT COUNT(*) se stejnou podmínkou (přibližně 66).




















-- -----------------------------------------------------------------------------
-- DELETE 5: RETURNING a transakce
-- -----------------------------------------------------------------------------
-- Zadání:
--   a) Otevři transakci.
--   b) Smaž sady, které mají v názvu slovo 'Test', a pomocí RETURNING vypiš
--      set_num, name a year smazaných řádků (3 až 4 řádky).
--   c) Rozhodni se: zrušit změnu (ROLLBACK).
--   d) Ověř SELECTem, že jsou sady s 'Test' v názvu zpátky.




















-- =============================================================================
-- D. ÚKLID
-- =============================================================================
-- Zadání:
--   Odstraň dočasnou tabulku moje_sety (pokud ji chceš zahodit hned,
--   nečekaje na odpojení).




