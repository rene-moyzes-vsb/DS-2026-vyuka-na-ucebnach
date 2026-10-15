/*SELECT i.set_num, COUNT(DISTINCT ip.part_num) as pocet_dilku
FROM sets s
join inventories i on i.set_num = s.set_num and i.version = 1
join inventory_parts ip on ip.inventory_id = i.id
WHERE year = 2015 and ip.is_spare = false
GROUP BY i.set_num
having COUNT(ip.part_num) > 50;

SELECT m.fig_num, m.name, COUNT(i.set_num) as pocet_stavebnic,MAX(rs.pocet_dilku)
from minifigs m
join inventory_minifigs im on im.fig_num = m.fig_num
join inventories i on i.id = im.inventory_id and i.version = 1
join (
    SELECT i.set_num, COUNT(DISTINCT ip.part_num) as pocet_dilku
    FROM sets s
    join inventories i on i.set_num = s.set_num and i.version = 1
    join inventory_parts ip on ip.inventory_id = i.id
    WHERE year = 2015 and ip.is_spare = false
    GROUP BY i.set_num
    having COUNT(ip.part_num) > 50
    ) rs on rs.set_num = i.set_num
GROUP BY m.fig_num
HAVING COUNT(i.set_num) > 3 --AND MAX(rs.pocet_dilku) <> MIN(rs.pocet_dilku)
ORDER BY m.name
*/
SELECT s.set_num,
       s.name,
       s.year,
       sum(ip.quantity)
FROM
    (SELECT id,
            name
     FROM themes
     WHERE name = 'Bionicle'
     UNION SELECT child.id,
                  child.name
     FROM themes parent
     JOIN themes child ON parent.id=child.parent_id
     WHERE parent.name = 'Bionicle') as myThemes
JOIN
sets s ON myThemes.id = s.theme_id
JOIN inventories i ON s.set_num = i.set_num
AND i.version=1
JOIN inventory_parts ip ON ip.inventory_id = i.id
WHERE s.year BETWEEN 2006 AND 2010
GROUP BY s.set_num,
         s.name,
         s.year
HAVING sum(ip.quantity) >
    (SELECT AVG (pocet_dilku)
     FROM
         (SELECT --s.set_num, s.name, s.year,
 SUM(ip.quantity) as pocet_dilku
          FROM
              (SELECT id,
                      name
               FROM themes
               WHERE name = 'Bionicle'
               UNION SELECT child.id,
                            child.name
               FROM themes parent
               JOIN themes child ON parent.id=child.parent_id
               WHERE parent.name = 'Bionicle') as myThemes
          JOIN
          sets s ON myThemes.id = s.theme_id
          JOIN inventories i ON s.set_num = i.set_num
          AND i.version=1
          JOIN inventory_parts ip ON ip.inventory_id = i.id --WHERE s.year BETWEEN 2006 AND 2010
GROUP BY s.set_num,
         s.name,
         s.year)) 
         
         AND


         sum(ip.quantity) <
    (SELECT MAX (pocet_dilku)
     FROM
         (SELECT --s.set_num, s.name, s.year,
 SUM(ip.quantity) as pocet_dilku
          FROM
              (SELECT id,
                      name
               FROM themes
               WHERE name = 'Bionicle'
               UNION SELECT child.id,
                            child.name
               FROM themes parent
               JOIN themes child ON parent.id=child.parent_id
               WHERE parent.name = 'Bionicle') as myThemes
          JOIN
          sets s ON myThemes.id = s.theme_id
          JOIN inventories i ON s.set_num = i.set_num
          AND i.version=1
          JOIN inventory_parts ip ON ip.inventory_id = i.id --WHERE s.year BETWEEN 2006 AND 2010
GROUP BY s.set_num,
         s.name,
         s.year)) 
         ;