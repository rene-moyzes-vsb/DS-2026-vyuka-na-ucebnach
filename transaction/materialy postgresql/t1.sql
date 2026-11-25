-- Cvičení: Izolační úrovně transakcí v PostgreSQL
--
-- Cíle:
--   1. Pozorovat, jak souběžné transakce vidí nepotvrzené a potvrzené změny.
--   2. Porovnat snímek příkazu v READ COMMITTED se snímkem transakce
--      v REPEATABLE READ.
--   3. Pozorovat explicitní zámek řádku pomocí SELECT ... FOR UPDATE.
--   4. Vyvolat konflikt serializace a pochopit, proč je nutné transakci opakovat.
--
-- Organizace práce:
--   Otevřete dvě samostatné relace (T1 a T2) připojené ke stejné testovací
--   databázi. Každý očíslovaný krok provádějte v označené relaci a ve
--   stanoveném pořadí. Nespouštějte celý soubor najednou.
--
-- Základní průběh transakce:
--   BEGIN -> jeden nebo více SQL příkazů -> COMMIT (potvrzení) nebo
--   ROLLBACK (zrušení změn).
--
-- Časová osa souběhu v úloze 3 (čas plyne shora dolů):
--
--   Čas | Relace T1 (čtenář)                         | Relace T2
--   ----+--------------------------------------------+------------------------------
--    1  | BEGIN ISOLATION LEVEL READ COMMITTED;       |
--    2  | SELECT AVG(pieces) -> 6;                    |
--    3  |                                            | BEGIN ISOLATION LEVEL
--       |                                            |   READ COMMITTED;
--    4  |                                            | INSERT pieces = 50;
--    5  |                                            | COMMIT;
--    6  | SELECT AVG(pieces) -> 14.8; COMMIT;        |
--
-- Tento rozvrh ukazuje, že potvrzená změna T2 je při READ COMMITTED
-- viditelná druhému příkazu T1, přestože oba příkazy patří do jedné transakce.
--
-- Upozornění:
--   Úvodní část maže tabulku orders, pokud již existuje. Použijte testovací
--   databázi a spusťte přípravu pouze tehdy, když v obou relacích neběží
--   žádná předchozí transakce z tohoto cvičení.

-------------------------- 0. PŘÍPRAVA (T1)

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    login  CHAR(6),
    item   INTEGER,
    pieces INTEGER,
    otime  DATE
);

INSERT INTO orders (login, item, pieces, otime) VALUES
    ('nor001',  1, 10, DATE '2019-02-27'),
    ('sta001',  1,  5, DATE '2019-02-25'),
    ('swa005', 10,  1, DATE '2019-02-20'),
    ('cha100',  1,  8, DATE '2019-02-25');

-- Tabulka záměrně nemá primární ani unikátní klíč. Cvičení se soustředí
-- na viditelnost změn a serializaci, nikoli na návrh datového modelu.
-- Výchozí průměr hodnoty pieces je 6.

-------------------------- 1. READ UNCOMMITTED: ŠPINAVÉ ČTENÍ

-- Krok 1 (T1): vložte řádek, ale transakci zatím nepotvrzujte.
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
INSERT INTO orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');

-- Krok 2 (T2): spusťte blok 1.0–1.1 v t2.sql.
-- Očekávejte pouze původní čtyři řádky; nepotvrzený INSERT není viditelný.

-- Krok 3 (T1): zrušte vložení.
ROLLBACK;

-- Krok 4 (T2): spusťte znovu blok 1.0–1.1.
-- Otázka: změnila se sada řádků? Proč?
--
-- PostgreSQL přijímá úroveň READ UNCOMMITTED, ale interně ji vykonává
-- stejně jako READ COMMITTED. Špinavé čtení proto nelze pozorovat.

-------------------------- 2. READ COMMITTED: NOVÝ SNÍMEK PŘÍKAZU

-- Krok 1 (T1): znovu vložte řádek v neukončené transakci.
BEGIN ISOLATION LEVEL READ COMMITTED;
INSERT INTO orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');

-- Krok 2 (T2): spusťte blok 2.0–2.1.
-- Očekávejte původní čtyři řádky.

-- Krok 3 (T1): vložení zrušte.
ROLLBACK;

-- Krok 4 (T2): spusťte znovu blok 2.0–2.1.
-- Výsledek je stále stejný: řádek byl zrušen, nikoli potvrzen.
--
-- READ COMMITTED zaručuje, že příkaz čte pouze data potvrzená před jeho
-- začátkem. Každý příkaz v této úrovni však dostává vlastní snímek dat.

-------------------------- 3. READ COMMITTED: ZMĚNA MEZI PŘÍKAZY

-- Krok 1 (T1): přečtěte průměr.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT AVG(pieces) FROM orders;
-- Očekávaný výsledek: 6.

-- Krok 2 (T2): spusťte blok 3.0 v t2.sql, vložte řádek příkazem 3.1
-- a potvrďte transakci.

-- Krok 3 (T1): zopakujte dotaz.
SELECT AVG(pieces) FROM orders;
-- Očekávaný výsledek: 14.8 (74 / 5).
-- Nejde o špinavé čtení: transakce T2 již změnu potvrdila.
-- Nový řádek se stal viditelným díky novému snímku druhého příkazu.

-- Krok 4 (T1): ukončete transakci.
COMMIT;

-- Otázky:
--   a) Proč se výsledky dvou SELECTů liší, přestože jsou v jedné transakci?
--   b) Který jev pozorujete při čtení množiny řádků, do níž byl vložen nový řádek?

-- Krok 5: připravte čistá data pro další příklad spuštěním části 0 v T1.

-------------------------- 4. REPEATABLE READ: SNÍMEK TRANSAKCE

-- Krok 1 (T1): začněte transakci a přečtěte průměr.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT AVG(pieces) FROM orders;
-- Očekávaný výsledek: 6.

-- Krok 2 (T2): spusťte blok 4.0 v t2.sql a potvrďte změnu.

-- Krok 3 (T1): zopakujte dotaz.
SELECT AVG(pieces) FROM orders;
-- Očekávaný výsledek: stále 6.
-- REPEATABLE READ používá po celou transakci stejný snímek dat.

-- Krok 4 (T1): potvrďte transakci a spusťte dotaz v nové transakci.
COMMIT;
SELECT AVG(pieces) FROM orders;
-- Očekávaný výsledek: 253.5 (1014 / 4).

-- Krok 5: připravte čistá data pro další příklad spuštěním části 0 v T1.

-------------------------- 5. REPEATABLE READ: VLOŽENÝ ŘÁDEK

-- Krok 1 (T1): načtěte objednávky v zadaném rozsahu.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM orders WHERE item BETWEEN 5 AND 10;

-- Krok 2 (T2): spusťte a potvrďte blok 5.0–5.1 v t2.sql.

-- Krok 3 (T1): zopakujte dotaz v rámci stejné transakce.
SELECT * FROM orders WHERE item BETWEEN 5 AND 10;
-- Nový řádek se v tomto snímku neobjeví.

-- Krok 4 (T1): ukončete transakci a dotaz opakujte.
COMMIT;
SELECT * FROM orders WHERE item BETWEEN 5 AND 10;
-- Nový řádek je nyní viditelný.

-- PostgreSQL REPEATABLE READ zabraňuje nejen opakovanému čtení odlišných
-- hodnot, ale i tomu, aby se v témže snímku objevily nové řádky splňující
-- predikát dotazu.

-------------------------- 6. ZÁMEK ŘÁDKU: SELECT ... FOR UPDATE

-- Příprava: spusťte část 0, aby byl řádek nor001 v původním stavu.
--
-- Krok 1 (T1): načtěte a zamkněte konkrétní řádek.
BEGIN;
SELECT login, pieces
FROM orders
WHERE login = 'nor001'
FOR UPDATE;
-- T1 drží zámek řádku až do ukončení transakce.

-- Krok 2 (T2): spusťte blok 6.0 v t2.sql.
-- SELECT ... FOR UPDATE v T2 se zablokuje a čeká na uvolnění řádku.

-- Krok 3 (T1): potvrďte transakci a uvolněte zámek.
COMMIT;

-- Krok 4 (T2): po odblokování příkazu potvrďte transakci v T2.
-- Otázky:
--   a) Kdy se mohl SELECT v T2 dokončit?
--   b) Co by se stalo, kdyby T1 provedla ROLLBACK místo COMMITu?
--
-- FOR UPDATE zamyká řádky vrácené dotazem. Zámek brání souběžným
-- transakcím v jejich změně nebo získání konfliktního zámku, ale běžné
-- SELECTy bez zamykací klauzule mohou řádek stále číst díky MVCC.
-- Zámek se uvolní při COMMITu nebo ROLLBACKu.

-------------------------- 7. SERIALIZABLE: KONFLIKT SERIALIZACE

-- Příprava: spusťte část 0, aby v tabulce nebyly řádky s item = 42.
--
-- Krok 1 (T1): oba dotazy v obou transakcích musí nejprve vrátit 0.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM orders WHERE item = 42;

-- Krok 2 (T2): spusťte pouze krok 7.0 v t2.sql. Transakci ponechte otevřenou.

-- Krok 3 (T1): vložte řádek do stejné množiny a potvrďte transakci.
INSERT INTO orders (login, item, pieces, otime)
VALUES ('tx001', 42, 1, DATE '2024-01-01');
COMMIT;

-- Krok 4 (T2): spusťte krok 7.1 v t2.sql.
-- PostgreSQL může transakci T2 odmítnout chybou serializace při INSERTu
-- nebo při COMMITu. Pokud transakce přešla do chybového stavu, ukončete ji
-- příkazem ROLLBACK.
--
-- Obě transakce četly stejnou prázdnou množinu a následně do ní vkládají.
-- Jejich výsledky nelze vysvětlit žádným sériovým pořadím. SERIALIZABLE
-- proto zajistí, že jedna transakce musí být opakována.
--
-- PostgreSQL používá Serializable Snapshot Isolation (SSI). Nezamyká
-- jednoduše celý rozsah řádků; sleduje konfliktní závislosti a při
-- nebezpečné kombinaci transakci přeruší.

-------------------------- 8. SHRNUTÍ

-- READ UNCOMMITTED: v PostgreSQL se chová jako READ COMMITTED.
-- READ COMMITTED: každý příkaz pracuje s novým snímkem potvrzených dat.
-- REPEATABLE READ: celá transakce pracuje se stabilním snímkem dat.
-- FOR UPDATE: explicitně zamyká vybrané řádky do konce transakce.
-- SERIALIZABLE: navíc odmítne některé souběžné transakce, jejichž výsledek
--                by neodpovídal žádnému sériovému pořadí.
--
-- Aplikační kód musí po chybě serializace zopakovat celou transakci,
-- nikoli pouze poslední neúspěšný příkaz.
