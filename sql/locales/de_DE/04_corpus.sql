-- German (Germany): Markov chain corpus (original texts written for this project) and training.
SET NAMES utf8mb4;

INSERT INTO faker_markov_corpus (locale, title, body) VALUES
('de_DE', 'Ein Morgen in der Kleinstadt', '
Jeden Morgen öffnet die kleine Bäckerei am Marktplatz ihre Türen, lange bevor die Sonne aufgeht. Der Duft von
frischen Brötchen zieht durch die Gassen und weckt die Nachbarn einen nach dem anderen. Herr Becker, der seit
dreißig Jahren über dem Eisenwarenladen wohnt, ist immer der erste Kunde. Er kauft zwei Brötchen und eine Zeitung
und spricht mit jedem, der zuhören will, über das Wetter. An manchen Tagen sagt er, der Regen sei gut für die
Gärten. An anderen Tagen sagt er, der Regen höre nie wieder auf. Die Bäckerin lächelt und nickt, denn sie kennt
jede Geschichte schon mindestens zweimal. Um sieben Uhr fahren die ersten Schulbusse los. Die Kinder laufen mit
ihren Rucksäcken zur Haltestelle, und die Eltern winken vom Fenster aus. Die Stadt ist ruhig, aber niemals leer.
Immer geht jemand mit dem Hund spazieren, trägt Einkäufe nach Hause oder repariert einen Zaun. Die Menschen hier
kennen sich beim Namen, und sie bemerken sofort, wenn eine neue Familie einzieht. Ein neues Gesicht im Café ist
eine ganze Woche lang das wichtigste Thema.
'),
('de_DE', 'Arbeit und Alltag', '
Die meisten Menschen in der Stadt arbeiten in Büros im Zentrum, aber viele arbeiten an einigen Tagen lieber von
zu Hause. Ein guter Morgen beginnt mit einer Tasse Kaffee und einer kurzen Liste von Aufgaben. Das Telefon
klingelt, das Postfach füllt sich, und die Liste wird länger statt kürzer. Besprechungen dauern länger als
geplant. Ein Projekt, das am Montag einfach aussah, ist am Mittwoch kompliziert, und am Freitag sind sich alle
einig, dass es noch eine Woche braucht. Trotzdem ist es schön, eine schwierige Aufgabe zu beenden. Das Team feiert
mit Kuchen in der Küche, und zu jedem Geburtstag bringt jemand etwas Süßes mit. Frau Schneider aus der Buchhaltung
kennt jeden Geburtstag im Haus. Sie schreibt alle Daten in einen Kalender neben der Kaffeemaschine und erinnert die
Kollegen mit einem freundlichen Zettel. Am Abend leert sich langsam der Parkplatz. Einige gehen ins Fitnessstudio,
andere fahren direkt nach Hause, und manche bleiben länger, um noch einen Bericht fertig zu schreiben. Am Ende
schaltet der Hausmeister das Licht aus, Stockwerk für Stockwerk, und das Gebäude kommt endlich zur Ruhe.
'),
('de_DE', 'Eine Reise in die Berge', '
Sie fuhren an einem Samstag früh los, mit vollem Tank und einer Dose belegter Brote auf dem Rücksitz. Die Autobahn
führte stundenlang durch flaches Land unter einem weiten, blauen Himmel. Jede Stunde wechselten sie den Fahrer und
die Musik. Irgendwo in der Mitte machten sie Pause an einer kleinen Raststätte, wo es Kaffee aus großen Kannen und
Kuchen vom Blech gab. Am Nachmittag wurde die Landschaft hügeliger, und am Horizont erschienen die ersten Berge
wie eine graue Wolkenwand. Die Luft wurde kühler, und die Straße begann zu steigen. Kurz vor Sonnenuntergang
erreichten sie den Campingplatz und bauten das Zelt neben einem klaren, kalten Bach auf. Am Abend kochten sie
Suppe auf dem kleinen Kocher und zählten die Sterne, bis sie den Überblick verloren. Am nächsten Morgen lief ein
Reh am Zelt vorbei, sah sie einen langen Moment an und verschwand zwischen den Bäumen. Es war eine Reise, an die man
sich noch viele Jahre erinnert.
'),
('de_DE', 'Der Gemeinschaftsgarten', '
Hinter der Stadtbibliothek liegt ein Gemeinschaftsgarten, in dem jeder für den Sommer ein kleines Beet mieten kann.
Im Frühling treffen sich die Gärtner, um die Saison zu planen. Sie tauschen Samen, Werkzeug und gute Ratschläge,
und manchmal streiten sie darüber, wie man die besten Tomaten zieht. Frau Wagner pflanzt nur Rosen und weigert
sich, etwas anzubauen, das man essen kann. Ihr Nachbar pflanzt nur Gemüse und sagt, Blumen seien eine
Verschwendung von guter Erde. Trotzdem sind die beiden seit zwanzig Jahren befreundet. An warmen Abenden ist der
Garten voller Menschen, die gießen, jäten und reden. Kinder jagen Schmetterlinge zwischen den Beeten, und die
älteren Gärtner sitzen auf einer Bank im Schatten. Im Spätsommer ist die Ernte so groß, dass vor jeder Haustür in
der Nachbarschaft ein Korb mit Zucchini steht. Niemand weiß genau, wer sie dort hinstellt, aber jeder hat eine
Vermutung. Im Herbst räumen die Gärtner ihre Beete auf, bedecken die Erde mit Laub und versprechen, dass das
nächste Jahr noch besser wird.
'),
('de_DE', 'Briefe und Nachrichten', '
Meine Großmutter schreibt immer noch Briefe mit der Hand, und sie erwartet eine Antwort mit der Post. Ihre Briefe
beginnen immer mit dem Wetter und enden mit einer Frage nach meiner Gesundheit. Dazwischen erzählt sie von ihren
Freundinnen, von der Kirche und von den Vögeln, die an ihr Fenster kommen. Sie hat eine schöne, aber schwer
lesbare Handschrift, deshalb lese ich jeden Brief zweimal. Meistens antworte ich mit einer kurzen Karte und einem
Foto, und eine Woche später ruft sie an, um zu sagen, dass die Post angekommen ist. Die meisten meiner Freunde
schreiben lieber kurze Nachrichten auf dem Handy. Sie schicken Bilder von ihrem Mittagessen, Witze über die Arbeit
und Pläne für das Wochenende, die sich jede Stunde ändern. Eine Nachricht ist schnell, aber einen Brief kann man
viele Jahre in einer Schublade aufbewahren. Wenn ich meine Großmutter besuche, zeigt sie mir eine Kiste voller
Briefe von Menschen, die schon lange nicht mehr leben. Jeder Brief ist ein kleines Stück eines Lebens, langsam und
sorgfältig geschrieben, in der Hoffnung, dass ihn eines Tages jemand wieder liest.
'),
('de_DE', 'Die Jahreszeiten', '
Der Winter ist hier lang und grau, und der Schnee bleibt oft wochenlang liegen. Die Leute schippen im Dunkeln den
Schnee vor der Haustür und fahren langsam zur Arbeit. Der erste warme Frühlingstag fühlt sich an wie ein Feiertag.
Die Fenster werden geöffnet, die Fahrräder kommen aus dem Keller, und im Park treffen sich Menschen, die sich
monatelang nicht gesehen haben. Der Sommer bringt lange Abende, Stadtfeste und Gewitter, die am späten Nachmittag
aus dem Westen heranziehen. Am See ist es am Wochenende voll, und vor der Eisdiele steht eine lange Schlange. Für
viele Menschen ist der Herbst die schönste Jahreszeit. Die Blätter färben sich rot und golden, die Luft riecht nach
Rauch und Äpfeln, und auf dem Weinfest kommt die ganze Stadt zusammen. Dann werden die Tage kürzer, der erste Frost
kommt, und alle reden wieder vom Winter, als wäre er eine große Überraschung.
'),
('de_DE', 'Auf dem Wochenmarkt', '
Am Samstagmorgen füllt sich der Marktplatz mit Ständen, Lieferwagen und Klapptischen. Die Bauern kommen noch vor
der Dämmerung und laden Kisten mit Äpfeln, Kartoffeln, Kohl und frischen Eiern ab. Ein Mann mit langem Bart
verkauft Honig von seinen eigenen Bienen, und er erzählt gern alles über sie, wenn man Zeit hat. Ein junges Paar
verkauft Brot und Kuchen, und ihre Zimtschnecken sind meistens schon um neun Uhr ausverkauft. Musiker spielen auf
den Stufen vor dem Rathaus, während Familien langsam von einem Stand zum nächsten gehen. Die Leute probieren Käse,
vergleichen Preise und tragen mehr nach Hause, als sie kaufen wollten. Der Markt ist nicht nur ein Ort zum
Einkaufen. Er ist ein Ort, an dem man alte Freunde trifft, die neuesten Nachrichten hört und sich daran erinnert,
dass unser Essen von echten Menschen kommt, die bei jedem Wetter hart arbeiten.
');

CALL faker_train_markov('de_DE', 1, 30);
