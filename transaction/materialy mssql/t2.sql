-- Zde jsou vsechny prikazy T2

-------------------------- READ UNCOMMITTED

--1.0
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--1.1
SELECT * FROM orders


-------------------------- READ COMMITTED 1

--2.0
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

--2.1
SELECT * FROM orders

-------------------------- READ COMMITTED 2

--2.2
INSERT INTO orders VALUES ('lee040', 5, 50, '2019-02-24')


-------------------------- READ COMMITTED SNAPSHOT

--pred provedenim ALTER TABLE v t1.sql, zavrete tento skript

--3.0
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

--3.1 
SELECT * FROM orders

-------------------------- REPEATABLE READ 1

--4.0
UPDATE orders
SET pieces = 1000
WHERE login = 'nor001'

-------------------------- REPEATABLE READ 2 a SERIALIZABLE

--4.1
INSERT INTO orders ('lee020', 6, 10, '2019-04-04')

-------------------------- SNAPSHOT

--5.0
BEGIN TRAN

--5.1
INSERT INTO orders VALUES ('lee040', 5, 50, '2019-02-24')

--5.2
COMMIT TRAN