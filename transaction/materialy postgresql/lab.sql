-- LABORATORNÍ CVIČENÍ: SOUBĚH A IZOLACE TRANSAKCÍ V POSTGRESQL
--
-- Tento soubor je interaktivní scénář, nikoli skript ke spuštění celý najednou.
-- Otevřete dvě SQL okna připojená ke STEJNÉ testovací databázi:
--
--   T1 = první SQL okno
--   T2 = druhé SQL okno
--   Obě okna musí používat samostatná spojení, nikoli sdílenou relaci.
--
-- Postupujte shora dolů. Vždy spusťte pouze SQL blok označený T1 nebo T2
-- podle pokynu. Očekávané výsledky a vysvětlení jsou uvedeny hned za krokem.
-- Pokud příkaz T2 zablokuje čekání, přepněte do T1 a proveďte další uvedený
-- krok. Časové pořadí je důležité.
--
-- Základní průběh transakce:
--   BEGIN -> SQL příkazy -> COMMIT (potvrzení) nebo ROLLBACK (zrušení změn)
--
-- Než začnete:
--   MVCC (Multi-Version Concurrency Control) umožňuje transakcím číst
--   různé verze řádků. Snímek určuje, které změny jsou pro čtení viditelné.
--   Špinavé čtení znamená přečtení nepotvrzené změny jiné transakce.
--   Neopakovatelné čtení znamená, že opakované čtení téhož řádku ukáže
--   jinou hodnotu. Phantom znamená, že opakovaný dotaz se stejnou podmínkou
--   vrátí jinou množinu řádků, například kvůli novému vloženému řádku.
--
-- Bezpečnost: použijte testovací databázi a vlastní schéma transakce_lab.
-- CREATE SCHEMA bez IF NOT EXISTS záměrně skončí chybou, pokud schéma už
-- existuje. V takovém případě jej nepřebírejte ani nemažte: zvolte jiné
-- jméno a nahraďte transakce_lab v celém scénáři, nebo použijte jinou
-- testovací databázi. Každý student potřebuje vlastní schéma.

-- ===============================================================================
-- 0. PŘÍPRAVA DAT
-- ===============================================================================

-- Krok 0.1 — v T1 vytvořte nové schéma. Musíte k tomu mít příslušné oprávnění:
CREATE SCHEMA transakce_lab;

-- Krok 0.2 — v T1 vytvořte cvičnou tabulku ve svém schématu:
CREATE TABLE transakce_lab.orders (
    login  CHAR(6),
    item   INTEGER,
    pieces INTEGER,
    otime  DATE
);

-- Krok 0.3 — v T1 vložte výchozí data:
INSERT INTO transakce_lab.orders (login, item, pieces, otime) VALUES
    ('nor001',  1, 10, DATE '2019-02-27'),
    ('sta001',  1,  5, DATE '2019-02-25'),
    ('swa005', 10,  1, DATE '2019-02-20'),
    ('cha100',  1,  8, DATE '2019-02-25');

-- Tabulka záměrně nemá primární ani unikátní klíč. Zaměřujeme se na
-- souběh transakcí, nikoli na návrh datového modelu.
--
-- Kontrola v T1:
SELECT COUNT(*) AS pocet_radku, ROUND(AVG(pieces), 1) AS prumer
FROM transakce_lab.orders;
--
-- Očekávaný výsledek: pocet_radku = 4, prumer = 6.0.
--
-- Obnovení dat: tento blok spusťte v T1 jen na místech označených
-- „obnovte data“ a pouze když obě transakce předchozího příkladu skončily.
-- TRUNCATE smaže všechna data v této cvičné tabulce.
-- Krok 0.4 — obnovení:
TRUNCATE TABLE transakce_lab.orders;
INSERT INTO transakce_lab.orders (login, item, pieces, otime) VALUES
    ('nor001',  1, 10, DATE '2019-02-27'),
    ('sta001',  1,  5, DATE '2019-02-25'),
    ('swa005', 10,  1, DATE '2019-02-20'),
    ('cha100',  1,  8, DATE '2019-02-25');

-- ===============================================================================
-- 1. READ UNCOMMITTED: LZE PŘEČÍST NEPOTVRZENÝ ŘÁDEK?
-- ===============================================================================

-- Krok 1.1 — spusťte v T1 a ponechte transakci otevřenou:
BEGIN ISOLATION LEVEL READ UNCOMMITTED;

INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');

-- Krok 1.2 — spusťte v T2:
-- Než dotaz provedete: uvidí T2 řádek, který T1 ještě nepotvrdila? Proč?
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT login, item, pieces FROM transakce_lab.orders ORDER BY login;
COMMIT;
--
-- Očekávaný výsledek: T2 uvidí pouze čtyři původní řádky.
-- Vložený řádek lee040 není potvrzen, proto jej T2 nevidí.

-- Krok 1.3 — vraťte se do T1 a zrušte vložení:
ROLLBACK;

-- Krok 1.4 — v T2 znovu spusťte celý blok 1.2.
-- Očekávaný výsledek: opět čtyři původní řádky.
--
-- PostgreSQL přijímá READ UNCOMMITTED, ale vykonává ji stejně jako
-- READ COMMITTED. Špinavé čtení tedy nelze pozorovat.

-- ===============================================================================
-- 2. READ COMMITTED: NOVÝ SNÍMEK PRO KAŽDÝ PŘÍKAZ
-- ===============================================================================

-- Krok 2.1 — spusťte v T1 a ponechte transakci otevřenou:
BEGIN ISOLATION LEVEL READ COMMITTED;

INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');

-- Krok 2.2 — spusťte v T2:
-- Předpověď: liší se výsledek od úlohy 1?
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT login, item, pieces FROM transakce_lab.orders ORDER BY login;
COMMIT;
--
-- Očekávaný výsledek: T2 opět vidí pouze čtyři původní řádky.

-- Krok 2.3 — vraťte se do T1:
ROLLBACK;

-- Krok 2.4 — v T2 znovu spusťte celý blok 2.2.
-- Očekávaný výsledek: stále čtyři řádky, protože INSERT byl zrušen.
--
-- READ COMMITTED neukazuje nepotvrzené změny. Každý příkaz však dostává
-- nový snímek dat, který zahrnuje změny potvrzené před jeho zahájením.

-- ===============================================================================
-- 3. READ COMMITTED: ZMĚNA VIDITELNÁ UVNITŘ JEDNÉ TRANSAKCE
-- ===============================================================================

-- Krok 3.1 — spusťte v T1:
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
--
-- Očekávaný výsledek: 6.0.

-- Krok 3.2 — spusťte v T2 a potvrďte:
BEGIN ISOLATION LEVEL READ COMMITTED;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
COMMIT;

-- Krok 3.3 — vraťte se do T1 a spusťte:
-- Předpověď: bude průměr stejný, přestože T2 už změnu potvrdila?
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
--
-- Očekávaný výsledek: 14.8 (74 / 5).
-- Nejde o špinavé čtení: transakce T2 už změnu potvrdila. Druhý SELECT
-- dostal nový snímek a proto nový řádek zahrnul.

-- Krok 3.4 — ukončete transakci v T1:
COMMIT;

-- Otázka k zamyšlení:
-- Proč mohou dva SELECTy v jedné transakci READ COMMITTED vrátit odlišný
-- výsledek? Nový řádek odpovídá jevu označovanému jako phantom read.

-- ===============================================================================
-- 4. REPEATABLE READ: STABILNÍ SNÍMEK TRANSAKCE
-- ===============================================================================

-- Příprava — v T1 obnovte data podle kroku 0.4.

-- Krok 4.1 — spusťte v T1:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
--
-- Očekávaný výsledek: 6.0.

-- Krok 4.2 — spusťte v T2 a potvrďte změnu:
BEGIN;
UPDATE transakce_lab.orders SET pieces = 1000 WHERE login = 'nor001';
COMMIT;

-- Krok 4.3 — vraťte se do T1:
-- Předpověď: uvidí T1 změnu potvrzenou T2?
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
--
-- Očekávaný výsledek: stále 6.0. T1 používá snímek vytvořený pro svou
-- transakci, takže změnu potvrzenou T2 zatím nevidí.
-- V PostgreSQL se snímek této úrovně stanoví při prvním příkazu, který
-- jej potřebuje, nikoli již samotným BEGIN. Další čtení jej používají znovu;
-- transakce přitom vidí i své vlastní změny.

-- Krok 4.4 — potvrďte T1 a spusťte dotaz znovu jako nový příkaz:
COMMIT;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
--
-- Očekávaný výsledek: 253.5 (1014 / 4).

-- ===============================================================================
-- 5. REPEATABLE READ: NOVÝ ŘÁDEK SPLŇUJÍCÍ PREDIKÁT
-- ===============================================================================

-- Příprava — v T1 obnovte data podle kroku 0.4.

-- Krok 5.1 — spusťte v T1:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
--
-- Očekávaný výsledek: pouze swa005 (item = 10).

-- Krok 5.2 — spusťte v T2 a potvrďte vložení:
BEGIN;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee020', 6, 10, DATE '2019-04-04');
COMMIT;

-- Krok 5.3 — vraťte se do T1. Předpověď: objeví se nyní nový řádek?
-- Spusťte pouze následující SELECT, nikoli znovu BEGIN:
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
--
-- Očekávaný výsledek: stále pouze swa005.

-- Krok 5.4 — ukončete T1 a spusťte dotaz z kroku 5.1 znovu:
COMMIT;
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
--
-- Očekávané řádky:
--   lee020 |  6 | 10
--   swa005 | 10 |  1
--
-- PostgreSQL REPEATABLE READ zachovává snímek celé transakce; nové řádky
-- splňující stejný predikát se proto během transakce neobjeví.

-- ===============================================================================
-- 6. EXPLICITNÍ ZÁMEK ŘÁDKU: SELECT ... FOR UPDATE
-- ===============================================================================

-- Příprava — v T1 obnovte data podle kroku 0.4.

-- Krok 6.1 — spusťte v T1:
BEGIN;
SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001'
FOR UPDATE;
--
-- Očekávaný výsledek: nor001 | 10.
-- T1 nyní drží zámek vybraného řádku až do COMMITu nebo ROLLBACKu.

-- Krok 6.2 — v T2 spusťte běžné čtení:
-- Předpověď: bude běžný SELECT čekat na zámek T1?
BEGIN;
SELECT login, pieces FROM transakce_lab.orders WHERE login = 'nor001';
COMMIT;
--
-- Očekávaný výsledek: T2 ihned přečte nor001 | 10.
-- Běžný SELECT nečeká na zámek řádku; díky MVCC čte potvrzenou verzi.

-- Krok 6.3 — v T2 spusťte tento blok.
-- Než jej spustíte: bude čekat stejně jako běžný SELECT v kroku 6.2?
BEGIN;
SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001'
FOR UPDATE;
COMMIT;
--
-- Očekávaný průběh: SELECT čeká na zámek. Vraťte se do T1 a proveďte
-- krok 6.4; nečekejte na dokončení bloku v T2.

-- Krok 6.4 — spusťte v T1:
COMMIT;
--
-- Po uvolnění zámku se příkaz T2 dokončí a vrátí nor001 | 10.
-- T2 pak provede svůj COMMIT a uvolní získaný zámek.
--
-- FOR UPDATE zamyká řádky vrácené dotazem. Souběžné změny a konfliktní
-- zamykací příkazy musí počkat; běžné SELECTy mohou pokračovat.

-- ===============================================================================
-- 7. SERIALIZABLE: KONFLIKT A OPAKOVÁNÍ TRANSAKCE
-- ===============================================================================

-- Příprava — v T1 obnovte data podle kroku 0.4.
-- Cílem je, aby zatím žádný řádek neměl item = 42.

-- Krok 7.1 — spusťte v T1 a ponechte transakci otevřenou:
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
--
-- Očekávaný výsledek: 0.

-- Krok 7.2 — spusťte v T2 a ponechte transakci otevřenou:
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
--
-- Očekávaný výsledek: 0.

-- Krok 7.3 — vraťte se do T1, vložte řádek a potvrďte:
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx001', 42, 1, DATE '2024-01-01');
COMMIT;

-- Krok 7.4 — vraťte se do T2 a zkuste vložit další řádek do stejné množiny:
-- Předpověď: mohou obě transakce úspěšně skončit v libovolném sériovém pořadí?
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx002', 42, 1, DATE '2024-01-01');
COMMIT;
--
-- Očekávaný výsledek: PostgreSQL jednu z transakcí odmítne chybou
-- serializace (SQLSTATE 40001), obvykle při INSERTu nebo COMMITu.
-- Pokud T2 přejde do chybového stavu, spusťte v T2 ROLLBACK.
--
-- Obě transakce četly prázdnou množinu a následně do ní vkládají.
-- Výsledek obou úspěšných transakcí by neodpovídal žádnému sériovému
-- pořadí. PostgreSQL používá SSI (Serializable Snapshot Isolation) a
-- nebezpečnou kombinaci závislostí přeruší.
--
-- Aplikace musí při chybě 40001 zopakovat celou transakci od jejího
-- začátku, nikoli pouze poslední neúspěšný příkaz.

-- Kontrola v nové transakci T1 před opakováním:
SELECT login, item FROM transakce_lab.orders WHERE item = 42 ORDER BY login;
--
-- Očekávaný výsledek: pouze tx001 | 42.

-- Krok 7.5 — v T2 ukončete případnou neúspěšnou transakci a začněte
-- znovu: opakujte jak čtení, tak vložení a potvrzení. Pokud klient už
-- provedl COMMIT či ROLLBACK po chybě, může ROLLBACK pouze upozornit,
-- že žádná transakce neběží.
ROLLBACK;
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx002', 42, 1, DATE '2024-01-01');
COMMIT;
--
-- Očekávaný výsledek SELECTu: 1. Nový pokus už vidí řádek potvrzený T1
-- a v tomto příkladu může svůj INSERT a COMMIT úspěšně provést.
-- Představte si pravidlo „vložit, jen když žádný řádek neexistuje“:
-- aplikace by se na základě nového čtení rozhodla další řádek nevložit.
-- V aplikaci je nutné znovu provést i rozhodování a všechny ostatní příkazy
-- transakce; nestačí automaticky zopakovat jen původní INSERT.

-- Krok 7.6 — v nové transakci T1 ověřte konečný stav:
SELECT login, item FROM transakce_lab.orders WHERE item = 42 ORDER BY login;
--
-- Očekávané řádky: tx001 | 42 a tx002 | 42.

-- ===============================================================================
-- 8. SHRNUTÍ
-- ===============================================================================

-- READ UNCOMMITTED: v PostgreSQL se chová jako READ COMMITTED.
-- READ COMMITTED: každý příkaz pracuje s novým snímkem potvrzených dat
--                 a vidí také vlastní změny transakce.
-- REPEATABLE READ: transakce pracuje se stabilním snímkem a vidí vlastní změny.
-- FOR UPDATE: explicitně zamyká vybrané řádky do konce transakce.
-- SERIALIZABLE: zachová serializovatelnost; některé transakce je nutné opakovat.
--
-- Volitelné uklizení vlastního schématu (až obě relace dokončí transakce):
-- DROP TABLE transakce_lab.orders;
-- DROP SCHEMA transakce_lab;
