-- Address.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Street from a 'street_format' template; each placeholder draws from the list of the same name
-- (street_name, street_type, street_direction, street_ordinal, street_adjective, street_phrase...).
-- en_US: '{street_name} {street_type}' = 'Maple Avenue'; de_DE glues the type: '{street_name}{street_type}' = 'Lindenweg'.
DROP PROCEDURE IF EXISTS faker_random_street$$
CREATE PROCEDURE faker_random_street(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    OUT p_street VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_street MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_random_value(p_key, 'street.format', p_locale, 'street_format', '', v_format);
    CALL faker_expand(p_key, 'street', p_locale, v_format, NULL, v_street);
    SET p_street = v_street;
END$$

-- Postal code: 'postal_code_format' mask whose first characters are replaced by the city's postal_prefix,
-- so codes match the city region ('#####-####' + '021' -> '021##-####' -> '02134-5521').
DROP PROCEDURE IF EXISTS faker_random_postal_code$$
CREATE PROCEDURE faker_random_postal_code(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_prefix VARCHAR(16) CHARACTER SET utf8mb4, OUT p_postal_code VARCHAR(32) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_mask VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_prefix VARCHAR(16) CHARACTER SET utf8mb4 DEFAULT COALESCE(p_prefix, '');
    CALL faker_random_value(p_key, 'address.postal_code', p_locale, 'postal_code_format', '', v_mask);
    CALL faker_fill_digits(p_key, 'address.postal_code.digits',
        INSERT(v_mask, 1, CHAR_LENGTH(v_prefix), v_prefix), p_postal_code);
END$$

-- Full address from a weighted 'address_format' template. Placeholders: building, street, secondary
-- (apartment / floor), city, region_code, postal_code. City items carry region_code and postal_prefix.
DROP PROCEDURE IF EXISTS faker_random_address$$
CREATE PROCEDURE faker_random_address(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    OUT p_street VARCHAR(255) CHARACTER SET utf8mb4, OUT p_building VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_secondary VARCHAR(255) CHARACTER SET utf8mb4, OUT p_city VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_region_code VARCHAR(255) CHARACTER SET utf8mb4, OUT p_postal_code VARCHAR(32) CHARACTER SET utf8mb4,
    OUT p_full_address VARCHAR(500) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_details MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_mask VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_full MEDIUMTEXT CHARACTER SET utf8mb4;
    SET p_secondary = NULL;

    CALL faker_random_value(p_key, 'address.format', p_locale, 'address_format', '', v_format);
    CALL faker_random_item(p_key, 'address.city', p_locale, 'city', '', p_city, v_details);
    SET p_region_code = JSON_UNQUOTE(JSON_EXTRACT(v_details, '$.region_code'));
    CALL faker_random_postal_code(p_key, p_locale, JSON_UNQUOTE(JSON_EXTRACT(v_details, '$.postal_prefix')), p_postal_code);
    CALL faker_random_street(p_key, p_locale, p_street);
    CALL faker_random_value(p_key, 'address.building', p_locale, 'building_number_format', '', v_mask);
    CALL faker_fill_digits(p_key, 'address.building.digits', v_mask, p_building);
    IF INSTR(v_format, '{secondary}') > 0 THEN
        CALL faker_random_value(p_key, 'address.secondary', p_locale, 'secondary_format', '', v_mask);
        CALL faker_fill_digits(p_key, 'address.secondary.digits', v_mask, p_secondary);
    END IF;

    CALL faker_render(v_format, JSON_OBJECT(
        'building', p_building, 'street', p_street, 'secondary', p_secondary,
        'city', p_city, 'region_code', p_region_code, 'postal_code', p_postal_code), v_full);
    SET p_full_address = v_full;
END$$

-- Fills faker_geo_tiles for one region: its box is split into tile_grid x tile_grid tiles, each marked wholly
-- inside the border, wholly outside it, or crossed by it. Works top-down like a quadtree: a square of tiles the border
-- crosses is cut into four quarters, each keeping the part of the border inside it (ST_Intersection with its parent's
-- part, so the geometry shrinks at every level), and quarters wholly inside or outside are written out tile by tile.
-- Every square is judged with a margin of c_margin degrees around it, far wider than the rounding of the tile index
-- in faker_border_contains, so any point mapped to a tile lies well inside the square that tile was judged with: an
-- inside or outside tile gives ST_Contains(border, point) for all its points, a crossed tile computes it on its part.
DROP PROCEDURE IF EXISTS faker_build_geo_tiles$$
CREATE PROCEDURE faker_build_geo_tiles(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_name VARCHAR(100) CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_margin DOUBLE DEFAULT 0.000001;                -- degrees, about 0.1 m
    DECLARE v_grid INT;
    DECLARE v_size INT;
    DECLARE v_lat_min, v_lat_step, v_lon_min, v_lon_step DOUBLE;
    SELECT tile_grid, lat_min, (lat_max - lat_min) / tile_grid, lon_min, (lon_max - lon_min) / tile_grid
    INTO v_grid, v_lat_min, v_lat_step, v_lon_min, v_lon_step
    FROM faker_geo_regions WHERE locale = p_locale AND name = p_name;
    IF v_grid < 2 OR v_grid & (v_grid - 1) <> 0 THEN
        SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = 'faker_build_geo_tiles: tile_grid must be a power of 2, at least 2';
    END IF;
    DELETE FROM faker_geo_tiles WHERE locale = p_locale AND region = p_name;

    DROP TEMPORARY TABLE IF EXISTS faker_tile_squares;
    CREATE TEMPORARY TABLE faker_tile_squares (
        row_no INT      NOT NULL,
        col_no INT      NOT NULL,
        part   GEOMETRY NOT NULL,
        PRIMARY KEY (row_no, col_no)
    );
    DROP TEMPORARY TABLE IF EXISTS faker_tile_quarters;
    CREATE TEMPORARY TABLE faker_tile_quarters (
        row_no   INT         NOT NULL,
        col_no   INT         NOT NULL,
        frame    GEOMETRY    NOT NULL,                       -- the quarter plus the margin
        part     GEOMETRY    NOT NULL,                       -- border inside the frame
        coverage VARCHAR(16) NOT NULL DEFAULT '',            -- 'inside', 'outside' or 'crossed'
        PRIMARY KEY (row_no, col_no)
    );

    -- The whole box is one square crossed by all of the border.
    INSERT INTO faker_tile_squares
    SELECT 0, 0, border FROM faker_geo_regions WHERE locale = p_locale AND name = p_name;
    SET v_size = v_grid;
    WHILE v_size > 1 DO
        SET v_size = v_size DIV 2;
        DELETE FROM faker_tile_quarters;
        INSERT INTO faker_tile_quarters (row_no, col_no, frame, part)
        SELECT row_no, col_no, frame, ST_Intersection(part, frame)
        FROM (
            SELECT s.row_no + q.dr * v_size AS row_no, s.col_no + q.dc * v_size AS col_no, s.part,
                ST_Envelope(LineString(
                    Point(v_lon_min + (s.col_no + q.dc * v_size) * v_lon_step - c_margin,
                          v_lat_min + (s.row_no + q.dr * v_size) * v_lat_step - c_margin),
                    Point(v_lon_min + (s.col_no + q.dc * v_size + v_size) * v_lon_step + c_margin,
                          v_lat_min + (s.row_no + q.dr * v_size + v_size) * v_lat_step + c_margin))) AS frame
            FROM faker_tile_squares s
            CROSS JOIN (SELECT 0 AS dr, 0 AS dc UNION ALL SELECT 0, 1 UNION ALL SELECT 1, 0 UNION ALL SELECT 1, 1) q
        ) quarter;
        -- A part without area (empty, or the lines and points where the border only touches the frame) means no
        -- point of the frame is inside. The dimension tells it on both engines: ST_Area fails on anything but
        -- polygons in MySQL, ST_IsEmpty is 0 for an empty collection in MariaDB, whose dimension is NULL in MySQL.
        UPDATE faker_tile_quarters SET coverage = CASE
            WHEN COALESCE(ST_Dimension(part), 0) < 2 THEN 'outside'
            WHEN ST_Contains(part, frame) THEN 'inside'
            ELSE 'crossed'
        END;

        INSERT INTO faker_geo_tiles (locale, region, row_no, col_no, inside, border)
        WITH RECURSIVE offsets (n) AS (SELECT 0 UNION ALL SELECT n + 1 FROM offsets WHERE n + 1 < v_size)
        SELECT p_locale, p_name, q.row_no + r.n, q.col_no + c.n, q.coverage = 'inside',
            IF(q.coverage = 'crossed', q.part, NULL)
        FROM faker_tile_quarters q
        CROSS JOIN offsets r
        CROSS JOIN offsets c
        WHERE q.coverage <> 'crossed' OR v_size = 1;

        DELETE FROM faker_tile_squares;
        INSERT INTO faker_tile_squares
        SELECT row_no, col_no, part FROM faker_tile_quarters WHERE coverage = 'crossed';
    END WHILE;
    DROP TEMPORARY TABLE faker_tile_quarters;
    DROP TEMPORARY TABLE faker_tile_squares;
END$$

-- ST_Contains(border, POINT(p_longitude, p_latitude)) of a region, answered from its tiles (faker_build_geo_tiles):
-- one primary key lookup, plus a containment test on a few vertices when the border crosses the tile.
-- Points outside the box are mapped to the nearest edge tile, which is only right within the margin of the tiles,
-- so callers pass points of the box. NULL for an unknown region.
DROP PROCEDURE IF EXISTS faker_border_contains$$
CREATE PROCEDURE faker_border_contains(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_region VARCHAR(100) CHARACTER SET utf8mb4,
    IN p_latitude DOUBLE, IN p_longitude DOUBLE, OUT p_inside BOOLEAN)
    READS SQL DATA
BEGIN
    SET p_inside = NULL;
    SELECT COALESCE(ST_Contains(t.border, POINT(p_longitude, p_latitude)), t.inside) INTO p_inside
    FROM faker_geo_regions r
    JOIN faker_geo_tiles t ON t.locale = r.locale AND t.region = r.name
    WHERE r.locale = p_locale AND r.name = p_region
      AND t.row_no = LEAST(GREATEST(FLOOR((p_latitude - r.lat_min) / (r.lat_max - r.lat_min) * r.tile_grid), 0),
                           r.tile_grid - 1)
      AND t.col_no = LEAST(GREATEST(FLOOR((p_longitude - r.lon_min) / (r.lon_max - r.lon_min) * r.tile_grid), 0),
                           r.tile_grid - 1);
END$$

-- Stores a border polygon (WKT, lon/lat degrees) as a region of the locale's territory. The box is the polygon's
-- envelope; the region joins list 'geo_region' with weight = spherical area of the box
-- (sin lat_max - sin lat_min) * (lon_max - lon_min in radians), which keeps the density constant across regions.
-- The box is split into c_tile_grid x c_tile_grid tiles for the border test (faker_build_geo_tiles).
DROP PROCEDURE IF EXISTS faker_add_geo_region$$
CREATE PROCEDURE faker_add_geo_region(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_name VARCHAR(100) CHARACTER SET utf8mb4,
    IN p_border_wkt LONGTEXT CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_unique BOOLEAN DEFAULT TRUE;
    DECLARE c_tile_grid INT DEFAULT 64;                      -- power of 2
    DECLARE v_border GEOMETRY DEFAULT ST_GeomFromText(p_border_wkt);
    DECLARE v_box GEOMETRY DEFAULT ST_ExteriorRing(ST_Envelope(v_border));
    DECLARE v_corner_a GEOMETRY DEFAULT ST_PointN(v_box, 1);
    DECLARE v_corner_b GEOMETRY DEFAULT ST_PointN(v_box, 3);
    DECLARE v_lat_min DOUBLE DEFAULT LEAST(ST_Y(v_corner_a), ST_Y(v_corner_b));
    DECLARE v_lat_max DOUBLE DEFAULT GREATEST(ST_Y(v_corner_a), ST_Y(v_corner_b));
    DECLARE v_lon_min DOUBLE DEFAULT LEAST(ST_X(v_corner_a), ST_X(v_corner_b));
    DECLARE v_lon_max DOUBLE DEFAULT GREATEST(ST_X(v_corner_a), ST_X(v_corner_b));
    DECLARE v_list_id INT;
    DELETE FROM faker_geo_regions WHERE locale = p_locale AND name = p_name;
    INSERT INTO faker_geo_regions (locale, name, lat_min, lat_max, lon_min, lon_max, tile_grid, border)
    VALUES (p_locale, p_name, v_lat_min, v_lat_max, v_lon_min, v_lon_max, c_tile_grid, v_border);
    CALL faker_build_geo_tiles(p_locale, p_name);
    CALL faker_ensure_list(p_locale, 'geo_region', '', v_list_id);
    CALL faker_append_value(v_list_id, p_name,
        (SIN(RADIANS(v_lat_max)) - SIN(RADIANS(v_lat_min))) * RADIANS(v_lon_max - v_lon_min), NULL, c_unique);
    CALL faker_refresh_lists(p_locale, 'geo_region');
END$$

-- Location inside the locale's territory with constant density per unit area (rejection sampling):
-- 1. choose a region from 'geo_region' (weight = spherical area of its box),
-- 2. draw an equal-area point in that box (faker_random_spherical_box),
-- 3. keep it if the region border contains it, otherwise start again at step 1 with the next attempt's streams.
-- Choosing the box again on every attempt makes the result uniform over all regions together: a point lands in
-- an area dA with probability proportional to (box area / total) * (dA / box area) = dA / total.
-- Locales without regions fall back to the whole sphere. After c_max_attempts misses (probability ~0.5^64) the
-- last point, still inside the box, is returned. Coordinates are rounded to c_coordinate_decimals (6 = ~0.1 m), which
-- also hides last-digit differences of SIN/ASIN between database engines.
-- Step 1 is faker_random_value(p_key, '<p_stream>.<attempt>.region', p_locale, 'geo_region', '') written as the
-- faker_pick query joined to the region's box, so one query gives both; step 3 uses the tiles of the region.
DROP PROCEDURE IF EXISTS faker_random_location$$
CREATE PROCEDURE faker_random_location(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, OUT p_latitude DOUBLE, OUT p_longitude DOUBLE)
    READS SQL DATA
BEGIN
    DECLARE c_max_attempts INT DEFAULT 64;
    DECLARE c_coordinate_decimals INT DEFAULT 6;
    DECLARE v_attempt INT DEFAULT 1;
    DECLARE v_inside BOOLEAN DEFAULT FALSE;
    DECLARE v_u DOUBLE;
    DECLARE v_region VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_lat_min, v_lat_max, v_lon_min, v_lon_max DOUBLE;
    attempts: WHILE v_attempt <= c_max_attempts AND NOT v_inside DO
        CALL faker_random_uniform(p_key, CONCAT(p_stream, '.', v_attempt, '.region'), v_u);
        SET v_region = NULL;
        SELECT r.name, r.lat_min, r.lat_max, r.lon_min, r.lon_max
        INTO v_region, v_lat_min, v_lat_max, v_lon_min, v_lon_max
        FROM faker_lookup_lists l
        JOIN faker_lookup_values v FORCE INDEX (faker_lookup_values_pick) ON v.list_id = l.list_id
        JOIN faker_geo_regions r ON r.locale = l.locale AND r.name = v.value
        WHERE l.locale = p_locale AND l.category = 'geo_region' AND l.variant = ''
          AND v.cum_weight >= v_u * l.total_weight
        ORDER BY v.cum_weight
        LIMIT 1;
        IF v_region IS NULL THEN
            CALL faker_random_geolocation(p_key, p_stream, p_latitude, p_longitude);
            LEAVE attempts;
        END IF;
        CALL faker_random_spherical_box(p_key, CONCAT(p_stream, '.', v_attempt), v_lat_min, v_lat_max, v_lon_min, v_lon_max,
            p_latitude, p_longitude);
        CALL faker_border_contains(p_locale, v_region, p_latitude, p_longitude, v_inside);
        SET v_attempt = v_attempt + 1;
    END WHILE;
    SET p_latitude = ROUND(p_latitude, c_coordinate_decimals), p_longitude = ROUND(p_longitude, c_coordinate_decimals);
END$$

DELIMITER ;
