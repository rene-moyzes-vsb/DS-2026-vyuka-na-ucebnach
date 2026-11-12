# Evidence databáze pro sdílení nákladů na výlety

## Příběhové zadání

Jmenuji se Anna a vedu skautský oddíl. Na výlety jezdíme v různém složení a po návratu často není jasné, kdo má kolik doplatit. Výdaje platíme na různých místech, účtenky se schovají v batohu nebo v mobilu a částky nakonec sčítám ručně.

Nedávno jsme jeli na víkend do Prahy od 16. do 18. května. Jeli jsme tři: já, David a Eva. Předem jsem odhadla rozpočet na 8 000 Kč. Ubytování stálo 4 800 Kč, doprava 1 200 Kč a společné jídlo 1 800 Kč. Výdaje se nedělí vždy rovným dílem, proto chci u každého určit podíl jednotlivých účastníků. Tentokrát jsme celkových 7 800 Kč rozdělili mezi Davida a Evu, každému po 3 900 Kč; jako vedoucí náklady nenesu.

Do společné kasy jsem vložila 3 000 Kč, David zaplatil 2 000 Kč a Eva 2 800 Kč. Platbu chci nejprve zaznamenat jako nepotvrzenou a započítat ji až po ověření. Po potvrzení plateb má vyúčtování ukázat, že David doplácí 1 900 Kč, Eva 1 100 Kč a mně se vrací 3 000 Kč.

Potřebuji proto evidovat členy, výlety, účastníky a jejich role, kategorie a výdaje, podíly na jednotlivých výdajích i platby. Odhlášené účastníky ani neaktivní členy nechci mazat, protože jejich historie zůstává důležitá. Zůstatek se nemá ukládat jako ručně měněná hodnota, ale pokaždé vypočítat z podílů a potvrzených plateb. Pro první verzi stačí jedna měna; přihlašování, ukládání účtenek ani automatické platby nejsou součástí zadání.

## 1. Nápad a popis systému

Systém pomáhá malé skupině naplánovat výlet a přehledně rozdělit společné výdaje mezi účastníky.  
Řeší situaci, kdy se náklady platí na různých místech a po návratu není jasné, kdo má kolik doplatit.  
Vedoucí výletu díky evidenci nemusí částky dohledávat v chatu, účtenkách a tabulkách.  
Systém slouží vedoucím výletů a jejich účastníkům.  
Uchovává členy, výlety, účast jednotlivých členů, kategorie služeb, výdaje, podíly účastníků na výdajích a platby.  
U každého výdaje lze zaznamenat částku, datum, kategorii a popis.  
Vedoucí může výdaj rozdělit mezi účastníky a zaznamenat jejich platby do společného rozpočtu.  
Systém umožní zjistit skutečné náklady výletu i součet nákladů připadající na každého účastníka.  
Porovnáním podílů na výdajích s potvrzenými platbami ukáže, kdo má ještě doplatit a kdo zaplatil navíc.  
Tento návrh je malou, připravenou základnou pro aplikaci; přihlášení uživatelů, nahrávání účtenek ani automatické platby nejsou jeho součástí.

## 2. Uživatelé a přínosy

- **Vedoucí výletu** zakládá výlet, přidává účastníky a služby, eviduje výdaje a potvrzuje platby. Na nákladech se nepodílí; výdaje se rozdělí mezi ostatní účastníky.
- **Účastník** může získat přehled o svém podílu na nákladech a o zaplacené částce.

Konkrétním přínosem je dohledatelné rozúčtování: namísto ručního sčítání je možné získat z databáze částku připadající na každého účastníka a porovnat ji s jeho potvrzenými platbami.

## 3. Od požadavků k databázovému modelu

| Požadavek | Návrh v databázi |
|---|---|
| Evidovat osoby, které výlety vedou nebo se jich účastní | `members` |
| Evidovat výlety, jejich termíny a očekávaný rozpočet | `trips` |
| Zaznamenat účastníky a vedoucí konkrétního výletu | `participants`, spojovací tabulka mezi členy a výlety s příznakem `is_leader` |
| Kategorizovat výdaje | `services` |
| Evidovat výdaj v rámci výletu | `expenses`, každý výdaj má kategorii |
| Rozdělit výdaj mezi účastníky | `expense_shares`, každému účastníkovi lze přiřadit podíl |
| Zaznamenat platby účastníků | `payments` |
| Zjistit neuhrazený rozdíl | Agregační `SELECT` nad podíly a potvrzenými platbami; zůstatek se neukládá jako ručně měněná hodnota |

Model má **7 tabulek**. Vztah člena k výletu je typu mnoho-k-mnoha a realizuje se tabulkou `participants`. Výdaj může mít podíl pro více účastníků a jeden účastník může mít podíly na více výdajích; tento vztah mnoho-k-mnoha realizuje `expense_shares`.

### ER diagram

Soubor [`trips.dbml`](trips.dbml) obsahuje diagram, který lze vložit do editoru [dbdiagram.io](https://dbdiagram.io/). Hlavní vztahy jsou:

```text
members 1 ── N participants N ── 1 trips (role účastník/vedoucí)
trips 1 ── N expenses N ── 1 services
expenses 1 ── N expense_shares N ── 1 participants
participants 1 ── N payments
```

### Popis tabulek

| Tabulka | Účel a důležité údaje |
|---|---|
| `members` | Členové systému, jméno, příjmení, datum registrace a příznak aktivního účtu. |
| `trips` | Název výletu, datum začátku a konce a případné očekávané náklady. |
| `participants` | Přihlášení člena na výlet, příznak aktivní účasti a role vedoucího (`is_leader`). Role je vázaná na konkrétní výlet; jedinečná kombinace člena a výletu brání duplicitní účasti. |
| `services` | Kategorie výdajů, například ubytování, doprava nebo strava. |
| `expenses` | Konkrétní výdaje daného výletu, jejich kategorie, částka, datum a popis. |
| `expense_shares` | Částka konkrétního výdaje přiřazená konkrétnímu účastníkovi. |
| `payments` | Platby účastníka do společného rozpočtu; nepotvrzená platba se do vyúčtování nezapočítává. |

## 4. Pravidla a zvolená zjednodušení

- Částky jsou v ukázce vedené v jedné společné měně, bez samostatné tabulky měn.
- Peněžní hodnoty používají `numeric(10,2)`, aby bylo možné přesně ukládat haléře/centy; nepoužívá se typ `float`.
- `is_active`, `is_leader` a `is_confirmed` jsou booleovské příznaky uložené typem `boolean`, který je pro PostgreSQL přirozený.
- Role vedoucího je uložena v `participants.is_leader`, protože stejný člen může vést jeden výlet a být běžným účastníkem jiného. `false` znamená běžného účastníka. Výlet může mít i více vedoucích; databáze jejich počet neomezuje.
- Podíl se eviduje v `expense_shares` na úrovni jednotlivého výdaje a účastníka. Vedoucí v ukázkových datech nemá v `expense_shares` žádné řádky, proto se jeho podíl ve vyúčtování přirozeně zobrazí jako nula; dotaz pouze sčítá zadané podíly a nemusí zvlášť kontrolovat roli.
- Součet podílů jednoho výdaje má odpovídat jeho celkové částce a podíl má patřit účastníkovi stejného výletu, ke kterému patří výdaj. Tato pravidla se týkají více řádků nebo tabulek, takže je běžný `CHECK` nevynutí; v tomto jednoduchém modelu je kontroluje aplikace při zápisu (v pokročilejší verzi by šlo použít trigger nebo složené cizí klíče).
- Ukázkový dotaz zahrnuje jen účastníky s `participants.is_active = true`. Pokud neaktivní účastník může mít stále nevyrovnané náklady, je nutné upravit pravidla vyúčtování; příznak účasti sám o sobě nemaže jeho výdaje ani platby.
- Platba je chápána jako příspěvek účastníka do společného rozpočtu, nikoli jako přímá úhrada konkrétní účtenky. Nově zadaná platba je ve výchozím stavu nepotvrzená (`is_confirmed = false`) a do vyúčtování se započítá až po potvrzení vedoucím. Pokud má být evidováno, kdo výdaj původně zaplatil, lze v další verzi přidat do `expenses` odkaz na účastníka-platícího.
- Kladný rozdíl **podíly − potvrzené platby** znamená částku k doplacení; záporný rozdíl znamená příspěvek nad přidělené podíly. Potvrzené platby vedoucího se započítávají jako příspěvky do společného rozpočtu, přestože vedoucímu nejsou přiděleny náklady. Nejde o uložený sloupec, ale o výsledek dotazu, aby se předešlo zastaralým zůstatkům.
- Unikátní omezení brání duplicitní účasti člena na výletu i duplicitnímu podílu účastníka na jednom výdaji.
- Cizí klíče a `CHECK` omezení hlídají základní integritu: platnost termínu, nezáporný očekávaný rozpočet a podíly i kladné částky výdajů a plateb.
- Indexy jsou vytvořené na cizích klíčích, přes které vyúčtování vyhledává data výletu (`participants.trip_id`, `expenses.trip_id`, `expense_shares.expense_id`, `payments.participant_id`).

## 5. Ukázková data a dotaz

Skript [`trips.sql`](trips.sql) vytvoří schéma a všech sedm tabulek. Vzorová data pro víkendový výlet do Prahy jsou v [`trips.seed.sql`](trips.seed.sql) a dotaz pro výpočet vyúčtování v [`vzorovy_select.sql`](vzorovy_select.sql). Anna (vedoucí) nepřebírá podíl na výdajích; celkových 7 800,00 se rozdělí mezi Davida a Evu, každému po 3 900,00. Potvrzené platby jsou 3 000,00, 2 000,00 a 2 800,00. Výsledné rozdíly jsou doplatek 1 900,00 u Davida, doplatek 1 100,00 u Evy a −3 000,00 u vedoucí Anny: Anna zaplatila 3 000,00 do společného rozpočtu, přestože nemá žádný podíl, a doplatky Davida a Evy jí tuto částku vrátí. Součet zůstatků je proto nula. Očekávaný rozpočet výletu je 8 000,00, tedy o 200,00 vyšší než evidované výdaje.

Ukázkový dotaz odpovídá na otázku: **Kolik má každý účastník doplatit, nebo kolik zaplatil navíc?** Je v souboru [`vzorovy_select.sql`](vzorovy_select.sql). Používá samostatné agregace podílů a plateb, aby spojení více výdajů a plateb neznásobilo částky. Podíly se k výletu přiřazují přes výdaj (`expenses.trip_id`), platby přes účastníka (`participants.trip_id`). Role se v agregaci podílů samostatně nefiltruje: rozhodující je, komu byl záznam v `expense_shares` přiřazen. Ve vzorovém souboru změňte `trip_id` v CTE `selected_trip`, pokud chcete zobrazit jiné vyúčtování.

## 6. Spuštění v PostgreSQL

1. V dbdiagram.io zkopírujte obsah `trips.dbml` do levého editoru. DBML je nativní syntaxe editoru a diagram se vykreslí automaticky. Menu **Import** přijímá pouze SQL, ne soubory `.dbml`. SQL DDL lze vytvořit také lokálně pomocí DBML CLI (viz sekce 7).
2. Pro novou databázi spusťte nejprve `trips.sql` a potom `trips.seed.sql` jako uživatel s oprávněním vytvořit schéma a tabulky. Pro výpočet vyúčtování spusťte `vzorovy_select.sql`.
3. Skript na začátku odstraní celé schéma příkazem `DROP SCHEMA IF EXISTS trips CASCADE;` a poté ho vytvoří znovu, proto jej lze spouštět opakovaně. Pozor: při každém spuštění se smažou všechny tabulky a data ve schématu `trips` i objekty v jiných schématech, které na ně závisí. Samostatný dotaz v [`vzorovy_select.sql`](vzorovy_select.sql) lze spouštět opakovaně; pro jiný výlet změňte `trip_id` v CTE `selected_trip`.

DBML zachycuje strukturu a vztahy pro diagram a export. Autoritativní spustitelnou podobou projektu jsou SQL skripty: `trips.sql` vytváří strukturu a doplňuje kontroly hodnot, `trips.seed.sql` vkládá vzorová data.

## 7. Použití DBML CLI

DBML CLI (`@dbml/cli`) převádí schéma mezi DBML a SQL z příkazové řádky. Vyžaduje Node.js 18 nebo novější. Nainstalujte jej globálně:

```bash
npm install -g @dbml/cli
```

Z kořenové složky projektu vytvořte PostgreSQL DDL z modelu:

```bash
dbml2sql trips.dbml --postgres -o trips.generated.sql
```

Výstup `trips.generated.sql` obsahuje SQL pro vytvoření tabulek a vztahů popsaných v `trips.dbml`. **Nenahrazuje projektové skripty**: neobsahuje vzorová data z `trips.seed.sql` ani dodatečná omezení `CHECK` z `trips.sql`. Projektový `trips.sql` navíc na začátku nevratně odstraní existující schéma `trips`; používejte jej pouze tehdy, když chcete schéma znovu vytvořit.

Pro převod SQL DDL zpět do DBML slouží například:

```bash
sql2dbml schema.sql --postgres -o schema.dbml
```

Tento převod používejte na souboru obsahujícím pouze DDL. Projektový `trips.sql` začíná příkazem `DROP SCHEMA ... CASCADE`, který při spuštění smaže existující schéma `trips`; před použitím jiného SQL souboru zkontrolujte jeho obsah.
