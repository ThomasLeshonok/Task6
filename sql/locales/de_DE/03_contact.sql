-- German (Germany): phone, e-mail, physical attributes.
SET NAMES utf8mb4;

CALL faker_add_values('de_DE', 'phone_format', '', '["0{area_code} %######", "0{area_code}/%#####", "+49 {area_code} %######", "(0{area_code}) %### ###", "+49 (0){area_code} %#####", "0{mobile_prefix} %#######", "+49 {mobile_prefix} %#######", "0{mobile_prefix}/%#######", "+49 {mobile_prefix} %### ####"]', '[15, 10, 12, 6, 5, 20, 15, 8, 9]');

-- Landline area codes without the trunk prefix 0.
CALL faker_add_words('de_DE', 'area_code', '', '
30|40|89|221|69|711|211|231|201|341|421|351|511|911|203|234|202|521|228|251|721|621|821|611|209|2161|531|371|431|
241|345|391|761|2151|451|208|361|6131|381|561|2331|2381|681|331|441|214|541|212|6221|2323|2131|6151|5251|941|841|
931|7131|731|7231|551|5361|471|2191|261|951|921|3641|651|335|355|385|375|3591|3581|8031|871|851|831|751|7531|7121|
7071|6341|631|2421|2241|271|2921|5221|571|5121|5141|4131|461|4321|3301|3381|340|3943|3621|3643
', '|');
CALL faker_add_words('de_DE', 'mobile_prefix', '', '151|152|155|157|159|160|162|163|170|171|172|173|174|175|176|177|178|179', '|');

CALL faker_add_values('de_DE', 'email_format', '', '["{first}.{last}", "{first}{last}", "{f}.{last}", "{first}_{last}", "{first}.{last}##", "{first}{last}##", "{f}{last}", "{last}.{first}", "{first}-{last}", "{first}##", "{last}{f}##", "{first}.{l}", "{first}{last}%###"]', '[24, 8, 10, 5, 10, 6, 8, 6, 5, 4, 3, 3, 2]');

CALL faker_add_values('de_DE', 'email_domain', '', '["gmail.com", "web.de", "gmx.de", "gmx.net", "t-online.de", "outlook.de", "yahoo.de", "freenet.de", "posteo.de", "mail.de", "icloud.com", "hotmail.de", "online.de", "arcor.de", "mailbox.org"]', '[20, 20, 18, 6, 12, 5, 5, 4, 3, 2, 4, 3, 2, 2, 1]');

CALL faker_add_items('de_DE', 'transliteration', '', '["value", "ascii"]', '[
["ä","ae"],["ö","oe"],["ü","ue"],["ß","ss"],["é","e"],["è","e"],["ç","c"],["ş","s"],["ğ","g"],["ı","i"],
["ć","c"],["č","c"],["š","s"],["ž","z"],["ł","l"],["ń","n"],["ó","o"],["ś","s"],["ź","z"],["ż","z"]
]');

-- Destatis Mikrozensus adult body measures (cm, kg/m^2). Height clamps sit about 5 standard deviations out; the BMI
-- floors of 15-16 sit 2.0-2.5 standard deviations below the mean (0.7-2.4% of BMI draws land on them), the ceilings
-- about 5 above.
INSERT INTO faker_distributions (locale, attribute, variant, mean, stddev, min_value, max_value) VALUES
    ('de_DE', 'height_cm', 'male',   179.0, 7.2, 143, 215),
    ('de_DE', 'height_cm', 'female', 165.8, 6.6, 133, 199),
    ('de_DE', 'bmi',       'male',    26.8, 4.4,  16,  48),
    ('de_DE', 'bmi',       'female',  25.3, 5.2,  15,  51);

CALL faker_add_values('de_DE', 'height_format', '', '["{cm} cm", "{m} m"]', '[70, 30]');
CALL faker_add_values('de_DE', 'weight_format', '', '["{kg} kg", "{kg_decimal} kg"]', '[75, 25]');

CALL faker_add_values('de_DE', 'eye_color', '', '["blau", "braun", "grün", "grau", "haselnussbraun", "blaugrau"]',
    '[38, 30, 12, 9, 7, 4]');
CALL faker_add_values('de_DE', 'hair_color', '', '["braun", "dunkelblond", "blond", "schwarz", "rot", "grau", "weiß"]',
    '[38, 20, 14, 14, 4, 8, 2]');
CALL faker_add_values('de_DE', 'blood_type', '', '["A+", "0+", "B+", "AB+", "A-", "0-", "B-", "AB-"]',
    '[37, 35, 9, 4, 6, 6, 2, 1]');
