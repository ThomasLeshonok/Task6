-- English (United States): Markov chain corpus (original texts written for this project) and training.
SET NAMES utf8mb4;

INSERT INTO faker_markov_corpus (locale, title, body) VALUES
('en_US', 'Morning in a small town', '
Every morning the old bakery on the corner opens its doors before the sun is up. The smell of fresh bread drifts
down the street and wakes the neighbors one by one. Old Walker, who has lived above the hardware store for thirty
years, is always the first customer. He buys two rolls and a newspaper, and he talks about the weather with anyone
who will listen. Some days he says the rain is good for the gardens. Other days he says the rain will never stop.
The baker smiles and nods, because she has heard every story at least twice. By seven o''clock the school buses
start their routes. Children run to the stop with their backpacks bouncing, and their parents wave from the porch.
The town is quiet but never empty. There is always someone walking a dog, someone carrying groceries, someone
fixing a fence or painting a mailbox. People here know each other by name, and they notice when a new family moves
in. A new face at the coffee shop is news for a whole week.
'),
('en_US', 'Working life', '
Most people in the city work in offices downtown, but many prefer to work from home a few days a week. A good
morning starts with a cup of coffee and a short list of goals. The phone rings, the inbox fills up, and the list
grows longer instead of shorter. Meetings take more time than anyone planned. A project that looked simple on
Monday becomes complicated by Wednesday, and by Friday everyone agrees that it needs another week. Still, there is
satisfaction in finishing a difficult task. The team celebrates with pizza in the break room, and someone always
brings a cake for birthdays. Sarah from accounting knows every birthday in the building. She writes them on a
calendar next to the coffee machine and reminds everyone with a friendly note. When the evening comes, the
parking lot slowly empties. Some people go to the gym, some go straight home, and some stay late to finish one
more report. The night cleaner turns off the lights floor by floor, and the building finally rests.
'),
('en_US', 'A long road trip', '
They left early on a Saturday with a full tank of gas and a box of sandwiches on the back seat. The highway
stretched across the plains for hundreds of miles, flat and straight under a wide blue sky. Every hour they
switched drivers and changed the music. Somewhere in the middle of the state they stopped at a small diner with
red booths and a jukebox that played only old songs. The waitress called everyone honey and refilled the coffee
without asking. In the afternoon the land began to rise, and the first mountains appeared on the horizon like a
gray line of clouds. The air became cooler and the road began to climb. They reached the campground just before
sunset and set up the tent next to a cold, clear river. That night they cooked beans over the fire and counted
the stars until they lost track. In the morning a deer walked past the tent, looked at them for a long moment,
and disappeared into the trees. It was the kind of trip that people remember for many years.
'),
('en_US', 'The neighborhood garden', '
Behind the library there is a community garden where anyone can rent a small plot for the summer. In spring the
gardeners meet to plan the season. They share seeds, tools, and advice, and sometimes they argue about the best
way to grow tomatoes. Martha Johnson grows roses and refuses to grow anything you can eat. Her neighbor grows only
vegetables and says that flowers are a waste of good soil. Somehow they have been friends for twenty years. On
warm evenings the garden is full of people watering, weeding, and talking. Children chase butterflies between the
rows, and the older gardeners sit on a bench in the shade. In late summer the harvest is so large that baskets of
zucchini appear on every doorstep in the neighborhood. Nobody knows exactly who leaves them, but everyone has a
guess. In the fall the gardeners clean their plots, cover the soil with leaves, and promise that next year will
be even better.
'),
('en_US', 'Letters and messages', '
My grandmother still writes letters by hand, and she expects an answer by mail. Her letters always begin with the
weather and end with a question about my health. In between she tells me about her friends, her church, and the
birds that visit her window. She has a beautiful handwriting that is hard to read, so I read every letter twice.
I usually answer with a short card and a photograph, and she calls me a week later to say that it arrived. Most of
my friends prefer short messages on their phones. They send pictures of their lunch, jokes about their work, and
plans for the weekend that change every hour. A message is quick, but a letter is something you can keep in a
drawer for many years. When I visit my grandmother, she shows me a box full of letters from people who are long
gone. Each one is a small piece of a life, written slowly and carefully, with the hope that someone would read it
again one day.
'),
('en_US', 'Seasons', '
Winter here is long and gray, with snow that stays on the ground for weeks. People shovel their driveways in the
dark and drive slowly to work. The first warm day of spring feels like a holiday. Windows open, bicycles come out
of the garage, and the park fills with people who seem surprised to see each other again. Summer brings long
evenings, county fairs, and thunderstorms that roll in from the west in the late afternoon. The lake is crowded
on weekends, and the ice cream shop has a line out the door. Fall is the favorite season for many people. The
leaves turn red and gold, the air smells of smoke and apples, and the high school football games bring the whole
town together on Friday night. Then the days grow shorter, the first frost arrives, and everyone starts to talk
about winter again as if it were a surprise.
'),
('en_US', 'At the market', '
On Saturday mornings the farmers market fills the main square with tents, trucks, and folding tables. Farmers
arrive before dawn to unload crates of apples, potatoes, corn, and fresh eggs. A man with a long beard sells honey
from his own bees, and he will tell you everything about them if you have the time. A young couple sells bread and
pies, and their cinnamon rolls are usually gone by nine. Musicians play on the steps of the courthouse while
families walk slowly from one table to the next. People taste cheese, compare prices, and carry home more than they
planned to buy. The market is not only a place to shop. It is a place to meet old friends, to hear the latest
news, and to remember that food comes from real people who work hard in every kind of weather.
');

CALL faker_train_markov('en_US', 1, 30);
