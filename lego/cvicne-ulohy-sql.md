# Cvičné úlohy SQL

Úlohy jsou určeny k procvičení práce s relačními daty nad schématem `lego`.
U každé úlohy je uvedeno řešení v PostgreSQL.

## Úloha 1 — Barevná pestrost kategorií

Pro každou kategorii dílků vypište:

- název kategorie,
- počet různých stavebnic, v jejichž inventářích se objevil alespoň jeden
  dílek dané kategorie,
- počet různých barev, ve kterých se dílky této kategorie v těchto
  inventářích objevily.

Do výsledku zahrňte i kategorie, které se v žádné stavebnici nevyskytují.
Taková kategorie má mít oba počty rovny nule. Každou stavebnici a každou barvu
počítejte v rámci kategorie nejvýše jednou; zahrňte všechny verze inventářů
stavebnic. Výsledek seřaďte sestupně podle
počtu stavebnic a při shodě vzestupně podle názvu kategorie.

### Procvičované dovednosti

- spojení více tabulek,
- zachování kategorií bez výskytu pomocí vnějšího spojení,
- `COUNT(DISTINCT ...)`,
- správné seskupení a řazení podle agregované hodnoty.

### Řešení

```sql
WITH vyskyt_kategorii AS (
    SELECT DISTINCT
           pc.id AS category_id,
           s.set_num,
           ip.color_id
    FROM lego.part_categories pc
    JOIN lego.parts p
      ON p.part_cat_id = pc.id
    JOIN lego.inventory_parts ip
      ON ip.part_num = p.part_num
    JOIN lego.inventories i
      ON i.id = ip.inventory_id
    JOIN lego.sets s
      ON s.set_num = i.set_num
)
SELECT pc.name AS kategorie,
       COUNT(DISTINCT vk.set_num) AS pocet_stavebnic,
       COUNT(DISTINCT vk.color_id) AS pocet_barev
FROM lego.part_categories pc
LEFT JOIN vyskyt_kategorii vk
  ON vk.category_id = pc.id
GROUP BY pc.id, pc.name
ORDER BY pocet_stavebnic DESC, pc.name;

-- Náhled výsledku: celkem 76 řádků; zobrazeno prvních 5.
-- | kategorie | pocet_stavebnic | pocet_barev |
-- | Plates | 12013 | 98 |
-- | Plates Special | 11714 | 88 |
-- | Bricks | 10095 | 106 |
-- | Bricks Sloped | 9964 | 83 |
-- | Plates Round Curved and Dishes | 9870 | 96 |
```

## Úloha 2 — Středně rozšířené barvy a jejich výskyt

Pro každou barvu, u níž je evidovaný celkový počet dílků (`num_parts`)
v rozsahu od 1000 do 5000 včetně, vypište v tomto pořadí:

- název barvy,
- celkové množství běžných dílků této barvy ve stavebnicích vydaných
  v letech 2000 až 2010 včetně, a to přes všechny verze jejich inventářů;
  běžný dílek je řádek inventáře s `is_spare = FALSE`, na rozdíl od
  náhradního dílku s `is_spare = TRUE`,
- počet různých stavebnic, v jejichž inventáři se tato barva objevuje,
  přičemž postačí libovolná verze inventáře,
- počet elementů evidovaných pro danou barvu.

Vypište pouze barvy, u kterých je počet elementů větší než 20 nebo celkové
množství běžných dílků větší než 500. Pokud se barva v požadovaných
inventářích nevyskytuje, zobrazte místo součtu nulu. Výsledek seřaďte
vzestupně podle názvu barvy.

### Procvičované dovednosti

- korelované dílčí výpočty,
- `COALESCE` u součtu nad prázdnou množinou,
- rozlišení `SUM` a `COUNT(DISTINCT ...)`,
- filtrování podle hodnoty vypočtené pro aktuální řádek.

### Řešení

```sql
SELECT c.name AS barva,
       (
           SELECT COALESCE(SUM(ip.quantity), 0)
           FROM lego.inventory_parts ip
           JOIN lego.inventories i
             ON i.id = ip.inventory_id
           JOIN lego.sets s
             ON s.set_num = i.set_num
           WHERE ip.color_id = c.id
             AND ip.is_spare = FALSE
             AND s.year BETWEEN 2000 AND 2010
       ) AS bezne_dilky_2000_2010,
       (
           SELECT COUNT(DISTINCT i.set_num)
           FROM lego.inventory_parts ip
           JOIN lego.inventories i
             ON i.id = ip.inventory_id
           JOIN lego.sets s
             ON s.set_num = i.set_num
           WHERE ip.color_id = c.id
       ) AS pocet_stavebnic,
       (
           SELECT COUNT(*)
           FROM lego.elements e
           WHERE e.color_id = c.id
       ) AS pocet_elementu
FROM lego.colors c
WHERE c.num_parts BETWEEN 1000 AND 5000
  AND (
      (
          SELECT COALESCE(SUM(ip.quantity), 0)
          FROM lego.inventory_parts ip
          JOIN lego.inventories i
            ON i.id = ip.inventory_id
          JOIN lego.sets s
            ON s.set_num = i.set_num
          WHERE ip.color_id = c.id
            AND ip.is_spare = FALSE
            AND s.year BETWEEN 2000 AND 2010
      ) > 500
      OR
      (
          SELECT COUNT(*)
          FROM lego.elements e
          WHERE e.color_id = c.id
      ) > 20
  )
ORDER BY c.name;

-- Náhled výsledku: celkem 13 řádků; zobrazeno prvních 5.
-- | barva | bezne_dilky_2000_2010 | pocet_stavebnic | pocet_elementu |
-- | Chrome Gold | 1100 | 283 | 51 |
-- | Chrome Silver | 743 | 414 | 86 |
-- | Medium Dark Pink | 408 | 130 | 204 |
-- | Metallic Gold | 158 | 357 | 169 |
-- | Metallic Silver | 1028 | 778 | 259 |
```

## Úloha 3 — Nejnovější stavebnice v podtématech

Najděte přímá podtémata kořenového tématu `City` (tedy tématu, které nemá
nadřazené téma, `parent_id IS NULL`). Pro každé takové podtéma
vypište všechny stavebnice, které mají v daném podtématu nejvyšší rok vydání.
Při shodě nejvyššího roku vypište všechny odpovídající stavebnice.

U každé vypsané stavebnice dále uveďte název podtématu, číslo stavebnice,
název stavebnice, rok vydání a počet různých kategorií dílků, které se
objeví alespoň v jedné verzi jejího inventáře. Podtéma bez stavebnic do
výsledku nezařazujte. Výsledek seřaďte vzestupně podle názvu podtématu a
čísla stavebnice.

### Procvičované dovednosti

- jednoúrovňová hierarchie,
- hledání maxima v rámci skupiny,
- zachování všech remíz,
- korelovaný dílčí počet přes více verzí,
- `COUNT(DISTINCT ...)`.

### Řešení

```sql
SELECT podtema.name AS podtema,
       s.set_num,
       s.name AS stavebnice,
       s.year,
       (
           SELECT COUNT(DISTINCT p.part_cat_id)
           FROM lego.inventories i
           JOIN lego.inventory_parts ip
             ON ip.inventory_id = i.id
           JOIN lego.parts p
             ON p.part_num = ip.part_num
           WHERE i.set_num = s.set_num
       ) AS pocet_kategorii
FROM lego.themes koren
JOIN lego.themes podtema
  ON podtema.parent_id = koren.id
JOIN lego.sets s
  ON s.theme_id = podtema.id
WHERE koren.name = 'City'
  AND koren.parent_id IS NULL
  AND s.year = (
      SELECT MAX(s2.year)
      FROM lego.sets s2
      WHERE s2.theme_id = podtema.id
  )
ORDER BY podtema.name, s.set_num;

-- Náhled výsledku: celkem 54 řádků; zobrazeno prvních 5.
-- | podtema | set_num | stavebnice | year | pocet_kategorii |
-- | Airport | 60492-1 | Passenger Jet | 2026 | 19 |
-- | Airport | 60499-1 | Airport Fire Truck | 2026 | 32 |
-- | Airport | 60502-1 | Airport with Airplane | 2026 | 36 |
-- | Arctic | 60470-1 | Explorer Train | 2025 | 42 |
-- | Arctic | 60471-1 | Arctic Explorer Science Lab Truck | 2025 | 40 |
```

## Úloha 4 — Kategorie zastoupené v celé skupině

Najděte kategorie dílků, které se objeví alespoň v jednom inventáři některé
stavebnice z **každého přímého podtématu** kořenového tématu `City` (tedy
tématu, které nemá nadřazené téma, `parent_id IS NULL`). Posuzujte jen
podtémata, do kterých je přímo zařazena alespoň jedna stavebnice a alespoň
jeden její inventář.

Vypište název kategorie a počet podtémat, ve kterých byla kategorie zjištěna.
Každé podtéma započítejte pouze jednou bez ohledu na počet stavebnic, verzí
inventáře nebo jednotlivých výskytů kategorie. Pokud kořenové téma nemá žádné
neprázdné přímé podtéma, nemá úloha vracet žádnou kategorii. Výsledek seřaďte
vzestupně podle názvu kategorie.

### Procvičované dovednosti

- relační dělení, tedy podmínka „pro každou skupinu“,
- rozlišení podtématu, stavebnice a jejích více inventářů,
- `COUNT(DISTINCT ...)`,
- porovnání počtu vyhovujících skupin s celkovým počtem skupin,
- ošetření prázdné skupiny.

### Řešení

```sql
WITH cilova_podtemata AS (
    SELECT podtema.id
    FROM lego.themes koren
    JOIN lego.themes podtema
      ON podtema.parent_id = koren.id
    WHERE koren.name = 'City'
      AND koren.parent_id IS NULL
      AND EXISTS (
          SELECT 1
          FROM lego.sets s
          JOIN lego.inventories i
            ON i.set_num = s.set_num
          WHERE s.theme_id = podtema.id
      )
),
kategorie_podtemat AS (
    SELECT DISTINCT
           p.part_cat_id,
           s.theme_id
    FROM lego.parts p
    JOIN lego.inventory_parts ip
      ON ip.part_num = p.part_num
    JOIN lego.inventories i
      ON i.id = ip.inventory_id
    JOIN lego.sets s
      ON s.set_num = i.set_num
    JOIN cilova_podtemata cp
      ON cp.id = s.theme_id
)
SELECT pc.name AS kategorie,
       COUNT(DISTINCT kp.theme_id) AS pocet_podtemat
FROM lego.part_categories pc
JOIN kategorie_podtemat kp
  ON kp.part_cat_id = pc.id
GROUP BY pc.id, pc.name
HAVING COUNT(DISTINCT kp.theme_id) = (
    SELECT COUNT(*)
    FROM cilova_podtemata
)
   AND (
       SELECT COUNT(*)
       FROM cilova_podtemata
   ) > 0
ORDER BY pc.name;

-- Náhled výsledku: celkem 32 řádků; zobrazeno prvních 5.
-- | kategorie | pocet_podtemat |
-- | Bars, Ladders and Fences | 17 |
-- | Bricks | 17 |
-- | Bricks Curved | 17 |
-- | Bricks Round and Cones | 17 |
-- | Bricks Sloped | 17 |
```

## Kontrolní otázky k řešení

Před odevzdáním každého dotazu si ověřte:

- Co představuje jeden řádek výsledku?
- Nezpůsobí spojení více verzí nebo více položek nechtěné násobení řádků?
- Má se něco počítat jednou pro každou skupinu, nebo jednou za celou úlohu?
- Musí být podmínka splněna jedním konkrétním členem, některým členem,
  nebo všemi členy?
- Co se má stát, pokud skupina nemá žádné související záznamy?
- Zachovají se všechny řádky při shodě nejvyšší hodnoty?
