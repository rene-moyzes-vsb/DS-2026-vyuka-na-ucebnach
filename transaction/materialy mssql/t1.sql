-------------------------- SET UP
drop table if exists orders
GO

create table orders (
  login char(6),
  item int,
  pieces int,
  otime date
)
GO 

INSERT INTO orders VALUES ('nor001', 1, 10, '2019-02-27')
INSERT INTO orders VALUES ('sta001', 1, 5, '2019-02-25')
INSERT INTO orders VALUES ('swa005', 10, 1, '2019-02-20')
INSERT INTO orders VALUES ('cha100', 1, 8, '2019-02-25')
GO



-------------------------- READ UNCOMMITTED

--T1
BEGIN TRAN
INSERT INTO orders VALUES ('lee040', 5, 50, '2019-02-24')
--T2 provede prikazy 1.0 a 1.1

--T1
ROLLBACK TRANSACTION

--T2 opet provede select 1.1
--ceho jsme byli svedky v transakci T2?

-------------------------- READ COMMITTED 1

--T1
BEGIN TRAN
INSERT INTO orders VALUES ('lee040', 5, 50, '2019-02-24')
--T2 provede prikazy 2.0 a 2.1

--T1
ROLLBACK TRANSACTION

--T2 opet provede select 2.1
--ceho jsme byli svedky v transakci T2?
--co je příčinou tohoto chovani?

-------------------------- READ COMMITTED 2

--T1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN
SELECT AVG(pieces) FROM orders


--T2 provede prikaz 2.2


--T1 
SELECT AVG(pieces) FROM orders
--Je vysledek prikazu select spravny?

--T1
ROLLBACK TRANSACTION

--Provedte SET UP tabulky Orders (prikazy drop,create a insert nahore)

-------------------------- READ COMMITTED SNAPSHOT

--T1 je nutne zavrit t2.sql pred provedenim nasledujiciho prikazu
ALTER DATABASE bac027 SET READ_COMMITTED_SNAPSHOT ON

--T1
BEGIN TRAN
INSERT INTO orders VALUES ('lee040', 5, 50, '2019-02-24')

--T2 provede prikazy 3.0 a 3.1
--V cem se lisi READ COMMITTED a READ COMMITTED SNAPSHOT?

--T1
ROLLBACK TRANSACTION

--T1 je nutne zavrit t2.sql pred provedenim nasledujiciho prikazu
ALTER DATABASE bac027 SET READ_COMMITTED_SNAPSHOT OFF

-------------------------- REPEATABLE READ 1

--T1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRAN
SELECT AVG(pieces) FROM orders

--T2 provede prikaz 4.0

--T1
SELECT AVG(pieces) FROM orders
--Jak je zajištěna konzistence transakce T1 v této úrovni izolace?

--T1
ROLLBACK TRANSACTION

--Provedte SET UP tabulky Orders (prikazy drop,create a insert nahore)

-------------------------- REPEATABLE READ 2

--T1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRAN
SELECT * FROM orders WHERE item BETWEEN 5 AND 10

--T2 provede prikaz 4.1

--T1
SELECT * FROM orders WHERE item BETWEEN 5 AND 10
--Jak se lisi situace v tomto prikladu oproti REPEATABLE READ 1?
--Co je pricinou rozdilu? Jak nazyvame tento fenomen?

--T1
ROLLBACK TRANSACTION

--Provedte SET UP tabulky Orders (prikazy drop,create a insert nahore)


-------------------------- SERIALIZABLE

--Vyzkousejte priklad REPEATABLE READ 2 s urovni izolace SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

-------------------------- SNAPSHOT 1

--T1 je nutne zavrit t2.sql pred provedenim nasledujiciho prikazu
ALTER DATABASE bac027 SET READ_COMMITTED_SNAPSHOT ON
ALTER DATABASE bac027 SET ALLOW_SNAPSHOT_ISOLATION ON

--T2 provede prikazy 5.0 a 5.1

--T1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRAN
SELECT * FROM orders

--T2 provede prikaz 5.2

--T1
SELECT * FROM orders
--Jak to ze nyni nevidime potvzenou transakci T2?

--T1
COMMIT TRAN

--T1
SELECT * FROM orders
--Jak to ze nyni ano?


-------------------------- SNAPSHOT

--Vyzkousejte priklad REPEATABLE READ 2 s urovni izolace SNAPSHOT
--Porovnejte chovani SQL Serveru s predchozimi dvema testy
