# Transakce v databázi: když se o stejná data stará víc lidí najednou

## Proč se o transakcích učíme

Předpokládáme, že už umíte základní operace nad daty:

- `INSERT` přidá řádek,
- `SELECT` data přečte,
- `UPDATE` řádek změní,
- `DELETE` řádek smaže.

To ale samo o sobě neřeší, co se stane, když několik lidí nebo částí
programu pracuje se stejnými daty současně. Databáze musí rozhodnout:

- Kterou změnu kdo uvidí?
- Co když se jedna operace skládá z více příkazů a jeden z nich selže?
- Co když si dva zákazníci současně chtějí koupit poslední kus zboží?
- Jak zabránit tomu, aby jedna změna omylem přepsala druhou?

Právě tady nastupují **transakce**. V tomto textu si nejdřív vysvětlíme
jejich smysl a potom se podíváme, jak se jednotlivé situace projevují
v PostgreSQL. Výklad odpovídá laboratornímu cvičení v souboru
[laborator-transakce.md](./laborator-transakce.md) a SQL scénáři
[lab.sql](./lab.sql).

---

## 1. Transakce: jeden celek, ne hromádka nesouvisejících příkazů

Představte si převod 500 Kč mezi dvěma účty:

1. odečteme 500 Kč z účtu A,
2. připíšeme 500 Kč na účet B.

Kdyby první příkaz uspěl a druhý selhal, peníze by z účtu A zmizely,
ale na účet B by nedorazily. To nechceme. Oba příkazy proto považujeme
za **jednu transakci**: buď se podaří oba, nebo se neprovede ani jeden.

```sql
BEGIN;

UPDATE ucty
SET zustatek = zustatek - 500
WHERE cislo_uctu = 'A';

UPDATE ucty
SET zustatek = zustatek + 500
WHERE cislo_uctu = 'B';

COMMIT;
```

`BEGIN` zahájí transakci a `COMMIT` potvrdí její změny. Pokud zjistíme,
že je něco špatně, můžeme dosud nepotvrzené změny zrušit:

```sql
ROLLBACK;
```

Dokud transakci nepotvrdíme, ostatní transakce naše změny běžně nevidí.
Po `COMMIT` se potvrzené změny stanou dostupnými ostatním. Po `ROLLBACK`
se naopak tváří, jako by naše neúspěšná práce vůbec neproběhla.

### Čtyři vlastnosti ACID

Kvalitní databázová transakce se tradičně popisuje čtyřmi vlastnostmi
ACID:

| Písmeno | Název | Lidsky řečeno |
|---|---|---|
| **A** | Atomicity – atomicita | Všechno, nebo nic. Převod neodečte peníze bez jejich připsání. |
| **C** | Consistency – konzistence | Potvrzená data dodržují pravidla databáze a aplikace. |
| **I** | Isolation – izolace | Souběžné transakce se navzájem neovlivní způsobem, který by porušil pravidla. |
| **D** | Durability – trvanlivost | Po potvrzení změna přežije například běžné vypnutí databázového procesu. |

V našem labu se zaměříme především na **izolaci**. Zbylé vlastnosti jsou
užitečné pro celkový obrázek: transakce není jen „několik SQL příkazů
za sebou“, ale bezpečný celek s jasným začátkem a koncem.

---

## 2. Co znamená souběh

Databázi obvykle používá mnoho lidí zároveň. V příkladech jim budeme říkat
**T1** a **T2**. Každá transakce má své vlastní připojení k databázi.
Představte si dvě samostatné pokladny, které obsluhují zákazníky současně.

Například:

1. T1 začne pracovat s objednávkami.
2. T2 ve stejnou chvíli vloží novou objednávku.
3. T1 se znovu podívá na objednávky.

Zda T1 novou objednávku uvidí, záleží na izolační úrovni a také na tom,
zda T2 změnu potvrdila.

### Důležitá slova

- **Potvrzená změna**: transakce, která ji provedla, skončila úspěšně
  příkazem `COMMIT`.
- **Nepotvrzená změna**: transakce stále běží; může ještě skončit
  potvrzením nebo zrušením.
- **Snímek (snapshot)**: pohled na verze dat, které jsou pro konkrétní
  příkaz nebo transakci viditelné.
- **Anomálie**: překvapivý nebo nekonzistentní výsledek způsobený tím,
  jak se transakce překrývají.

### MVCC: více verzí dat

PostgreSQL používá **MVCC** (*Multi-Version Concurrency Control*),
tedy řízení souběhu pomocí více verzí řádků. Zjednodušeně: když se řádek
změní, databáze může po určitou dobu uchovávat jeho starší verzi a vytvořit
verzi novou. Každý dotaz pak přečte verzi odpovídající svému snímku.

Představte si, že někdo během čtení přepíše řádek v knize. Místo toho,
aby vám knihu vytrhl z ruky, databáze vám může nechat dočíst starou verzi
a novou ukázat později. Díky tomu obyčejný čtecí dotaz obvykle nemusí
čekat na každý souběžný zápis.

MVCC neznamená, že zámky neexistují. Při změnách se zámky používají
a můžeme si o ně říct i výslovně. MVCC a zámky jsou dvě části jednoho
mechanismu, které pomáhají souběžné práci.

---

## 3. Tři situace, které je dobré umět rozpoznat

Názvy těchto jevů mohou znít odtažitě. Představme si ale konkrétní
objednávky a otázku „kolik jich splňuje podmínku?“.

### Špinavé čtení: přečtu něco, co se možná nikdy nestalo

T1 vloží objednávku, ale ještě ji nepotvrdí. T2 ji přečte. Potom T1
provede `ROLLBACK`.

T2 tedy viděla data, která nakonec nebyla uložena. Takovému čtení
nepotvrzené změny se říká **špinavé čtení** (*dirty read*).

Je to podobné, jako kdyby se v obchodním systému na chvíli ukázalo,
že poslední kus zboží někdo koupil, systém podle toho odmítl další nákup,
a první zákazník pak objednávku zrušil.

PostgreSQL špinavé čtení nepovoluje. Dokonce i když nastavíme
`READ UNCOMMITTED`, chová se tato úroveň v PostgreSQL stejně jako
`READ COMMITTED`.

### Neopakovatelně přečtený řádek: stejný řádek, jiná hodnota

T1 přečte cenu produktu: 100 Kč. Mezitím T2 změní cenu na 120 Kč
a potvrdí změnu. T1 přečte tentýž řádek znovu a dostane 120 Kč.

Jedno konkrétní čtení řádku tedy při opakování vrátilo jinou hodnotu.
Tomu se říká **neopakovatelný záznam** (*non-repeatable read*).

### Phantom: změnila se množina výsledků

T1 se zeptá:

```sql
SELECT *
FROM objednavky
WHERE stav = 'nova';
```

Dotaz vrátí pět řádků. Mezitím T2 vloží novou objednávku se stavem
`'nova'` a potvrdí ji. Když T1 zopakuje stejný dotaz, může dostat šest
řádků.

Nezměnil se nutně žádný z původních pěti řádků. Změnila se **množina**
řádků, které odpovídají podmínce. Novému řádku se v tomto kontextu říká
**phantom** (*phantom read*).

Zapamatujte si jednoduché rozlišení:

- stejný řádek, jiná hodnota → **neopakovatelně přečtený řádek**;
- jiná sada řádků odpovídající podmínce → **phantom**.

---

## 4. Izolační úrovně: jak přísně mají transakce držet svůj pohled

Izolační úroveň určuje, jaké souběžné změny může transakce pozorovat
a kterým anomáliím databáze zabrání. Přísnější pravidla mohou vyžadovat
více práce databáze nebo způsobit, že některá transakce bude muset začít
znovu.

### Dva různé časové úseky: trvání příkazu a trvání transakce

Než se pustíme do jednotlivých úrovní, rozlišujme dvě věci, které se
snadno pletou:

- **průběh příkazu** je doba od začátku do konce jednoho `SELECT`u,
  `UPDATE`u apod.;
- **průběh transakce** je doba od `BEGIN` do `COMMIT`/`ROLLBACK`; může
  obsahovat mnoho příkazů.

Izolační úroveň říká, **ke kterému okamžiku se vztahuje snímek dat**:

| Úroveň | Snímek vzniká | Platí po dobu |
|---|---|---|
| `READ COMMITTED` | při začátku každého příkazu | jednoho příkazu |
| `REPEATABLE READ` | při prvním příkazu, který čte nebo mění data | celé transakce |
| `SERIALIZABLE` | při prvním příkazu, který čte nebo mění data | celé transakce |

Dvě důležité věty k zapamatování:

1. **Uvnitř jednoho příkazu** se pohled na data nemění nikdy. Dlouhý
   `SELECT` vidí jen to, co bylo potvrzeno před jeho začátkem. Změny,
   které jiná transakce potvrdí během jeho běhu, neuvidí, a to ani
   v `READ COMMITTED`.
2. **Mezi příkazy** záleží na úrovni. `READ COMMITTED` si u dalšího
   příkazu vezme nový snímek, `REPEATABLE READ` a `SERIALIZABLE` zůstávají
   u snímku z prvního příkazu.

Časová osa (čas plyne shora dolů, T2 mezitím potvrdí změnu):

```text
T1: BEGIN;
T1: SELECT ...            <- (A) snímek v čase A
T2:   UPDATE ...; COMMIT; <- změna potvrzena po (A)
T1: SELECT ...            <- (B) ?
```

- `READ COMMITTED`: druhý `SELECT` v (B) dostane nový snímek, takže
  změnu T2 **uvidí**.
- `REPEATABLE READ` / `SERIALIZABLE`: druhý `SELECT` zůstává u snímku
  z (A), takže změnu T2 **neuvidí**.

Samotné `BEGIN` snímek nevytváří. Kdyby T1 provedla první `SELECT` až
po `COMMIT` v T2, viděla by změnu i na úrovni `REPEATABLE READ`.

**Výjimka u zápisů:** `UPDATE`, `DELETE` a `SELECT ... FOR UPDATE` se při
konfliktu mohou chovat jinak než čtení. V `READ COMMITTED` příkaz
počká na transakci, která drží zámek řádku, a po jejím `COMMIT` znovu
vyhodnotí nejnovější potvrzenou verzi tohoto řádku. V `REPEATABLE READ`
a `SERIALIZABLE` by v takové situaci skončil chybou serializace.

### `READ COMMITTED`: nový pohled pro každý příkaz

Tohle je v PostgreSQL výchozí izolační úroveň. Každý SQL příkaz dostane
svůj snímek potvrzených dat. Představte si, že se při každém novém
dotazu podíváte na aktuální nástěnku.

T1 může v jedné transakci provést dva dotazy:

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT AVG(pieces) FROM transakce_lab.orders;
-- například 6.0
```

T2 mezitím vloží řádek a potvrdí ho:

```sql
BEGIN;
INSERT INTO transakce_lab.orders (login, item, pieces, otime)
VALUES ('lee040', 5, 50, DATE '2019-02-24');
COMMIT;
```

Když T1 zopakuje svůj dotaz, dostane nový snímek:

```sql
SELECT AVG(pieces) FROM transakce_lab.orders;
-- nyní 14.8

COMMIT;
```

Není to špinavé čtení: T2 změnu potvrdila dříve, než ji druhý dotaz T1
četl. T1 ale nemá po celou dobu transakce jeden neměnný pohled na data.
Proto se může změnit hodnota i množina řádků.

**Praktická věta:** `READ COMMITTED` znamená „každý příkaz uvidí
potvrzené změny, které byly hotové před jeho začátkem“.

### `REPEATABLE READ`: jeden stabilní pohled během transakce

U `REPEATABLE READ` používá transakce stabilní snímek. Když T1 přečte
objednávky a T2 pak potvrdí novou objednávku, T1 ji při opakování dotazu
během své transakce stále neuvidí.

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT AVG(pieces) FROM transakce_lab.orders;
-- 6.0
```

Po změně a potvrzení v T2:

```sql
SELECT AVG(pieces) FROM transakce_lab.orders;
-- stále 6.0 v témže snímku

COMMIT;

SELECT AVG(pieces) FROM transakce_lab.orders;
-- nový příkaz po skončení transakce už změnu uvidí
```

V PostgreSQL se snímek `REPEATABLE READ` stanoví při prvním příkazu,
který ho potřebuje. Samotné `BEGIN` ho ještě nemusí vytvořit. Transakce
také vždy vidí vlastní změny.

**Důležité:** `REPEATABLE READ` v PostgreSQL zabraňuje tomu, aby se
v průběhu transakce objevil phantom nebo změnila dříve přečtená verze
řádku. Není ale ve všech situacích totéž co `SERIALIZABLE`: některé
nebezpečné kombinace souběžných zápisů stále řeší až přísnější úroveň.

### `SERIALIZABLE`: výsledek jako při postupném vykonání

`SERIALIZABLE` se snaží zajistit, aby souběžně provedené transakce
dopadly stejně, jako kdyby se provedly jedna po druhé v nějakém pořadí.

To neznamená, že databáze vždy všechny transakce nechá uspět. Pokud
některá kombinace čtení a zápisů nemůže bezpečně odpovídat žádnému
postupnému pořadí, PostgreSQL může jednu transakci zastavit chybou
serializace. Aplikace pak musí transakci znovu provést.

#### Příklad: dvě pokladny a poslední vstupenka

Představte si pravidlo: „Pokud ještě není prodaná žádná vstupenka
do řady 42, vlož prodej.“ T1 i T2 se podívají na databázi a obě zjistí,
že tam zatím žádný takový prodej není. Každá se proto rozhodne vložit
prodej. Kdyby se transakce provedly postupně, druhá by už při kontrole
viděla první prodej a rozhodla by se jinak. Pokud by tedy obě uspěly
s původním výsledkem čtení, jejich průběh by neodpovídal žádnému
postupnému pořadí.

Při `SERIALIZABLE` může PostgreSQL jednu z nich odmítnout, typicky
s SQLSTATE `40001`. Chyba může přijít při zápisu nebo při `COMMIT`.
To není databáze „rozbitá“ — databáze tím brání výsledku, který by nebylo
možné vysvětlit bezpečným postupným pořadím.

Při opakování je třeba provést **celou transakci znovu**:

1. znovu načíst potřebná data,
2. znovu vyhodnotit podmínky a rozhodnutí,
3. znovu provést příslušné zápisy,
4. znovu potvrdit.

Nestačí zopakovat jen poslední `INSERT`: předchozí rozhodnutí mohlo být
založeno na údajích, které už neplatí.

### Co se mění u CRUD operací

Izolační úroveň nemění syntaxi CRUD příkazů. `SELECT` je stále čtení,
`INSERT` vložení, `UPDATE` změna a `DELETE` smazání. Mění ale to, **jaké
verze dat příkaz uvidí a co se stane při souběžném zápisu**.

Základní pravidlo pro PostgreSQL: transakce vidí své vlastní změny,
ale jiné transakci se její změny stanou viditelné až po `COMMIT`.
`ROLLBACK` je zruší. Následující tabulka popisuje rozdíly pro práci
se souběžnými transakcemi:

| Izolace | `SELECT` | `INSERT` | `UPDATE` / `DELETE` |
|---|---|---|---|
| `READ UNCOMMITTED` | Stejně jako `READ COMMITTED`; cizí nepotvrzené změny nevidí. | Nový řádek vidí jeho autor; ostatní až po potvrzení. | Vlastní změnu vidí autor; ostatní ji uvidí až po potvrzení. |
| `READ COMMITTED` | Každý příkaz dostane nový snímek potvrzených dat. | Cizí transakce vložený řádek uvidí až po `COMMIT` a ve svém dalším příkazu. | Příkaz může čekat na souběžnou změnu stejného řádku; po jejím potvrzení PostgreSQL znovu ověří, zda řádek stále splňuje podmínku. |
| `REPEATABLE READ` | Čtení používají stabilní snímek celé transakce; vlastní změny jsou vidět. | Ostatní uvidí vložený řádek až po `COMMIT`; vkládající transakce ho vidí hned. | Pokud se jiná transakce pokusila změnit nebo smazat řádek, který tato transakce také mění, může PostgreSQL vrátit chybu serializace. |
| `SERIALIZABLE` | Stabilní snímek a navíc kontrola, zda celek souběžných transakcí odpovídá bezpečnému postupnému pořadí. | Vložení je viditelné ostatním až po `COMMIT`; souběžná logika může vést k chybě serializace. | Souběžné zápisy mohou čekat nebo skončit chybou serializace, aby nevznikl nebezpečný výsledek. |

#### `UPDATE` vs. `INSERT` v `REPEATABLE READ`

Zápisy se v `REPEATABLE READ` chovají rozdílně podle toho, jestli sahají
na **existující řádek**, nebo vytvářejí **nový**.

**`UPDATE` a `DELETE`** pracují s řádky viditelnými ve snímku transakce.
Pokud ale některý z těchto řádků mezitím změnila jiná transakce a potvrdila
to, příkaz skončí chybou serializace (`40001`, „could not serialize access
due to concurrent update“). Transakce by jinak přepsala změnu, kterou
ve svém snímku nikdy neviděla.

- Jiná transakce změnu **ještě nepotvrdila**: náš `UPDATE` počká.
  Po jejím `COMMIT` skončí chybou, po `ROLLBACK` normálně pokračuje.
- Řádek, který jiná transakce **vložila po vzniku našeho snímku**, náš
  `UPDATE ... WHERE` neuvidí, a proto ho ani nezmění. Žádná chyba nevznikne.

**`INSERT`** nepřepisuje žádnou starší verzi řádku, takže sám o sobě
s chybou serializace nekončí. Vložený řádek je ostatním viditelný až po
`COMMIT` a vkládající transakce ho vidí hned. Výjimka je porušení
`PRIMARY KEY` nebo `UNIQUE`: pokud jiná transakce vložila stejný klíč
a potvrdila ho, dostanete chybu `23505` (unique violation), i když řádek
ve svém snímku nevidíte.

Příklad:

```sql
-- T1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pieces FROM transakce_lab.orders WHERE login = 'nor001'; -- 10

-- T2
UPDATE transakce_lab.orders SET pieces = 99 WHERE login = 'nor001';
-- (autocommit, změna je potvrzena)

-- T1
UPDATE transakce_lab.orders SET pieces = pieces + 1 WHERE login = 'nor001';
-- ERROR: could not serialize access due to concurrent update
ROLLBACK;  -- a celou transakci zopakujte
```

Kdyby T2 místo toho vložila nový řádek (`INSERT`), T1 by se nic nestalo.

| | `UPDATE` / `DELETE` | `INSERT` |
|---|---|---|
| Na co sahá | existující řádky ve snímku | nový řádek |
| Souběžná potvrzená změna téhož řádku | chyba `40001`, nutné zopakovat transakci | nelze, řádek zatím neexistuje |
| Nový řádek od jiné transakce | neuvidí ho, nezmění ho | nevadí; jen při duplicitě klíče chyba `23505` |

Na přímé zachování pravidla „nejdřív zkontroluj, pak vlož“ ale
`REPEATABLE READ` nestačí. Obě transakce mohou vložit nový řádek bez
konfliktu. Na to je potřeba `UNIQUE`, `FOR UPDATE` na existujícím řádku,
nebo `SERIALIZABLE`.

Například při tomto příkazu:

```sql
UPDATE produkty
SET skladem = skladem - 1
WHERE id = 42;
```

izolační úroveň sama o sobě nezaručuje, že `skladem` neklesne pod nulu.
Pokud je to zakázáno, pravidlo vyjádřete také v databázi, například
omezením `CHECK (skladem >= 0)`, a navrhněte transakci tak, aby s řádkem
pracovala bezpečně. Izolace pomáhá koordinovat souběžnou práci, ale
nenahrazuje integritní omezení ani správnou obchodní logiku.

Ještě jeden důležitý případ: jestliže mají být dva řádky jedinečné,
například dvě objednávky se stejným číslem nejsou dovoleny, použijte
`PRIMARY KEY` nebo `UNIQUE`. Bez takového omezení může PostgreSQL povolit
oba `INSERT` příkazy — žádná izolační úroveň nenahradí chybějící pravidlo
datového modelu.

---

## 5. Když nestačí číst: výslovné zamknutí řádku

Někdy chceme říct: „Tento řádek si teď beru k bezpečné úpravě. Jiný
zapisující uživatel ať počká.“

V PostgreSQL k tomu můžeme použít `SELECT ... FOR UPDATE`:

```sql
BEGIN;

SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001'
FOR UPDATE;
```

T1 přečte odpovídající řádek a drží na něm zámek do `COMMIT`u nebo
`ROLLBACK`u. Pokud T2 provede běžný `SELECT`, obvykle může pokračovat:

```sql
SELECT login, pieces
FROM transakce_lab.orders
WHERE login = 'nor001';
```

Běžné čtení nepotřebuje stejný zámek; díky MVCC může číst viditelnou,
již potvrzenou verzi. Pokud se ale T2 pokusí získat konfliktní zámek
pomocí dalšího `FOR UPDATE`, bude čekat, než T1 svou transakci ukončí.

### Zámek je užitečný, ale není kouzelná hůlka

Zámek řádku je užitečný, když aplikace potřebuje nejdřív přečíst
konkrétní existující řádek a potom ho upravit. Například při rezervaci
konkrétního sedadla:

```sql
BEGIN;

SELECT stav
FROM sedadla
WHERE cislo = 'A12'
FOR UPDATE;

-- Aplikace ověří, že je sedadlo volné, a případně ho rezervuje.
UPDATE sedadla
SET stav = 'rezervovano'
WHERE cislo = 'A12';

COMMIT;
```

Zamyká se pouze řádek nalezený dotazem; `FOR UPDATE` nezamkne „prázdné
místo“ pro řádek, který zatím neexistuje. U podmínek nad větším rozsahem
dat je proto potřeba přemýšlet, zda je vhodný explicitní zámek, vhodné
omezení v databázi, nebo úroveň `SERIALIZABLE`.

---

## 6. Co dělat, když transakce čeká nebo selže

### Čekání může být očekávané

Jestliže T2 žádá o zámek řádku, který právě drží T1, může se příkaz T2
zastavit a čekat. V laboratorním cvičení je to záměr: T1 ukončíte příkazem
`COMMIT` nebo `ROLLBACK` a T2 pak může pokračovat.

Pokud čekání nečekáte, ověřte:

- zda v druhém okně opravdu běží samostatná transakce;
- zda T1 už neprovedla `COMMIT` nebo `ROLLBACK`;
- zda obě okna pracují se stejným řádkem a schématem.

### Po chybě může transakce potřebovat `ROLLBACK`

Když PostgreSQL nahlásí chybu uvnitř transakce, transakce může zůstat
v chybovém stavu. Před novou prací ji obvykle ukončete:

```sql
ROLLBACK;
```

Potom můžete začít nový pokus příkazem `BEGIN`. Chybu neignorujte
a nepředpokládejte, že se všechny předchozí příkazy automaticky provedly.

### `COMMIT` a `ROLLBACK` nejsou zaměnitelné

- `COMMIT` říká: „Tyto změny potvrzuji.“
- `ROLLBACK` říká: „Změny této dosud nepotvrzené transakce ruším.“

Po `COMMIT` už běžný `ROLLBACK` potvrzené změny nevrátí. Pro změnu
potvrzených dat by byl potřeba nový SQL příkaz, případně obnova z jiné
zálohy či historie.

---

## 7. Jak si výsledky z labu zapamatovat

| Co pozorujeme | Co si říct |
|---|---|
| T2 nevidí necommitnutý řádek T1 | PostgreSQL nepouští špinavé čtení. |
| Druhý `SELECT` v `READ COMMITTED` vidí novou potvrzenou změnu | Každý příkaz dostal nový snímek. |
| Druhý `SELECT` v `REPEATABLE READ` změnu nevidí | Transakce drží stabilní snímek. |
| Běžný `SELECT` pokračuje, zatímco `FOR UPDATE` čeká | Čtení a zamykací požadavek nejsou totéž. |
| `SERIALIZABLE` vrátí chybu `40001` | Databáze požaduje nový pokus, aby zachovala bezpečný výsledek. |

Rychlá pomůcka:

> **READ COMMITTED** – čerstvý pohled při každém příkazu.  
> **REPEATABLE READ** – stejný pohled po dobu transakce.  
> **SERIALIZABLE** – výsledek jako při bezpečném postupném provedení;
> někdy za cenu opakování transakce.

---

## 8. Pět otázek před spuštěním SQL

Když pracujete s transakcemi, zvykněte si předem položit tyto otázky:

1. Kde transakce začíná a kde má skončit?
2. Co přesně se stane, když některý příkaz selže?
3. Je změna už potvrzená, nebo ji jiná transakce ještě může zrušit?
4. Potřebuji, aby opakované čtení ukázalo stejná data?
5. Když nastane konflikt, musím znovu provést celé rozhodnutí?

Jestli na ně umíte odpovědět, už nepíšete SQL jen jako sled příkazů.
Začínáte přemýšlet o tom, jak bude databáze bezpečně sloužit více lidem
najednou.

## Další materiály

- [Postup laboratorního cvičení](./laborator-transakce.md)
- [SQL scénář pro PostgreSQL](./lab.sql)
