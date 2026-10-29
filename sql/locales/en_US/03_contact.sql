-- English (United States): phone, e-mail, physical attributes.
SET NAMES utf8mb4;

CALL faker_add_values('en_US', 'phone_format', '', '["({area_code}) %##-####", "{area_code}-%##-####", "{area_code}.%##.####", "+1 {area_code} %## ####", "+1 ({area_code}) %##-####", "1-{area_code}-%##-####", "({area_code}) %##-#### x###", "{area_code}%######"]', '[30, 25, 10, 10, 8, 8, 4, 5]');

CALL faker_add_words('en_US', 'area_code', '', '
201|202|203|205|206|207|208|209|210|212|213|214|215|216|217|218|219|224|225|228|229|231|234|239|240|248|251|252|253|
254|256|260|262|267|269|270|272|276|281|301|302|303|304|305|307|308|309|310|312|313|314|315|316|317|318|319|320|321|
323|325|330|331|334|336|337|339|347|351|352|360|361|385|386|401|402|404|405|406|407|408|409|410|412|413|414|415|417|
419|423|424|425|430|432|434|435|440|443|458|469|470|475|478|479|480|484|501|502|503|504|505|507|508|509|510|512|513|
515|516|517|518|520|530|531|534|539|540|541|551|559|561|562|563|567|570|571|573|574|575|580|585|586|601|602|603|605|
606|607|608|609|610|612|614|615|616|617|618|619|620|623|626|628|629|630|631|636|641|646|650|651|657|660|661|662|667|
669|678|681|682|701|702|703|704|706|707|708|712|713|714|715|716|717|718|719|720|724|725|727|731|732|734|737|740|743|
747|754|757|760|762|763|765|769|770|772|773|774|775|779|781|785|786|801|802|803|804|805|806|808|810|812|813|814|815|
816|817|818|828|830|831|832|843|845|847|848|850|856|857|858|859|860|862|863|864|865|870|872|878|901|903|904|906|907|
908|909|910|912|913|914|915|916|917|918|919|920|925|928|929|931|936|937|938|940|941|947|949|951|952|954|956|970|971|
972|973|978|979|980|984|985|989
', '|');

CALL faker_add_values('en_US', 'email_format', '', '["{first}.{last}", "{first}{last}", "{f}{last}", "{first}_{last}", "{first}.{last}##", "{first}{last}##", "{f}{last}###", "{first}{l}", "{last}.{first}", "{first}##", "{last}{f}", "{f}.{last}", "{first}-{last}", "{first}{last}%###", "{last}{first}##"]', '[18, 9, 14, 6, 10, 8, 6, 4, 5, 5, 4, 5, 3, 2, 1]');

CALL faker_add_values('en_US', 'email_domain', '', '["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "aol.com", "icloud.com", "comcast.net", "proton.me", "msn.com", "live.com", "att.net", "verizon.net", "me.com", "mail.com"]', '[35, 15, 10, 9, 4, 8, 3, 2, 2, 3, 2, 2, 2, 2]');

CALL faker_add_items('en_US', 'transliteration', '', '["value", "ascii"]', '[
["á","a"],["à","a"],["â","a"],["ä","a"],["ã","a"],["é","e"],["è","e"],["ê","e"],["ë","e"],["í","i"],["ï","i"],
["ó","o"],["ô","o"],["ö","o"],["ú","u"],["ü","u"],["ñ","n"],["ç","c"]
]');

-- CDC adult anthropometry (cm, kg/m^2). Height clamps sit about 5 standard deviations out; the BMI floor of 16 sits
-- 2.0-2.4 standard deviations below the mean (0.8-2.4% of BMI draws land on it), the BMI ceiling about 4 above.
INSERT INTO faker_distributions (locale, attribute, variant, mean, stddev, min_value, max_value) VALUES
    ('en_US', 'height_cm', 'male',   175.4, 7.6, 137, 214),
    ('en_US', 'height_cm', 'female', 161.7, 7.1, 126, 198),
    ('en_US', 'bmi',       'male',    29.1, 5.4,  16,  52),
    ('en_US', 'bmi',       'female',  29.6, 6.9,  16,  58);

CALL faker_add_values('en_US', 'height_format', '', '["{feet}''{inches}\\"", "{feet} ft {inches} in", "{feet}′ {inches}″", "{inches_total} in"]', '[45, 35, 15, 5]');
CALL faker_add_values('en_US', 'weight_format', '', '["{lb} lb", "{lb} lbs", "{lb} pounds"]', '[55, 35, 10]');

CALL faker_add_values('en_US', 'eye_color', '', '["Brown", "Blue", "Hazel", "Green", "Gray", "Amber"]',
    '[45, 27, 18, 9, 3, 2]');
CALL faker_add_values('en_US', 'hair_color', '', '["Brown", "Black", "Blond", "Red", "Auburn", "Gray", "White"]',
    '[40, 28, 15, 4, 3, 8, 2]');
CALL faker_add_values('en_US', 'blood_type', '', '["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-"]',
    '[37.4, 35.7, 8.5, 3.4, 6.6, 6.3, 1.5, 0.6]');
