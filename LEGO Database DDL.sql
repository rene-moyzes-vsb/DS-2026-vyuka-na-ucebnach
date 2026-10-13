-- LEGO Database DDL 
SET ROLE "MOY001";

CREATE SCHEMA IF NOT EXISTS lego;
SET search_path TO lego;


-- Drop tables if they exist
DROP TABLE IF EXISTS inventory_sets;
DROP TABLE IF EXISTS inventory_minifigs;
DROP TABLE IF EXISTS inventory_parts;
DROP TABLE IF EXISTS inventories;
DROP TABLE IF EXISTS sets;
DROP TABLE IF EXISTS minifigs;
DROP TABLE IF EXISTS part_relationships;
DROP TABLE IF EXISTS elements;
DROP TABLE IF EXISTS parts;
DROP TABLE IF EXISTS themes;
DROP TABLE IF EXISTS colors;
DROP TABLE IF EXISTS part_categories;


-- Part Categories (already has COPY)
CREATE TABLE part_categories (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(200) NOT NULL
);

COPY part_categories(id, name) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\part_categories.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Colors
CREATE TABLE colors (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    rgb         VARCHAR(6),
    is_trans    BOOLEAN NOT NULL DEFAULT FALSE,
    num_parts   INTEGER,
    num_sets    INTEGER,
    y1          INTEGER,
    y2          INTEGER
);

COPY colors(id, name, rgb, is_trans, num_parts, num_sets, y1, y2) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\colors.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Themes
CREATE TABLE themes (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    parent_id   INTEGER,
    CONSTRAINT fk_themes_parent FOREIGN KEY (parent_id) REFERENCES themes(id) ON DELETE SET NULL
);

COPY themes(id, name, parent_id) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\themes.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Parts
CREATE TABLE parts (
    part_num    VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(250) NOT NULL,
    part_cat_id INTEGER NOT NULL,
    part_material VARCHAR(50),
    CONSTRAINT fk_parts_category FOREIGN KEY (part_cat_id) REFERENCES part_categories(id)
);

COPY parts(part_num, name, part_cat_id, part_material) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\parts.csv' 
WITH (FORMAT CSV, HEADER TRUE);


-- Elements
CREATE TABLE elements (
    element_id  VARCHAR(10) PRIMARY KEY,
    part_num    VARCHAR(20) NOT NULL,
    color_id    INTEGER NOT NULL,
    design_id   INTEGER,
    CONSTRAINT fk_elements_part FOREIGN KEY (part_num) REFERENCES parts(part_num),
    CONSTRAINT fk_elements_color FOREIGN KEY (color_id) REFERENCES colors(id)
);


COPY elements(element_id, part_num, color_id, design_id) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\elements.csv' 
WITH (FORMAT CSV, HEADER TRUE);


-- Part Relationships
CREATE TABLE part_relationships (
    rel_type         VARCHAR(1) NOT NULL,
    child_part_num   VARCHAR(20) NOT NULL,
    parent_part_num  VARCHAR(20) NOT NULL,
    PRIMARY KEY (rel_type, child_part_num, parent_part_num),
    CONSTRAINT fk_part_rel_child FOREIGN KEY (child_part_num) REFERENCES parts(part_num),
    CONSTRAINT fk_part_rel_parent FOREIGN KEY (parent_part_num) REFERENCES parts(part_num)
);

COPY part_relationships(rel_type, child_part_num, parent_part_num) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\part_relationships.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Minifigs
CREATE TABLE minifigs (
    fig_num     VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(256) NOT NULL,
    num_parts   INTEGER,
    img_url     VARCHAR(500)
);

COPY minifigs(fig_num, name, num_parts, img_url) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\minifigs.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Sets
CREATE TABLE sets (
    set_num     VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(256) NOT NULL,
    year        INTEGER,
    theme_id    INTEGER,
    num_parts   INTEGER,
    img_url     VARCHAR(500),
    CONSTRAINT fk_sets_theme FOREIGN KEY (theme_id) REFERENCES themes(id)
);

COPY sets(set_num, name, year, theme_id, num_parts, img_url) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\sets.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Inventories
CREATE TABLE inventories (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version     INTEGER NOT NULL,
    set_num     VARCHAR(20) NOT NULL
    -- CONSTRAINT fk_inventories_set FOREIGN KEY (set_num) REFERENCES sets(set_num)
);

COPY inventories(id, version, set_num) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\inventories.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Inventory Parts
CREATE TABLE inventory_parts (
    inventory_id    INTEGER NOT NULL,
    part_num        VARCHAR(20) NOT NULL,
    color_id        INTEGER NOT NULL,
    quantity        INTEGER NOT NULL,
    is_spare        BOOLEAN NOT NULL DEFAULT FALSE,
    img_url         VARCHAR(500),
    PRIMARY KEY (inventory_id, part_num, color_id, is_spare),
    CONSTRAINT fk_inventory_parts_inventory FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_parts_part FOREIGN KEY (part_num) REFERENCES parts(part_num),
    CONSTRAINT fk_inventory_parts_color FOREIGN KEY (color_id) REFERENCES colors(id)
);

COPY inventory_parts(inventory_id, part_num, color_id, quantity, is_spare, img_url) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\inventory_parts.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Inventory Minifigs
CREATE TABLE inventory_minifigs (
    inventory_id    INTEGER NOT NULL,
    fig_num         VARCHAR(20) NOT NULL,
    quantity        INTEGER NOT NULL,
    PRIMARY KEY (inventory_id, fig_num),
    CONSTRAINT fk_inventory_minifigs_inventory FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_minifigs_fig FOREIGN KEY (fig_num) REFERENCES minifigs(fig_num)
);

COPY inventory_minifigs(inventory_id, fig_num, quantity) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\inventory_minifigs.csv' 
WITH (FORMAT CSV, HEADER TRUE);

-- Inventory Sets
CREATE TABLE inventory_sets (
    inventory_id    INTEGER NOT NULL,
    set_num         VARCHAR(20) NOT NULL,
    quantity        INTEGER NOT NULL,
    PRIMARY KEY (inventory_id, set_num),
    CONSTRAINT fk_inventory_sets_inventory FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_sets_set FOREIGN KEY (set_num) REFERENCES sets(set_num)
);

COPY inventory_sets(inventory_id, set_num, quantity) 
FROM 'c:\Program Files\PostgreSQL\18\data\lego\inventory_sets.csv' 
WITH (FORMAT CSV, HEADER TRUE);