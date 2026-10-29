-- Public API: what applications call. Each of these returns one result set.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Supported locales for pickers.
DROP PROCEDURE IF EXISTS faker_list_locales$$
CREATE PROCEDURE faker_list_locales()
    READS SQL DATA
BEGIN
    SELECT code, name FROM faker_locales ORDER BY sort_order, name;
END$$

-- Raises SQLSTATE 22023 (invalid parameter value) for an unknown locale, listing the known ones.
DROP PROCEDURE IF EXISTS faker_assert_locale$$
CREATE PROCEDURE faker_assert_locale(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_message VARCHAR(255) CHARACTER SET utf8mb4;
    IF NOT EXISTS (SELECT 1 FROM faker_locales WHERE code = p_locale) THEN
        SELECT CONCAT('Unknown locale "', p_locale, '". Available: ', GROUP_CONCAT(code ORDER BY code SEPARATOR ', '))
        INTO v_message FROM faker_locales;
        SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = v_message;
    END IF;
END$$

-- Session-private result table of the generators (dropped again by the caller).
DROP PROCEDURE IF EXISTS faker_open_batch$$
CREATE PROCEDURE faker_open_batch()
    MODIFIES SQL DATA
BEGIN
    DROP TEMPORARY TABLE IF EXISTS faker_batch;
    CREATE TEMPORARY TABLE faker_batch (
        position   BIGINT       NOT NULL PRIMARY KEY,
        full_name  VARCHAR(255) CHARACTER SET utf8mb4,
        gender     VARCHAR(255) CHARACTER SET utf8mb4,
        address    VARCHAR(500) CHARACTER SET utf8mb4,
        latitude   DOUBLE,
        longitude  DOUBLE,
        height     VARCHAR(64)  CHARACTER SET utf8mb4,
        height_cm  DOUBLE,
        weight     VARCHAR(64)  CHARACTER SET utf8mb4,
        weight_kg  DOUBLE,
        eye_color  VARCHAR(255) CHARACTER SET utf8mb4,
        hair_color VARCHAR(255) CHARACTER SET utf8mb4,
        blood_type VARCHAR(255) CHARACTER SET utf8mb4,
        phone      VARCHAR(255) CHARACTER SET utf8mb4,
        email      VARCHAR(255) CHARACTER SET utf8mb4,
        about      TEXT         CHARACTER SET utf8mb4
    );
END$$

-- Generates the user at an absolute position (0-based) of the (locale, seed) sequence into faker_batch.
-- Every attribute is drawn from its own named stream of the same key, so attributes are independent and
-- adding a new attribute never changes existing ones.
DROP PROCEDURE IF EXISTS faker_add_user_to_batch$$
CREATE PROCEDURE faker_add_user_to_batch(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_position BIGINT, IN p_about_sentences INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_min_sentences INT DEFAULT 1;
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

    CALL faker_rng_key(p_locale, p_seed, p_position, v_key);
    CALL faker_random_gender(v_key, p_locale, v_gender, v_gender_label);
    CALL faker_random_person_name(v_key, p_locale, v_gender, v_title, v_first, v_middle, v_last, v_suffix, v_full_name);
    CALL faker_random_address(v_key, p_locale, v_street, v_building, v_secondary, v_city, v_region, v_postal_code, v_address);
    CALL faker_random_location(v_key, 'geo', p_locale, v_latitude, v_longitude);
    CALL faker_random_physical(v_key, p_locale, v_gender, v_height_cm, v_height, v_weight_kg, v_weight,
        v_eye_color, v_hair_color, v_blood_type);
    CALL faker_random_phone(v_key, p_locale, v_phone);
    CALL faker_random_email(v_key, p_locale, v_first, v_last, v_email);
    CALL faker_random_int(v_key, 'about.sentences', c_min_sentences, GREATEST(p_about_sentences, c_min_sentences), v_sentences);
    CALL faker_markov_text(v_key, 'about', p_locale, v_sentences, v_about);

    INSERT INTO faker_batch VALUES (p_position + 1, v_full_name, v_gender_label, v_address, v_latitude, v_longitude,
        v_height, v_height_cm, v_weight, v_weight_kg, v_eye_color, v_hair_color, v_blood_type, v_phone, v_email, v_about);
END$$

-- One user at 0-based p_position; result set with the same columns as faker_generate_users.
DROP PROCEDURE IF EXISTS faker_generate_user$$
CREATE PROCEDURE faker_generate_user(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_position BIGINT, IN p_about_sentences INT)
    MODIFIES SQL DATA
BEGIN
    CALL faker_assert_locale(p_locale);
    CALL faker_open_batch();
    CALL faker_add_user_to_batch(p_locale, p_seed, p_position, p_about_sentences);
    SELECT * FROM faker_batch;
    DROP TEMPORARY TABLE faker_batch;
END$$

-- A batch of users. Row i of batch b is position b * p_batch_size + i, so a position always holds the same
-- person for the same locale and seed, whatever batch size is used. Column position is 1-based.
DROP PROCEDURE IF EXISTS faker_generate_users$$
CREATE PROCEDURE faker_generate_users(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_batch INT, IN p_batch_size INT,
    IN p_about_sentences INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_position BIGINT;
    DECLARE v_end BIGINT;
    CALL faker_assert_locale(p_locale);
    IF p_batch < 0 OR p_batch_size < 1 THEN
        SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = 'Batch index must be >= 0 and batch size >= 1';
    END IF;

    CALL faker_open_batch();
    SET v_position = p_batch * p_batch_size, v_end = (p_batch + 1) * p_batch_size;
    WHILE v_position < v_end DO
        CALL faker_add_user_to_batch(p_locale, p_seed, v_position, p_about_sentences);
        SET v_position = v_position + 1;
    END WHILE;
    SELECT * FROM faker_batch ORDER BY position;
    DROP TEMPORARY TABLE faker_batch;
END$$

-- Markov-chain text: p_paragraphs paragraphs of p_sentences sentences, reproducible for (locale, seed).
DROP PROCEDURE IF EXISTS faker_generate_text$$
CREATE PROCEDURE faker_generate_text(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_paragraphs INT, IN p_sentences INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE c_text_position BIGINT DEFAULT 0;
    DECLARE v_key CHAR(32) CHARACTER SET ascii;
    DECLARE v_n INT DEFAULT 1;
    DECLARE v_paragraph TEXT CHARACTER SET utf8mb4;
    CALL faker_assert_locale(p_locale);
    CALL faker_rng_key(p_locale, p_seed, c_text_position, v_key);

    DROP TEMPORARY TABLE IF EXISTS faker_text;
    CREATE TEMPORARY TABLE faker_text (
        paragraph_no INT NOT NULL PRIMARY KEY,
        paragraph    TEXT CHARACTER SET utf8mb4
    );
    WHILE v_n <= p_paragraphs DO
        CALL faker_markov_text(v_key, CONCAT('text.p', v_n), p_locale, p_sentences, v_paragraph);
        INSERT INTO faker_text VALUES (v_n, v_paragraph);
        SET v_n = v_n + 1;
    END WHILE;
    SELECT paragraph_no, paragraph FROM faker_text ORDER BY paragraph_no;
    DROP TEMPORARY TABLE faker_text;
END$$

DELIMITER ;
