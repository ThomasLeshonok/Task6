-- Sampling and benchmark helpers: many draws of one primitive as a result set, to check the distributions
-- (used by tests/test_procedures.py, handy for histograms).
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- p_count points from faker_random_geolocation: the whole sphere.
DROP PROCEDURE IF EXISTS faker_sample_geolocations$$
CREATE PROCEDURE faker_sample_geolocations(IN p_seed BIGINT, IN p_count INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_latitude, v_longitude DOUBLE;
    DROP TEMPORARY TABLE IF EXISTS faker_sample;
    CREATE TEMPORARY TABLE faker_sample (n INT NOT NULL PRIMARY KEY, latitude DOUBLE, longitude DOUBLE);
    WHILE v_i < p_count DO
        CALL faker_rng_key('sample', p_seed, v_i, v_key);
        CALL faker_random_geolocation(v_key, 'geo', v_latitude, v_longitude);
        INSERT INTO faker_sample VALUES (v_i, v_latitude, v_longitude);
        SET v_i = v_i + 1;
    END WHILE;
    SELECT latitude, longitude FROM faker_sample ORDER BY n;
    DROP TEMPORARY TABLE faker_sample;
END$$

-- p_count points from faker_random_location: inside the locale's territory.
DROP PROCEDURE IF EXISTS faker_sample_locations$$
CREATE PROCEDURE faker_sample_locations(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_count INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_latitude, v_longitude DOUBLE;
    DROP TEMPORARY TABLE IF EXISTS faker_sample;
    CREATE TEMPORARY TABLE faker_sample (n INT NOT NULL PRIMARY KEY, latitude DOUBLE, longitude DOUBLE);
    WHILE v_i < p_count DO
        CALL faker_rng_key('sample', p_seed, v_i, v_key);
        CALL faker_random_location(v_key, 'geo', p_locale, v_latitude, v_longitude);
        INSERT INTO faker_sample VALUES (v_i, v_latitude, v_longitude);
        SET v_i = v_i + 1;
    END WHILE;
    SELECT latitude, longitude FROM faker_sample ORDER BY n;
    DROP TEMPORARY TABLE faker_sample;
END$$

-- p_count points drawn like one attempt of faker_random_location (weighted region, equal-area point of its box),
-- each with the border test answered by the tiles (faker_border_contains) and by ST_Contains on the whole border.
DROP PROCEDURE IF EXISTS faker_sample_border_checks$$
CREATE PROCEDURE faker_sample_border_checks(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_count INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_region VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_lat_min, v_lat_max, v_lon_min, v_lon_max, v_latitude, v_longitude DOUBLE;
    DECLARE v_by_tiles, v_by_border BOOLEAN;
    DROP TEMPORARY TABLE IF EXISTS faker_sample;
    CREATE TEMPORARY TABLE faker_sample (
        n INT NOT NULL PRIMARY KEY, region VARCHAR(100) CHARACTER SET utf8mb4, latitude DOUBLE, longitude DOUBLE,
        by_tiles BOOLEAN, by_border BOOLEAN);
    WHILE v_i < p_count DO
        CALL faker_rng_key('sample', p_seed, v_i, v_key);
        CALL faker_random_value(v_key, 'region', p_locale, 'geo_region', '', v_region);
        SELECT lat_min, lat_max, lon_min, lon_max INTO v_lat_min, v_lat_max, v_lon_min, v_lon_max
        FROM faker_geo_regions WHERE locale = p_locale AND name = v_region;
        CALL faker_random_spherical_box(v_key, 'point', v_lat_min, v_lat_max, v_lon_min, v_lon_max, v_latitude, v_longitude);
        CALL faker_border_contains(p_locale, v_region, v_latitude, v_longitude, v_by_tiles);
        SELECT ST_Contains(border, POINT(v_longitude, v_latitude)) INTO v_by_border
        FROM faker_geo_regions WHERE locale = p_locale AND name = v_region;
        INSERT INTO faker_sample VALUES (v_i, v_region, v_latitude, v_longitude, v_by_tiles, v_by_border);
        SET v_i = v_i + 1;
    END WHILE;
    SELECT region, latitude, longitude, by_tiles, by_border FROM faker_sample ORDER BY n;
    DROP TEMPORARY TABLE faker_sample;
END$$

-- p_count values from faker_random_normal(mean, stddev).
DROP PROCEDURE IF EXISTS faker_sample_normal$$
CREATE PROCEDURE faker_sample_normal(IN p_seed BIGINT, IN p_count INT, IN p_mean DOUBLE, IN p_stddev DOUBLE)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_value DOUBLE;
    DROP TEMPORARY TABLE IF EXISTS faker_sample;
    CREATE TEMPORARY TABLE faker_sample (n INT NOT NULL PRIMARY KEY, value DOUBLE);
    WHILE v_i < p_count DO
        CALL faker_rng_key('sample', p_seed, v_i, v_key);
        CALL faker_random_normal(v_key, 'normal', p_mean, p_stddev, v_value);
        INSERT INTO faker_sample VALUES (v_i, v_value);
        SET v_i = v_i + 1;
    END WHILE;
    SELECT value FROM faker_sample ORDER BY n;
    DROP TEMPORARY TABLE faker_sample;
END$$

-- p_count weighted draws from one lookup list.
DROP PROCEDURE IF EXISTS faker_sample_values$$
CREATE PROCEDURE faker_sample_values(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_count INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_value VARCHAR(255) CHARACTER SET utf8mb4;
    DROP TEMPORARY TABLE IF EXISTS faker_sample;
    CREATE TEMPORARY TABLE faker_sample (n INT NOT NULL PRIMARY KEY, value VARCHAR(255) CHARACTER SET utf8mb4);
    WHILE v_i < p_count DO
        CALL faker_rng_key('sample', p_seed, v_i, v_key);
        CALL faker_random_value(v_key, 'value', p_locale, p_category, p_variant, v_value);
        INSERT INTO faker_sample VALUES (v_i, v_value);
        SET v_i = v_i + 1;
    END WHILE;
    SELECT value FROM faker_sample ORDER BY n;
    DROP TEMPORARY TABLE faker_sample;
END$$

-- Benchmark: generates the users at 0-based positions p_start .. p_start + p_count - 1 exactly like
-- faker_generate_users, but sends no rows back, and reports the time the database spent in one row
-- (locale, users, seconds, users_per_second). The batch table is emptied every c_flush_every users so memory
-- stays flat for millions of users. Independent ranges can run at the same time on separate connections.
DROP PROCEDURE IF EXISTS faker_benchmark_users$$
CREATE PROCEDURE faker_benchmark_users(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_start BIGINT, IN p_count INT,
    IN p_about_sentences INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_flush_every INT DEFAULT 1000;
    DECLARE c_microseconds_per_second DOUBLE DEFAULT 1000000;
    DECLARE v_position BIGINT DEFAULT p_start;
    DECLARE v_started DATETIME(6);
    DECLARE v_seconds DOUBLE;
    CALL faker_assert_locale(p_locale);
    CALL faker_open_batch();
    SET v_started = SYSDATE(6);
    WHILE v_position < p_start + p_count DO
        CALL faker_add_user_to_batch(p_locale, p_seed, v_position, p_about_sentences);
        SET v_position = v_position + 1;
        IF (v_position - p_start) MOD c_flush_every = 0 THEN
            DELETE FROM faker_batch;
        END IF;
    END WHILE;
    SET v_seconds = TIMESTAMPDIFF(MICROSECOND, v_started, SYSDATE(6)) / c_microseconds_per_second;
    DROP TEMPORARY TABLE faker_batch;
    SELECT p_locale AS locale, p_count AS users, v_seconds AS seconds, p_count / NULLIF(v_seconds, 0) AS users_per_second;
END$$

DELIMITER ;
