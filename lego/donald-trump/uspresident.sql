-- Referenční sada dílků pro MOC „President Donald Trump“
-- Zdroj: president-donald-trump.csv (Part, Color, Quantity, Is Spare)
-- Skript lze spustit opakovaně; tabulka se pokaždé vytvoří znovu.

DROP TABLE IF EXISTS lego.uspresident;

CREATE TABLE lego.uspresident (
    part_num  VARCHAR(20) NOT NULL,   -- odpovídá lego.parts.part_num
    color_id  INTEGER     NOT NULL,   -- odpovídá lego.colors.id
    quantity  INTEGER     NOT NULL CHECK (quantity > 0),
    is_spare  BOOLEAN     NOT NULL DEFAULT FALSE,
    PRIMARY KEY (part_num, color_id, is_spare)
);

INSERT INTO lego.uspresident (part_num, color_id, quantity, is_spare) VALUES
('3024',   0,   2, FALSE),
('49668',  0,   2, FALSE),
('6141',   191, 2, FALSE),
('15573',  191, 1, FALSE),
('4304',   191, 1, FALSE),
('25269',  191, 2, FALSE),
('3005',   272, 2, FALSE),
('11477',  272, 3, FALSE),
('15068',  272, 1, FALSE),
('24201',  272, 1, FALSE),
('5404',   272, 2, FALSE),
('87087',  272, 4, FALSE),
('32952',  272, 4, FALSE),
('3024',   272, 2, FALSE),
('86996',  272, 1, FALSE),
('3023',   272, 2, FALSE),
('3623',   272, 2, FALSE),
('3021',   272, 2, FALSE),
('3070b',  272, 2, FALSE),
('63864',  272, 1, FALSE),
('26603',  272, 1, FALSE),
('24299',  272, 1, FALSE),
('24307',  272, 1, FALSE),
('6141',   320, 2, FALSE),
('3021',   2,   1, FALSE),
('6091',   4,   1, FALSE),
('11303',  4,   1, FALSE),
('3023',   4,   1, FALSE),
('3070b',  4,   1, FALSE),
('37352',  19,  1, FALSE),
('15573',  19,  1, FALSE),
('65578',  15,  1, FALSE),
('6091',   15,  2, FALSE),
('15672',  15,  2, FALSE),
('3024',   15,  2, FALSE),
('3623',   15,  3, FALSE),
('3386',   15,  1, FALSE);

-- Kontrola: očekává se 37 řádků, 28 různých dílků, 8 barev, 62 kusů,
-- 0 náhradních dílků a 0 dílků/barev chybějících v katalogu.
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
