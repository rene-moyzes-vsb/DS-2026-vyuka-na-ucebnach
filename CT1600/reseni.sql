/*
select S.set_num, COUNT(DISTINCT P.part_num) as pocet_dilku
from sets as S
JOIN inventories as I on I.set_num = S.set_num and I.version = 1
JOIN inventory_parts as P ON P.inventory_id = I.id
where S.YEAR = 2015 and P.is_spare = false
GROUP BY S.set_num
HAVING COUNT(P.part_num) > 50;*/

/*
SELECT minifigs.fig_num,
       minifigs.name,
       COUNT(DISTINCT(sets.set_num)) AS pocet_figurek, MAX(pocet_dilku)
from minifigs
JOIN inventory_minifigs on minifigs.fig_num = inventory_minifigs.fig_num
JOIN inventories on inventory_minifigs.inventory_id = inventories.id
AND inventories.version = 1
JOIN
sets on inventories.set_num = sets.set_num
JOIN
    (select S.set_num,
            COUNT(DISTINCT P.part_num) as pocet_dilku
     from
     sets as S
     JOIN inventories as I on I.set_num = S.set_num
     and I.version = 1
     JOIN inventory_parts as P ON P.inventory_id = I.id
     where S.YEAR = 2015
         and P.is_spare = false
     GROUP BY S.set_num
     HAVING COUNT(P.part_num) > 50) AS Sub_Select1 ON 
     Sub_Select1.set_num = sets.set_num
     /*WHERE minifigs.fig_num = 'fig-002330'*/
GROUP BY minifigs.fig_num
HAVING (COUNT(DISTINCT(sets.set_num)) >= 4)
ORDER BY minifigs.name
*/


WITH T AS
(
SELECT s.set_num, s.name, s.year, sum(ip.quantity) as pocet_dilku
FROM sets s
JOIN inventories i ON s.set_num = i.set_num AND i.version=1
JOIN inventory_parts ip ON ip.inventory_id = i.id
WHERE theme_id IN
(
SELECT id from themes
WHERE parent_id =
    (
        SELECT id from themes
        WHERE name = 'Bionicle'
    )
    OR name = 'Bionicle'
)
GROUP BY s.set_num, s.name)
    
SELECT * FROM T
WHERE 

T.YEAR BETWEEN 2006 AND 2010

AND

pocet_dilku > 
    (
        SELECT AVG(pocet_dilku) FROM T
    )

AND
pocet_dilku<
    (
        SELECT MAX(pocet_dilku) FROM T
    )
;