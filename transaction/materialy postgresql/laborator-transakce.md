# Laboratoř: transakce a souběh v PostgreSQL

## Cíle

Po dokončení cvičení budete umět:

- vysvětlit, co transakce vidí při `READ COMMITTED` a `REPEATABLE READ`;
- rozpoznat špinavé čtení a phantom;
- pozorovat zámek řádku pomocí `SELECT ... FOR UPDATE`;
- vyvolat chybu serializace a zopakovat celou transakci.

Pro jednotlivé příkazy můžete použít také připravený [SQL scénář](./lab.sql).
**Nespouštějte jej celý najednou** – příkazy jsou určeny ke střídavému
spouštění ve dvou oknech.
Pro vysvětlení pojmů a principů před cvičením si projděte
[studentský výklad transakcí](./vysvetleni-transakci-pro-studenty.md).

## Než začnete

Otevřete dvě SQL okna, každé s vlastním nezávislým spojením ke stejné
testovací databázi. Označte je **T1** a **T2**. Dodržujte pořadí kroků;
otevřenou transakci nepřerušujte, dokud k tomu postup nevyzve. Každý student
nebo dvojice potřebuje své vlastní schéma.

Postup předpokládá, že klient samovolně nepotvrzuje transakci zahájenou
příkazem `BEGIN`. Při neočekávaném výsledku ověřte, že okna skutečně používají
samostatná spojení a že předchozí transakce byla ukončena.

Základní průběh transakce je `BEGIN` → příkazy → `COMMIT` (potvrzení) nebo
`ROLLBACK` (zrušení změn).

**MVCC** uchovává verze dat, aby souběžné transakce mohly číst odpovídající
snímek. **Špinavé čtení** je přečtení nepotvrzené změny jiné transakce.
Při **neopakovatelném čtení** opakované čtení téhož řádku vrátí jinou hodnotu.
**Phantom** je změna množiny řádků vyhovujících opakovanému dotazu, například
v důsledku vložení řádku jinou transakcí.

## 0. Příprava

> **Pozor:** pracujte jen v testovací databázi. Příkazy níže vytvářejí
> `transakce_lab`; pro vytvoření schématu potřebujete oprávnění. Pokud už
> existuje, nepřebírejte ho ani nemažte. Vyberte si jiné vlastní jméno
> schématu a nahraďte `transakce_lab` ve všech příkazech tohoto návodu i
> v [SQL scénáři](./lab.sql).

**T1:** Vytvořte nové schéma a tabulku:

```sql
CREATE SCHEMA transakce_lab;

CREATE TABLE transakce_lab.orders (
    login  CHAR(6),
    item   INTEGER,
    pieces INTEGER,
    otime  DATE
);
```

Jestliže vytvoření schématu selže, nepokračujte vytvořením tabulky v již
existujícím schématu.

**T1:** Vložte výchozí data:

```sql
INSERT INTO transakce_lab.orders (login, item, pieces, otime) VALUES
    ('nor001',  1, 10, DATE '2019-02-27'),
    ('sta001',  1,  5, DATE '2019-02-25'),
    ('swa005', 10,  1, DATE '2019-02-20'),
    ('cha100',  1,  8, DATE '2019-02-25');

SELECT COUNT(*) AS pocet_radku, ROUND(AVG(pieces), 1) AS prumer
FROM transakce_lab.orders;
```

**Kontrola:** 4 řádky, průměr `6.0`. Tabulka záměrně nemá primární klíč;
cílem je souběh transakcí, nikoli návrh datového modelu.

### Obnovení dat

Na místech označených „obnovte data“ spusťte v **T1** následující blok.
Nejprve se ujistěte, že obě relace dokončily předchozí transakce.
`TRUNCATE` smaže všechna data ve vaší cvičné tabulce.

```sql
TRUNCATE TABLE transakce_lab.orders;
INSERT INTO transakce_lab.orders (login, item, pieces, otime) VALUES
    ('nor001',  1, 10, DATE '2019-02-27'),
    ('sta001',  1,  5, DATE '2019-02-25'),
    ('swa005', 10,  1, DATE '2019-02-20'),
    ('cha100',  1,  8, DATE '2019-02-25');
```

## 1. READ UNCOMMITTED

**Předpověď:** Uvidí T2 řádek, který T1 vložila, ale nepotvrdila?

**T1:**

```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
```

**T2:**

```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT login, item, pieces FROM transakce_lab.orders ORDER BY login;
COMMIT;
```

**T1:** Zrušte vložení:

```sql
ROLLBACK;
```

**T2:** Zopakujte celý předchozí blok T2.

**Kontrola:** V obou čteních T2 vidí pouze čtyři původní řádky. PostgreSQL
úroveň `READ UNCOMMITTED` přijímá, ale chová se při ní jako při
`READ COMMITTED`: špinavé čtení neumožňuje.

## 2. READ COMMITTED: nepotvrzená změna

**Předpověď:** Bude se výsledek lišit od úlohy 1?

**T1:**

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
```

**T2:**

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT login, item, pieces FROM transakce_lab.orders ORDER BY login;
COMMIT;
```

**T1:** Proveďte `ROLLBACK;`. **T2:** Zopakujte svůj blok.

**Kontrola:** T2 pokaždé vidí čtyři původní řádky; vložení nebylo potvrzeno.

## 3. READ COMMITTED: změna mezi příkazy

**Předpověď:** Může se výsledek dvou dotazů v jedné transakci změnit, když
mezitím jiná transakce potvrdí vložení?

**T1:**

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
```

**T2:**

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
COMMIT;
```

**T1:** Zopakujte dotaz a ukončete transakci:

```sql
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
COMMIT;
```

**Kontrola:** První průměr je `6.0`, druhý `14.8`. Nejde o špinavé čtení:
T2 změnu potvrdila. `READ COMMITTED` používá pro každý příkaz nový snímek;
nově vložený řádek je příkladem phantomu.

## 4. REPEATABLE READ: stabilní snímek

**Příprava:** V T1 obnovte data podle části 0.

**Předpověď:** Změní se průměr v T1, když T2 potvrdí změnu řádku?

**T1:**

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
```

**T2:**

```sql
BEGIN;
UPDATE transakce_lab.orders SET pieces = 1000 WHERE login = 'nor001';
COMMIT;
```

**T1:**

```sql
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
COMMIT;
SELECT ROUND(AVG(pieces), 1) AS prumer FROM transakce_lab.orders;
```

**Kontrola:** T1 v transakci vidí `6.0` před změnou i po ní. Po ukončení
transakce vidí nový dotaz `253.5`. Snímek `REPEATABLE READ` se v PostgreSQL
stanoví při prvním příkazu, který jej potřebuje, nikoli nutně při `BEGIN`.
Transakce vidí také své vlastní změny.

## 5. REPEATABLE READ: nový řádek

**Příprava:** V T1 obnovte data podle části 0.

**Předpověď:** Objeví se v opakovaném dotazu T1 nový řádek vložený T2?

**T1:**

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
```

**T2:**

```sql
BEGIN;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee020', 6, 10, DATE '2019-04-04');
COMMIT;
```

**T1:** Opakujte pouze dotaz, nikoli `BEGIN`:

```sql
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
```

Poté transakci ukončete a zopakujte dotaz:

```sql
COMMIT;
SELECT login, item, pieces
FROM transakce_lab.orders
WHERE item BETWEEN 5 AND 10
ORDER BY item, login;
```

**Kontrola:** V transakci vidíte pouze `swa005` s `item = 10`. Po `COMMIT`
vidíte i `lee020` s `item = 6`. PostgreSQL `REPEATABLE READ` v tomto snímku
zabraňuje výskytu nových phantom řádků.

## 6. Zámek řádku: SELECT FOR UPDATE

**Příprava:** V T1 obnovte data podle části 0.

**Předpověď:** Který příkaz v T2 bude čekat – běžný `SELECT`, nebo
`SELECT ... FOR UPDATE`?

**T1:** Zamkněte řádek a neukončujte transakci:

```sql
BEGIN;
SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001'
FOR UPDATE;
```

**T2:** Nejprve proveďte běžné čtení:

```sql
BEGIN;
SELECT login, pieces FROM transakce_lab.orders WHERE login = 'nor001';
COMMIT;
```

**T2:** Spusťte následující blok. Až bude `SELECT` čekat, přepněte do T1;
nečekejte na dokončení bloku v T2.

```sql
BEGIN;
SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001'
FOR UPDATE;
COMMIT;
```

**T1:** Uvolněte zámek:

```sql
COMMIT;
```

**Kontrola:** Běžný `SELECT` v T2 přečte `nor001 | 10` bez čekání.
`SELECT ... FOR UPDATE` čeká na ukončení T1 a potom vrátí stejný řádek.
Po dokončení bloku T2 potvrzení transakce uvolní i jeho zámek.

## 7. SERIALIZABLE: konflikt a opakování

**Příprava:** V T1 obnovte data podle části 0. Žádný řádek nemá `item = 42`.

**Předpověď:** Mohou obě transakce přečíst počet `0`, každá vložit řádek
s `item = 42` a obě úspěšně skončit, jako by běžely jedna po druhé?

**T1:**

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
```

**T2:**

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
```

**T1:**

```sql
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx001', 42, 1, DATE '2024-01-01');
COMMIT;
```

**T2:**

```sql
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx002', 42, 1, DATE '2024-01-01');
COMMIT;
```

**Kontrola:** Obě počáteční čtení vrátí `0`. Při uvedeném pořadí PostgreSQL
odmítne T2 chybou serializace `40001`. Chyba se může projevit při `INSERT`
nebo `COMMIT`. Pokud klient zastaví blok po chybě, transakci ukončíte
v následujícím kroku příkazem `ROLLBACK`.

**T1:** Ověřte stav před opakováním:

```sql
SELECT login, item FROM transakce_lab.orders WHERE item = 42 ORDER BY login;
```

Očekávaný výsledek je pouze `tx001 | 42`.

**T2:** Zopakujte *celou* transakci:

```sql
ROLLBACK;
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM transakce_lab.orders WHERE item = 42;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('tx002', 42, 1, DATE '2024-01-01');
COMMIT;
```

`ROLLBACK` může upozornit, že klient transakci již ukončil. Nové čtení vrátí
`1`; vložení a potvrzení se nyní mohou podařit. Kdyby obchodní pravidlo
říkalo „vložit pouze při počtu 0“, musela by aplikace znovu vyhodnotit
podmínku a tentokrát nevložit.

**T1:** Zopakujte kontrolní `SELECT`. Nyní očekávejte `tx001 | 42`
a `tx002 | 42`.

## Shrnutí a úklid

| Mechanismus | Pozorování |
|---|---|
| `READ UNCOMMITTED` | V PostgreSQL se chová jako `READ COMMITTED`. |
| `READ COMMITTED` | Každý příkaz používá nový snímek; transakce vidí i vlastní změny. |
| `REPEATABLE READ` | Transakce používá stabilní snímek a vidí vlastní změny. |
| `FOR UPDATE` | Zamyká vybrané řádky; konfliktní změny a zámky čekají. |
| `SERIALIZABLE` | Brání neserializovatelnému výsledku, někdy chybou `40001`. |

Až obě okna dokončí všechny transakce, můžete **ve svém schématu** uklidit:

```sql
DROP TABLE transakce_lab.orders;
DROP SCHEMA transakce_lab;
```

## Otázky na závěr

1. Proč PostgreSQL v úloze 1 neumožnil špinavé čtení?
2. Jak se liší výsledek druhého čtení v úlohách 3 a 4?
3. Proč v úloze 6 běžné čtení nečekalo, zatímco `FOR UPDATE` ano?
4. Proč při chybě `40001` opakujeme celou transakci?
