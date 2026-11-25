# LEGO: jak přidávat, měnit a mazat data (INSERT, UPDATE, DELETE)

Umíš číst data pomocí `SELECT`. Dnes se naučíš data **měnit**: přidávat nové řádky,
opravovat stávající a mazat ty, které už nepotřebuješ. Tyto tři příkazy
spolu s `SELECT` tvoří základ práce s databází.

Praktická část je v souboru [lego-cud-priklady.sql](./lego-cud-priklady.sql).
Tento text ti k ní dává vysvětlení, souvislosti a pomůcky. Doporučuju
číst je vedle sebe: tady si přečteš, **proč** se příkaz píše tak, jak se píše,
a ve skriptu si to hned vyzkoušíš.

---

## 1. Než začneme: proč nejdřív dočasná tabulka?

Při `SELECT` se nic nemůže pokazit. Při `INSERT`, `UPDATE` a `DELETE` ano.
Špatný příkaz může přepsat nebo smazat data a vrátit je zpět nemusí být snadné.

Proto budeme pracovat **na kopii**:

```sql
CREATE TEMP TABLE moje_sety (LIKE lego.sets INCLUDING ALL);
INSERT INTO moje_sety SELECT * FROM lego.sets;
```

- `TEMP` znamená **dočasná tabulka**. Vidíš ji jen ty, jen v tomto spojení,
  a zmizí, když se odpojíš.
- `LIKE lego.sets INCLUDING ALL` vytvoří tabulku se stejnými sloupci,
  stejným primárním klíčem a stejným `NOT NULL` jako originál. Pravidla
  z originálu tedy platí i v kopii. Nekopírují se jen cizí klíče.
- Druhý příkaz kopii naplní všemi řádky z originálu (28 179 sad).

> **Pozor:** pracuj stále v jednom SQL okně. Dočasná tabulka patří spojení,
> ne souboru. Když okno zavřeš, musíš znovu spustit část 0 skriptu.

Pokud se něco pokazí, kopii prostě zahodíš a vytvoříš novou. Originál zůstane nedotčený.

### Tabulka `sets`, se kterou budeme pracovat

| Sloupec | Typ | Význam |
|---|---|---|
| `set_num` | `VARCHAR(20)` | Klíč sady, např. `75252-1`. **Primární klíč**, musí být jedinečný. |
| `name` | `VARCHAR(256)` | Název sady. **Povinný** (`NOT NULL`). |
| `year` | `INTEGER` | Rok vydání. |
| `theme_id` | `INTEGER` | Číslo tématu; název je v tabulce `themes`. |
| `num_parts` | `INTEGER` | Počet dílků. |
| `img_url` | `VARCHAR(500)` | Adresa obrázku. |

Dvě věci, které budeme potřebovat pořád:

- **Primární klíč** je sloupec, jehož hodnota řádek jednoznačně určuje. Dvě sady
  se stejným `set_num` existovat nemohou.
- **`NOT NULL`** říká, že sloupec musí mít hodnotu. `NULL` znamená "nevíme /
  chybí". Není to nula ani prázdný text.

---

## 2. INSERT: přidáváme nový řádek

### Jak o tom přemýšlet

Představ si, že do evidence zapisuješ novou sadu na nový řádek. Musíš říct:
**kam** (do které tabulky), **které sloupce** vyplňuješ a **jaké hodnoty** tam patří.

```sql
INSERT INTO tabulka (sloupec1, sloupec2, ...)
VALUES (hodnota1, hodnota2, ...);
```

> **Zlaté pravidlo:** pořadí hodnot musí odpovídat pořadí sloupců, které jsi vypsal.
> První hodnota patří prvnímu sloupci, druhá druhému atd.

### Pět příkladů a co z nich plyne

| # | Co ukazuje | Klíčová myšlenka |
|---|---|---|
| 1 | Jedna sada, všechny sloupce | Text do `'...'`, čísla bez uvozovek, `NULL` = chybí. Duplicitní klíč vyvolá chybu. |
| 2 | Jen některé sloupce | Co nevyplníš, bude `NULL`, ale jen pokud to sloupec dovoluje. |
| 3 | Více řádků najednou | Za `VALUES` více závorek oddělených čárkou. Příkaz je celý, nebo nic. |
| 4 | `INSERT ... SELECT` | Místo `VALUES` vložíš výsledek dotazu: hromadné kopírování a úprava. |
| 5 | Poddotaz a `RETURNING` | Hodnotu si necháš dohledat a ihned vidíš, co se vložilo. |

### Co mají studenti často za problém

**Chybí povinný sloupec.** `name` je `NOT NULL`:

```sql
INSERT INTO moje_sety (set_num, year) VALUES ('MOJE-X', 2025);
-- ERROR: null value in column "name" violates not-null constraint
```

**Duplicitní klíč.** `set_num` je primární klíč:

```sql
-- spuštěno podruhé:
-- ERROR: duplicate key value violates unique constraint
```

**Hodnota se nevejde.** `set_num` je `VARCHAR(20)`. Předpona `'KOPIE-'` k nejdelším
klíčům přesáhne 20 znaků, proto ve skriptu používáme krátké `'K-'`.

**Poddotaz vrátil víc řádků.** Názvy témat nejsou unikátní. `Star Wars` existuje
čtyřikrát (id 18, 158, 209, 261). Proto ve skriptu hledáme `... AND parent_id IS NULL`.
Je to dobrá připomínka: **nikdy nepředpokládej, že název je jedinečný, když to
tabulka nezaručuje.**

> **Co když řádek už může existovat?** Bonus u příkladu 5 ukazuje `ON CONFLICT`:
> buď tiše přeskočí (`DO NOTHING`), nebo existující řádek přepíše (`DO UPDATE`).

---

## 3. UPDATE: opravujeme existující řádky

### Jak o tom přemýšlet

`UPDATE` nevytváří nic nového. Hledá řádky, které **už existují**, a mění
v nich vybrané sloupce. Má dvě části a obě jsou důležité:

```sql
UPDATE tabulka
SET sloupec1 = nová_hodnota1,    -- CO se mění
    sloupec2 = nová_hodnota2
WHERE podmínka;                  -- KTERÝCH řádků se to týká
```

> **Nejdůležitější věta celého cvičení:**
> `WHERE` rozhoduje, kterých řádků se změna týká. **Bez `WHERE` se změní VŠECHNY řádky tabulky.**

Představ si, že chceš opravit jednu chybu v seznamu, a místo toho přepíšeš celý seznam.
Proto děláme **dvě věci pokaždé**:

1. **Nejdřív `SELECT` se stejným `WHERE`**, abys viděl, jaké řádky se změní.
2. **Po `UPDATE` zkontroluj počet** (`UPDATE 1`, `UPDATE 8` ...). Musí sedět s tím,
   co jsi čekal.

### Pět příkladů a co z nich plyne

| # | Co ukazuje | Klíčová myšlenka |
|---|---|---|
| 1 | Jeden řádek, jeden sloupec | `WHERE` na primární klíč zasáhne nejvýš jeden řádek. |
| 2 | Více sloupců najednou | V `SET` oddělujeme sloupce **čárkou** (ne `AND`). |
| 3 | Více řádků a výpočet | Vpravo od `=` můžeš použít původní hodnotu: `num_parts * 1.1`. |
| 4 | `UPDATE ... FROM` | Hodnotu vezmeš z jiné tabulky (název tématu z `themes`). |
| 5 | `UPDATE` bez `WHERE` | Ukázka katastrofy a záchranná síť: transakce. |

### Příklad 3 podrobně: výpočet z původní hodnoty

```sql
UPDATE moje_sety
SET num_parts = ROUND(num_parts * 1.1)
WHERE theme_id = 246 AND year = 2019;
```

Při provedení databáze pro každý vybraný řádek vezme **současné** `num_parts`,
vynásobí 1,1, zaokrouhlí a uloží. Vpravo od `=` tedy vidíš starý stav,
vlevo se zapisuje nový.

### Příklad 5: záchranná síť (transakce)

```sql
BEGIN;                            -- začínám "zkoušku"
UPDATE moje_sety SET num_parts = 0;   -- ups, zapomněl jsem WHERE
SELECT SUM(num_parts) FROM moje_sety; -- 0, je to špatně
ROLLBACK;                         -- vše vrať zpět
```

- `BEGIN` otevře transakci: změny zatím nejsou definitivní.
- `ROLLBACK` všechno zruší, jako by se nic nestalo.
- `COMMIT` by změny potvrdil a staly by se trvalými.

Je to jako "Ctrl+Z", ale s pevnou hranicí: platí jen do `COMMIT`.

---

## 4. DELETE: mažeme řádky

### Jak o tom přemýšlet

`DELETE` maže **celé řádky**, proto za něj nepíšeš sloupce. Jen určíš, ze které
tabulky a podle jaké podmínky.

```sql
DELETE FROM tabulka
WHERE podmínka;
```

> **Stejné pravidlo jako u `UPDATE`:** bez `WHERE` se smažou **všechny** řádky.
> Struktura tabulky zůstane, ale bude prázdná.

Postup, který se vyplatí vždy:

1. `SELECT` se stejným `WHERE` (co přesně se smaže?)
2. `DELETE`
3. Zkontroluj počet (`DELETE 4` odpovídá tomu, co ukázal `SELECT`?)

### Pět příkladů a co z nich plyne

| # | Co ukazuje | Klíčová myšlenka |
|---|---|---|
| 1 | Jeden řádek podle klíče | Nejbezpečnější a nejpřesnější forma mazání. |
| 2 | Více řádků podle podmínky | Počet smazaných řádků porovnej s kontrolním `SELECT`. |
| 3 | Poddotaz a `IN` | Hodnoty hledáš v jiné tabulce; `IN` zvládne víc hodnot než `=`. |
| 4 | `NOT EXISTS` | Mažeš řádky, ke kterým v jiné tabulce **nic neexistuje**. |
| 5 | `RETURNING` + transakce | Vidíš, co se smazalo, a můžeš couvnout. |

### Proč u příkladu 3 `IN` a ne `=`?

```sql
-- správně
WHERE theme_id IN (SELECT id FROM lego.themes WHERE name = 'Technic')

-- špatně: poddotaz vrátí víc než jedno id
WHERE theme_id = (SELECT id FROM lego.themes WHERE name = 'Technic')
```

`=` porovnává s **jednou** hodnotou. Téma `Technic` má v tabulce pět různých `id`,
takže poddotaz vrací pět čísel. `IN` zkontroluje, jestli je hodnota **kdekoli
v seznamu**. Správně se tedy smaže 955 sad, ne jen 461 z jednoho tématu.

### Příklad 4: `NOT EXISTS` lidsky

```sql
DELETE FROM moje_sety s
WHERE s.year < 1980
  AND NOT EXISTS (
      SELECT 1
      FROM lego.inventories i
      JOIN lego.inventory_parts ip ON ip.inventory_id = i.id
      WHERE i.set_num = s.set_num
  );
```

Čti to takhle: "Smaž sadu `s` z doby před rokem 1980, **pokud neexistuje** žádný
dílek v inventáři této sady." Poddotaz se spustí pro každou sadu zvlášť, protože
odkazuje na `s.set_num` z vnějšího příkazu.

### Příklad 5: vidět, co mažu

```sql
BEGIN;
DELETE FROM moje_sety
WHERE name LIKE '%Test%'
RETURNING set_num, name, year;   -- vypíše smazané řádky
ROLLBACK;                        -- nebo COMMIT, když to sedí
```

`RETURNING` je užitečný u `INSERT`, `UPDATE` i `DELETE`: ihned vidíš, co se stalo
s řádky. U mazání je to zvlášť cenné.

---

## 5. A jak je to v originální tabulce?

Na kopii se mazání dělá snadno. V originální databázi LEGO by ale `DELETE`
narazil na **cizí klíče**. Kdyby sada byla použita v tabulce `inventory_sets`,
databáze by smazání odmítla, aby nevznikly "osiřelé" záznamy:

```text
ERROR: update or delete on table "sets" violates foreign key constraint ...
```

Naše kopie cizí klíče nemá, proto se tam podobné chyby neukážou. Je dobré
vědět, že **v ostrém systému mazání omezují vztahy mezi tabulkami**. Další
způsob je `ON DELETE CASCADE` (smaže i související záznamy), který je v tabulkách
`inventory_parts` apod. skutečně nastaven.

---

## 6. Nejčastější chyby na jednom místě

| Chyba / hláška | Příčina | Řešení |
|---|---|---|
| `duplicate key value violates unique constraint` | Vkládáš klíč, který už existuje. | Zvol jiný klíč nebo použij `ON CONFLICT`. |
| `null value in column ... violates not-null constraint` | Vynechal jsi povinný sloupec. | Doplň ho do `INSERT`. |
| `value too long for type character varying(20)` | Text je delší než sloupec. | Zkrať hodnotu. |
| `invalid input syntax for type integer` | Dal jsi text tam, kde má být číslo. | Zkontroluj typ hodnoty. |
| `more than one row returned by a subquery used as an expression` | Poddotaz vrací víc řádků a ty jsi ho použil jako jednu hodnotu. | Zpřesni podmínku nebo použij `IN`. |
| `UPDATE 28202` místo očekávaného `UPDATE 8` | Chybí nebo je špatný `WHERE`. | `ROLLBACK` (pokud jsi v transakci) a oprav podmínku. |

---

## 7. Zásady, které si odnes

1. **`INSERT`**: pořadí hodnot odpovídá pořadí sloupců.
2. **`UPDATE` a `DELETE`**: `WHERE` je to nejdůležitější. Bez něj se zasáhnou všechny řádky.
3. **Nejdřív `SELECT`, pak změna.** Podmínku si nejprve vyzkoušej na čtení.
4. **Kontroluj počet řádků**, který příkaz hlásí. Musí odpovídat očekávání.
5. **Při pochybnostech použij transakci**: `BEGIN`, příkaz, kontrola, `COMMIT` nebo `ROLLBACK`.
6. **Nepředpokládej jedinečnost.** Když sloupec není klíč, může mít duplicity (viz názvy témat).

---

## 8. Úkoly na doma / ve cvičení

Vyber si podle chuti. Řešení si zkontroluj `SELECT`em. Pracuj v kopii `moje_sety`.

**INSERT**

1. Vlož novou sadu `MOJE-100` s názvem „Hrad na skále“, rokem 2026 a 500 dílky. Téma nech prázdné.
2. Vlož dvě sady najednou: `MOJE-101` a `MOJE-102`, obě s tématem 246 (Harry Potter).
3. Zkopíruj všechny sady Star Wars (`theme_id = 158`) z roku 2020 s klíčem začínajícím `SW-`.

**UPDATE**

4. Změň název sady `MOJE-100` na „Velký hrad na skále“ a počet dílků na 650.
5. U všech sad `MOJE-%` s tématem 246 zvyš počet dílků o 50.
6. U sad z roku 2019 s nulovým počtem dílků (`num_parts = 0`) nastav `num_parts` na `NULL`, protože počet „nevíme“. *(Nejdřív zjisti, kolik jich je.)*

**DELETE**

7. Smaž sadu `MOJE-102`.
8. Smaž všechny sady, jejichž klíč začíná `K-`.
9. Smaž sady, které mají nulový počet dílků a jsou starší než rok 1970. *(Použij `RETURNING` v transakci.)*

**Zamyšlení**

10. Proč je nebezpečné, že názvy témat nejsou jedinečné? Jak by to mohlo způsobit chybu u `DELETE ... WHERE theme_id = (SELECT ...)`?

---

## 9. Poznámky pro vyučujícího

- **Tempo:** v ideálním případě stačí 60 až 75 minut pro skript a 15 minut na
  úkoly. Pro každý blok navrhuju: *přečtu situaci, studenti předpoví výsledek,
  spustíme, porovnáme.*
- **Hlavní myšlenky na zdůraznění:** WHERE jako nejnebezpečnější část,
  kontrola počtu řádků, a že `SELECT` předchází každé změně.
- **Připravené „pasti“**, které se vyplatí nechat studenty vyzkoušet (jsou ve
  skriptu v komentářích): duplicitní klíč, chybějící `NOT NULL`, nevhodný typ,
  poddotaz s více řádky, příliš dlouhá předpona klíče.
- **Dočasná tabulka je spojená s oknem.** Nejčastější potíž: student otevře nové
  okno nebo se znovu připojí, a `moje_sety` zmizí (`relation "moje_sety" does not
  exist`). Stačí znovu spustit část 0.
- **Přibližné počty řádků** ve skriptu platí pro postupné spuštění od začátku.
  Studenty vede spíš ke kontrole „sedí to s `SELECT`em?“ než k hledání přesného čísla.
- **Navazující téma:** transakce, `COMMIT`/`ROLLBACK` a souběh viz
  [laboratoř o transakcích](../transaction/materialy%20postgresql/laborator-transakce.md).
