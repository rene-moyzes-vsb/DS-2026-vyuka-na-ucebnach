-- Ukázková úloha 1
-- Sběratel hledá minifigurky, které v roce 2015 doprovázely rozsáhlé
-- stavebnice. Za rozsáhlou považujte takovou verzi inventáře stavebnice
-- vydané v roce 2015, která obsahuje více než 50 různých druhů běžných
-- dílků. Druhy dílků počítejte podle čísla dílku bez ohledu na barvu
-- a počítejte pouze běžné dílky (is_spare = FALSE), nikoli náhradní dílky
-- (is_spare = TRUE). Pro každou minifigurku spočítejte, v kolika různých
-- takových stavebnicích je obsažena. Stavebnici započítejte jen jednou, i když
-- vyhovuje více jejích verzí inventáře. Ponechte pouze minifigurky
-- obsažené alespoň ve čtyřech takových stavebnicích. Vypište číslo
-- minifigurky, její název, počet stavebnic a počet druhů
-- dílků v tomto pořadí.

-- Výsledek seřaďte vzestupně podle názvu minifigurky.

 -- HINT: Postupujte od stavebnic k minifigurkám, ne naopak. Nejprve omezte
-- inventáře na stavebnice z roku 2015 a u každého inventáře ověřte podmínku
-- na více než 50 různých čísel běžných dílků; tato podmínka je agregační,
-- proto ji vyhodnoťte uvnitř poddotazu. Teprve na vyhovující inventáře
-- napojte minifigurky. Stavebnice počítejte přes různá set_num, protože
-- jedna stavebnice může mít více verzí inventáře. Práh čtyř stavebnic
-- je podmínka nad agregací, patří tedy do HAVING.
 




-- které v roce 2015 doprovázely rozsáhlé
-- stavebnice. Za rozsáhlou považujte takovou verzi inventáře stavebnice
-- vydané v roce 2015, která obsahuje více než 50 různých druhů běžných
-- dílků.

select s.set_num, count(distinct ip.part_num) as pocet_dilku
from sets s
join inventories i on s.set_num = i.set_num and version = 1
join inventory_parts ip on ip.inventory_id = i.id
where year = 2015 AND ip.is_spare = FALSE
group by s.set_num  
having count(distinct ip.part_num) > 50;

-- Pro každou minifigurku spočítejte, v kolika různých
-- takových stavebnicích je obsažena

select 
  im.fig_num,
  m.name, count(i.set_num) as pocet_stavebnic,
  --pocet_dilku
  MAX(pocty.pocet_dilku) as pocet_dilku
from inventory_minifigs im
join inventories i on im.inventory_id = i.id and version = 1
join minifigs m ON m.fig_num = im.fig_num
join
  (
  select s.set_num,count(distinct ip.part_num) as pocet_dilku
  from sets s
  join inventories i on s.set_num = i.set_num and version = 1
  join inventory_parts ip on ip.inventory_id = i.id
  where year = 2015 AND ip.is_spare = FALSE
  group by s.set_num  
  having count(distinct ip.part_num) > 50
) as pocty ON i.set_num=pocty.set_num
group by im.fig_num, m.name,pocet_dilku
having count(i.set_num) >= 4
ORDER BY m.name ;

















 
 
 
 */ -- Náhled výsledku: celkem 8 řádků; zobrazeno prvních 5.
-- | fig_num | minifigurka | pocet_stavebnic | nejvice_druhu_dilku |
-- | fig-003414 | Batman, Dark Bluish Gray Suit, Black Cape and Cowl, Light Nougat Head, Dark Bluish Gray Hips, Muscles Outline | 6 | 79 |
-- | fig-002330 | Battle Droid, One Bent Arm, One Straight Arm | 4 | 137 |
-- | fig-002711 | Cole in Deepstone Shoulder Armor (Possession) | 4 | 325 |
-- | fig-007884 | Criminal, Woman, Prison Shirt, Sand Blue Legs, Dark Orange Hair | 4 | 177 |
-- | fig-003415 | Gandalf (Dimensions) | 6 | 79 |
  -- Ukázková úloha 2
-- Představte si, že vybíráte dárek pro fanouška Bionicle. Najděte stavebnice
-- z tohoto tématu vydané v letech 2006 až 2010, jejichž katalogový počet dílků
-- je vyšší než průměrný počet dílků v tématu, ale nižší než nejvyšší počet
-- dílků v tématu. Průměr a maximum počítejte ze všech stavebnic daného tématu,
-- nejen z uvedených let. Vypište číslo stavebnice, její název, rok vydání
-- a katalogový počet dílků v tomto pořadí.
-- Výsledek seřaďte sestupně podle katalogového počtu dílků a potom vzestupně
-- podle čísla stavebnice.
-- HINT: Rozlišujte dvě různá omezení. Rok 2006 až 2010 vybírá stavebnice,
-- které se objeví ve výsledku, zatímco průměr a maximum se počítají ze všech
-- stavebnic tématu. Proto do poddotazů s AVG a MAX nikdy nepište podmínku
-- na rok; ta patří pouze do vnějšího dotazu. Oba poddotazy korelujte přes
-- theme_id vnější stavebnice, aby se počítaly v rámci jejího tématu.



-- Náhled výsledku: celkem 38 řádků; zobrazeno prvních 5.
-- | set_num | name | year | num_parts |
-- | 8943-1 | Axalara T9 | 2008 | 693 |
-- | 6620-1 | Ultimate Accessory Set 500 | 2006 | 500 |
-- | 8995-1 | Thornatus V9 | 2009 | 438 |
-- | 8942-1 | Jetrax T6 | 2008 | 419 |
-- | 8942-2 | Jetrax T6 Limited Edition | 2008 | 419 |
 -- Ukázková úloha 3
-- Marketing zkoumá, které minifigurky táhly jednotlivá témata v roce 2007.
-- Pro každé téma a minifigurku spočítejte, v kolika různých stavebnicích
-- vydaných v roce 2007 se minifigurka vyskytuje. Minifigurku započítejte,
-- pokud je v libovolné verzi inventáře dané stavebnice; každou stavebnici
-- ale započítejte jen jednou, i když má více verzí inventáře.
-- Vyřaďte minifigurky, které se vyskytují v některé stavebnici z roku 2006.
-- Ponechte jen dvojice tématu a minifigurky s alespoň dvěma stavebnicemi
-- z roku 2007. Vypište ID tématu, název tématu, číslo minifigurky, její název
-- a počet stavebnic v tomto pořadí.
-- Výsledek seřaďte vzestupně podle názvu tématu a potom čísla minifigurky.
-- HINT: Úlohu si rozdělte na dvě nezávislé části. První je počítání výskytů
-- v roce 2007, druhá je vyloučení minifigurek z roku 2006. Vyloučení napište
-- jako NOT EXISTS s poddotazem, který vede od stavebnic přes inventáře
-- k minifigurkám a je korelovaný na fig_num z vnějšího dotazu. Počítejte
-- různá set_num, jinak by stavebnice s více verzemi inventáře byla započtena
-- vícekrát. Podmínku na alespoň dvě stavebnice dejte do HAVING.
 -- Náhled výsledku: celkem 33 řádků; zobrazeno prvních 5.
-- | theme_id | tema | fig_num | minifigurka | pocet_stavebnic |
-- | 310 | Aquaraiders II | fig-002434 | Aquaraider Diver 8 | 3 |
-- | 310 | Aquaraiders II | fig-002435 | Aquaraider Diver 6 | 2 |
-- | 310 | Aquaraiders II | fig-005763 | Aquaraider Diver 2 | 2 |
-- | 697 | Batman | fig-004989 | Batman, Light Bluish Gray Suit, Dark Blue Cape and Cowl | 2 |
-- | 389 | Exo-Force | fig-000508 | Hikaru in Gold Armor | 3 |
 -- Ukázková úloha 4
-- Pro stavbu barevných oken hledáte dílky s nadprůměrnou nabídkou
-- průhledných barev. Podle katalogu elementů spočítejte pro každý dílek
-- počet různých průhledných barev (colors.is_trans = TRUE).
-- Průměr těchto počtů vypočítejte pouze mezi dílky, které mají alespoň
-- jednu průhlednou barvu. Vyberte dílky s počtem vyšším než tento průměr.
-- Zobrazte nejvýše prvních 20 řádků a vypište číslo dílku, jeho název
-- a počet různých průhledných barev v tomto pořadí.
-- Výsledek seřaďte sestupně podle počtu průhledných barev a potom vzestupně
-- podle čísla dílku.
-- HINT: Jde o agregaci z agregace, proto potřebujete dva kroky. Nejprve
-- si připravte mezivýsledek, kde každý řádek je jeden dílek a jeho počet
-- různých průhledných barev; filtr na průhlednost patří už sem, aby se
-- nepočítaly ostatní barvy. Teprve z tohoto mezivýsledku spočítejte průměr,
-- jinak byste průměrovali jednotlivé elementy místo dílků. Porovnání
-- s průměrem patří do vnějšího dotazu a LIMIT až úplně na konec.
 -- Náhled výsledku: dotaz vrací 20 řádků; bez LIMIT by vrátil 724; zobrazeno prvních 5.
-- | part_num | name | transparent_colors |
-- | 98138 | Tile Round 1 x 1 | 22 |
-- | 3065 | Brick 1 x 2 without Bottom Tube | 18 |
-- | 3005 | Brick 1 x 1 | 17 |
-- | 4740 | Dish 2 x 2 Inverted [Radar] | 17 |
-- | 59900 | Cone 1 x 1 [Top Groove] | 17 |
 -- Ukázková úloha 5
-- Chcete porovnat, která barva převládá v různých stavebnicích s přesným
-- názvem Millennium Falcon. Každou verzi inventáře posuzujte samostatně.
-- Pracujte pouze s běžnými dílky (is_spare = FALSE), nikoli s náhradními
-- dílky (is_spare = TRUE). Pro každou barvu v dané verzi inventáře sečtěte
-- počet kusů, tedy hodnoty quantity. Vítězná barva má v této verzi inventáře
-- nejvyšší počet kusů; při shodě vypište všechny vítězné barvy.
-- Vypište číslo stavebnice (set_num), její název (name), verzi inventáře,
-- název vítězné barvy a počet kusů této barvy v tomto pořadí.
-- Výsledek seřaďte vzestupně podle čísla stavebnice, verze inventáře
-- a potom názvu vítězné barvy.
-- HINT: Nejprve si spočítejte součet kusů pro každou dvojici verze inventáře
-- a barva; teprve nad tímto mezivýsledkem hledejte vítěze. Skupinou je verze
-- inventáře, proto porovnávejte s maximem počítaným pro totéž inventory_id,
-- nikoli pro set_num; jedna stavebnice má více verzí a ty se nesmí sloučit.
-- Vítěze vybírejte rovností s maximem, ne omezením na jeden řádek, jinak
-- byste při shodě přišli o část vítězných barev.
 -- Náhled výsledku: celkem 18 řádků; zobrazeno prvních 5.
-- | set_num | name | version | barva | pocet_dilku |
-- | 10179-1 | Millennium Falcon | 1 | Light Bluish Gray | 2825 |
-- | 4488-1 | Millennium Falcon | 1 | Light Gray | 46 |
-- | 6523826-1 | Millennium Falcon | 1 | Light Bluish Gray | 12 |
-- | 7190-1 | Millennium Falcon | 1 | Dark Gray | 136 |
-- | 75030-1 | Millennium Falcon | 1 | Light Bluish Gray | 43 |
