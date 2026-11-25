-- Cvičení: Izolační úrovně transakcí v PostgreSQL — relace T2
--
-- Tento soubor používejte společně s t1.sql ve druhé relaci připojené
-- ke stejné testovací databázi. Spouštějte pouze očíslované kroky podle
-- pokynů v t1.sql. U kroků, které končí COMMITem, potvrzení proveďte
-- až v okamžiku určeném postupem cvičení.

-------------------------- 1. READ UNCOMMITTED

-- Krok 1.0: spusťte jako samostatnou transakci.
BEGIN ISOLATION LEVEL READ UNCOMMITTED;

-- Krok 1.1: spusťte během neukončené transakce T1.
SELECT * FROM orders;
COMMIT;

-------------------------- 2. READ COMMITTED

-- Krok 2.0: spusťte jako samostatnou transakci.
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Krok 2.1: spusťte během neukončené transakce T1.
SELECT * FROM orders;
COMMIT;

-------------------------- 3. READ COMMITTED: NOVÝ SNÍMEK PŘÍKAZU

-- Krok 3.0: spusťte v okamžiku uvedeném v t1.sql.
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Krok 3.1: vložení se stane viditelným až po potvrzení.
INSERT INTO orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
COMMIT;

-------------------------- 4. REPEATABLE READ: SNÍMEK TRANSAKCE

-- Krok 4.0: potvrďte změnu před opakovaným SELECTem v T1.
BEGIN;
UPDATE orders
SET pieces = 1000
WHERE login = 'nor001';
COMMIT;

-------------------------- 5. REPEATABLE READ: VLOŽENÝ ŘÁDEK

-- Krok 5.0: vložte řádek během otevřené transakce T1.
BEGIN;

-- Krok 5.1: potvrďte vložení před opakováním SELECTu v T1.
INSERT INTO orders (login, item, pieces, otime)
VALUES ('lee020', 6, 10, DATE '2019-04-04');
COMMIT;

-------------------------- 6. ZÁMEK ŘÁDKU: SELECT ... FOR UPDATE

-- Krok 6.0: spusťte během otevřené transakce T1.
-- Tento příkaz se zablokuje, dokud T1 neuvolní zámek řádku.
BEGIN;
SELECT login, pieces
FROM orders
WHERE login = 'nor001'
FOR UPDATE;
COMMIT;

-------------------------- 7. SERIALIZABLE: KONFLIKT SERIALIZACE

-- Krok 7.0: přečtěte množinu a ponechte transakci otevřenou.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM orders WHERE item = 42;

-- Po vložení a COMMITu v T1 spusťte krok 7.1.
-- Při chybě serializace ukončete transakci příkazem ROLLBACK.

-- Krok 7.1
INSERT INTO orders (login, item, pieces, otime)
VALUES ('tx002', 42, 1, DATE '2024-01-01');
COMMIT;
