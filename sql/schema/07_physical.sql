-- Physical attributes: normally distributed measures and discrete weighted traits.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Normal draw with the locale parameters of faker_distributions; the gender-specific row wins over variant ''.
DROP PROCEDURE IF EXISTS faker_random_measure$$
CREATE PROCEDURE faker_random_measure(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_attribute VARCHAR(64) CHARACTER SET utf8mb4,
    IN p_variant VARCHAR(255) CHARACTER SET utf8mb4, OUT p_value DOUBLE)
    READS SQL DATA
BEGIN
    DECLARE v_mean DOUBLE;
    DECLARE v_stddev DOUBLE;
    DECLARE v_min DOUBLE;
    DECLARE v_max DOUBLE;
    SET p_value = NULL;
    SELECT mean, stddev, min_value, max_value INTO v_mean, v_stddev, v_min, v_max
    FROM faker_distributions
    WHERE locale = p_locale AND attribute = p_attribute AND variant IN (p_variant, '')
    ORDER BY variant = p_variant DESC
    LIMIT 1;
    IF v_mean IS NOT NULL THEN
        CALL faker_random_normal_bounded(p_key, p_stream, v_mean, v_stddev, v_min, v_max, p_value);
    END IF;
END$$

-- Height text from a weighted 'height_format' template.
-- Placeholders: cm, m (meters, with p_separator, the locale decimal separator), feet, inches (remainder), inches_total.
DROP PROCEDURE IF EXISTS faker_format_height$$
CREATE PROCEDURE faker_format_height(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_separator VARCHAR(4) CHARACTER SET utf8mb4, IN p_cm DOUBLE, OUT p_text VARCHAR(64) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_cm_per_inch DOUBLE DEFAULT 2.54;
    DECLARE c_inches_per_foot INT DEFAULT 12;
    DECLARE c_cm_per_meter INT DEFAULT 100;
    DECLARE c_meter_decimals INT DEFAULT 2;
    DECLARE v_inches INT DEFAULT ROUND(p_cm / c_cm_per_inch);
    DECLARE v_meters VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_text MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_format_decimal(p_cm / c_cm_per_meter, c_meter_decimals, p_separator, v_meters);
    CALL faker_random_value(p_key, 'body.height.format', p_locale, 'height_format', '', v_format);
    CALL faker_render(v_format, JSON_OBJECT(
        'cm', CAST(ROUND(p_cm) AS SIGNED),
        'm', v_meters,
        'feet', v_inches DIV c_inches_per_foot,
        'inches', v_inches MOD c_inches_per_foot,
        'inches_total', v_inches), v_text);
    SET p_text = v_text;
END$$

-- Weight text from a weighted 'weight_format' template. Placeholders: kg, kg_decimal (one decimal, with
-- p_separator), lb.
DROP PROCEDURE IF EXISTS faker_format_weight$$
CREATE PROCEDURE faker_format_weight(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_separator VARCHAR(4) CHARACTER SET utf8mb4, IN p_kg DOUBLE, OUT p_text VARCHAR(64) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_kg_per_pound DOUBLE DEFAULT 0.45359237;
    DECLARE c_kg_decimals INT DEFAULT 1;
    DECLARE v_kg_decimal VARCHAR(64) CHARACTER SET utf8mb4;
    DECLARE v_format VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_text MEDIUMTEXT CHARACTER SET utf8mb4;
    CALL faker_format_decimal(p_kg, c_kg_decimals, p_separator, v_kg_decimal);
    CALL faker_random_value(p_key, 'body.weight.format', p_locale, 'weight_format', '', v_format);
    CALL faker_render(v_format, JSON_OBJECT(
        'kg', CAST(ROUND(p_kg) AS SIGNED),
        'kg_decimal', v_kg_decimal,
        'lb', CAST(ROUND(p_kg / c_kg_per_pound) AS SIGNED)), v_text);
    SET p_text = v_text;
END$$

-- Body: height ~ N(mean, sd) per locale and gender; weight = BMI * height^2 with BMI ~ N(mean, sd), so weight
-- follows height like in real data. Eye color, hair color and blood type are weighted discrete draws.
DROP PROCEDURE IF EXISTS faker_random_physical$$
CREATE PROCEDURE faker_random_physical(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_locale VARCHAR(16) CHARACTER SET utf8mb4,
    IN p_gender VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_height_cm DOUBLE, OUT p_height VARCHAR(64) CHARACTER SET utf8mb4,
    OUT p_weight_kg DOUBLE, OUT p_weight VARCHAR(64) CHARACTER SET utf8mb4,
    OUT p_eye_color VARCHAR(255) CHARACTER SET utf8mb4, OUT p_hair_color VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_blood_type VARCHAR(255) CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_cm_per_meter INT DEFAULT 100;
    DECLARE c_cm_decimals INT DEFAULT 1;
    DECLARE c_kg_decimals INT DEFAULT 1;
    DECLARE v_bmi DOUBLE;
    DECLARE v_separator VARCHAR(4) CHARACTER SET utf8mb4 DEFAULT '.';
    SELECT decimal_separator INTO v_separator FROM faker_locales WHERE code = p_locale;
    CALL faker_random_measure(p_key, 'body.height', p_locale, 'height_cm', p_gender, p_height_cm);
    CALL faker_random_measure(p_key, 'body.bmi', p_locale, 'bmi', p_gender, v_bmi);
    SET p_height_cm = ROUND(p_height_cm, c_cm_decimals);
    SET p_weight_kg = ROUND(v_bmi * POW(p_height_cm / c_cm_per_meter, 2), c_kg_decimals);
    CALL faker_format_height(p_key, p_locale, v_separator, p_height_cm, p_height);
    CALL faker_format_weight(p_key, p_locale, v_separator, p_weight_kg, p_weight);
    CALL faker_random_value(p_key, 'body.eye_color', p_locale, 'eye_color', '', p_eye_color);
    CALL faker_random_value(p_key, 'body.hair_color', p_locale, 'hair_color', '', p_hair_color);
    CALL faker_random_value(p_key, 'body.blood_type', p_locale, 'blood_type', '', p_blood_type);
END$$

DELIMITER ;
