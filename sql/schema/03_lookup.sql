-- Lookup lists: loading helpers and weighted random selection.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Line breaks and tabs become spaces, runs of spaces collapse to one, ends are trimmed.
DROP PROCEDURE IF EXISTS faker_clean_text$$
CREATE PROCEDURE faker_clean_text(IN p_text MEDIUMTEXT CHARACTER SET utf8mb4, OUT p_result MEDIUMTEXT CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    SET p_result = REPLACE(REPLACE(REPLACE(p_text,
        CHAR(13 USING utf8mb4), ' '), CHAR(10 USING utf8mb4), ' '), CHAR(9 USING utf8mb4), ' ');
    WHILE LOCATE('  ', p_result) > 0 DO
        SET p_result = REPLACE(p_result, '  ', ' ');
    END WHILE;
    SET p_result = TRIM(p_result);
END$$

-- Id of list (locale, category, variant), created empty when missing.
DROP PROCEDURE IF EXISTS faker_ensure_list$$
CREATE PROCEDURE faker_ensure_list(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, OUT p_list_id INT)
    MODIFIES SQL DATA
BEGIN
    SET p_list_id = NULL;
    SELECT list_id INTO p_list_id FROM faker_lookup_lists
    WHERE locale = p_locale AND category = p_category AND variant = p_variant;
    IF p_list_id IS NULL THEN
        INSERT INTO faker_lookup_lists (locale, category, variant) VALUES (p_locale, p_category, p_variant);
        SET p_list_id = LAST_INSERT_ID();
    END IF;
END$$

-- Recomputes running weights and totals of every list of one category in a locale.
DROP PROCEDURE IF EXISTS faker_refresh_lists$$
CREATE PROCEDURE faker_refresh_lists(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    UPDATE faker_lookup_values v
    JOIN (
        SELECT i.list_id, i.item_no, SUM(i.weight) OVER (PARTITION BY i.list_id ORDER BY i.item_no) AS running
        FROM faker_lookup_values i
        JOIN faker_lookup_lists l ON l.list_id = i.list_id
        WHERE l.locale = p_locale AND l.category = p_category
    ) s ON s.list_id = v.list_id AND s.item_no = v.item_no
    SET v.cum_weight = s.running;

    UPDATE faker_lookup_lists l
    JOIN (
        SELECT list_id, COUNT(*) AS item_count, MAX(cum_weight) AS total_weight
        FROM faker_lookup_values
        GROUP BY list_id
    ) s ON s.list_id = l.list_id
    SET l.item_count = s.item_count, l.total_weight = s.total_weight
    WHERE l.locale = p_locale AND l.category = p_category;
END$$

-- Appends one item at the end of a list. With p_unique, a value already in the list is skipped, so loading the
-- same words twice is harmless; compound items are kept as given (two cities may share a name).
DROP PROCEDURE IF EXISTS faker_append_value$$
CREATE PROCEDURE faker_append_value(
    IN p_list_id INT, IN p_value VARCHAR(255) CHARACTER SET utf8mb4, IN p_weight DOUBLE,
    IN p_details MEDIUMTEXT CHARACTER SET utf8mb4, IN p_unique BOOLEAN)
    MODIFIES SQL DATA
BEGIN
    IF p_value <> '' AND NOT (p_unique AND EXISTS (
            SELECT 1 FROM faker_lookup_values WHERE list_id = p_list_id AND value = p_value)) THEN
        INSERT INTO faker_lookup_values (list_id, item_no, value, weight, details)
        SELECT p_list_id, COALESCE(MAX(item_no), 0) + 1, p_value, p_weight, p_details
        FROM faker_lookup_values
        WHERE list_id = p_list_id;
    END IF;
END$$

-- Appends delimited words with weight 1: CALL faker_add_words('en_US', 'last_name', '', 'Smith|Johnson', '|').
-- Whitespace and line breaks around words are trimmed, so long lists can span many lines.
DROP PROCEDURE IF EXISTS faker_add_words$$
CREATE PROCEDURE faker_add_words(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, IN p_words MEDIUMTEXT CHARACTER SET utf8mb4,
    IN p_delimiter VARCHAR(8) CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_weight DOUBLE DEFAULT 1;
    DECLARE v_list_id INT;
    DECLARE v_rest MEDIUMTEXT CHARACTER SET utf8mb4 DEFAULT p_words;
    DECLARE v_word MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_at INT;
    CALL faker_ensure_list(p_locale, p_category, p_variant, v_list_id);
    WHILE CHAR_LENGTH(v_rest) > 0 DO
        SET v_at = LOCATE(p_delimiter, v_rest);
        IF v_at = 0 THEN
            SET v_word = v_rest, v_rest = '';
        ELSE
            SET v_word = LEFT(v_rest, v_at - 1), v_rest = SUBSTRING(v_rest, v_at + CHAR_LENGTH(p_delimiter));
        END IF;
        CALL faker_clean_text(v_word, v_word);
        CALL faker_append_value(v_list_id, v_word, c_weight, NULL, TRUE);
    END WHILE;
    CALL faker_refresh_lists(p_locale, p_category);
END$$

-- Appends values given as a JSON array, optionally weighted by a JSON array of numbers (NULL = weight 1):
-- CALL faker_add_values('en_US', 'title', 'female', '["Ms.", "Mrs.", "Dr."]', '[40, 34, 12]').
DROP PROCEDURE IF EXISTS faker_add_values$$
CREATE PROCEDURE faker_add_values(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, IN p_values MEDIUMTEXT CHARACTER SET utf8mb4,
    IN p_weights MEDIUMTEXT CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_default_weight DOUBLE DEFAULT 1;
    DECLARE v_list_id INT;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_path VARCHAR(32);
    CALL faker_ensure_list(p_locale, p_category, p_variant, v_list_id);
    WHILE v_i < JSON_LENGTH(p_values) DO
        SET v_path = CONCAT('$[', v_i, ']');
        CALL faker_append_value(v_list_id,
            JSON_UNQUOTE(JSON_EXTRACT(p_values, v_path)),
            COALESCE(JSON_EXTRACT(p_weights, v_path) + 0, c_default_weight),
            NULL, TRUE);
        SET v_i = v_i + 1;
    END WHILE;
    CALL faker_refresh_lists(p_locale, p_category);
END$$

-- Appends compound items: p_items is a JSON array of arrays, p_fields a JSON array naming the positions.
-- 'value' is required, 'weight' optional, every other field goes into details (as text):
--   CALL faker_add_items('en_US', 'city', '', '["value", "region_code", "postal_prefix"]',
--                        '[["Boston", "MA", "021"], ["Denver", "CO", "802"]]');
DROP PROCEDURE IF EXISTS faker_add_items$$
CREATE PROCEDURE faker_add_items(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, IN p_fields MEDIUMTEXT CHARACTER SET utf8mb4,
    IN p_items MEDIUMTEXT CHARACTER SET utf8mb4)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_default_weight DOUBLE DEFAULT 1;
    DECLARE v_list_id INT;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_f INT;
    DECLARE v_item MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_field VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_text VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_value VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_weight DOUBLE;
    DECLARE v_details MEDIUMTEXT CHARACTER SET utf8mb4;
    IF JSON_SEARCH(p_fields, 'one', 'value') IS NULL THEN
        SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = 'faker_add_items: p_fields must contain "value"';
    END IF;
    CALL faker_ensure_list(p_locale, p_category, p_variant, v_list_id);
    WHILE v_i < JSON_LENGTH(p_items) DO
        SET v_item = JSON_EXTRACT(p_items, CONCAT('$[', v_i, ']'));
        SET v_value = NULL, v_weight = c_default_weight, v_details = JSON_OBJECT(), v_f = 0;
        WHILE v_f < JSON_LENGTH(p_fields) DO
            SET v_field = JSON_UNQUOTE(JSON_EXTRACT(p_fields, CONCAT('$[', v_f, ']')));
            SET v_text = JSON_UNQUOTE(JSON_EXTRACT(v_item, CONCAT('$[', v_f, ']')));
            IF v_field = 'value' THEN
                SET v_value = v_text;
            ELSEIF v_field = 'weight' THEN
                SET v_weight = v_text + 0;
            ELSE
                SET v_details = JSON_SET(v_details, CONCAT('$.', v_field), v_text);
            END IF;
            SET v_f = v_f + 1;
        END WHILE;
        CALL faker_append_value(v_list_id, v_value, v_weight, v_details, FALSE);
        SET v_i = v_i + 1;
    END WHILE;
    CALL faker_refresh_lists(p_locale, p_category);
END$$

-- Weighted selection by inverse CDF: the item whose running-weight interval contains p_u * total_weight.
-- The list row is found by its unique key, so the item lookup is one range seek on (list_id, cum_weight).
-- FORCE INDEX keeps it a seek: left alone, the optimizer reads the list from its first item whenever it expects the
-- match far down the list (ref access on list_id), which costs a step per skipped item. faker_random_location and
-- faker_markov_sentence repeat this query (joined to what they need next); tests check that they agree.
-- Returns NULLs when the list does not exist.
DROP PROCEDURE IF EXISTS faker_pick$$
CREATE PROCEDURE faker_pick(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, IN p_u DOUBLE,
    OUT p_value VARCHAR(255) CHARACTER SET utf8mb4, OUT p_details MEDIUMTEXT CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    SET p_value = NULL, p_details = NULL;
    SELECT v.value, v.details INTO p_value, p_details
    FROM faker_lookup_lists l
    JOIN faker_lookup_values v FORCE INDEX (faker_lookup_values_pick) ON v.list_id = l.list_id
    WHERE l.locale = p_locale AND l.category = p_category AND l.variant = p_variant
      AND v.cum_weight >= p_u * l.total_weight
    ORDER BY v.cum_weight
    LIMIT 1;
END$$

-- Random value of a list for one draw of a record (NULL when the locale has no such list):
-- faker_pick of faker_random_uniform(p_key, p_stream), the uniform written out as in faker_random_uniform.
DROP PROCEDURE IF EXISTS faker_random_value$$
CREATE PROCEDURE faker_random_value(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, OUT p_value VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_hex_digits INT DEFAULT 16;                     -- as in faker_random_uniform
    DECLARE c_hash_bits INT DEFAULT 64;
    DECLARE c_mantissa_bits INT DEFAULT 53;
    DECLARE v_u DOUBLE DEFAULT (CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream)), c_hex_digits), 16, 10) AS UNSIGNED)
        >> (c_hash_bits - c_mantissa_bits)) / POW(2, c_mantissa_bits);
    DECLARE v_details MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_pick(p_locale, p_category, p_variant, v_u, p_value, v_details);
END$$

-- Random item with its details (compound items such as cities); the uniform as in faker_random_value.
DROP PROCEDURE IF EXISTS faker_random_item$$
CREATE PROCEDURE faker_random_item(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_category VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_value VARCHAR(255) CHARACTER SET utf8mb4, OUT p_details MEDIUMTEXT CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_hex_digits INT DEFAULT 16;                     -- as in faker_random_uniform
    DECLARE c_hash_bits INT DEFAULT 64;
    DECLARE c_mantissa_bits INT DEFAULT 53;
    DECLARE v_u DOUBLE DEFAULT (CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream)), c_hex_digits), 16, 10) AS UNSIGNED)
        >> (c_hash_bits - c_mantissa_bits)) / POW(2, c_mantissa_bits);
    CALL faker_pick(p_locale, p_category, p_variant, v_u, p_value, p_details);
END$$

-- Catalog of the lists of a locale, for inspection (result set).
DROP PROCEDURE IF EXISTS faker_list_categories$$
CREATE PROCEDURE faker_list_categories(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    SELECT category, variant, item_count, total_weight
    FROM faker_lookup_lists
    WHERE locale = p_locale AND category <> 'markov'
    ORDER BY category, variant;
END$$

DELIMITER ;
