-- Random number generation.
-- Counter-based (stateless) generator: every value is a hash of (key, stream label). No sequence state is kept,
-- so any user at any position can be generated directly and the result never depends on call order.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- Key of one generated record: MD5 of 'locale:seed:position' as 32 hex characters (128 bits).
DROP PROCEDURE IF EXISTS faker_rng_key$$
CREATE PROCEDURE faker_rng_key(
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_seed BIGINT, IN p_position BIGINT,
    OUT p_key CHAR(32) CHARACTER SET ascii)
    NO SQL DETERMINISTIC
BEGIN
    SET p_key = MD5(CONCAT_WS(':', p_locale, p_seed, p_position));
END$$

-- 64 pseudo-random bits for one named draw ('name.first', 'body.height#1', ...) of a record.
DROP PROCEDURE IF EXISTS faker_random_bits$$
CREATE PROCEDURE faker_random_bits(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_bits BIGINT UNSIGNED)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE c_hex_digits INT DEFAULT 16;                     -- 16 hex digits = 64 bits
    SET p_bits = CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream)), c_hex_digits), 16, 10) AS UNSIGNED);
END$$

-- Uniform double in [0, 1): the top 53 bits (DOUBLE mantissa size) of the 64 random bits divided by 2^53.
-- The bits are exactly faker_random_bits, computed here without the nested CALL (a CALL costs about as much as the
-- hash). faker_random_value, faker_random_item and faker_markov_sentence repeat this one expression for the same
-- reason; tests check that they agree.
DROP PROCEDURE IF EXISTS faker_random_uniform$$
CREATE PROCEDURE faker_random_uniform(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4, OUT p_value DOUBLE)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE c_hex_digits INT DEFAULT 16;                     -- as in faker_random_bits
    DECLARE c_hash_bits INT DEFAULT 64;
    DECLARE c_mantissa_bits INT DEFAULT 53;
    SET p_value = (CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream)), c_hex_digits), 16, 10) AS UNSIGNED)
        >> (c_hash_bits - c_mantissa_bits)) / POW(2, c_mantissa_bits);
END$$

-- Uniform integer in [p_min, p_max], both ends included.
DROP PROCEDURE IF EXISTS faker_random_int$$
CREATE PROCEDURE faker_random_int(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_min BIGINT, IN p_max BIGINT, OUT p_value BIGINT)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE v_u DOUBLE;
    CALL faker_random_uniform(p_key, p_stream, v_u);
    SET p_value = p_min + FLOOR(v_u * (p_max - p_min + 1));
END$$

-- Normal N(mean, stddev) by the Box-Muller transform of two independent uniforms:
-- z = sqrt(-2 ln u1) * cos(2 pi u2), u1 in (0, 1] so the logarithm is defined.
DROP PROCEDURE IF EXISTS faker_random_normal$$
CREATE PROCEDURE faker_random_normal(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_mean DOUBLE, IN p_stddev DOUBLE, OUT p_value DOUBLE)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE v_u1 DOUBLE;
    DECLARE v_u2 DOUBLE;
    CALL faker_random_uniform(p_key, CONCAT(p_stream, '#1'), v_u1);
    CALL faker_random_uniform(p_key, CONCAT(p_stream, '#2'), v_u2);
    SET p_value = p_mean + p_stddev * SQRT(-2 * LN(1 - v_u1)) * COS(2 * PI() * v_u2);
END$$

-- Normal value clamped to [p_min, p_max] (bounds far in the tails keep the shape practically unchanged).
DROP PROCEDURE IF EXISTS faker_random_normal_bounded$$
CREATE PROCEDURE faker_random_normal_bounded(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_mean DOUBLE, IN p_stddev DOUBLE, IN p_min DOUBLE, IN p_max DOUBLE, OUT p_value DOUBLE)
    NO SQL DETERMINISTIC
BEGIN
    CALL faker_random_normal(p_key, p_stream, p_mean, p_stddev, p_value);
    SET p_value = LEAST(GREATEST(p_value, p_min), p_max);
END$$

-- Point uniformly distributed (constant density per unit area) on the part of the sphere between two latitudes
-- and two longitudes. Longitude is uniform. Latitude is not: the band at latitude phi has area proportional to
-- cos(phi), so the CDF inside the box is (sin phi - sin lat_min) / (sin lat_max - sin lat_min) and inverse
-- sampling gives phi = asin(sin lat_min + u (sin lat_max - sin lat_min)): z = sin(phi) is uniform
-- (Archimedes' hat-box theorem). A plain uniform latitude would crowd points toward the poles.
DROP PROCEDURE IF EXISTS faker_random_spherical_box$$
CREATE PROCEDURE faker_random_spherical_box(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_lat_min DOUBLE, IN p_lat_max DOUBLE, IN p_lon_min DOUBLE, IN p_lon_max DOUBLE,
    OUT p_latitude DOUBLE, OUT p_longitude DOUBLE)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE v_z_min DOUBLE DEFAULT SIN(RADIANS(p_lat_min));
    DECLARE v_z_max DOUBLE DEFAULT SIN(RADIANS(p_lat_max));
    DECLARE v_u DOUBLE;
    CALL faker_random_uniform(p_key, CONCAT(p_stream, '#lat'), v_u);
    SET p_latitude = DEGREES(ASIN(v_z_min + v_u * (v_z_max - v_z_min)));
    CALL faker_random_uniform(p_key, CONCAT(p_stream, '#lon'), v_u);
    SET p_longitude = p_lon_min + v_u * (p_lon_max - p_lon_min);
END$$

-- Point uniformly distributed on the whole sphere: the spherical box from pole to pole, all longitudes.
DROP PROCEDURE IF EXISTS faker_random_geolocation$$
CREATE PROCEDURE faker_random_geolocation(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_latitude DOUBLE, OUT p_longitude DOUBLE)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE c_south_pole DOUBLE DEFAULT -90;
    DECLARE c_north_pole DOUBLE DEFAULT 90;
    DECLARE c_west_edge DOUBLE DEFAULT -180;
    DECLARE c_east_edge DOUBLE DEFAULT 180;
    CALL faker_random_spherical_box(p_key, p_stream, c_south_pole, c_north_pole, c_west_edge, c_east_edge,
        p_latitude, p_longitude);
END$$

DELIMITER ;
