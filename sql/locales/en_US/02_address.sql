-- English (United States): addresses.
SET NAMES utf8mb4;

CALL faker_add_values('en_US', 'address_format', '', '["{building} {street}, {city}, {region_code} {postal_code}", "{building} {street}, {secondary}, {city}, {region_code} {postal_code}", "{building} {street} {secondary}, {city}, {region_code} {postal_code}", "{building} {street}, {city} {region_code} {postal_code}", "{building} {street}, {city}, {region_code} {postal_code}, USA"]', '[55, 14, 10, 12, 9]');

CALL faker_add_values('en_US', 'street_format', '', '["{street_name} {street_type}", "{street_direction} {street_name} {street_type}", "{street_ordinal} {street_type}", "{street_name} {street_type} {street_direction}"]', '[70, 14, 10, 6]');

CALL faker_add_values('en_US', 'building_number_format', '', '["%", "%#", "%##", "%###", "%####"]',
    '[5, 15, 30, 35, 15]');
CALL faker_add_values('en_US', 'secondary_format', '', '["Apt. %##", "Apt. %#", "Apt %#", "Suite %##", "Suite %#0", "Unit %#", "Unit %", "Ste %##", "Fl. %", "Room %##"]', '[22, 12, 8, 12, 6, 12, 6, 12, 5, 5]');
CALL faker_add_values('en_US', 'postal_code_format', '', '["#####", "#####-####"]', '[85, 15]');

CALL faker_add_values('en_US', 'street_type', '', '["Street", "St.", "Avenue", "Ave.", "Road", "Rd.", "Drive", "Dr.", "Lane", "Ln.", "Boulevard", "Blvd.", "Court", "Ct.", "Place", "Way", "Circle", "Terrace", "Parkway", "Trail", "Highway", "Loop", "Pike", "Square"]', '[25, 10, 15, 6, 12, 4, 10, 3, 8, 2, 4, 2, 5, 2, 4, 5, 3, 2, 2, 2, 1, 1, 1, 1]');
CALL faker_add_values('en_US', 'street_direction', '', '["N", "S", "E", "W", "North", "South", "East", "West", "NE", "NW", "SE", "SW"]', '[10, 10, 10, 10, 6, 6, 6, 6, 3, 3, 3, 3]');

-- 1st ... 120th
CALL faker_add_words('en_US', 'street_ordinal', '', '1st|2nd|3rd|4th|5th|6th|7th|8th|9th|10th|11th|12th|13th|14th|15th|16th|17th|18th|19th|20th|21st|22nd|23rd|24th|25th|26th|27th|28th|29th|30th|31st|32nd|33rd|34th|35th|36th|37th|38th|39th|40th|41st|42nd|43rd|44th|45th|46th|47th|48th|49th|50th|51st|52nd|53rd|54th|55th|56th|57th|58th|59th|60th|61st|62nd|63rd|64th|65th|66th|67th|68th|69th|70th|71st|72nd|73rd|74th|75th|76th|77th|78th|79th|80th|81st|82nd|83rd|84th|85th|86th|87th|88th|89th|90th|91st|92nd|93rd|94th|95th|96th|97th|98th|99th|100th|101st|102nd|103rd|104th|105th|106th|107th|108th|109th|110th|111th|112th|113th|114th|115th|116th|117th|118th|119th|120th', '|');

CALL faker_add_words('en_US', 'street_name', '', '
Main|Oak|Pine|Maple|Cedar|Elm|Washington|Lake|Hill|Park|Walnut|Sunset|Lincoln|Jackson|Madison|Jefferson|Franklin|
Adams|Church|Spring|Ridge|Highland|Meadow|River|Forest|Willow|Cherry|Chestnut|Birch|Spruce|Hickory|Sycamore|Magnolia|
Dogwood|Aspen|Poplar|Laurel|Juniper|Cypress|Holly|Center|Mill|School|Broad|Market|Union|Water|Bridge|Railroad|Front|
High|Prospect|Pleasant|Liberty|Greenwood|Fairview|Lakeview|Valley|Woodland|Grove|Orchard|Garden|Rose|Lilac|Jasmine|
Heather|Ivy|Clover|Hawthorn|Sherwood|Westwood|Brookside|Creekside|Riverside|Hillcrest|Stonebridge|Fox Run|Deer Creek|
Eagle|Hawk|Falcon|Cardinal|Robin|Bluebird|Sparrow|Heron|Quail|Pheasant|Canyon|Mesa|Desert|Prairie|Harbor|Bay|Ocean|
Shore|Beach|Coral|Mountain|Summit|Glen|Hollow|Crest|Vista|Horizon|Sunrise|Morning|Evening|Autumn|Winter|Summer|King|
Queen|Prince|Duke|Kingston|Hamilton|Monroe|Wilson|Taylor|Grant|Cleveland|Harrison|Pierce|Polk|Tyler|Van Buren|
Roosevelt|Kennedy|Martin Luther King Jr.|Johnson|Hoover|Truman|Webster|Clay|Davis|Lee|Wood|Smith|Brown|Miller|Walker|
Cooper|Hunter|Carter|Parker|Baker|Fisher|Mason|College|University|Academy|Chapel|Depot|Industrial|Commerce|
Enterprise|Independence|Constitution|Patriot|Colonial|Heritage|Pioneer|Frontier|Wagon Wheel|Old Mill|Country Club|
Golf Course|Lexington|Concord|Bedford|Oxford|Cambridge|Princeton|Dartmouth|Hampton|Charleston|Savannah|Richmond|
Arlington|Fremont|Berkeley|Sheridan|Marshall|Peachtree|Cottonwood|Mulberry|Linden|Locust|Beech|Ash|Hemlock|Redwood|
Sequoia|Palm|Olive|Orange|Lemon|Apple|Pecan|Butternut|Bayview|Seaside|Sandpiper|Pelican|Mockingbird|Whippoorwill|
Thunderbird|Wildflower|Primrose|Sunflower|Bluebonnet|Cactus|Saddle|Ranch|Meadowbrook|Brookfield|Fieldstone|
Cobblestone|Timber|Pinecrest|Oakwood|Elmwood|Maplewood|Ridgewood|Briarwood|Kensington|Windsor|Ashford|Stratford|
Wellington|Belmont|Fairfax|Hillside|Lakeshore|Riverbend|Clearwater|Silver Lake|Crystal Springs|Shady Grove
', '|');

CALL faker_add_items('en_US', 'city', '', '["value", "region_code", "postal_prefix"]', '[
["New York","NY","100"],["Los Angeles","CA","900"],["Chicago","IL","606"],["Houston","TX","770"],
["Phoenix","AZ","850"],["Philadelphia","PA","191"],["San Antonio","TX","782"],["San Diego","CA","921"],
["Dallas","TX","752"],["San Jose","CA","951"],["Austin","TX","787"],["Jacksonville","FL","322"],
["Fort Worth","TX","761"],["Columbus","OH","432"],["Charlotte","NC","282"],["San Francisco","CA","941"],
["Indianapolis","IN","462"],["Seattle","WA","981"],["Denver","CO","802"],["Washington","DC","200"],
["Boston","MA","021"],["El Paso","TX","799"],["Nashville","TN","372"],["Detroit","MI","482"],
["Oklahoma City","OK","731"],["Portland","OR","972"],["Las Vegas","NV","891"],["Memphis","TN","381"],
["Louisville","KY","402"],["Baltimore","MD","212"],["Milwaukee","WI","532"],["Albuquerque","NM","871"],
["Tucson","AZ","857"],["Fresno","CA","937"],["Sacramento","CA","958"],["Mesa","AZ","852"],
["Kansas City","MO","641"],["Atlanta","GA","303"],["Omaha","NE","681"],["Colorado Springs","CO","809"],
["Raleigh","NC","276"],["Long Beach","CA","908"],["Virginia Beach","VA","234"],["Miami","FL","331"],
["Oakland","CA","946"],["Minneapolis","MN","554"],["Tulsa","OK","741"],["Bakersfield","CA","933"],
["Wichita","KS","672"],["Arlington","TX","760"],["Aurora","CO","800"],["Tampa","FL","336"],
["New Orleans","LA","701"],["Cleveland","OH","441"],["Honolulu","HI","968"],["Anaheim","CA","928"],
["Lexington","KY","405"],["Stockton","CA","952"],["Corpus Christi","TX","784"],["Henderson","NV","890"],
["Riverside","CA","925"],["Newark","NJ","071"],["Saint Paul","MN","551"],["Santa Ana","CA","927"],
["Cincinnati","OH","452"],["Irvine","CA","926"],["Orlando","FL","328"],["Pittsburgh","PA","152"],
["St. Louis","MO","631"],["Greensboro","NC","274"],["Jersey City","NJ","073"],["Anchorage","AK","995"],
["Lincoln","NE","685"],["Plano","TX","750"],["Durham","NC","277"],["Buffalo","NY","142"],
["Chandler","AZ","852"],["Chula Vista","CA","919"],["Toledo","OH","436"],["Madison","WI","537"],
["Gilbert","AZ","852"],["Reno","NV","895"],["Fort Wayne","IN","468"],["North Las Vegas","NV","890"],
["St. Petersburg","FL","337"],["Lubbock","TX","794"],["Irving","TX","750"],["Laredo","TX","780"],
["Winston-Salem","NC","271"],["Chesapeake","VA","233"],["Glendale","AZ","853"],["Garland","TX","750"],
["Scottsdale","AZ","852"],["Norfolk","VA","235"],["Boise","ID","837"],["Fremont","CA","945"],
["Spokane","WA","992"],["Santa Clarita","CA","913"],["Baton Rouge","LA","708"],["Richmond","VA","232"],
["Hialeah","FL","330"],["San Bernardino","CA","924"],["Tacoma","WA","984"],["Modesto","CA","953"],
["Huntsville","AL","358"],["Des Moines","IA","503"],["Yonkers","NY","107"],["Rochester","NY","146"],
["Moreno Valley","CA","925"],["Fayetteville","NC","283"],["Fontana","CA","923"],["Columbus","GA","319"],
["Worcester","MA","016"],["Port St. Lucie","FL","349"],["Little Rock","AR","722"],["Augusta","GA","309"],
["Oxnard","CA","930"],["Birmingham","AL","352"],["Montgomery","AL","361"],["Frisco","TX","750"],
["Amarillo","TX","791"],["Salt Lake City","UT","841"],["Grand Rapids","MI","495"],["Huntington Beach","CA","926"],
["Overland Park","KS","662"],["Glendale","CA","912"],["Tallahassee","FL","323"],["Grand Prairie","TX","750"],
["McKinney","TX","750"],["Cape Coral","FL","339"],["Sioux Falls","SD","571"],["Peoria","AZ","853"],
["Providence","RI","029"],["Vancouver","WA","986"],["Knoxville","TN","379"],["Akron","OH","443"],
["Shreveport","LA","711"],["Mobile","AL","366"],["Brownsville","TX","785"],["Newport News","VA","236"],
["Fort Lauderdale","FL","333"],["Chattanooga","TN","374"],["Tempe","AZ","852"],["Aurora","IL","605"],
["Santa Rosa","CA","954"],["Eugene","OR","974"],["Elk Grove","CA","956"],["Salem","OR","973"],
["Ontario","CA","917"],["Cary","NC","275"],["Rancho Cucamonga","CA","917"],["Oceanside","CA","920"],
["Lancaster","CA","935"],["Garden Grove","CA","928"],["Pembroke Pines","FL","330"],["Fort Collins","CO","805"],
["Palmdale","CA","935"],["Springfield","MO","658"],["Clarksville","TN","370"],["Rockford","IL","611"],
["Alexandria","VA","223"],["Paterson","NJ","075"],["Hayward","CA","945"],["Kansas City","KS","661"],
["Savannah","GA","314"],["Bridgeport","CT","066"],["Hartford","CT","061"],["New Haven","CT","065"],
["Albany","NY","122"],["Syracuse","NY","132"],["Burlington","VT","054"],["Portland","ME","041"],
["Manchester","NH","031"],["Charleston","SC","294"],["Columbia","SC","292"],["Greenville","SC","296"],
["Charleston","WV","253"],["Wilmington","DE","198"],["Annapolis","MD","214"],["Dover","DE","199"],
["Trenton","NJ","086"],["Allentown","PA","181"],["Erie","PA","165"],["Harrisburg","PA","171"],
["Scranton","PA","185"],["Dayton","OH","454"],["Ann Arbor","MI","481"],["Lansing","MI","489"],
["Flint","MI","485"],["Green Bay","WI","543"],["Duluth","MN","558"],["Fargo","ND","581"],
["Bismarck","ND","585"],["Rapid City","SD","577"],["Billings","MT","591"],["Missoula","MT","598"],
["Cheyenne","WY","820"],["Casper","WY","826"],["Boulder","CO","803"],["Santa Fe","NM","875"],
["Flagstaff","AZ","860"],["Provo","UT","846"],["Ogden","UT","844"],["Juneau","AK","998"],
["Fairbanks","AK","997"],["Hilo","HI","967"],["Bellevue","WA","980"],["Olympia","WA","985"],
["Berkeley","CA","947"],["Pasadena","CA","911"],["Santa Barbara","CA","931"],["Santa Monica","CA","904"],
["Palo Alto","CA","943"],["San Mateo","CA","944"],["Monterey","CA","939"],["Redding","CA","960"],
["Gainesville","FL","326"],["Pensacola","FL","325"],["Naples","FL","341"],["Sarasota","FL","342"],
["Daytona Beach","FL","321"],["Key West","FL","330"],["Athens","GA","306"],["Macon","GA","312"],
["Asheville","NC","288"],["Wilmington","NC","284"],["Roanoke","VA","240"],["Lynchburg","VA","245"],
["Jackson","MS","392"],["Gulfport","MS","395"],["Lafayette","LA","705"],["Lake Charles","LA","706"],
["Waco","TX","767"],["Tyler","TX","757"],["Galveston","TX","775"],["Abilene","TX","796"],
["Midland","TX","797"],["Odessa","TX","797"],["Beaumont","TX","777"],["Killeen","TX","765"],
["Topeka","KS","666"],["Lawrence","KS","660"],["Columbia","MO","652"],["Iowa City","IA","522"],
["Cedar Rapids","IA","524"],["Davenport","IA","528"],["Peoria","IL","616"],["Springfield","IL","627"],
["Champaign","IL","618"],["Evansville","IN","477"],["South Bend","IN","466"],["Bloomington","IN","474"],
["Bowling Green","KY","421"],["Huntington","WV","257"],["Morgantown","WV","265"],["Cambridge","MA","021"],
["Springfield","MA","011"],["Lowell","MA","018"],["Stamford","CT","069"],["Ithaca","NY","148"],
["Princeton","NJ","085"],["Concord","NH","033"],["Montpelier","VT","056"],["Bangor","ME","044"],
["Newport","RI","028"],["Frederick","MD","217"],["Lancaster","PA","176"],["Reading","PA","196"],
["Youngstown","OH","445"],["Kalamazoo","MI","490"],["Eau Claire","WI","547"],["Rochester","MN","559"],
["Sioux City","IA","511"],["Grand Island","NE","688"],["Pueblo","CO","810"],["Las Cruces","NM","880"],
["Yuma","AZ","853"],["St. George","UT","847"],["Bend","OR","977"],["Medford","OR","975"],
["Yakima","WA","989"],["Bellingham","WA","982"],["Idaho Falls","ID","834"],["Helena","MT","596"]
]');
