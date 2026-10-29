-- German (Germany): locale row and person names.
SET NAMES utf8mb4;
INSERT INTO faker_locales (code, name, language_code, country_code, decimal_separator, sort_order)
VALUES ('de_DE', 'Deutsch (Deutschland)', 'de', 'DE', ',', 2);

CALL faker_add_items('de_DE', 'gender', '', '["value", "weight", "label"]',
    '[["male", 49, "männlich"], ["female", 51, "weiblich"]]');

-- Name variations are template weights: double first names, double surnames, academic titles, nobility particles.
CALL faker_add_values('de_DE', 'name_format', '', '["{first} {last}", "{first} {middle} {last}", "{first}-{middle} {last}", "{title} {first} {last}", "{title} {first} {middle} {last}", "{first} {last}-{last2}", "{first} {particle} {last}", "{title} {first} {particle} {last}"]', '[54, 12, 6, 12, 3, 8, 4, 1]');

CALL faker_add_values('de_DE', 'title', 'male', '["Herr", "Dr.", "Prof. Dr.", "Dipl.-Ing.", "Prof.", "Herr Dr."]',
    '[55, 20, 5, 8, 3, 9]');
CALL faker_add_values('de_DE', 'title', 'female', '["Frau", "Dr.", "Prof. Dr.", "Dipl.-Ing.", "Prof.", "Frau Dr."]',
    '[55, 20, 5, 6, 3, 11]');
CALL faker_add_values('de_DE', 'name_particle', '', '["von", "von der", "vom", "zu", "von und zu", "van"]',
    '[55, 12, 10, 8, 3, 12]');

CALL faker_add_words('de_DE', 'first_name', 'male', '
Alexander|Andreas|Michael|Thomas|Peter|Wolfgang|Klaus|Jürgen|Dieter|Hans|Uwe|Stefan|Frank|Bernd|Werner|Christian|
Martin|Markus|Matthias|Ralf|Jörg|Manfred|Helmut|Gerhard|Heinz|Rainer|Horst|Karl|Günter|Joachim|Holger|Torsten|Sven|
Dirk|Jens|Oliver|Carsten|Tobias|Daniel|Sebastian|Florian|Jan|Tim|Lukas|Jonas|Leon|Finn|Felix|Paul|Max|Maximilian|
Elias|Noah|Ben|Luis|Louis|Henry|Emil|Theo|Anton|Jakob|Moritz|Niklas|Nico|Julian|Philipp|Fabian|David|Simon|Kevin|
Dennis|Marcel|Patrick|Benjamin|Marco|Mario|Robert|Johannes|Georg|Friedrich|Wilhelm|Heinrich|Hermann|Walter|Otto|
Ernst|Fritz|Kurt|Rudolf|Erich|Willi|Herbert|Gerd|Rolf|Reinhard|Norbert|Volker|Lothar|Hartmut|Detlef|Ulrich|Harald|
Bernhard|Josef|Franz|Ludwig|Albert|Alfred|Arthur|Konrad|Gustav|Bruno|Erwin|Siegfried|Günther|Dietmar|Eckhard|Kai|
Lars|Nils|Ole|Hannes|Malte|Henrik|Mats|Lennard|Lennart|Linus|Mattis|Milan|Jonathan|Samuel|Aaron|Adrian|Leonard|
Vincent|Valentin|Raphael|Oskar|Liam|Mika|Luca|Jannik|Marvin|Dominik|Pascal|Sascha|Timo|Steffen|Björn|Axel|Achim|
Burkhard|Christoph|Clemens|Constantin|Eberhard|Edgar|Egon|Emanuel|Erik|Eugen|Ferdinand|Gabriel|Gernot|Gottfried|
Hagen|Heiko|Hendrik|Hubert|Ingo|Jochen|Kilian|Knut|Konstantin|Leopold|Lutz|Magnus|Marius|Mathias|Olaf|Oswald|
Quirin|Reiner|Richard|Roland|Rüdiger|Severin|Silvio|Theodor|Thorsten|Till|Udo|Ulf|Viktor|Waldemar|Wendelin|Wilfried|
Winfried|Xaver|Yannick|Benedikt|Bastian|Fynn|Hugo|Jasper|Justus|Karsten|Leander|Levin|Lorenz|Malik|Merlin|Michel|
Mirko|Nick|Noel|Rafael|Robin|Ruben|Sören|Thilo|Tom|Vitus|Wolf|Armin|Gunnar|Henning|Arne|Bodo|Claus|Dietrich|Götz|
Hanno|Helge|Kaspar|Leonhard|Meinhard|Raimund|Siegmund|Tilman|Volkmar|Mehmet|Ahmet|Mustafa|Ali|Can|Emre|Deniz|Piotr|
Marek|Tomasz|Ivan|Luka|Matteo|Elia|Joshua|Colin|Damian|Jona|Joel|Lian|Nevio|Hamza|Yusuf|Leo|Mohammed|Toni|Ludger|
Gregor|Ansgar|Wigand|Hinrich|Jost|Enno|Focke|Tjark|Hauke|Momme|Sönke|Frerk|Lasse|Jarne|Kalle|Piet
', '|');

CALL faker_add_words('de_DE', 'first_name', 'female', '
Maria|Ursula|Monika|Petra|Elisabeth|Sabine|Renate|Helga|Karin|Brigitte|Ingrid|Erika|Andrea|Gisela|Claudia|Susanne|
Gabriele|Christa|Christine|Hannelore|Birgit|Anna|Marianne|Barbara|Stefanie|Angelika|Nicole|Heike|Martina|Elke|Ute|
Silke|Anja|Katrin|Kerstin|Tanja|Sandra|Melanie|Julia|Katharina|Christina|Jessica|Jennifer|Sarah|Laura|Lisa|Lena|Lea|
Leonie|Hannah|Emma|Mia|Sophie|Sofia|Emilia|Marie|Lina|Ella|Clara|Klara|Lara|Lilly|Luisa|Louisa|Mila|Ida|Frieda|
Greta|Paula|Johanna|Charlotte|Mathilda|Amelie|Pia|Jana|Nina|Vanessa|Franziska|Carina|Anke|Bettina|Daniela|Doris|
Edith|Elfriede|Gertrud|Hedwig|Hildegard|Ilse|Irmgard|Inge|Jutta|Lieselotte|Margarete|Margot|Marlene|Martha|
Rosemarie|Rita|Ruth|Sieglinde|Waltraud|Annette|Antje|Astrid|Beate|Carola|Cornelia|Dagmar|Dorothea|Elena|Eva|Evelyn|
Gerda|Gudrun|Hanna|Heidi|Helene|Iris|Irene|Jacqueline|Janina|Jasmin|Josephine|Judith|Kathrin|Kirsten|Larissa|
Lydia|Magdalena|Manuela|Mareike|Maren|Marion|Miriam|Nadine|Natalie|Patricia|Regina|Rebecca|Ronja|Saskia|Simone|
Svenja|Tatjana|Theresa|Ulrike|Verena|Veronika|Viktoria|Yvonne|Zoe|Alina|Antonia|Carla|Elisa|Finja|Fiona|Helena|
Isabel|Jule|Juna|Lotta|Luna|Malia|Merle|Nele|Romy|Rosa|Selma|Smilla|Thea|Tilda|Valentina|Wilma|Alma|Anni|Amira|
Aylin|Emely|Elif|Isabella|Leni|Liv|Mara|Maya|Mira|Nora|Stella|Agnes|Adelheid|Alexandra|Angela|Anneliese|Annika|
Bärbel|Berta|Britta|Carmen|Constanze|Corinna|Diana|Ellen|Emilie|Friederike|Gesine|Hedda|Henriette|Hilde|Ines|
Ingeborg|Isolde|Karla|Katja|Kristin|Liane|Linda|Lore|Luise|Margit|Mechthild|Nathalie|Olga|Ottilie|Roswitha|
Sibylle|Sonja|Stephanie|Swantje|Tabea|Tina|Uta|Vera|Wiebke|Fatma|Ayse|Zeynep|Elif|Natalia|Agnieszka|Katarzyna|
Svetlana|Irina|Olena|Giulia|Chiara|Lia|Leila|Mina|Lou|Edda|Fenja|Hella|Imke|Inken|Kea|Maike|Meike|Talea|Thekla|
Gesa|Frauke|Silja|Telse|Wenke|Henrike|Rieke|Anouk|Elodie|Eleni|Dana|Ivana|Jelena|Milena|Zofia|Ewa|Hilda|Ricarda
', '|');

CALL faker_add_words('de_DE', 'last_name', '', '
Müller|Schmidt|Schneider|Fischer|Weber|Meyer|Wagner|Becker|Schulz|Hoffmann|Schäfer|Koch|Bauer|Richter|Klein|Wolf|
Schröder|Neumann|Schwarz|Zimmermann|Braun|Krüger|Hofmann|Hartmann|Lange|Schmitt|Werner|Schmitz|Krause|Meier|
Lehmann|Schmid|Schulze|Maier|Köhler|Herrmann|König|Walter|Mayer|Huber|Kaiser|Fuchs|Peters|Lang|Scholz|Möller|Weiß|
Jung|Hahn|Schubert|Vogel|Friedrich|Keller|Günther|Frank|Berger|Winkler|Roth|Beck|Lorenz|Baumann|Franke|Albrecht|
Schuster|Simon|Ludwig|Böhm|Winter|Kraus|Martin|Schumacher|Krämer|Vogt|Stein|Jäger|Otto|Sommer|Groß|Seidel|
Heinrich|Brandt|Haas|Schreiber|Graf|Schulte|Dietrich|Ziegler|Kuhn|Kühn|Pohl|Engel|Horn|Busch|Bergmann|Thomas|
Voigt|Sauer|Arnold|Wolff|Pfeiffer|Ernst|Lindner|Hübner|Kramer|Franz|Jansen|Beyer|Wenzel|Brinkmann|Lenz|Böttcher|
Thiel|Fiedler|Hesse|Kühne|Schilling|Hermann|Ritter|Kirchner|Wittmann|Götz|Bock|Krug|Marx|Sander|Haase|Schulze|Ott|
Kurz|Forster|Weis|Witt|Schütz|Paul|Hartung|Friedrichs|Wendt|Rieger|Behrens|Busse|Zander|Kunz|Nagel|Arndt|Riedel|
Gerlach|Stahl|Hein|Gross|Engelhardt|Mohr|Schuhmacher|Menzel|Seifert|Brauer|Bischoff|Vetter|Schwab|Wiegand|Kopp|
Fröhlich|Dittrich|Thiele|Jahn|Kurz|Reuter|Unger|Petersen|Fritz|Schott|Kroll|Michel|Hecht|Wilhelm|Nowak|Maurer|
Ebert|Hauser|Kolb|Schiller|Schenk|Brenner|Moser|Bayer|Heinz|Kraft|Suhr|Winkelmann|Lutz|Rudolph|Graf|Krebs|Kühl|
Schlüter|Löffler|Wolter|Schreiner|Pietsch|Beckmann|Gärtner|Wörner|Reinhardt|Heck|Hoppe|Bach|Steiner|Henning|
Dorn|Wirth|Hamann|Rose|Martens|Born|Schramm|Roth|Keil|Haag|Gebhardt|Ullrich|Adam|Rau|Stark|Lange|
Bachmann|Lehner|Bruns|Funk|Merkel|Hennig|Reich|Pfeifer|Jakob|Meißner|Strauß|Kuhlmann|Steffen|Wolters|Reimann|
Schneiders|Großmann|Kunze|Mayr|Hartwig|Thomsen|Sauter|Petzold|Wagener|Lindemann|Frey|Fleischer|Raab|Albers|
Heller|Diehl|Brückner|Oswald|Böhme|Barth|Bartsch|Wiese|Ackermann|Kessler|Eckert|Knoll|Heinemann|Busch|Heß|Schöne|
Probst|Kemper|Gruber|Hagen|Burkhardt|Stephan|Ruf|Kuhn|Jürgens|Herzog|Wegener|Langer|Hinz|Wild|Matthes|Schmitz|
Bender|Eggert|Marquardt|Feldmann|Ahrens|Bode|Zeller|Kunz|Specht|Brand|Schaller|Löw|Harms|Rothe|Klose|Heinze|Kamp|
Fink|Nolte|Hennings|Siebert|Lux|Geiger|Hofer|Pape|Dreyer|Lindenberg|Hertel|Weller|Blum|Schweizer|Kretschmer|Wille|
Haupt|Mertens|Pfaff|Hahn|Schlegel|Engels|Melzer|Weise|Scherer|Kaufmann|Kluge|Peter|Rauch|Eichhorn|Siegel|Wahl|
Wendel|Rupp|Grimm|Faber|Korn|Bremer|Falk|Rothermel|Kunkel|Schaaf|Urban|Hammer|Ehlers|Wiedemann|Kirsch|Heilmann|
Brandl|Lehnert|Beier|Dietz|Kowalski|Nowak|Lewandowski|Wojcik|Yilmaz|Kaya|Demir|Şahin|Çelik|Yildiz|Öztürk|Aydin|
Arslan|Doğan|Koç|Kurt|Popović|Jovanović|Petrović|Horvat|Novak|Rossi|Russo|Esposito|Bianchi|Romano|Papadopoulos|
Ivanov|Petrov|Smirnov|Kuznetsov|Popov|Thalheim|Achterberg|Ahlers|Altmann|Appel|Aust|Bahr|Baier|
Balzer|Bauerfeind|Baum|Baumgartner|Bechtold|Behr|Behrendt|Benz|Berg|Bergner|Bernhardt|Beutel|Biermann|Binder|
Birkner|Blank|Blechschmidt|Bley|Blume|Bohn|Brandes|Bräuer|Braune|Breuer|Brinkhaus|Brockmann|Buchholz|Buck|Bühler|
Burger|Burmeister|Buschmann|Christ|Clausen|Conrad|Daum|Decker|Deutsch|Diekmann|Dietze|Dinkel|Doll|Drescher|Ebel|
Eberhardt|Eck|Eckhardt|Ehrhardt|Eichler|Eisele|Elsner|Ende|Endres|Erdmann|Esser|Fabian|Fechner|Fels|Feuerstein|
Fichte|Fiebig|Fleck|Förster|Frenzel|Freund|Fricke|Frisch|Fritsch|Fromm|Fuhrmann|Gabriel|Geisler|Geißler|Gerber|
Giese|Glaser|Gottschalk|Grabowski|Graupner|Grün|Gutmann|Haack|Hackl|Hagedorn|Hänel|Hansen|Hartl|Hauck|Haug|Hecker|
Hegemann|Heide|Heim|Held|Helbig|Henke|Henkel|Herold|Heuer|Hildebrandt|Hiller|Hirsch|Höfer|Hofmeister|Höhne|Holz|
Holzer|Horst|Hummel|Hutter|Imhof|Jacobs|Jäckel|Janke|Jost|Junge|Junker|Kahl|Kaminski|Karl|Kasper|Kellner|Kern|
Kiefer|Kiel|Kirchhoff|Klaus|Klemm|Klotz|Knapp|Knauer|Knopf|Kober|Köster|Kraemer|Kranz|Kress|Kriegel|Kruse|Kuhnert|
Kummer|Lach|Lamprecht|Landgraf|Lau|Laue|Lauer|Lehr|Leitner|Lemke|Liebig|Link|Linke|Lohmann|Lorenzen|Ludewig|Lüdtke|
Lukas|Maas|Mack|Mader|Mann|Marschall|Matthäus|Mauer|May|Meister|Mende|Mertz|Metz|Metzger|Mielke|Moll|
Möbius|Münch|Nickel|Niemann|Noack|Nolde|Obermeier|Opitz|Ostermann|Pabst|Pauli|Pfister|Philipp|Pieper|Plank|Preuß|
Prinz|Puls|Rademacher|Rapp|Rath|Rausch|Rehm|Reiter|Renner|Reuß|Richers|Riemann|Ries|Rink|Ritz|Rohde|Roos|Rösch|
Rössler|Rost|Rüdiger|Runge|Sachs|Salomon|Schade|Schaefer|Scharf|Scheffler|Schell|Schick|Schindler|Schlosser|
Schmidtke|Schnell|Scholl|Schreck|Schrader|Schuler|Schwarzer|Schwenk|Seeger|Seel|Sievers|Sommerfeld|Sonntag|Spahn|
Sperling|Springer|Stadler|Staub|Steinbach|Steinmetz|Stoll|Storm|Straub|Strobel|Stumpf|Thoma|Tietz|Trautmann|Ulrich|
Vollmer|Voss|Wachter|Wagenknecht|Walther|Weidner|Weigel|Weinert|Weiss|Welter|Wendland|Wessel|Westphal|Wichmann|
Wiegmann|Wilke|Will|Winkel|Wirtz|Wittig|Wolfram|Wulf|Wunderlich|Zahn|Zeh|Zielke|Zimmer|Zink|Zuber
', '|');
