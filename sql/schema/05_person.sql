-- Person: gender, name, e-mail, phone.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Gender key ('male' / 'female', used as variant of name lists) and its localized label.
DROP PROCEDURE IF EXISTS faker_random_gender$$
CREATE PROCEDURE faker_random_gender(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    OUT p_gender VARCHAR(255) CHARACTER SET utf8mb4, OUT p_label VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_details MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_random_item(p_key, 'person.gender', p_locale, 'gender', '', p_gender, v_details);
    SET p_label = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(v_details, '$.label')), p_gender);
END$$

-- Full name built from a weighted 'name_format' template, e.g. '{title} {first} {middle_initial}. {last}'.
-- Placeholders: title, first, middle, middle_initial, last, last2 (second surname), particle ('von'), suffix.
-- Name variations (title or not, middle name or initial, double surname...) are template weights, so a locale
-- tunes them with data only. Parts not used by the chosen template are not drawn and are returned as NULL.
DROP PROCEDURE IF EXISTS faker_random_person_name$$
CREATE PROCEDURE faker_random_person_name(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_gender VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_title VARCHAR(255) CHARACTER SET utf8mb4, OUT p_first_name VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_middle_name VARCHAR(255) CHARACTER SET utf8mb4, OUT p_last_name VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_suffix VARCHAR(255) CHARACTER SET utf8mb4, OUT p_full_name VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_last2 VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_particle VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_full MEDIUMTEXT CHARACTER SET utf8mb4;
    SET p_title = NULL, p_middle_name = NULL, p_suffix = NULL;

    CALL faker_random_value(p_key, 'name.format', p_locale, 'name_format', '', v_format);
    CALL faker_random_value(p_key, 'name.first', p_locale, 'first_name', p_gender, p_first_name);
    CALL faker_random_value(p_key, 'name.last', p_locale, 'last_name', '', p_last_name);
    IF INSTR(v_format, '{title}') > 0 THEN
        CALL faker_random_value(p_key, 'name.title', p_locale, 'title', p_gender, p_title);
    END IF;
    IF INSTR(v_format, '{middle') > 0 THEN
        CALL faker_random_value(p_key, 'name.middle', p_locale, 'first_name', p_gender, p_middle_name);
        IF p_middle_name = p_first_name THEN
            CALL faker_random_value(p_key, 'name.middle#retry', p_locale, 'first_name', p_gender, p_middle_name);
        END IF;
    END IF;
    IF INSTR(v_format, '{last2}') > 0 THEN
        CALL faker_random_value(p_key, 'name.last2', p_locale, 'last_name', '', v_last2);
    END IF;
    IF INSTR(v_format, '{particle}') > 0 THEN
        CALL faker_random_value(p_key, 'name.particle', p_locale, 'name_particle', '', v_particle);
    END IF;
    IF INSTR(v_format, '{suffix}') > 0 THEN
        CALL faker_random_value(p_key, 'name.suffix', p_locale, 'suffix', '', p_suffix);
    END IF;

    CALL faker_render(v_format, JSON_OBJECT(
        'title', p_title,
        'first', p_first_name,
        'middle', p_middle_name,
        'middle_initial', LEFT(p_middle_name, 1),
        'last', p_last_name,
        'last2', v_last2,
        'particle', v_particle,
        'suffix', p_suffix), v_full);
    SET p_full_name = v_full;
END$$

-- E-mail: 'email_format' template over ASCII-folded names (placeholders first, last, f, l = initials),
-- '#'/'%' in the template become digits, then '@' and a weighted 'email_domain'.
DROP PROCEDURE IF EXISTS faker_random_email$$
CREATE PROCEDURE faker_random_email(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_first_name VARCHAR(255) CHARACTER SET utf8mb4, IN p_last_name VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_email VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_first VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_last VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_local MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_domain VARCHAR(255) CHARACTER SET utf8mb4;
    CALL faker_to_ascii(p_locale, p_first_name, v_first);
    CALL faker_to_ascii(p_locale, p_last_name, v_last);
    CALL faker_random_value(p_key, 'email.format', p_locale, 'email_format', '', v_format);
    CALL faker_expand(p_key, 'email', p_locale, v_format,
        JSON_OBJECT('first', v_first, 'last', v_last, 'f', LEFT(v_first, 1), 'l', LEFT(v_last, 1)), v_local);
    CALL faker_fill_digits(p_key, 'email.digits', v_local, v_local);
    CALL faker_random_value(p_key, 'email.domain', p_locale, 'email_domain', '', v_domain);
    SET p_email = CONCAT(v_local, '@', v_domain);
END$$

-- Phone: weighted 'phone_format' template whose placeholders come from lists of the same name
-- ({area_code}, {mobile_prefix}) and whose '#'/'%' masks become digits,
-- e.g. '({area_code}) %##-####' or '+49 {mobile_prefix} %#######'.
DROP PROCEDURE IF EXISTS faker_random_phone$$
CREATE PROCEDURE faker_random_phone(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    OUT p_phone VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_text MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_random_value(p_key, 'phone.format', p_locale, 'phone_format', '', v_format);
    CALL faker_expand(p_key, 'phone', p_locale, v_format, NULL, v_text);
    CALL faker_fill_digits(p_key, 'phone.digits', v_text, p_phone);
END$$

DELIMITER ;
