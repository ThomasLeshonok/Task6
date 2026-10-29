-- Formatted strings: digit masks, template rendering, ASCII folding.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Replaces every '#' with a random digit 0-9 and every '%' with 1-9; other characters are kept.
-- Each position uses its own draw, so '(###) %##-####' gives independent digits. A digit is exactly
-- faker_random_int(p_key, '<p_stream>.<position>', min, 9), written out here (bits -> uniform -> integer) because
-- the three nested CALLs per digit cost several times the hash itself; tests check that the two agree.
DROP PROCEDURE IF EXISTS faker_fill_digits$$
CREATE PROCEDURE faker_fill_digits(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_template VARCHAR(255) CHARACTER SET utf8mb4, OUT p_result VARCHAR(255) CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE c_any_digit CHAR(1) DEFAULT '#';
    DECLARE c_nonzero_digit CHAR(1) DEFAULT '%';
    DECLARE c_min_digit INT DEFAULT 0;
    DECLARE c_min_nonzero INT DEFAULT 1;
    DECLARE c_max_digit INT DEFAULT 9;
    DECLARE c_hex_digits INT DEFAULT 16;                     -- as in faker_random_bits
    DECLARE c_hash_bits INT DEFAULT 64;                      -- as in faker_random_uniform
    DECLARE c_mantissa_bits INT DEFAULT 53;
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_ch VARCHAR(4) CHARACTER SET utf8mb4;
    DECLARE v_min INT;
    DECLARE v_bits BIGINT UNSIGNED;
    DECLARE v_u DOUBLE;
    DECLARE v_digit BIGINT;
    SET p_result = '';
    WHILE v_i <= CHAR_LENGTH(p_template) DO
        SET v_ch = SUBSTRING(p_template, v_i, 1);
        IF v_ch IN (c_any_digit, c_nonzero_digit) THEN
            SET v_min = IF(v_ch = c_any_digit, c_min_digit, c_min_nonzero);
            SET v_bits = CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream, '.', v_i)), c_hex_digits), 16, 10) AS UNSIGNED);
            SET v_u = (v_bits >> (c_hash_bits - c_mantissa_bits)) / POW(2, c_mantissa_bits);
            SET v_digit = v_min + FLOOR(v_u * (c_max_digit - v_min + 1));
            SET v_ch = v_digit;
        END IF;
        SET p_result = CONCAT(p_result, v_ch);
        SET v_i = v_i + 1;
    END WHILE;
END$$

-- Substitutes {name} placeholders with values of the JSON object p_vars (missing or null values become empty),
-- removes placeholders left without a value and collapses the whitespace left behind.
DROP PROCEDURE IF EXISTS faker_render$$
CREATE PROCEDURE faker_render(
    IN p_template VARCHAR(255) CHARACTER SET utf8mb4, IN p_vars MEDIUMTEXT CHARACTER SET utf8mb4,
    OUT p_result MEDIUMTEXT CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE v_names MEDIUMTEXT CHARACTER SET utf8mb4 DEFAULT JSON_KEYS(COALESCE(p_vars, JSON_OBJECT()));
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_name VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_raw MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_open INT;
    DECLARE v_close INT;
    SET p_result = p_template;
    WHILE v_i < JSON_LENGTH(v_names) DO
        SET v_name = JSON_UNQUOTE(JSON_EXTRACT(v_names, CONCAT('$[', v_i, ']')));
        SET v_raw = JSON_EXTRACT(p_vars, CONCAT('$.', v_name));
        SET p_result = REPLACE(p_result, CONCAT('{', v_name, '}'),
            IF(v_raw IS NULL OR JSON_TYPE(v_raw) = 'NULL', '', JSON_UNQUOTE(v_raw)));
        SET v_i = v_i + 1;
    END WHILE;

    SET v_open = LOCATE('{', p_result);
    WHILE v_open > 0 DO
        SET v_close = LOCATE('}', p_result, v_open);
        IF v_close = 0 THEN
            SET v_open = 0;
        ELSE
            SET p_result = CONCAT(LEFT(p_result, v_open - 1), SUBSTRING(p_result, v_close + 1));
            SET v_open = LOCATE('{', p_result, v_open);
        END IF;
    END WHILE;
    CALL faker_clean_text(p_result, p_result);
END$$

-- Renders a template, filling every placeholder missing from p_vars with a random value of the lookup list
-- named like the placeholder: '{street_name} {street_type}' draws from lists street_name and street_type.
-- New placeholders therefore need only a new list, no code.
DROP PROCEDURE IF EXISTS faker_expand$$
CREATE PROCEDURE faker_expand(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_template VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_vars MEDIUMTEXT CHARACTER SET utf8mb4, OUT p_result MEDIUMTEXT CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_no_variant VARCHAR(1) DEFAULT '';
    DECLARE v_vars MEDIUMTEXT CHARACTER SET utf8mb4 DEFAULT COALESCE(p_vars, JSON_OBJECT());
    DECLARE v_open INT DEFAULT LOCATE('{', p_template);
    DECLARE v_close INT;
    DECLARE v_name VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_value VARCHAR(255) CHARACTER SET utf8mb4;
    WHILE v_open > 0 DO
        SET v_close = LOCATE('}', p_template, v_open);
        IF v_close = 0 THEN
            SET v_open = 0;
        ELSE
            SET v_name = SUBSTRING(p_template, v_open + 1, v_close - v_open - 1);
            IF JSON_CONTAINS_PATH(v_vars, 'one', CONCAT('$.', v_name)) = 0 THEN
                CALL faker_random_value(p_key, CONCAT(p_stream, '.', v_name), p_locale, v_name, c_no_variant, v_value);
                SET v_vars = JSON_SET(v_vars, CONCAT('$.', v_name), v_value);
            END IF;
            SET v_open = LOCATE('{', p_template, v_close);
        END IF;
    END WHILE;
    CALL faker_render(p_template, v_vars, p_result);
END$$

-- Lower-case ASCII form for e-mail addresses: locale transliteration rules (list 'transliteration',
-- value = one character outside [a-z0-9], details.ascii = its ASCII replacement, e.g. 'ü' -> 'ue'); anything else
-- outside [a-z0-9] is dropped. The text is walked character by character and only characters outside [a-z0-9] are
-- looked up, each with a primary key seek, so a plain name costs no query. (A cursor or a join sorted by item_no
-- went through an on-disk temporary table on MariaDB, because of the JSON column: milliseconds per call, the
-- slowest step of a user.) SUBSTRING, not REGEXP_SUBSTR, picks the characters: MariaDB 10.4 returns '?' from
-- REGEXP_SUBSTR for 4-byte characters such as emoji.
DROP PROCEDURE IF EXISTS faker_to_ascii$$
CREATE PROCEDURE faker_to_ascii(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_text VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_result VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_not_ascii VARCHAR(16) DEFAULT '[^a-z0-9]';
    DECLARE v_text VARCHAR(255) CHARACTER SET utf8mb4 DEFAULT LOWER(p_text);
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_list_id INT;
    DECLARE v_char VARCHAR(4) CHARACTER SET utf8mb4;
    DECLARE v_to VARCHAR(255) CHARACTER SET utf8mb4;
    IF LENGTH(v_text) = CHAR_LENGTH(v_text) AND v_text NOT REGEXP c_not_ascii THEN
        SET p_result = v_text;                                  -- only [a-z0-9] already
    ELSE
        SELECT list_id INTO v_list_id
        FROM faker_lookup_lists
        WHERE locale = p_locale AND category = 'transliteration' AND variant = '';
        SET p_result = '';
        WHILE v_i <= CHAR_LENGTH(v_text) DO
            SET v_char = SUBSTRING(v_text, v_i, 1), v_to = v_char;
            -- ORD is the byte value for one-byte characters (larger for others): exact, unlike the _ci collation,
            -- and with no conversion, which MySQL 8 refuses for non-ASCII bytes (error 3854)
            IF NOT (ORD(v_char) BETWEEN ORD('a') AND ORD('z') OR ORD(v_char) BETWEEN ORD('0') AND ORD('9')) THEN
                SET v_to = NULL;
                SELECT JSON_UNQUOTE(JSON_EXTRACT(details, '$.ascii')) INTO v_to
                FROM faker_lookup_values
                WHERE list_id = v_list_id AND value = v_char
                ORDER BY item_no
                LIMIT 1;
                SET v_to = REGEXP_REPLACE(COALESCE(v_to, v_char), c_not_ascii, '');
            END IF;
            SET p_result = CONCAT(p_result, v_to);
            SET v_i = v_i + 1;
        END WHILE;
    END IF;
END$$

-- Formats a number with a fixed count of decimals and a decimal separator (faker_locales.decimal_separator, which
-- the caller reads once for all the numbers of a record).
DROP PROCEDURE IF EXISTS faker_format_decimal$$
CREATE PROCEDURE faker_format_decimal(
    IN p_value DOUBLE, IN p_decimals INT, IN p_separator VARCHAR(4) CHARACTER SET utf8mb4,
    OUT p_result VARCHAR(64) CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    SET p_result = REPLACE(REPLACE(FORMAT(p_value, p_decimals), ',', ''), '.', p_separator);
END$$

DELIMITER ;
