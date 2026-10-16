# Příprava na práci s relačními daty

Tento přehled shrnuje obecné dovednosti potřebné při řešení databázových
úloh. Neobsahuje konkrétní zadání, hodnoty ani informace o podobě testu.

## 1. Techniky, které je potřeba ovládat

- **Spojování souvisejících dat** z více tabulek a rozpoznání, přes které
  vazby se lze dostat od výchozí entity k hledané informaci.
- **Rozlišení rolí stejného typu entity**. Jedna tabulka může v úloze
  vystupovat vícekrát, například jednou jako rodič a podruhé jako potomek
  nebo jako dva různí členové téže skupiny.
- **Procházení hierarchie** přes několik předem určených úrovní a správné
  rozlišení kořene, přímého potomka a vzdálenějšího potomka.
- **Zachování entit bez souvisejících záznamů**, pokud mají být ve výsledku
  uvedeny i s nulovým počtem nebo nedefinovaným souhrnem. Dodatečné podmínky
  se nesmějí použít způsobem, který by takové entity nechtěně odstranil.
- **Souhrnné výpočty** — zejména počet, počet různých hodnot, součet, průměr
  a maximum — na správně zvolené úrovni seskupení.
- **Podmíněné souhrny**, kdy se hodnoty jedné skupiny rozdělují podle
  vlastnosti a pro každou část se vypočítá samostatný výsledek.
- **Rozlišení podmínky na jednotlivý záznam a podmínky na celý souhrn**.
  Nejprve je nutné určit, zda se má záznam vyřadit ještě před výpočtem, nebo
  zda se má až hotový výsledek porovnat s požadovanou mezí.
- **Pomocné mezivýsledky**, pokud je třeba nejprve něco spočítat a teprve
  potom vypočtené hodnoty dále porovnávat, filtrovat nebo použít při hledání
  celkového maxima.
- **Dílčí výpočty pro každý výsledný řádek**. Je nutné vědět, že takový
  výpočet není automaticky zaměnitelný se společným seskupením: může se
  odlišně chovat u entit, které nemají žádné související záznamy.
- **Ověřování existence a neexistence** — zda alespoň jeden související
  záznam podmínku splňuje, nebo zda ji nesplňuje žádný.
- **Univerzální podmínky** — zda podmínka platí pro všechny členy skupiny.
  Jde o jiný požadavek než pouhá existence jednoho vyhovujícího člena.
- **Hledání extrémní hodnoty ve skupině** tak, aby se při shodě zachovaly
  všechny odpovídající řádky, nikoli jen jeden libovolný.
- **Odstraňování duplicit** a správné určení, co se má považovat za jednu
  jedinečnou položku, jednoho člena nebo jednu skupinu.
- **Hledání podle části textu**, včetně případů, kdy se nemá rozlišovat
  velikost písmen.
- **Práce s chybějícími hodnotami**. Počet neprázdných hodnot může být nula,
  zatímco součet, průměr nebo maximum bez vstupních hodnot nemusí být
  definován. Nula a chybějící hodnota nejsou totéž a zadání musí určit, která
  z nich má být ve výsledku.
- **Přesné určení úrovně výsledku** — zda má vzniknout jeden řádek pro každý
  jednotlivý záznam, jeden řádek pro každou skupinu, nebo jeden společný
  souhrn za více skupin.

## 2. Varianty vět o členství — jak je číst

Databázová zadání často popisují vztah mezi **skupinou**, jejími **členy**
a položkami spojenými s jednotlivými členy. Před řešením je potřeba určit:

1. která entita má být ve výsledku,
2. přes které členy se podmínka vyhodnocuje,
3. zda stačí jeden člen, nesmí vyhovět žádný, nebo musí vyhovět všichni,
4. zda se více podmínek musí sejít u stejného člena,
5. zda se členové posuzují samostatně, nebo společně.

### a) „Alespoň jeden člen“ / „některý člen“

Stačí, aby podmínku splnil jeden libovolný člen skupiny. Ostatní členové ji
splňovat nemusí.

> *Alespoň jeden člen skupiny má požadovanou vlastnost.*

### b) „Žádný člen“ / „nikdy se nevyskytuje“

Podmínku nesmí splnit ani jeden člen skupiny.

> *Žádný člen skupiny nemá zakázanou vlastnost.*

Pozor na prázdnou skupinu: pokud skupina nemá žádného člena, pak v ní
skutečně neexistuje člen se zakázanou vlastností. Jestli mají být prázdné
skupiny vyloučeny, musí zadání současně požadovat existenci alespoň jednoho
člena.

### c) „Jeden a tentýž člen splňuje více podmínek zároveň“

Všechny uvedené podmínky se musí potkat u jednoho konkrétního člena. Nestačí,
aby první podmínku splnil jeden člen a druhou podmínku jiný člen stejné
skupiny.

> *Alespoň jeden člen má zároveň vlastnost A i vlastnost B.*

### d) „Jedna podmínka někde ve skupině a druhá také někde ve skupině“

Každou podmínku může splnit jiný člen. Zadání zde nevyžaduje, aby se obě
vlastnosti setkaly u stejného člena.

> *Ve skupině se vyskytuje člen s vlastností A a také člen s vlastností B.*

Tato formulace není totožná s bodem c). Rozhodující je, zda se slovo
„zároveň“ vztahuje k jednomu členu, nebo pouze ke skupině jako celku.

### e) „Každého člena posuzujte samostatně“

Členové se nesmějí slučovat. Každý z nich představuje samostatně posuzovaný
případ a může tvořit vlastní řádek výsledku.

> *Pro každého člena určete jeho vlastnosti a souhrnné hodnoty.*

### f) „Napříč všemi členy“ / „za celou skupinu“

Členové se posuzují společně a výsledkem je jedna hodnota za celou skupinu.
Pokud se stejná položka opakuje u více členů, započte se jen jednou pouze
tehdy, když zadání požaduje počet různých nebo jedinečných položek.

> *Za celou skupinu určete počet různých souvisejících položek.*

### g) „Počet členů splňujících podmínku“

Samotný počet vyhovujících členů je měřenou veličinou. Je nutné určit, zda se
počítají všechny výskyty, nebo jen různí členové.

> *Určete počet různých členů s požadovanou vlastností.*

### h) „Podmínka platí pro každého člena skupiny“

Zde se obvykle hledá kandidátská položka nebo vlastnost, která vyhovuje vůči
všem členům sledované skupiny. Entita ve výsledku proto nemusí být totožná
s entitou, přes kterou se podmínka vyhodnocuje.

> *Najděte položky, které mají požadovaný vztah ke každému členu skupiny.*

Také zde je důležitá prázdná skupina. Výrok „podmínka platí pro všechny
členy“ nemá v prázdné skupině žádný protipříklad, a proto se považuje za
splněný. Pokud tento výsledek není zamýšlen, musí být neprázdnost skupiny
ověřena zvlášť.

### i) „U konkrétní skupiny“

Kterákoli z předchozích variant může být omezena na jednu určenou skupinu
místo všech skupin daného typu. Mění se rozsah hledání, nikoli význam slov
„alespoň jeden“, „žádný“ nebo „každý“.

## 3. Kontrolní otázky před řešením

- Co přesně má představovat jeden řádek výsledku?
- Které entity jsou skupiny, které jejich členové a které pouze související
  položky?
- Má stačit jeden vyhovující člen, nesmí existovat žádný, nebo musí vyhovět
  všichni?
- Musejí se dvě podmínky potkat u stejného člena?
- Mají se opakované položky počítat vícekrát, nebo jen jednou?
- Má se skupina bez členů ve výsledku zachovat, nebo vyloučit?
- Je nula skutečná hodnota, nebo pouze náhrada za chybějící výsledek?
- Pokud více řádků sdílí stejnou nejvyšší hodnotu, mají se zobrazit všechny?
