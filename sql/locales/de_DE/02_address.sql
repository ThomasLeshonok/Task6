-- German (Germany): addresses.
SET NAMES utf8mb4;

CALL faker_add_values('de_DE', 'address_format', '', '["{street} {building}, {postal_code} {city}", "{street} {building}, {secondary}, {postal_code} {city}", "{street} {building}, D-{postal_code} {city}", "{street} {building}, {postal_code} {city}, Deutschland", "{postal_code} {city}, {street} {building}"]', '[68, 12, 5, 10, 5]');

-- German street types are glued to the name: Linden + weg = Lindenweg.
CALL faker_add_values('de_DE', 'street_format', '', '["{street_name}{street_type}", "{street_adjective} Straße", "{street_adjective} Str.", "{street_phrase}"]', '[72, 13, 3, 12]');

CALL faker_add_values('de_DE', 'street_type', '', '["straße", "str.", "weg", "gasse", "allee", "platz", "ring", "damm", "steig", "pfad", "chaussee", "ufer"]', '[40, 5, 18, 5, 6, 5, 5, 3, 2, 2, 1, 1]');

CALL faker_add_words('de_DE', 'street_name', '', '
Haupt|Bahnhof|Schul|Garten|Kirch|Dorf|Berg|Wald|Linden|Birken|Eichen|Buchen|Ahorn|Tannen|Kastanien|Rosen|Tulpen|
Nelken|Mühlen|Brunnen|Feld|Wiesen|Sonnen|Stern|Markt|Burg|Schloss|Kloster|Rathaus|Post|Industrie|Gewerbe|Hafen|
Fluss|See|Teich|Bach|Quell|Heide|Moor|Hoch|Goethe|Schiller|Lessing|Heine|Mozart|Beethoven|Händel|Wagner|Brahms|
Schubert|Kant|Hegel|Luther|Bismarck|Humboldt|Kopernikus|Kepler|Einstein|Röntgen|Planck|Gutenberg|Dürer|Herder|
Wieland|Uhland|Eichendorff|Fontane|Storm|Hauff|Mörike|Hölderlin|Kleist|Barbarossa|Friedrich|Wilhelm|Luisen|Karl|
Ludwig|Maximilian|Albrecht|Otto|Konrad|Amsel|Drossel|Finken|Lerchen|Meisen|Schwalben|Falken|Adler|Kranich|
Storchen|Hirsch|Apfel|Birnen|Kirsch|Wein|Hopfen|Korn|Flachs|Stein|Sand|Ziegel|Glocken|Turm|Tor|Wall|Graben|
Brücken|Ufer|Hang|Tal|Grund|Anger|Hof|Kamp|Esch|Holz|Busch|Hecken|Acker|Weiden|Erlen|Eschen|Ulmen|Pappel|Fichten|
Kiefern|Lärchen|Holunder|Flieder|Jasmin|Lilien|Veilchen|Narzissen|Dahlien|Astern|Bergmanns|Fischer|Jäger|Müller|
Schmiede|Weber|Gerber|Bäcker|Zimmer|Färber|Wiesengrund|Sonnenhang|Waldrand|Lindenhof|Rosenhag|Feldrain|Mühlbach|
Kirchberg|Schlossberg|Weinberg|Hasen|Fuchs|Dachs|Biber|Otter|Eisvogel|Nachtigall|Rotkehlchen|Zaunkönig|Bussard
', '|');

CALL faker_add_words('de_DE', 'street_adjective', '', '
Berliner|Hamburger|Bremer|Lübecker|Kieler|Potsdamer|Leipziger|Dresdner|Hallesche|Magdeburger|Erfurter|Weimarer|
Jenaer|Münchner|Augsburger|Nürnberger|Würzburger|Stuttgarter|Heidelberger|Mannheimer|Frankfurter|Mainzer|
Wiesbadener|Kasseler|Göttinger|Braunschweiger|Bielefelder|Dortmunder|Essener|Bochumer|Düsseldorfer|Kölner|Bonner|
Aachener|Trierer|Koblenzer|Saarbrücker|Freiburger|Konstanzer|Ulmer|Regensburger|Passauer|Rosenheimer|Salzburger|
Wiener|Prager|Hannoversche|Lange|Kurze|Breite|Hohe|Neue|Alte|Obere|Untere|Große|Kleine
', '|');

CALL faker_add_words('de_DE', 'street_phrase', '', '
Am Markt|Am Bahnhof|Am Rathaus|Am Sportplatz|Am Stadtpark|Am Mühlbach|Am Kirchberg|Am Lindenhof|Am Steinbruch|
Am Wasserturm|Am Anger|Am Hang|Am Weiher|Am Schlossgarten|An der Kirche|An der Mühle|An der Linde|An der Post|
An der Schule|An der Bleiche|An den Eichen|Auf dem Hügel|Auf der Heide|Auf der Höhe|Im Winkel|Im Grund|
Im Wiesengrund|Im Tal|Im Kamp|Hinter den Gärten|Hinter der Kirche|Zum Sportplatz|Zur Mühle|Zur Linde|Zum Hafen|
Unter den Eichen|Unter den Linden|Alter Markt|Neuer Markt|Neuer Weg|Alte Dorfstraße|Alter Postweg|Kleiner Weg|
Großer Garten|Vor dem Tore|Bei der Kapelle|Über dem Bach
', '|');

CALL faker_add_values('de_DE', 'building_number_format', '', '["%", "%#", "%##", "%a", "%#a", "%b", "%#b", "%#c"]',
    '[22, 36, 14, 6, 9, 4, 6, 3]');
CALL faker_add_values('de_DE', 'secondary_format', '', '["%. OG", "Hinterhaus", "Whg. %#", "Whg. %", "App. %#", "Erdgeschoss", "Dachgeschoss", "Seitenflügel", "Zimmer %##"]', '[28, 10, 12, 8, 10, 8, 6, 5, 3]');
CALL faker_add_values('de_DE', 'postal_code_format', '', '["#####"]', NULL);

-- City, Bundesland code, first two digits of the postal code area.
CALL faker_add_items('de_DE', 'city', '', '["value", "region_code", "postal_prefix"]', '[
["Berlin","BE","10"],["Berlin","BE","12"],["Berlin","BE","13"],["Hamburg","HH","20"],["Hamburg","HH","22"],
["München","BY","80"],["München","BY","81"],["Köln","NW","50"],["Köln","NW","51"],["Frankfurt am Main","HE","60"],
["Stuttgart","BW","70"],["Düsseldorf","NW","40"],["Leipzig","SN","04"],["Dortmund","NW","44"],["Essen","NW","45"],
["Bremen","HB","28"],["Dresden","SN","01"],["Hannover","NI","30"],["Nürnberg","BY","90"],["Duisburg","NW","47"],
["Bochum","NW","44"],["Wuppertal","NW","42"],["Bielefeld","NW","33"],["Bonn","NW","53"],["Münster","NW","48"],
["Mannheim","BW","68"],["Karlsruhe","BW","76"],["Augsburg","BY","86"],["Wiesbaden","HE","65"],
["Mönchengladbach","NW","41"],["Gelsenkirchen","NW","45"],["Aachen","NW","52"],["Braunschweig","NI","38"],
["Kiel","SH","24"],["Chemnitz","SN","09"],["Halle (Saale)","ST","06"],["Magdeburg","ST","39"],
["Freiburg im Breisgau","BW","79"],["Krefeld","NW","47"],["Mainz","RP","55"],["Lübeck","SH","23"],
["Erfurt","TH","99"],["Oberhausen","NW","46"],["Rostock","MV","18"],["Kassel","HE","34"],["Hagen","NW","58"],
["Potsdam","BB","14"],["Saarbrücken","SL","66"],["Hamm","NW","59"],["Ludwigshafen am Rhein","RP","67"],
["Oldenburg","NI","26"],["Mülheim an der Ruhr","NW","45"],["Osnabrück","NI","49"],["Leverkusen","NW","51"],
["Heidelberg","BW","69"],["Darmstadt","HE","64"],["Solingen","NW","42"],["Regensburg","BY","93"],["Herne","NW","44"],
["Paderborn","NW","33"],["Neuss","NW","41"],["Ingolstadt","BY","85"],["Offenbach am Main","HE","63"],["Fürth","BY","90"],
["Würzburg","BY","97"],["Ulm","BW","89"],["Heilbronn","BW","74"],["Pforzheim","BW","75"],["Wolfsburg","NI","38"],
["Göttingen","NI","37"],["Bottrop","NW","46"],["Reutlingen","BW","72"],["Koblenz","RP","56"],["Bremerhaven","HB","27"],
["Recklinghausen","NW","45"],["Bergisch Gladbach","NW","51"],["Erlangen","BY","91"],["Jena","TH","07"],
["Remscheid","NW","42"],["Trier","RP","54"],["Salzgitter","NI","38"],["Moers","NW","47"],["Siegen","NW","57"],
["Hildesheim","NI","31"],["Cottbus","BB","03"],["Gütersloh","NW","33"],["Kaiserslautern","RP","67"],["Witten","NW","58"],
["Hanau","HE","63"],["Schwerin","MV","19"],["Gera","TH","07"],["Esslingen am Neckar","BW","73"],["Ludwigsburg","BW","71"],
["Iserlohn","NW","58"],["Düren","NW","52"],["Tübingen","BW","72"],["Zwickau","SN","08"],["Flensburg","SH","24"],
["Gießen","HE","35"],["Ratingen","NW","40"],["Lünen","NW","44"],["Villingen-Schwenningen","BW","78"],
["Konstanz","BW","78"],["Marl","NW","45"],["Worms","RP","67"],["Velbert","NW","42"],["Minden","NW","32"],
["Dessau-Roßlau","ST","06"],["Neumünster","SH","24"],["Norderstedt","SH","22"],["Delmenhorst","NI","27"],
["Bamberg","BY","96"],["Viersen","NW","41"],["Marburg","HE","35"],["Rheine","NW","48"],["Wilhelmshaven","NI","26"],
["Gladbeck","NW","45"],["Lüneburg","NI","21"],["Troisdorf","NW","53"],["Bayreuth","BY","95"],["Dorsten","NW","46"],
["Detmold","NW","32"],["Arnsberg","NW","59"],["Castrop-Rauxel","NW","44"],["Landshut","BY","84"],
["Brandenburg an der Havel","BB","14"],["Bocholt","NW","46"],["Aschaffenburg","BY","63"],["Celle","NI","29"],
["Kempten","BY","87"],["Fulda","HE","36"],["Aalen","BW","73"],["Lippstadt","NW","59"],["Dinslaken","NW","46"],
["Herford","NW","32"],["Kerpen","NW","50"],["Rüsselsheim","HE","65"],["Weimar","TH","99"],["Sindelfingen","BW","71"],
["Plauen","SN","08"],["Neuwied","RP","56"],["Dormagen","NW","41"],["Rosenheim","BY","83"],["Neubrandenburg","MV","17"],
["Grevenbroich","NW","41"],["Herten","NW","45"],["Bergheim","NW","50"],["Friedrichshafen","BW","88"],
["Schwäbisch Gmünd","BW","73"],["Garbsen","NI","30"],["Wesel","NW","46"],["Hürth","NW","50"],["Offenburg","BW","77"],
["Stralsund","MV","18"],["Greifswald","MV","17"],["Langenfeld","NW","40"],["Unna","NW","59"],["Göppingen","BW","73"],
["Euskirchen","NW","53"],["Hameln","NI","31"],["Frankfurt (Oder)","BB","15"],["Görlitz","SN","02"],
["Sankt Augustin","NW","53"],["Stolberg","NW","52"],["Eschweiler","NW","52"],["Hilden","NW","40"],["Meerbusch","NW","40"],
["Pulheim","NW","50"],["Passau","BY","94"],["Hattingen","NW","45"],["Ravensburg","BW","88"],["Wetzlar","HE","35"],
["Speyer","RP","67"],["Bad Homburg vor der Höhe","HE","61"],["Freising","BY","85"],["Nordhorn","NI","48"],
["Lingen","NI","49"],["Elmshorn","SH","25"],["Halberstadt","ST","38"],["Stade","NI","21"],["Wismar","MV","23"],
["Goslar","NI","38"],["Bautzen","SN","02"],["Meißen","SN","01"],["Freiberg","SN","09"],["Coburg","BY","96"],
["Schweinfurt","BY","97"],["Amberg","BY","92"],["Straubing","BY","94"],["Memmingen","BY","87"],["Kaufbeuren","BY","87"],
["Garmisch-Partenkirchen","BY","82"],["Baden-Baden","BW","76"],["Heidenheim an der Brenz","BW","89"],
["Lörrach","BW","79"],["Singen","BW","78"],["Waiblingen","BW","71"],["Böblingen","BW","71"],["Leonberg","BW","71"],
["Bruchsal","BW","76"],["Rastatt","BW","76"],["Weinheim","BW","69"],["Sinsheim","BW","74"],["Emden","NI","26"],
["Cuxhaven","NI","27"],["Leer","NI","26"],["Aurich","NI","26"],["Peine","NI","31"],["Wolfenbüttel","NI","38"],
["Gifhorn","NI","38"],["Uelzen","NI","29"],["Verden","NI","27"],["Husum","SH","25"],["Schleswig","SH","24"],
["Itzehoe","SH","25"],["Bad Oldesloe","SH","23"],["Eberswalde","BB","16"],["Oranienburg","BB","16"],
["Neuruppin","BB","16"],["Fürstenwalde","BB","15"],["Lutherstadt Wittenberg","ST","06"],["Stendal","ST","39"],
["Quedlinburg","ST","06"],["Wernigerode","ST","38"],["Nordhausen","TH","99"],["Gotha","TH","99"],["Eisenach","TH","99"],
["Suhl","TH","98"],["Ilmenau","TH","98"],["Saalfeld","TH","07"],["Altenburg","TH","04"],["Hof","BY","95"],
["Ansbach","BY","91"],["Neu-Ulm","BY","89"],["Dachau","BY","85"],["Erding","BY","85"],["Lindau","BY","88"],
["Kulmbach","BY","95"],["Pirna","SN","01"],["Riesa","SN","01"],["Döbeln","SN","04"],["Torgau","SN","04"],
["Annaberg-Buchholz","SN","09"],["Homburg","SL","66"],["Neunkirchen","SL","66"],["Völklingen","SL","66"],
["Saarlouis","SL","66"],["Merzig","SL","66"],["Idar-Oberstein","RP","55"],["Bad Kreuznach","RP","55"],
["Pirmasens","RP","66"],["Zweibrücken","RP","66"],["Landau in der Pfalz","RP","76"],
["Neustadt an der Weinstraße","RP","67"],["Bingen am Rhein","RP","55"],["Limburg an der Lahn","HE","65"],
["Bad Hersfeld","HE","36"],["Friedberg","HE","61"],["Bensheim","HE","64"],["Rodgau","HE","63"],["Oberursel","HE","61"]
]');
