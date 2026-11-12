# Logické úlohy — stavíme prezidenta Donalda Trumpa z LEGO

Úlohy pracují se schématem `lego` (PostgreSQL) a s referenční sadou dílků
MOC „President Donald Trump“ (soubor `donald-trump/president-donald-trump.csv`),
kterou si založíte jako tabulku `lego.uspresident` (viz dále). Pojem
„referenční sada“ v zadáních označuje obsah této tabulky.

## Příprava dat: tabulka `lego.uspresident`

Sada obsahuje 37 různých dvojic (dílek, barva), 28 různých dílků, 8 různých barev
a 62 kusů celkem. Žádný řádek není náhradní (`Is Spare = False`).
Sloupec `Part` odpovídá `parts.part_num`, `Color` odpovídá `colors.id`.

Všechna řešení čtou data z tabulky `lego.uspresident` (sloupce `part_num`,
`color_id`, `quantity`, `is_spare`). Tabulku si před řešením úloh vytvoříte
a naplníte skriptem [uspresident.sql](donald-trump/uspresident.sql).

### Spuštění skriptu ve VS Code

1. Otevřete soubor `lego/donald-trump/uspresident.sql` ve VS Code.
2. V rozšíření PostgreSQL se připojte ke své databázi (profil se svým
   přihlašovacím jménem, schéma `lego` musí obsahovat tabulky `parts`
   a `colors`). Připojení vyberte i jako aktivní pro otevřený editor.
3. Spusťte celý skript (ne jen označený řádek): v editoru klikněte pravým
   tlačítkem a zvolte spuštění dotazu (Run/Execute Query), případně použijte
   tlačítko Run v záhlaví editoru. Skript tabulku nejprve zruší, pak ji znovu
   vytvoří a naplní, proto jej lze spustit opakovaně.
4. K tomu je nutné mít právo `CREATE` ve schématu `lego`. Při chybě
   `permission denied for schema lego` kontaktujte vyučujícího.

### Kontrola vytvoření

Poslední příkaz skriptu vypíše kontrolní řádek. Stejnou kontrolu můžete
kdykoli spustit samostatně:

```sql
SELECT COUNT(*)                                   AS radku,
       COUNT(DISTINCT u.part_num)                 AS ruznych_dilku,
       COUNT(DISTINCT u.color_id)                 AS ruznych_barev,
       SUM(u.quantity)                            AS kusu,
       SUM(CASE WHEN u.is_spare THEN 1 ELSE 0 END)         AS nahradnich,
       SUM(CASE WHEN p.part_num IS NULL THEN 1 ELSE 0 END) AS chybi_v_parts,
       SUM(CASE WHEN c.id IS NULL THEN 1 ELSE 0 END)       AS chybi_v_colors
FROM lego.uspresident u
LEFT JOIN lego.parts  p ON p.part_num = u.part_num
LEFT JOIN lego.colors c ON c.id = u.color_id;
```

Správný výsledek je jediný řádek: `37 | 28 | 8 | 62 | 0 | 0 | 0`.

> Řešení úloh byla ověřena nad databází PostgreSQL (schéma `lego`)
> s touto tabulkou; u většiny úloh je uveden zkrácený náhled výsledku.

## Obecná pravidla pro všechny úlohy

- Stavebnice je řádek tabulky `sets`; její inventář má jednu nebo více verzí
  (`inventories.version`). Verze jsou **alternativní podoby téhož inventáře**,
  nikdy je nesčítejte jako součásti jedné stavebnice.
- Počítají se pouze běžné dílky (`is_spare = FALSE`) z `inventory_parts`.
  Dílky podsad (`inventory_sets`) a minifigurek (`inventory_minifigs`) se
  nezahrnují.
- Dílek referenční sady „odpovídá“ řádku inventáře, pokud se shoduje číslo
  dílku **i barva**, pokud zadání výslovně neříká jinak.
- Jak se zachází s verzemi, je výslovně uvedeno v každé úloze.

---

## Úloha 1 — Kolik Trumpa je v jedné krabici?

Pro každou stavebnici, jejíž alespoň jedna verze inventáře obsahuje alespoň
jednu shodu s referenční sadou, vypište v tomto pořadí:

- číslo stavebnice,
- název stavebnice,
- největší počet různých odpovídajících dvojic (dílek, barva), který se
  vyskytuje v jedné verzi inventáře,
- největší celkový počet kusů odpovídajících dílků, který se vyskytuje
  v jedné verzi inventáře,
- počet verzí inventáře, které mají s referenční sadou alespoň jednu shodu.

**Verze:** každou verzi inventáře nejprve posuzujte samostatně; maxima se pak
berou přes verze téže stavebnice. Maximum počtu dvojic a maximum počtu kusů
se určují nezávisle, mohou tedy pocházet z různých verzí. Verze se nesčítají.
Každou stavebnici uveďte jednou.

Výsledek seřaďte sestupně podle největšího počtu dvojic, při shodě sestupně
podle největšího počtu kusů a nakonec vzestupně podle čísla stavebnice.
Vypište prvních 10 řádků.

### Procvičované dovednosti

- mezivýsledek na úrovni verze (CTE), agregace nad ním na úrovni stavebnice,
- `COUNT(DISTINCT ...)` nad dvojicí hodnot,
- rozlišení „podmínka na záznam“ a „podmínka na souhrn“,
- spojení dvou množin (referenční sada × inventáře).

### Řešení

```sql
WITH shody_verzi AS (
    SELECT i.set_num,
           i.id AS inventory_id,
           COUNT(DISTINCT (ip.part_num, ip.color_id)) AS typy,
           SUM(ip.quantity)                           AS kusy
    FROM lego.inventories i
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = i.id
    JOIN lego.uspresident r
      ON r.part_num = ip.part_num
     AND r.color_id = ip.color_id
    WHERE NOT ip.is_spare
    GROUP BY i.set_num, i.id
)
SELECT s.set_num,
       s.name,
       MAX(sv.typy) AS max_dvojic,
       MAX(sv.kusy) AS max_kusu,
       COUNT(*)     AS pocet_verzi_se_shodou
FROM shody_verzi sv
JOIN lego.sets s
  ON s.set_num = sv.set_num
GROUP BY s.set_num, s.name
ORDER BY max_dvojic DESC, max_kusu DESC, s.set_num
LIMIT 10;
```

---

## Úloha 2 — Vzácné součástky Trumpova vzhledu

Pro každou dvojici (dílek, barva) z referenční sady zjistěte, v kolika různých
stavebnicích se vyskytuje. Vypište pouze dvojice, které se vyskytují
v **méně** stavebnicích, než je průměr počtu výskytů přes všech 37 dvojic
referenční sady. Vypište v tomto pořadí: číslo dílku, název dílku, název barvy
a počet stavebnic.

**Verze:** zahrnujte všechny verze inventářů; stavebnici počítejte u každé
dvojice nejvýše jednou, bez ohledu na to, v kolika verzích se dvojice objevila.

Dvojice, která se nevyskytuje v žádné stavebnici, má počet roven nule a do
průměru vstupuje s touto nulou. Výsledek seřaďte vzestupně podle počtu
stavebnic, poté podle čísla dílku a názvu barvy.

### Procvičované dovednosti

- zachování prvků množiny bez výskytu (`LEFT JOIN`), nula místo chybějící hodnoty,
- skalární poddotaz s průměrem z mezivýsledku,
- filtrování podle hotového souhrnu,
- `COUNT(DISTINCT ...)` při opakovaném výskytu přes verze.

### Řešení

```sql
WITH vyskyt AS (
    SELECT r.part_num,
           r.color_id,
           COUNT(DISTINCT i.set_num) AS pocet_stavebnic
    FROM lego.uspresident r
    LEFT JOIN lego.inventory_parts ip
           ON ip.part_num = r.part_num
          AND ip.color_id = r.color_id
          AND NOT ip.is_spare
    LEFT JOIN lego.inventories i
           ON i.id = ip.inventory_id
    GROUP BY r.part_num, r.color_id
)
SELECT v.part_num,
       p.name AS dilek,
       c.name AS barva,
       v.pocet_stavebnic
FROM vyskyt v
JOIN lego.parts  p ON p.part_num = v.part_num
JOIN lego.colors c ON c.id = v.color_id
WHERE v.pocet_stavebnic < (SELECT AVG(pocet_stavebnic) FROM vyskyt)
ORDER BY v.pocet_stavebnic, v.part_num, c.name;
```

---

## Úloha 3 — Z jakých kategorií je Trump poskládán

Pro každou kategorii dílků (`part_categories`), ze které referenční sada
používá alespoň 2 různé dílky, vypište v tomto pořadí:

- název kategorie,
- počet různých dílků referenční sady z této kategorie,
- celkový počet kusů těchto dílků v referenční sadě,
- podíl těchto kusů na všech 62 kusech referenční sady v procentech,
  zaokrouhlený na jedno desetinné místo,
- počet všech dílků dané kategorie evidovaných v tabulce `parts`.

**Verze:** úloha se týká pouze referenční sady a katalogu dílků, inventáře
stavebnic ani jejich verze se v ní nepoužívají. Počet 62 nezadávejte pevně,
spočtěte ho z referenční sady.

Výsledek seřaďte sestupně podle počtu kusů a při shodě vzestupně podle názvu
kategorie.

### Procvičované dovednosti

- agregace na úrovni kategorie nad spojením malé a velké množiny,
- skalární poddotaz pro celek (podíl),
- korelovaný poddotaz na počet dílků v kategorii,
- podmínka na souhrn (`HAVING` / filtr nad CTE).

### Řešení

```sql
WITH kategorie AS (
    SELECT pc.id,
           pc.name,
           COUNT(DISTINCT r.part_num) AS typy,
           SUM(r.quantity)            AS kusy
    FROM lego.uspresident r
    JOIN lego.parts p
      ON p.part_num = r.part_num
    JOIN lego.part_categories pc
      ON pc.id = p.part_cat_id
    GROUP BY pc.id, pc.name
)
SELECT k.name AS kategorie,
       k.typy AS pocet_dilku_sady,
       k.kusy AS pocet_kusu,
       ROUND(100.0 * k.kusy / (SELECT SUM(quantity) FROM lego.uspresident), 1) AS podil_procent,
       (SELECT COUNT(*) FROM lego.parts p WHERE p.part_cat_id = k.id) AS dilku_v_katalogu
FROM kategorie k
WHERE k.typy >= 2
ORDER BY k.kusy DESC, k.name;
```

---

## Úloha 4 — Které barvy Trumpa se potkávají

Uvažujte pouze 8 barev, které se vyskytují v referenční sadě. Pro každou
neuspořádanou dvojici těchto barev (každou dvojici uveďte jednou, například
tak, že `id` první barvy je menší než `id` druhé) vypište:

- název první barvy,
- název druhé barvy,
- počet stavebnic, v jejichž inventáři se vyskytuje alespoň jeden dílek
  odpovídající referenční sadě (dílek **a** barva) v první barvě **a zároveň**
  alespoň jeden takový dílek ve druhé barvě. Může jít o různé dílky.

**Verze:** zahrnujte všechny verze inventářů. Barvy se mohou objevit v různých
verzích téže stavebnice; stavebnice se považuje za vyhovující, pokud se obě
barvy objeví v libovolných verzích (každou stavebnici počítejte nejvýše jednou).

Dvojice barev, které se spolu nepotkaly v žádné stavebnici, zachovejte s počtem
nula. Výsledek seřaďte sestupně podle počtu stavebnic a poté vzestupně podle
názvů barev.

### Procvičované dovednosti

- varianta věty o členství d) — jedna podmínka někde ve skupině a druhá také,
- rozlišení rolí téže tabulky (barva jako první a druhá),
- zachování dvojic bez výskytu, `COUNT(sloupec)` vs. `COUNT(*)`,
- tvorba dvojic z jedné množiny.

### Řešení

```sql
WITH barvy_ref AS (
    SELECT DISTINCT color_id FROM lego.uspresident
),
dvojice AS (
    SELECT a.color_id AS c1, b.color_id AS c2
    FROM barvy_ref a
    JOIN barvy_ref b
      ON a.color_id < b.color_id
),
barvy_sad AS (
    SELECT DISTINCT i.set_num, r.color_id
    FROM lego.inventories i
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = i.id
     AND NOT ip.is_spare
    JOIN lego.uspresident r
      ON r.part_num = ip.part_num
     AND r.color_id = ip.color_id
)
SELECT ca.name AS barva_1,
       cb.name AS barva_2,
       COUNT(y.set_num) AS pocet_stavebnic
FROM dvojice d
JOIN lego.colors ca ON ca.id = d.c1
JOIN lego.colors cb ON cb.id = d.c2
LEFT JOIN barvy_sad x
       ON x.color_id = d.c1
LEFT JOIN barvy_sad y
       ON y.set_num = x.set_num
      AND y.color_id = d.c2
GROUP BY d.c1, d.c2, ca.name, cb.name
ORDER BY pocet_stavebnic DESC, ca.name, cb.name;
```

---

## Úloha 5 — Skoro kompletní Trump

Žádná verze inventáře neobsahuje všech 28 různých dílků referenční sady,
ale některé se tomu blíží. Najděte všechny dvojice (stavebnice, verze
inventáře), kterým chybí **nejvýše 3** různé dílky referenční sady. Dílek se
posuzuje pouze podle čísla, v libovolné barvě a v libovolném množství
(stačí 1 běžný kus). Vypište v tomto pořadí: číslo stavebnice, název
stavebnice, číslo verze a počet chybějících dílků.

**Verze:** každou verzi inventáře posuzujte samostatně. Stavebnice se může
objevit vícekrát, pokud vyhovuje více jejích verzí. Dílky z různých verzí se
nekombinují.

Výsledek seřaďte vzestupně podle počtu chybějících dílků, poté podle čísla
stavebnice a verze.

### Procvičované dovednosti

- rozdíl množin (dílky referenční sady, které inventář nemá),
- kartézský součin inventářů s množinou dílků a `NOT EXISTS`,
- podmínka na souhrn (`HAVING`),
- odstranění duplicit (`DISTINCT` na dílcích bez barvy).

### Řešení

```sql
WITH ref_dily AS (
    SELECT DISTINCT part_num FROM lego.uspresident
)
SELECT s.set_num,
       s.name,
       i.version,
       COUNT(*) AS chybi_typu
FROM lego.inventories i
CROSS JOIN ref_dily r
JOIN lego.sets s
  ON s.set_num = i.set_num
WHERE NOT EXISTS (
    SELECT 1
    FROM lego.inventory_parts ip
    WHERE ip.inventory_id = i.id
      AND ip.part_num = r.part_num
      AND NOT ip.is_spare
)
GROUP BY s.set_num, s.name, i.id, i.version
HAVING COUNT(*) <= 3
ORDER BY chybi_typu, s.set_num, i.version;

-- Náhled výsledku: celkem 8 řádků; zobrazeno prvních 3.
-- | set_num | name | version | chybi_typu |
-- | 71861-1 | The Old Town 15th Anniversary | 1 | 2 |
-- | 72153-1 | Venusaur, Charizard and Blastoise | 1 | 2 |
-- | 10352-1 | The Simpsons: Krusty Burger | 1 | 3 |
```

---

## Úloha 6 — Největší zásobárna každého kousku

Pro každou dvojici (dílek, barva) z referenční sady zjistěte největší
množství tohoto dílku v dané barvě, které se vyskytuje v **jedné verzi**
inventáře některé stavebnice (běžné dílky). Vypište v tomto pořadí:
číslo dílku, název barvy, množství potřebné v referenční sadě, největší
nalezené množství, celočíselný násobek (největší množství děleno potřebným,
dolů), počet dvojic (stavebnice, verze), které tohoto maxima dosahují,
a nejmenší číslo stavebnice (podle abecedního řazení) mezi nimi.

**Verze:** každá dvojice (stavebnice, verze) je samostatný kandidát. Maximum se
hledá přes všechny verze všech stavebnic; verze téže stavebnice se
neslučují ani nesčítají. Pokud dvě verze téže stavebnice dosáhnou stejného
maxima, počítají se obě.

Dvojice, která se nevyskytuje v žádné stavebnici, ve výsledku nebude.
Výsledek seřaďte sestupně podle násobku, poté podle čísla dílku a názvu barvy.

### Procvičované dovednosti

- extrém ve skupině a započtení všech remíz,
- spojení hotového maxima zpět s mezivýsledkem,
- mezivýsledek na úrovni verze,
- práce s dvojicí hodnot jako klíčem skupiny.

### Řešení

```sql
WITH mnozstvi AS (
    SELECT r.part_num,
           r.color_id,
           i.set_num,
           i.version,
           ip.quantity
    FROM lego.uspresident r
    JOIN lego.inventory_parts ip
      ON ip.part_num = r.part_num
     AND ip.color_id = r.color_id
     AND NOT ip.is_spare
    JOIN lego.inventories i
      ON i.id = ip.inventory_id
),
maxima AS (
    SELECT part_num, color_id, MAX(quantity) AS max_mnozstvi
    FROM mnozstvi
    GROUP BY part_num, color_id
)
SELECT r.part_num,
       c.name AS barva,
       r.quantity AS potreba,
       mx.max_mnozstvi,
       mx.max_mnozstvi / r.quantity AS nasobek,
       COUNT(*) AS pocet_verzi_s_maximem,
       MIN(m.set_num) AS prvni_stavebnice
FROM lego.uspresident r
JOIN maxima mx
  ON mx.part_num = r.part_num
 AND mx.color_id = r.color_id
JOIN mnozstvi m
  ON m.part_num = r.part_num
 AND m.color_id = r.color_id
 AND m.quantity = mx.max_mnozstvi
JOIN lego.colors c
  ON c.id = r.color_id
GROUP BY r.part_num, r.color_id, c.name, r.quantity, mx.max_mnozstvi
ORDER BY nasobek DESC, r.part_num, c.name;

-- Náhled výsledku: zobrazeny první 3 řádky.
-- | part_num | barva | potreba | max_mnozstvi | nasobek | pocet_verzi_s_maximem | prvni_stavebnice |
-- | 3024 | White | 2 | 1440 | 720 | 1 | k34432-1 |
-- | 3024 | Black | 2 | 900 | 450 | 1 | 40179-1 |
-- | 6141 | Dark Red | 2 | 503 | 251 | 1 | 31201-1 |
```

---

## Úloha 7 — Stavebnice se všemi Trumpovými barvami

Najděte stavebnice, jejichž **nejvyšší verze** inventáře obsahuje běžné dílky
ve všech 8 barvách referenční sady (barva se posuzuje samostatně, nemusí jít
o dílky z referenční sady). Pro každou takovou stavebnici vypište v tomto
pořadí: číslo stavebnice, název stavebnice, počet barev, které referenční sada
nepoužívá.

**Verze:** pro každou stavebnici uvažujte pouze verzi inventáře s nejvyšším
číslem `version`; ostatní verze ignorujte, i kdyby obsahovaly více barev.

Výsledek seřaďte vzestupně podle počtu přebývajících barev (nejméně přebytku
první) a poté podle čísla stavebnice. Vypište prvních 10 řádků.

### Procvičované dovednosti

- výběr jediné (poslední) verze korelovaným poddotazem,
- relační dělení přes `COUNT(DISTINCT ...) = (SELECT COUNT(*) ...)`,
- rozdíl množin (barvy navíc),
- `LEFT JOIN` pro rozlišení barev uvnitř a mimo referenční množinu.

### Řešení

```sql
WITH nejvyssi AS (
    SELECT i.id, i.set_num
    FROM lego.inventories i
    WHERE i.version = (
        SELECT MAX(i2.version)
        FROM lego.inventories i2
        WHERE i2.set_num = i.set_num
    )
),
barvy_ref AS (
    SELECT DISTINCT color_id FROM lego.uspresident
)
SELECT s.set_num,
       s.name,
       COUNT(DISTINCT ip.color_id) - COUNT(DISTINCT b.color_id) AS barev_navic
FROM nejvyssi n
JOIN lego.sets s
  ON s.set_num = n.set_num
JOIN lego.inventory_parts ip
  ON ip.inventory_id = n.id
 AND NOT ip.is_spare
LEFT JOIN barvy_ref b
       ON b.color_id = ip.color_id
GROUP BY s.set_num, s.name
HAVING COUNT(DISTINCT b.color_id) = (SELECT COUNT(*) FROM barvy_ref)
ORDER BY barev_navic, s.set_num
LIMIT 10;
```

---

## Úloha 8 — Malé stavebnice, velká pestrost

Uvažujte stavebnice, jejichž inventář (alespoň jedna verze) obsahuje alespoň
jednu shodu s referenční sadou. Z nich vyberte ty, ve kterých **žádná verze
inventáře** nemá více než 60 různých typů dílků (`part_num`, běžné dílky).
Pro každou takovou stavebnici vypište: číslo stavebnice, název, rok vydání,
největší počet různých typů dílků v jedné verzi a největší počet různých
barev v jedné verzi.

**Verze:** na vyloučení stavebnice rozhoduje **každá** verze (stačí, aby jedna
měla víc než 60 typů a stavebnice odpadá). Maxima typů a barev se určují přes
verze nezávisle. Verze se nesčítají.

Výsledek seřaďte sestupně podle největšího počtu barev, poté vzestupně podle
čísla stavebnice. Vypište prvních 10 řádků.

### Procvičované dovednosti

- univerzální podmínka přes verze (`HAVING MAX(...) <= ...`),
- kombinace dvou množin: stavebnice se shodou × všechny jejich verze,
- `IN` s poddotazem,
- `COUNT(DISTINCT ...)` na úrovni verze.

### Řešení

```sql
WITH verze AS (
    SELECT i.set_num,
           i.id,
           COUNT(DISTINCT ip.part_num) AS typy,
           COUNT(DISTINCT ip.color_id) AS barvy
    FROM lego.inventories i
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = i.id
     AND NOT ip.is_spare
    GROUP BY i.set_num, i.id
)
SELECT s.set_num,
       s.name,
       s.year,
       MAX(v.typy)  AS max_typu,
       MAX(v.barvy) AS max_barev
FROM verze v
JOIN lego.sets s
  ON s.set_num = v.set_num
WHERE v.set_num IN (
    SELECT i.set_num
    FROM lego.inventories i
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = i.id
     AND NOT ip.is_spare
    JOIN lego.uspresident r
      ON r.part_num = ip.part_num
     AND r.color_id = ip.color_id
)
GROUP BY s.set_num, s.name, s.year
HAVING MAX(v.typy) <= 60
ORDER BY max_barev DESC, s.set_num
LIMIT 10;
```

---

## Úloha 9 — Co Trumpovi chybí do kompletu

Uvažujte stavebnice, jejichž **nejvyšší verze** inventáře obsahuje alespoň
jeden dílek odpovídající referenční sadě. Pro každou takovou stavebnici
spočtěte:

- počet dvojic (dílek, barva) referenční sady, které inventář pokrývá
  v dostatečném množství (množství v inventáři je alespoň tak velké jako
  v referenční sadě),
- celkový počet kusů, které by do kompletní referenční sady chyběly
  (u každé dvojice chybí `max(potřeba − má, 0)` kusů; dvojice, která
  v inventáři není, má `má = 0`).

Vypište stavebnice s alespoň 14 plně pokrytými dvojicemi. Vypište v tomto
pořadí: číslo stavebnice, název, počet plně pokrytých dvojic, počet chybějících
kusů. Seřaďte vzestupně podle počtu chybějících kusů a poté podle čísla
stavebnice. Vypište prvních 10 řádků.

**Verze:** pro každou stavebnici uvažujte pouze nejvyšší verzi inventáře;
ostatní verze ignorujte.

### Procvičované dovednosti

- kartézský součin kandidátů s referenční sadou a následný `LEFT JOIN`,
- nula místo chybějící hodnoty (`COALESCE`),
- podmíněné souhrny (`SUM(CASE WHEN ... THEN ... ELSE ... END)`),
- poslední verze korelovaným poddotazem.

### Řešení

```sql
WITH nejvyssi AS (
    SELECT i.id, i.set_num
    FROM lego.inventories i
    WHERE i.version = (
        SELECT MAX(i2.version)
        FROM lego.inventories i2
        WHERE i2.set_num = i.set_num
    )
),
kandidati AS (
    SELECT DISTINCT n.id, n.set_num
    FROM nejvyssi n
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = n.id
     AND NOT ip.is_spare
    JOIN lego.uspresident r
      ON r.part_num = ip.part_num
     AND r.color_id = ip.color_id
),
potreba AS (
    SELECT k.set_num,
           r.quantity AS chce,
           COALESCE(ip.quantity, 0) AS ma
    FROM kandidati k
    CROSS JOIN lego.uspresident r
    LEFT JOIN lego.inventory_parts ip
           ON ip.inventory_id = k.id
          AND ip.part_num = r.part_num
          AND ip.color_id = r.color_id
          AND NOT ip.is_spare
)
SELECT s.set_num,
       s.name,
       SUM(CASE WHEN p.ma >= p.chce THEN 1 ELSE 0 END) AS plne_pokryte_dvojice,
       SUM(CASE WHEN p.chce > p.ma THEN p.chce - p.ma ELSE 0 END) AS chybi_kusu
FROM potreba p
JOIN lego.sets s
  ON s.set_num = p.set_num
GROUP BY s.set_num, s.name
HAVING SUM(CASE WHEN p.ma >= p.chce THEN 1 ELSE 0 END) >= 14
ORDER BY chybi_kusu, s.set_num
LIMIT 10;

-- Náhled výsledku: celkem 5 řádků; zobrazeny první 3.
-- | set_num | name | plne_pokryte_dvojice | chybi_kusu |
-- | 910059-1 | Privateer Frigate Fortuna | 15 | 30 |
-- | 71799-1 | NINJAGO City Markets | 14 | 33 |
-- | 72165-1 | Umbreon vs. Garchomp Championship Battle | 16 | 34 |
```

---

## Úloha 10 — Do jakých témat Trump proniká

Hierarchie témat má nejvýše 3 úrovně (kořen, podtéma, pod-podtéma).
Pro každé kořenové téma (`themes.parent_id IS NULL`) vypište:

- název kořenového tématu,
- počet všech stavebnic patřících do tohoto tématu nebo libovolného jeho
  podtématu,
- počet z nich, jejichž inventář obsahuje alespoň jednu shodu s referenční
  sadou (dílek **a** barva),
- podíl těchto stavebnic na všech stavebnicích tématu v procentech,
  zaokrouhlený na 2 desetinná místa.

Vypište pouze témata s alespoň jednou takovou stavebnicí. Stavebnice bez
přiřazeného tématu (`theme_id IS NULL`) se neuvažují.

**Verze:** zahrnujte všechny verze inventářů; stavebnice vyhovuje, pokud shodu
obsahuje libovolná její verze, a počítá se právě jednou.

Výsledek seřaďte sestupně podle počtu stavebnic se shodou a poté vzestupně
podle názvu tématu. Vypište prvních 8 řádků.

### Procvičované dovednosti

- určení kořene hierarchie pevným počtem samospojení (bez rekurze),
- zachování stavebnic bez shody (`LEFT JOIN`) a rozdíl `COUNT(*)` vs. `COUNT(sloupec)`,
- `DISTINCT` v mezivýsledku pro jednorázové započtení stavebnice,
- podmínka na souhrn (`HAVING`).

### Řešení

```sql
WITH koren AS (
    SELECT th.id,
           COALESCE(g.id, p.id, th.id) AS koren_id
    FROM lego.themes th
    LEFT JOIN lego.themes p
           ON p.id = th.parent_id
    LEFT JOIN lego.themes g
           ON g.id = p.parent_id
),
se_shodou AS (
    SELECT DISTINCT i.set_num
    FROM lego.inventories i
    JOIN lego.inventory_parts ip
      ON ip.inventory_id = i.id
     AND NOT ip.is_spare
    JOIN lego.uspresident r
      ON r.part_num = ip.part_num
     AND r.color_id = ip.color_id
)
SELECT rt.name AS tema,
       COUNT(*) AS pocet_stavebnic,
       COUNT(sh.set_num) AS stavebnic_se_shodou,
       ROUND(100.0 * COUNT(sh.set_num) / COUNT(*), 2) AS podil_procent
FROM lego.sets s
JOIN koren k
  ON k.id = s.theme_id
JOIN lego.themes rt
  ON rt.id = k.koren_id
LEFT JOIN se_shodou sh
       ON sh.set_num = s.set_num
GROUP BY rt.id, rt.name
HAVING COUNT(sh.set_num) > 0
ORDER BY stavebnic_se_shodou DESC, rt.name
LIMIT 8;

-- Náhled výsledku: zobrazeny první 4 řádky.
-- | tema | pocet_stavebnic | stavebnic_se_shodou | podil_procent |
-- | City | 1019 | 367 | 36.02 |
-- | Star Wars | 1101 | 342 | 31.06 |
-- | Creator | 637 | 309 | 48.51 |
-- | Town | 679 | 284 | 41.83 |
```

---

## Přehled úloh

| # | Techniky | Zacházení s verzemi |
|---|----------|---------------------|
| 1 | CTE na úrovni verze, `MAX` přes verze | každá verze zvlášť, maxima přes verze, bez součtu |
| 2 | `LEFT JOIN`, průměr v poddotazu | všechny verze, stavebnice jednou |
| 3 | skalární a korelovaný poddotaz, podíl | verze se nepoužívají |
| 4 | věta d), páry barev, nuly | všechny verze, stavebnice jednou |
| 5 | rozdíl množin, kartézský součin, `NOT EXISTS` | každá verze samostatně, bez kombinování |
| 6 | extrém s remízami, spojení maxima zpět | každá (stavebnice, verze) samostatná |
| 7 | dělení přes `COUNT`, rozdíl množin | pouze nejvyšší verze |
| 8 | univerzální podmínka přes verze, `IN` | všechny verze, rozhoduje každá |
| 9 | kartézský součin, `SUM(CASE ...)`, `COALESCE` | pouze nejvyšší verze |
| 10 | kořen hierarchie samospojením, `COUNT(sloupec)` | všechny verze, stavebnice jednou |
