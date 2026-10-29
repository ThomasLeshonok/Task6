-- Random text in the locale language with a word-level Markov chain trained on faker_markov_corpus.
-- The chain is stored in the generic lookup tables: one list per state (category 'markov', variant = state),
-- items = possible next tokens weighted by how often they followed that state in the corpus.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DELIMITER $$

-- True for a token that ends a sentence ('home.', 'really?!', 'said."').
DROP PROCEDURE IF EXISTS faker_is_sentence_end$$
CREATE PROCEDURE faker_is_sentence_end(IN p_token VARCHAR(255) CHARACTER SET utf8mb4, OUT p_result BOOLEAN)
    NO SQL DETERMINISTIC
BEGIN
    SET p_result = p_token REGEXP '[.!?][''"»«“”„)]*$';
END$$

-- Chain state at a sentence start: p_order start markers '^'.
DROP PROCEDURE IF EXISTS faker_markov_start$$
CREATE PROCEDURE faker_markov_start(IN p_order INT, OUT p_state VARCHAR(255) CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE c_start_marker VARCHAR(2) DEFAULT '^ ';
    SET p_state = TRIM(REPEAT(c_start_marker, p_order));
END$$

-- Next state: drop the oldest token of the state, append the new one (state = last p_order tokens).
DROP PROCEDURE IF EXISTS faker_markov_next_state$$
CREATE PROCEDURE faker_markov_next_state(
    IN p_state VARCHAR(255) CHARACTER SET utf8mb4, IN p_token VARCHAR(255) CHARACTER SET utf8mb4, IN p_order INT,
    OUT p_next VARCHAR(255) CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    IF p_order = 1 THEN
        SET p_next = p_token;
    ELSE
        SET p_next = CONCAT(SUBSTRING(p_state, LOCATE(' ', p_state) + 1), ' ', p_token);
    END IF;
END$$

-- Builds the chain of a locale from its corpus (replaces the previous one).
-- Tokens are whitespace-separated words with punctuation kept, so the chain also learns where commas and
-- sentence ends go. Order 1 = next word depends on the previous word; higher orders read more like the corpus.
-- p_max_words caps generated sentences.
DROP PROCEDURE IF EXISTS faker_train_markov$$
CREATE PROCEDURE faker_train_markov(IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_order INT, IN p_max_words INT)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE v_body MEDIUMTEXT CHARACTER SET utf8mb4;
    DECLARE v_state VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_token VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_is_end BOOLEAN;
    DECLARE v_at INT;
    DECLARE v_space INT;
    DECLARE c_corpus CURSOR FOR SELECT body FROM faker_markov_corpus WHERE locale = p_locale ORDER BY corpus_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    DELETE FROM faker_lookup_lists WHERE locale = p_locale AND category = 'markov';
    DROP TEMPORARY TABLE IF EXISTS faker_markov_pairs;
    CREATE TEMPORARY TABLE faker_markov_pairs (
        pair_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        state   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
        token   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
    );

    OPEN c_corpus;
    texts: LOOP
        FETCH c_corpus INTO v_body;
        IF v_done THEN
            LEAVE texts;
        END IF;
        CALL faker_clean_text(v_body, v_body);
        CALL faker_markov_start(p_order, v_state);
        SET v_at = 1;
        WHILE v_at <= CHAR_LENGTH(v_body) DO
            SET v_space = LOCATE(' ', v_body, v_at);
            IF v_space = 0 THEN
                SET v_space = CHAR_LENGTH(v_body) + 1;
            END IF;
            SET v_token = SUBSTRING(v_body, v_at, v_space - v_at);
            INSERT INTO faker_markov_pairs (state, token) VALUES (v_state, v_token);
            CALL faker_is_sentence_end(v_token, v_is_end);
            IF v_is_end THEN
                CALL faker_markov_start(p_order, v_state);
            ELSE
                CALL faker_markov_next_state(v_state, v_token, p_order, v_state);
            END IF;
            SET v_at = v_space + 1;
        END WHILE;
    END LOOP;
    CLOSE c_corpus;

    INSERT INTO faker_lookup_lists (locale, category, variant)
    SELECT DISTINCT p_locale, 'markov', state FROM faker_markov_pairs;

    INSERT INTO faker_lookup_values (list_id, item_no, value, weight)
    SELECT l.list_id, ROW_NUMBER() OVER (PARTITION BY l.list_id ORDER BY p.token), p.token, p.weight
    FROM (SELECT state, token, COUNT(*) AS weight FROM faker_markov_pairs GROUP BY state, token) p
    JOIN faker_lookup_lists l ON l.locale = p_locale AND l.category = 'markov' AND l.variant = p.state;

    CALL faker_refresh_lists(p_locale, 'markov');

    DELETE FROM faker_markov_models WHERE locale = p_locale;
    INSERT INTO faker_markov_models (locale, chain_order, max_words, token_count, state_count)
    SELECT p_locale, p_order, p_max_words, COUNT(*), COUNT(DISTINCT state) FROM faker_markov_pairs;

    DROP TEMPORARY TABLE faker_markov_pairs;
END$$

-- Closes a generated sentence: capital first letter, trailing comma-like punctuation replaced by a period.
DROP PROCEDURE IF EXISTS faker_finish_sentence$$
CREATE PROCEDURE faker_finish_sentence(IN p_text TEXT CHARACTER SET utf8mb4, OUT p_result TEXT CHARACTER SET utf8mb4)
    NO SQL DETERMINISTIC
BEGIN
    DECLARE v_is_end BOOLEAN;
    SET p_result = TRIM(TRAILING '-' FROM TRIM(TRAILING ':' FROM TRIM(TRAILING ';' FROM TRIM(TRAILING ',' FROM p_text))));
    SET p_result = CONCAT(UPPER(LEFT(p_result, 1)), SUBSTRING(p_result, 2));
    CALL faker_is_sentence_end(p_result, v_is_end);
    IF NOT v_is_end THEN
        SET p_result = CONCAT(p_result, '.');
    END IF;
END$$

-- One sentence: walk the chain from the start state, one weighted draw per word, until a sentence-ending
-- token, a dead end, or the model's max_words.
-- Word i is faker_random_value(p_key, '<p_stream>.<i>', p_locale, 'markov', state) followed by
-- faker_is_sentence_end and faker_markov_next_state. All of them are written out in the loop, because the nested
-- CALLs (five per word) cost more than the lookup itself and a user's "about" text has dozens of words.
DROP PROCEDURE IF EXISTS faker_markov_sentence$$
CREATE PROCEDURE faker_markov_sentence(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, OUT p_sentence TEXT CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE c_hex_digits INT DEFAULT 16;                     -- as in faker_random_uniform
    DECLARE c_hash_bits INT DEFAULT 64;
    DECLARE c_mantissa_bits INT DEFAULT 53;
    DECLARE v_order INT;
    DECLARE v_max_words INT;
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_u DOUBLE;
    DECLARE v_state VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_token VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_words TEXT CHARACTER SET utf8mb4 DEFAULT '';
    DECLARE v_is_end BOOLEAN DEFAULT FALSE;
    SELECT chain_order, max_words INTO v_order, v_max_words FROM faker_markov_models WHERE locale = p_locale;
    IF v_order IS NULL THEN
        SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = 'No Markov model for this locale; run faker_train_markov first';
    END IF;

    CALL faker_markov_start(v_order, v_state);
    words: WHILE v_i <= v_max_words AND NOT v_is_end DO
        SET v_u = (CAST(CONV(LEFT(MD5(CONCAT(p_key, ':', p_stream, '.', v_i)), c_hex_digits), 16, 10) AS UNSIGNED)
            >> (c_hash_bits - c_mantissa_bits)) / POW(2, c_mantissa_bits);
        SET v_token = NULL;
        SELECT v.value INTO v_token                          -- faker_pick
        FROM faker_lookup_lists l
        JOIN faker_lookup_values v FORCE INDEX (faker_lookup_values_pick) ON v.list_id = l.list_id
        WHERE l.locale = p_locale AND l.category = 'markov' AND l.variant = v_state
          AND v.cum_weight >= v_u * l.total_weight
        ORDER BY v.cum_weight
        LIMIT 1;
        IF v_token IS NULL THEN
            LEAVE words;
        END IF;
        SET v_words = TRIM(CONCAT(v_words, ' ', v_token));
        SET v_is_end = v_token REGEXP '[.!?][''"»«“”„)]*$';    -- faker_is_sentence_end
        SET v_state = IF(v_order = 1, v_token,                   -- faker_markov_next_state
            CONCAT(SUBSTRING(v_state, LOCATE(' ', v_state) + 1), ' ', v_token));
        SET v_i = v_i + 1;
    END WHILE;
    CALL faker_finish_sentence(v_words, p_sentence);
END$$

-- p_sentences sentences joined by spaces.
DROP PROCEDURE IF EXISTS faker_markov_text$$
CREATE PROCEDURE faker_markov_text(
    IN p_key CHAR(32) CHARACTER SET ascii, IN p_stream VARCHAR(255) CHARACTER SET utf8mb4,
    IN p_locale VARCHAR(16) CHARACTER SET utf8mb4, IN p_sentences INT, OUT p_text TEXT CHARACTER SET utf8mb4)
    READS SQL DATA
BEGIN
    DECLARE v_n INT DEFAULT 1;
    DECLARE v_sentence TEXT CHARACTER SET utf8mb4;
    SET p_text = '';
    WHILE v_n <= p_sentences DO
        CALL faker_markov_sentence(p_key, CONCAT(p_stream, '.s', v_n), p_locale, v_sentence);
        SET p_text = TRIM(CONCAT(p_text, ' ', v_sentence));
        SET v_n = v_n + 1;
    END WHILE;
END$$

DELIMITER ;
