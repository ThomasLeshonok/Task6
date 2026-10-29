-- Profiling: where the time of a generated user goes. Two views:
--   faker_profile_users      time of every step of faker_add_user_to_batch over many users (which step is slow),
--   faker_profile_primitives cost of one call of each building block (why it is slow: calls, lookups, geometry).
-- Timing uses SYSDATE(6) (microseconds, wall clock inside the server), so the numbers exclude the network.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Adds the microseconds since p_mark to p_microseconds and moves p_mark to now.
DROP PROCEDURE IF EXISTS faker_profile_lap$$
CREATE PROCEDURE faker_profile_lap(INOUT p_mark DATETIME(6), INOUT p_microseconds BIGINT)
    NO SQL
BEGIN
    DECLARE v_now DATETIME(6) DEFAULT SYSDATE(6);
    SET p_microseconds = p_microseconds + TIMESTAMPDIFF(MICROSECOND, p_mark, v_now);
    SET p_mark = v_now;
END$$

-- Does nothing: its cost is the bare price of one CALL.
DROP PROCEDURE IF EXISTS faker_profile_noop$$
CREATE PROCEDURE faker_profile_noop()
    NO SQL DETERMINISTIC
BEGIN
END$$

-- Session-private result table of the profilers: one row per measured step.
DROP PROCEDURE IF EXISTS faker_open_profile$$
CREATE PROCEDURE faker_open_profile()
    MODIFIES SQL DATA
BEGIN
    DROP TEMPORARY TABLE IF EXISTS faker_profile;
    CREATE TEMPORARY TABLE faker_profile (
        step_no      INT          NOT NULL PRIMARY KEY,
        step         VARCHAR(64)  CHARACTER SET utf8mb4 NOT NULL,
        calls        BIGINT       NOT NULL,
        microseconds BIGINT       NOT NULL
    );
END$$

-- Generates the users at 0-based positions p_start .. p_start + p_count - 1 exactly like faker_benchmark_users
-- (same procedures in the same order as faker_add_user_to_batch, same batch table) and times every step.
-- Result set, one row per step: step, calls, seconds, us_per_call, share (of the whole run).
-- Steps follow faker_add_user_to_batch call for call; tests/test_profiler.py checks they stay in sync.
DROP PROCEDURE IF EXISTS faker_profile_users$$
CREATE PROCEDURE faker_profile_users(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_start BIGINT, IN p_count INT,
    IN p_about_sentences INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_min_sentences INT DEFAULT 1;
    DECLARE c_flush_every INT DEFAULT 1000;
    DECLARE v_position BIGINT DEFAULT p_start;
    DECLARE v_started, v_mark DATETIME(6);
    DECLARE v_total BIGINT;
    DECLARE v_key_us, v_gender_us, v_name_us, v_address_us, v_location_us, v_physical_us, v_phone_us,
        v_email_us, v_about_count_us, v_about_us, v_insert_us, v_flush_us BIGINT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_gender, v_gender_label VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_title, v_first, v_middle, v_last, v_suffix, v_full_name VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_street, v_building, v_secondary, v_city, v_region VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_postal_code VARCHAR(32) CHARACTER SET utf8mb4;
    DECLARE v_address VARCHAR(500) CHARACTER SET utf8mb4;
    DECLARE v_latitude, v_longitude, v_height_cm, v_weight_kg DOUBLE;
    DECLARE v_height, v_weight VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_eye_color, v_hair_color, v_blood_type, v_phone, v_email VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_sentences BIGINT;
    DECLARE v_about TEXT CHARACTER SET utf8mb4;

    CALL faker_assert_locale(p_locale);
    CALL faker_open_batch();
    SET v_started = SYSDATE(6), v_mark = v_started;
    WHILE v_position < p_start + p_count DO
        CALL faker_rng_key(p_locale, p_seed, v_position, v_key);
        CALL faker_profile_lap(v_mark, v_key_us);
        CALL faker_random_gender(v_key, p_locale, v_gender, v_gender_label);
        CALL faker_profile_lap(v_mark, v_gender_us);
        CALL faker_random_person_name(v_key, p_locale, v_gender, v_title, v_first, v_middle, v_last, v_suffix, v_full_name);
        CALL faker_profile_lap(v_mark, v_name_us);
        CALL faker_random_address(v_key, p_locale, v_street, v_building, v_secondary, v_city, v_region, v_postal_code, v_address);
        CALL faker_profile_lap(v_mark, v_address_us);
        CALL faker_random_location(v_key, 'geo', p_locale, v_latitude, v_longitude);
        CALL faker_profile_lap(v_mark, v_location_us);
        CALL faker_random_physical(v_key, p_locale, v_gender, v_height_cm, v_height, v_weight_kg, v_weight,
            v_eye_color, v_hair_color, v_blood_type);
        CALL faker_profile_lap(v_mark, v_physical_us);
        CALL faker_random_phone(v_key, p_locale, v_phone);
        CALL faker_profile_lap(v_mark, v_phone_us);
        CALL faker_random_email(v_key, p_locale, v_first, v_last, v_email);
        CALL faker_profile_lap(v_mark, v_email_us);
        CALL faker_random_int(v_key, 'about.sentences', c_min_sentences, GREATEST(p_about_sentences, c_min_sentences), v_sentences);
        CALL faker_profile_lap(v_mark, v_about_count_us);
        CALL faker_markov_text(v_key, 'about', p_locale, v_sentences, v_about);
        CALL faker_profile_lap(v_mark, v_about_us);
        INSERT INTO faker_batch VALUES (v_position + 1, v_full_name, v_gender_label, v_address, v_latitude, v_longitude,
            v_height, v_height_cm, v_weight, v_weight_kg, v_eye_color, v_hair_color, v_blood_type, v_phone, v_email, v_about);
        CALL faker_profile_lap(v_mark, v_insert_us);
        SET v_position = v_position + 1;
        IF (v_position - p_start) MOD c_flush_every = 0 THEN
            DELETE FROM faker_batch;
        END IF;
        CALL faker_profile_lap(v_mark, v_flush_us);
    END WHILE;
    SET v_total = TIMESTAMPDIFF(MICROSECOND, v_started, SYSDATE(6));
    DROP TEMPORARY TABLE faker_batch;

    CALL faker_open_profile();
    INSERT INTO faker_profile VALUES
        (1, 'faker_rng_key', p_count, v_key_us),
        (2, 'faker_random_gender', p_count, v_gender_us),
        (3, 'faker_random_person_name', p_count, v_name_us),
        (4, 'faker_random_address', p_count, v_address_us),
        (5, 'faker_random_location', p_count, v_location_us),
        (6, 'faker_random_physical', p_count, v_physical_us),
        (7, 'faker_random_phone', p_count, v_phone_us),
        (8, 'faker_random_email', p_count, v_email_us),
        (9, 'faker_random_int', p_count, v_about_count_us),
        (10, 'faker_markov_text', p_count, v_about_us),
        (11, 'INSERT faker_batch', p_count, v_insert_us),
        (12, 'loop + flush', p_count, v_flush_us),
        (13, 'total', p_count, v_total);
    SELECT step, calls, microseconds / 1e6 AS seconds, microseconds / NULLIF(calls, 0) AS us_per_call,
        microseconds / NULLIF(v_total, 0) AS share
    FROM faker_profile ORDER BY step_no;
    DROP TEMPORARY TABLE faker_profile;
END$$

-- p_count calls of one building block with typical arguments; p_seconds = time of the whole loop.
-- 'empty_loop' is the loop alone and 'call_overhead' an empty CALL, the baselines for the others.
DROP PROCEDURE IF EXISTS faker_profile_primitive$$
CREATE PROCEDURE faker_profile_primitive(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_primitive VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_count INT, OUT p_seconds DOUBLE)
    READS SQL DATA
BEGIN
    DECLARE c_microseconds_per_second DOUBLE DEFAULT 1000000;
    DECLARE c_seed BIGINT DEFAULT 42;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_started DATETIME(6);
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_bits BIGINT UNSIGNED;
    DECLARE v_number BIGINT;
    DECLARE v_u, v_latitude, v_longitude, v_center_lat, v_center_lon DOUBLE;
    DECLARE v_inside BOOLEAN;
    DECLARE v_order INT;
    DECLARE v_state, v_value, v_region VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_details, v_text MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_sentence TEXT CHARACTER SET utf8mb4;

    SELECT chain_order INTO v_order FROM faker_markov_models WHERE locale = p_locale;
    CALL faker_markov_start(COALESCE(v_order, 1), v_state);
    SELECT name, (lat_min + lat_max) / 2, (lon_min + lon_max) / 2 INTO v_region, v_center_lat, v_center_lon
    FROM faker_geo_regions WHERE locale = p_locale ORDER BY LENGTH(ST_AsBinary(border)) DESC LIMIT 1;

    SET v_started = SYSDATE(6);
    WHILE v_i < p_count DO
        SET v_key = MD5(v_i);
        CASE p_primitive
            WHEN 'empty_loop' THEN DO 0;
            WHEN 'call_overhead' THEN CALL faker_profile_noop();
            WHEN 'select_into' THEN SELECT decimal_separator INTO v_value FROM faker_locales WHERE code = p_locale;
            WHEN 'faker_rng_key' THEN CALL faker_rng_key(p_locale, c_seed, v_i, v_key);
            WHEN 'faker_random_bits' THEN CALL faker_random_bits(v_key, 'profile', v_bits);
            WHEN 'faker_random_uniform' THEN CALL faker_random_uniform(v_key, 'profile', v_u);
            WHEN 'faker_random_int' THEN CALL faker_random_int(v_key, 'profile', 0, 9, v_number);
            WHEN 'faker_random_normal' THEN CALL faker_random_normal(v_key, 'profile', 170, 8, v_u);
            WHEN 'faker_pick' THEN CALL faker_pick(p_locale, 'last_name', '', v_i MOD 1000 / 1000, v_value, v_details);
            WHEN 'faker_random_value' THEN CALL faker_random_value(v_key, 'profile', p_locale, 'last_name', '', v_value);
            WHEN 'faker_random_item' THEN CALL faker_random_item(v_key, 'profile', p_locale, 'city', '', v_value, v_details);
            WHEN 'faker_random_value(markov)' THEN
                CALL faker_random_value(v_key, 'profile', p_locale, 'markov', v_state, v_value);
            WHEN 'faker_fill_digits(#####)' THEN CALL faker_fill_digits(v_key, 'profile', '#####', v_value);
            WHEN 'faker_render' THEN
                CALL faker_render('{first} {last}', JSON_OBJECT('first', 'Anna', 'last', 'Lee'), v_text);
            WHEN 'faker_expand' THEN CALL faker_expand(v_key, 'profile', p_locale, '{street_name}', NULL, v_text);
            WHEN 'faker_to_ascii' THEN CALL faker_to_ascii(p_locale, 'Müller-Lüdenscheidt', v_value);
            WHEN 'faker_format_decimal' THEN CALL faker_format_decimal(1.75, 2, ',', v_value);
            WHEN 'faker_random_spherical_box' THEN
                CALL faker_random_spherical_box(v_key, 'profile', 47, 55, 6, 15, v_latitude, v_longitude);
            WHEN 'ST_Contains(biggest border)' THEN
                SELECT ST_Contains(border, POINT(v_center_lon + v_i MOD 10 / 10, v_center_lat)) INTO v_inside
                FROM faker_geo_regions WHERE locale = p_locale AND name = v_region;
            WHEN 'faker_border_contains(biggest border)' THEN
                CALL faker_border_contains(p_locale, v_region, v_center_lat, v_center_lon + v_i MOD 10 / 10, v_inside);
            WHEN 'faker_random_location' THEN CALL faker_random_location(v_key, 'profile', p_locale, v_latitude, v_longitude);
            WHEN 'faker_markov_sentence' THEN CALL faker_markov_sentence(v_key, 'profile', p_locale, v_sentence);
        END CASE;
        SET v_i = v_i + 1;
    END WHILE;
    SET p_seconds = TIMESTAMPDIFF(MICROSECOND, v_started, SYSDATE(6)) / c_microseconds_per_second;
END$$

-- Cost of one call of every building block for a locale, p_count calls each.
-- Result set: primitive, calls, seconds, us_per_call, us_over_loop (us_per_call minus the empty loop).
DROP PROCEDURE IF EXISTS faker_profile_primitives$$
CREATE PROCEDURE faker_profile_primitives(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_count INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_microseconds_per_second DOUBLE DEFAULT 1000000;
    DECLARE c_primitives JSON DEFAULT JSON_ARRAY('empty_loop', 'call_overhead', 'select_into',
        'faker_rng_key', 'faker_random_bits', 'faker_random_uniform', 'faker_random_int', 'faker_random_normal',
        'faker_pick', 'faker_random_value', 'faker_random_item', 'faker_random_value(markov)',
        'faker_fill_digits(#####)', 'faker_render', 'faker_expand', 'faker_to_ascii', 'faker_format_decimal',
        'faker_random_spherical_box', 'ST_Contains(biggest border)', 'faker_border_contains(biggest border)',
        'faker_random_location', 'faker_markov_sentence');
    DECLARE v_n INT DEFAULT 0;
    DECLARE v_primitive VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_seconds DOUBLE;
    DECLARE v_loop_us DOUBLE;
    CALL faker_assert_locale(p_locale);
    CALL faker_open_profile();
    WHILE v_n < JSON_LENGTH(c_primitives) DO
        SET v_primitive = JSON_UNQUOTE(JSON_EXTRACT(c_primitives, CONCAT('$[', v_n, ']')));
        CALL faker_profile_primitive(p_locale, v_primitive, p_count, v_seconds);
        INSERT INTO faker_profile VALUES (v_n, v_primitive, p_count, ROUND(v_seconds * c_microseconds_per_second));
        SET v_n = v_n + 1;
    END WHILE;
    SELECT microseconds / calls INTO v_loop_us FROM faker_profile WHERE step = 'empty_loop';
    SELECT step AS primitive, calls, microseconds / 1e6 AS seconds, microseconds / calls AS us_per_call,
        microseconds / calls - v_loop_us AS us_over_loop
    FROM faker_profile ORDER BY step_no;
    DROP TEMPORARY TABLE faker_profile;
END$$

DELIMITER ;
