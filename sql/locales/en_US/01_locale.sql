-- English (United States): locale row and person names.
SET NAMES utf8mb4;
INSERT INTO faker_locales (code, name, language_code, country_code, decimal_separator, sort_order)
VALUES ('en_US', 'English (United States)', 'en', 'US', '.', 1);

CALL faker_add_items('en_US', 'gender', '', '["value", "weight", "label"]',
    '[["male", 49, "Male"], ["female", 51, "Female"]]');

-- Name variations are template weights.
CALL faker_add_values('en_US', 'name_format', '', '["{first} {last}", "{first} {middle_initial}. {last}", "{first} {middle} {last}", "{title} {first} {last}", "{title} {first} {middle_initial}. {last}", "{first} {last} {suffix}", "{first} {middle_initial}. {last} {suffix}", "{first} {last}-{last2}"]', '[44, 18, 12, 10, 4, 5, 3, 4]');

CALL faker_add_values('en_US', 'title', 'male', '["Mr.", "Dr.", "Prof.", "Rev."]', '[82, 12, 4, 2]');
CALL faker_add_values('en_US', 'title', 'female', '["Ms.", "Mrs.", "Miss", "Dr.", "Prof."]', '[40, 34, 10, 12, 4]');
CALL faker_add_values('en_US', 'suffix', '', '["Jr.", "Sr.", "II", "III", "IV", "PhD", "MD", "Esq."]',
    '[38, 16, 10, 14, 3, 9, 7, 3]');

CALL faker_add_words('en_US', 'first_name', 'male', '
James|John|Robert|Michael|William|David|Richard|Joseph|Thomas|Charles|Christopher|Daniel|Matthew|Anthony|Mark|
Donald|Steven|Paul|Andrew|Joshua|Kenneth|Kevin|Brian|George|Timothy|Ronald|Edward|Jason|Jeffrey|Ryan|Jacob|Gary|
Nicholas|Eric|Jonathan|Stephen|Larry|Justin|Scott|Brandon|Benjamin|Samuel|Gregory|Alexander|Frank|Patrick|Raymond|
Jack|Dennis|Jerry|Tyler|Aaron|Jose|Adam|Nathan|Henry|Douglas|Zachary|Peter|Kyle|Ethan|Walter|Noah|Jeremy|Christian|
Keith|Roger|Terry|Gerald|Harold|Sean|Austin|Carl|Arthur|Lawrence|Dylan|Jesse|Jordan|Bryan|Billy|Joe|Bruce|Gabriel|
Logan|Albert|Willie|Alan|Juan|Wayne|Elijah|Randy|Roy|Vincent|Ralph|Eugene|Russell|Bobby|Mason|Philip|Louis|Liam|
Oliver|Lucas|Aiden|Jackson|Sebastian|Mateo|Owen|Theodore|Levi|Hudson|Grayson|Carter|Wyatt|Julian|Isaac|Lincoln|
Jaxon|Asher|Leo|Caleb|Isaiah|Hunter|Eli|Connor|Landon|Adrian|Colton|Cameron|Evan|Chase|Ian|Miles|Josiah|Nolan|
Easton|Cooper|Jace|Dominic|Parker|Ezra|Xavier|Brayden|Gavin|Bentley|Luke|Carson|Ayden|Blake|Max|Tristan|Brody|
Declan|Silas|Micah|Maxwell|Wesley|Bennett|Everett|Kai|Emmett|Harrison|Jasper|Rowan|Beau|Weston|Brooks|Sawyer|
Graham|Sullivan|Calvin|Victor|Martin|Travis|Shawn|Clarence|Craig|Stanley|Leonard|Dale|Manuel|Rodney|Curtis|Norman|
Allen|Marvin|Glenn|Jeff|Chad|Lee|Melvin|Alfred|Francis|Bradley|Jesus|Herbert|Frederick|Ray|Joel|Edwin|Don|Eddie|
Ricky|Troy|Randall|Barry|Bernard|Mario|Leroy|Francisco|Marcus|Clifford|Miguel|Oscar|Jay|Jim|Tom|Alex|Jon|Ronnie|
Bill|Lloyd|Tommy|Leon|Derek|Warren|Darrell|Jerome|Floyd|Alvin|Tim|Gordon|Dean|Greg|Jorge|Dustin|Pedro|Derrick|Dan|
Lewis|Corey|Herman|Maurice|Vernon|Roberto|Clyde|Glen|Hector|Shane|Ricardo|Sam|Rick|Lester|Brent|Ramon|Charlie|
Gilbert|Gene|Marc|Reginald|Ruben|Brett|Angel|Nathaniel|Rafael|Leslie|Edgar|Milton|Raul|Ben|Chester|Cecil|Duane|
Franklin|Andre|Elmer|Brad|Ron|Mitchell|Roland|Arnold|Harvey|Jared|Karl|Cory|Claude|Erik|Darryl|Jamie|Neil|Javier|
Fernando|Clinton|Ted|Mathew|Tyrone|Darren|Lonnie|Lance|Cody|Julio|Kurt|Allan|Nelson|Guy|Clayton|Hugh|Dwayne|Dwight|
Armando|Felix|Wallace|Ken|Bob|Jaime|Casey|Alfredo|Alberto|Dave|Ivan|Sidney|Byron|Morris|Clifton|Willard|Daryl|Ross|
Virgil|Andy|Marshall|Salvador|Perry|Kirk|Sergio|Marion|Seth|Kent|Terrance|Rene|Eduardo|Terrence|Enrique|Freddie|
Wade|Elliot|Spencer|Garrett|Dallas|Quentin|Rhett|Damian|Malcolm|Omar|Abraham|Simon|Hayden|Preston|Ronan|Desmond|
Archer|Finn|Arlo|Atticus|Jude|Knox|Milo|Otis|Reid|Tucker|Zane|Felipe|Hugo|Ruben|Emilio|Andres|Diego|Santiago|Luis
', '|');

CALL faker_add_words('en_US', 'first_name', 'female', '
Mary|Patricia|Jennifer|Linda|Elizabeth|Barbara|Susan|Jessica|Sarah|Karen|Lisa|Nancy|Betty|Margaret|Sandra|Ashley|
Kimberly|Emily|Donna|Michelle|Carol|Amanda|Dorothy|Melissa|Deborah|Stephanie|Rebecca|Sharon|Laura|Cynthia|Kathleen|
Amy|Angela|Shirley|Anna|Brenda|Pamela|Emma|Nicole|Helen|Samantha|Katherine|Christine|Debra|Rachel|Carolyn|Janet|
Catherine|Maria|Heather|Diane|Ruth|Julie|Olivia|Joyce|Virginia|Victoria|Kelly|Lauren|Christina|Joan|Evelyn|Judith|
Megan|Andrea|Cheryl|Hannah|Jacqueline|Martha|Gloria|Teresa|Ann|Sara|Madison|Frances|Kathryn|Janice|Jean|Abigail|
Alice|Judy|Sophia|Grace|Denise|Amber|Doris|Marilyn|Danielle|Beverly|Isabella|Theresa|Diana|Natalie|Brittany|
Charlotte|Marie|Kayla|Alexis|Lori|Ava|Mia|Amelia|Harper|Ella|Camila|Luna|Sofia|Avery|Mila|Aria|Scarlett|Penelope|
Layla|Chloe|Eleanor|Nora|Riley|Zoey|Hazel|Lily|Ellie|Violet|Lillian|Zoe|Stella|Aurora|Emilia|Everly|Leah|Aubrey|
Willow|Addison|Lucy|Audrey|Bella|Nova|Brooklyn|Paisley|Savannah|Claire|Skylar|Isla|Genesis|Naomi|Elena|Caroline|
Eliana|Maya|Valentina|Ruby|Kennedy|Ivy|Ariana|Aaliyah|Cora|Madelyn|Kinsley|Hailey|Gabriella|Allison|Gianna|
Serenity|Autumn|Quinn|Eva|Piper|Sophie|Sadie|Delilah|Josephine|Nevaeh|Adeline|Arya|Emery|Lydia|Clara|Vivian|
Madeline|Peyton|Julia|Rylee|Brielle|Reagan|Natalia|Jade|Athena|Leilani|Everleigh|Liliana|Melanie|Mackenzie|Hadley|
Raelynn|Kaylee|Rose|Arianna|Isabelle|Melody|Eliza|Lyla|Aubree|Adalynn|Kylie|Faith|Ximena|Iris|Alexandra|Jasmine|
Charlie|Amaya|Taylor|Isabel|Khloe|Ryleigh|Alexa|Amara|Valeria|Parker|Norah|Eden|Elliana|Brianna|Valerie|Anastasia|
Eloise|Emerson|Cecilia|Remi|Josie|Reese|Bailey|Lucia|Adalyn|Molly|Ayla|Daisy|London|Jordyn|Esther|Genevieve|
Harmony|Annabelle|Alyssa|Ariel|Aliyah|Londyn|Juliana|Morgan|Summer|Juliette|Trinity|Callie|Sienna|Blakely|Alaina|
Teagan|Brynlee|Finley|Catalina|Sloane|Lilly|Ember|Juniper|Sydney|Arabella|Gemma|Jocelyn|Freya|June|Presley|Georgia|
Journey|Elise|Rosalie|Ada|Laila|Brooke|Olive|River|Payton|Hope|Tessa|Phyllis|Kathy|Gladys|Tammy|Wanda|Bonnie|Sherry|
Peggy|Annie|Jane|Rita|Dawn|Connie|Sylvia|Lois|Florence|Edna|Tina|Carrie|Ellen|Wendy|Rosa|Joy|Paula|Irene|Robin|
Lorraine|Jill|Erin|Holly|Tracy|Norma|Thelma|Dana|Vanessa|Sue|Stacy|Edith|Joanne|Beth|Monica|Crystal|Kristen|
Tiffany|Pauline|Gail|Lucille|Anita|Vera|Rhonda|Suzanne|Cindy|Darlene|Yvonne|Erica|Kristin|Shannon|Stacey|Renee|
Kristina|Jenna|Courtney|Whitney|Lindsey|Haley|Caitlin|Jillian|Kara|Mallory|Chelsea|Tara|Meredith|Bridget|Colleen|
Jenny|Marcia|Miriam|Regina|Marsha|Loretta|Jeanette|Ramona|Becky|Sheila|Roberta|Wilma|Agnes|Bernice|Eileen|Claudia|
Constance|Lena|Mildred|Hilda|Ida|Ethel|Gwendolyn|Priscilla|Sonia|Tanya|Natasha|Jessie|Kelsey|Brandy|Misty|Alicia|
Veronica|Kendra|Melinda|Opal|Pearl|Beatrice|Mabel|Nadia|Selena|Daphne|Fiona|Hallie|Lila|Mae|Margot|Maeve|Paige
', '|');

CALL faker_add_words('en_US', 'last_name', '', '
Smith|Johnson|Williams|Brown|Jones|Garcia|Miller|Davis|Rodriguez|Martinez|Hernandez|Lopez|Gonzalez|Wilson|Anderson|
Thomas|Taylor|Moore|Jackson|Martin|Lee|Perez|Thompson|White|Harris|Sanchez|Clark|Ramirez|Lewis|Robinson|Walker|Young|
Allen|King|Wright|Scott|Torres|Nguyen|Hill|Flores|Green|Adams|Nelson|Baker|Hall|Rivera|Campbell|Mitchell|Carter|
Roberts|Gomez|Phillips|Evans|Turner|Diaz|Parker|Cruz|Edwards|Collins|Reyes|Stewart|Morris|Morales|Murphy|Cook|Rogers|
Gutierrez|Ortiz|Morgan|Cooper|Peterson|Bailey|Reed|Kelly|Howard|Ramos|Kim|Cox|Ward|Richardson|Watson|Brooks|Chavez|
Wood|James|Bennett|Gray|Mendoza|Ruiz|Hughes|Price|Alvarez|Castillo|Sanders|Patel|Myers|Long|Ross|Foster|Jimenez|
Powell|Jenkins|Perry|Russell|Sullivan|Bell|Coleman|Butler|Henderson|Barnes|Gonzales|Fisher|Vasquez|Simmons|Romero|
Jordan|Patterson|Alexander|Hamilton|Graham|Reynolds|Griffin|Wallace|Moreno|West|Cole|Hayes|Bryant|Herrera|Gibson|
Ellis|Tran|Medina|Aguilar|Stevens|Murray|Ford|Castro|Marshall|Owens|Harrison|Fernandez|McDonald|Woods|Washington|
Kennedy|Wells|Vargas|Henry|Chen|Freeman|Webb|Tucker|Guzman|Burns|Crawford|Olson|Simpson|Porter|Hunter|Gordon|
Mendez|Silva|Shaw|Snyder|Mason|Dixon|Munoz|Hunt|Hicks|Holmes|Palmer|Wagner|Black|Robertson|Boyd|Rose|Stone|Salazar|
Fox|Warren|Mills|Meyer|Rice|Schmidt|Garza|Daniels|Ferguson|Nichols|Stephens|Soto|Weaver|Ryan|Gardner|Payne|Grant|
Dunn|Kelley|Spencer|Hawkins|Arnold|Pierce|Vazquez|Hansen|Peters|Santos|Hart|Bradley|Knight|Elliott|Cunningham|
Duncan|Armstrong|Hudson|Carroll|Lane|Riley|Andrews|Alvarado|Ray|Delgado|Berry|Perkins|Hoffman|Johnston|Matthews|
Pena|Richards|Contreras|Willis|Carpenter|Lawrence|Sandoval|Guerrero|George|Chapman|Rios|Estrada|Ortega|Watkins|
Greene|Nunez|Wheeler|Valdez|Harper|Burke|Larson|Santiago|Maldonado|Morrison|Franklin|Carlson|Austin|Dominguez|Carr|
Lawson|Jacobs|O''Brien|Lynch|Singh|Vega|Bishop|Montgomery|Oliver|Jensen|Harvey|Williamson|Gilbert|Dean|Sims|
Espinoza|Howell|Li|Wong|Reid|Hanson|Le|McCoy|Garrett|Burton|Fuller|Wang|Weber|Welch|Rojas|Lucas|Marquez|Fields|Park|
Yang|Little|Banks|Padilla|Day|Walsh|Bowman|Schultz|Luna|Fowler|Mejia|Davidson|Acosta|Brewer|May|Holland|Juarez|
Newman|Pearson|Curtis|Cortez|Douglas|Schneider|Joseph|Barrett|Navarro|Figueroa|Keller|Avila|Wade|Molina|Stanley|
Hopkins|Campos|Barnett|Bates|Chambers|Caldwell|Beck|Lambert|Miranda|Byrd|Craig|Ayala|Lowe|Frazier|Powers|Neal|
Leonard|Gregory|Carrillo|Sutton|Fleming|Rhodes|Shelton|Schwartz|Norris|Jennings|Watts|Duran|Walters|Cohen|McDaniel|
Moran|Parks|Steele|Vaughn|Becker|Holt|Deleon|Barker|Terry|Hale|Leon|Benson|Haynes|Horton|Miles|Lyons|Pham|Graves|
Bush|Thornton|Wolfe|Warner|Cabrera|McKinney|Mann|Zimmerman|Dawson|Lara|Fletcher|Page|McCarthy|Love|Robles|
Cervantes|Solis|Erickson|Reeves|Chang|Klein|Salinas|Fuentes|Baldwin|Daniel|Simon|Velasquez|Hardy|Higgins|Aguirre|
Lin|Cummings|Chandler|Sharp|Barber|Bowen|Ochoa|Dennis|Robbins|Liu|Ramsey|Francis|Griffith|Paul|Blair|O''Connor|
Cardenas|Pacheco|Cross|Calderon|Quinn|Moss|Swanson|Chan|Rivas|Khan|Rodgers|Serrano|Fitzgerald|Rosales|Stevenson|
Christensen|Manning|Gill|Curry|McLaughlin|Harmon|McGee|Gross|Doyle|Garner|Newton|Burgess|Reese|Walton|Blake|
Trujillo|Adkins|Brady|Goodman|Roman|Webster|Goodwin|Fischer|Huang|Potter|Delacruz|Montoya|Todd|Wu|Hines|Mullins|
Castaneda|Malone|Cannon|Tate|Mack|Sherman|Hubbard|Hodges|Zhang|Guerra|Wolf|Valencia|Saunders|Franco|Rowe|Gallagher|
Farmer|Hammond|Hampton|Townsend|Ingram|Wise|Gallegos|Clarke|Barton|Schroeder|Maxwell|Waters|Logan|Camacho|
Strickland|Norman|Person|Colon|Parsons|Frank|Harrington|Glover|Osborne|Buchanan|Casey|Floyd|Patton|Ibarra|Ball|
Tyler|Suarez|Bowers|Orozco|Salas|Cobb|Gibbs|Andrade|Bauer|Conner|Moody|Escobar|McGuire|Lloyd|Mueller|Hartman|
French|Kramer|McBride|Pope|Lindsey|Velazquez|Norton|McCormick|Sparks|Flynn|Yates|Hogan|Marsh|Macias|Villanueva|
Zamora|Pratt|Stokes|Owen|Ballard|Lang|Brock|Villarreal|Charles|Drake|Barrera|Cain|Patrick|Pineda|Burnett|Mercado|
Santana|Shepherd|Bautista|Ali|Shaffer|Lamb|Trevino|McKenzie|Hess|Olsen|Cochran|Morton|Nash|Wilkins|Petersen|
Briggs|Shah|Roth|Nicholson|Holloway|Lozano|Rangel|Flowers|Hoover|Short|Arias|Mora|Valenzuela|Bryan|Meyers|Weiss|
Underwood|Bass|Greer|Summers|Houston|Carson|Morrow|Clayton|Whitaker|Decker|Yoder|Collier|Zuniga|Carey|Wilcox|
Melendez|Poole|Roberson|Larsen|Conley|Davenport|Copeland|Massey|Lam|Huff|Rocha|Cameron|Jefferson|Hood|Monroe|
Anthony|Pittman|Huynh|Randall|Singleton|Kirk|Combs|Mathis|Christian|Skinner|Bradford|Richard|Galvan|Wall|Boone|
Kirby|Wilkinson|Bridges|Bruce|Atkinson|Velez|Meza|Roy|Vincent|York|Hodge|Villa|Abbott|Allison|Tapia|Gates|Chase|
Sosa|Sweeney|Farrell|Wyatt|Dalton|Horn|Barron|Phelps|Yu|Dickerson|Heath|Foley|Atkins|Mathews|Bonilla|Acevedo|
Benitez|Zavala|Hensley|Glenn|Cisneros|Harrell|Shields|Rubio|Choi|Huffman|Boyer|Garrison|Arroyo|Bond|Kane|Hancock|
Callahan|Dillon|Cline|Wiggins|Grimes|Arellano|Melton|O''Neill|Savage|Ho|Beltran|Pitts|Parrish|Ponce|Rich|Booth|
Koch|Golden|Ware|Brennan|McDowell|Marks|Cantu|Humphrey|Baxter|Sawyer|Clay|Tanner|Hutchinson|Kaur|Berg|Wiley|
Gilmore|Russo|Villegas|Hobbs|Keith|Wilkerson|Ahmed|Beard|McClain|Montes|Mata|Rosario|Vang|Walter|Henson|O''Neal|
Mosley|McClure|Beasley|Stephenson|Snow|Huerta|Preston|Vance|Barry|Johns|Eaton|Blackwell|Dyer|Prince|Macdonald|
Solomon|Guevara|Stafford|English|Hurst|Woodard|Cortes|Shannon|Kemp|Nolan|McCullough|Merritt|Murillo|Moon|Salgado|
Strong|Kline|Cordova|Barajas|Roach|Rosas|Winters|Jacobson|Lester|Knox|Bullock|Kerr|Leach|Meadows|Orr|Davila|
Whitehead|Pruitt|Kent|Conway|McKee|Barr|David|Dejesus|Marin|Berger|McIntyre|Blankenship|Gaines|Palacios|Cuevas|
Bartlett|Durham|Dorsey|McCall|O''Donnell|Stein|Browning|Stout|Lowery|Sloan|McLean|Hendricks|Calhoun|Sexton|Chung|
Gentry|Hull|Duarte|Ellison|Nielsen|Gillespie|Buck|Middleton|Sellers|Leblanc|Esparza|Hardin|Bradshaw|McIntosh|Howe|
Livingston|Frost|Glass|Morse|Knapp|Herman|Stark|Bravo|Noble|Spears|Weeks|Corona|Frederick|Buckley|McFarland|Hebert|
Enriquez|Hickman|Quintero|Randolph|Schaefer|Walls|Trejo|House|Reilly|Pennington|Michael|Conrad|Giles|Benjamin|
Crosby|Fitzpatrick|Donovan|Mays|Mahoney|Valentine|Raymond|Medrano|Hahn|McMillan|Small|Bentley|Felix|Peck|Lucero|
Boyle|Hanna|Pace|Rush|Hurley|Harding|McConnell|Bernal|Nava|Ayers|Everett|Ventura|Avery|Pugh|Mayer|Bender|Shepard|
McMahon|Landry|Case|Sampson|Moses|Magana|Blackburn|Dunlap|Gould|Duffy|Vaughan|Herring|McKay|Espinosa|Rivers|
Farley|Bernard|Ashley|Friedman|Potts|Truong|Costa|Correa|Blevins|Nixon|Clements|Fry|Delarosa|Best|Benton|Lugo|
Portillo|Dougherty|Crane|Haley|Phan|Villalobos|Blanchard|Horne|Finley|Quintana|Lynn|Esquivel|Bean|Dodson|Mullen|
Xiong|Hayden|Cano|Levy|Huber|Richmond|Moyer|Lim|Frye|Sheppard|McCarty|Avalos|Booker|Waller|Parra|Woodward|
Jaramillo|Krueger|Rasmussen|Brandt|Peralta|Donaldson|Stuart|Faulkner|Maynard|Galindo|Coffey|Estes|Sanford|Burch|
Maddox|Vo|O''Connell|Vu|Andersen|Spence|McPherson|Church|Schmitt|Stanton|Leal|Cherry|Compton|Dudley|Sierra|Pollard|
Alfaro|Hester|Proctor|Lu|Hinton|Novak|Good|Madden|McCann|Terrell|Jarvis|Dickson|Reyna|Cantrell|Mayo|Branch|
Hendrix|Rollins|Rowland|Whitney|Duke|Odom|Daugherty|Travis|Tang|Archer
', '|');
