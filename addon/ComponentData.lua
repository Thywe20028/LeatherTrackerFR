local _, addon = ...

-- Sélection de sources publiques signalées comme observées sur Forever.
-- Les observations de butin ne donnent ni taux ni compétence de dépeçage.
local cavernsAccess = {
 name = "Accès aux Cavernes des lamentations", method = "Accès", zone = "Les Tarides",
 map = 1413, x = 0.46, y = 0.365, locationSource = "Questing.wiki",
 sharedPin = "cavernes-acces", context = "Accès au donjon, positions des créatures non vérifiées",
}
local sources = {
 [8169] = {{
  name = "Rabid Forest Wolf", method = "Dépeçage", zone = "Feralas", continent = "Kalimdor",
  tentative = true, provenance = "WoW Forever Ninja (données Classic 1.12)",
  context = "Association à la peau épaisse à confirmer en jeu sur Forever.",
 }},
 [18240] = {{
  name = "Ogre Tannin Basket", method = "Ouverture", zone = "Hache-Tripes Nord",
  continent = "Kalimdor", tentative = true, provenance = "SenseOS (données Classic)",
  context = "Panier signalé dans les données Classic. Emplacement et obtention à confirmer en jeu sur Forever.",
 }},
 [8150] = {{
  name = "Elemental Slave", creatureID = 2359, method = "Butin", level = "32–33",
  zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", context = "Ruines de Dalaran",
  obtained = 6, observations = 23, provenance = "Forever Drop Rate",
  map = 1416, x = 0.253, y = 0.533, approximate = true, locationSource = "Forever Drop Rate",
 }},
 [5498] = {{
  name = "Petite palourde à bec", method = "Ouverture", obtained = 5, observations = 82,
  context = "Ouvrir la palourde #5523. Palourde observée sur Murloc Coastrunner (12–13), sur le littoral de la Marche de l’Ouest, et Oasis Snapjaw (15–16), aux oasis des Tarides.",
  provenance = "Forever Drop Rate",
 }},
 [1210] = {{
  name = "Deviate Guardian", creatureID = 3637, method = "Butin", level = "18–19",
  zone = "Cavernes des lamentations", continent = "Kalimdor", context = "Screaming Gully",
  observedRate = 5.3, observations = 95, provenance = "Forever Drop Rate",
 }, {
  name = "Ragefire Shaman", method = "Butin", zone = "Gouffre de Ragefeu", continent = "Kalimdor",
  observedRate = 6.5, observations = 31, provenance = "Forever Drop Rate",
 }},

 [5082] = {{
  name = "Lost Barrens Kodo", method = "Butin", zone = "Les Tarides", continent = "Kalimdor",
  level = "14–15", obtained = 2, observations = 5, provenance = "ForeverDB.net",
  map = 1413, x = 0.548, y = 0.401, approximate = true, locationSource = "Azeroth Wiki",
 }},
 [7286] = {{
  name = "Black Dragon Whelp", creatureID = 441, method = "Butin", zone = "Les Carmines",
  continent = "Royaumes de l’Est", level = "17–18", provenance = "ForeverDB.net",
  map = 1433, x = 0.618, y = 0.766, approximate = true, locationSource = "Bind on Forever",
 }},
 [249427] = {{
  name = "Mister Graphed", creatureID = 263384, method = "Achat", zone = "Riverglades",
  continent = "Royaumes de l’Est", level = 60, shop = "Vente documentée",
  provenance = "ForeverDB.net", map = 2548, x = 0.7820, y = 0.5180,
  locationSource = "HandyNotes NPCs (Forever)",
 }},
 [2321] = {
  {name = "Vendor-Tron 1000", creatureID = 12245, method = "Achat", zone = "Désolace", continent = "Kalimdor", level = 38,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #12245",
   map = 1443, x = 0.6020, y = 0.3820, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Ranik", creatureID = 3499, method = "Achat", zone = "Les Tarides", continent = "Kalimdor", level = 22,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #3499",
   map = 1413, x = 0.6180, y = 0.3860, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Vizzklick", creatureID = 6568, method = "Achat", zone = "Tanaris", continent = "Kalimdor", level = 50,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #6568",
   map = 1446, x = 0.5100, y = 0.2740, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Mahu", creatureID = 3005, method = "Achat", zone = "Les Pitons-du-Tonnerre", continent = "Kalimdor", level = 30,
   shop = "Vente documentée", provenance = "Warcraft Forever Wiki", portraitSource = "HandyNotes NPCs (Forever) #3005",
   map = 1456, x = 0.4367, y = 0.4427, locationSource = "HandyNotes NPCs (Forever)", approximate = true},
  {name = "Kalldan Felmoon", creatureID = 5783, method = "Achat", zone = "Cavernes des lamentations", continent = "Kalimdor", level = 27,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #5783"},
  {name = "Darnall", creatureID = 7940, method = "Achat", zone = "Reflet-de-Lune", continent = "Kalimdor", level = 53,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #7940",
   map = 1450, x = 0.5153, y = 0.3333, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Lorelae Wintersong", creatureID = 12022, method = "Achat", zone = "Reflet-de-Lune", continent = "Kalimdor", level = 51,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #12022",
   map = 1450, x = 0.4847, y = 0.4027, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Captured Servant of Azora", creatureID = 3096, method = "Achat", zone = "Les Carmines", continent = "Royaumes de l’Est", level = 22,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #3096",
   map = 1433, x = 0.6930, y = 0.7950, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Gilliwigs", creatureID = 260559, method = "Achat", zone = "Riverglades", continent = "Royaumes de l’Est", level = 41,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #260559",
   map = 2548, x = 0.7930, y = 0.5450, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Stitch Pinwizzle", creatureID = 260570, method = "Achat", zone = "Riverglades", continent = "Royaumes de l’Est", level = 41,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #260570",
   map = 2548, x = 0.7720, y = 0.5150, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Blixrez Goodstitch", creatureID = 2846, method = "Achat", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", level = 43,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #2846",
   map = 1434, x = 0.2820, y = 0.7750, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Cowardly Crosby", creatureID = 2672, method = "Achat", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", level = 40,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #2672",
   map = 1434, x = 0.2700, y = 0.8250, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Rikqiz", creatureID = 2699, method = "Achat", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", level = 43,
   shop = "1 pa", provenance = "ForeverDB.net", portraitSource = "HandyNotes NPCs (Forever) #2699",
   map = 1434, x = 0.2840, y = 0.7600, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Borya", creatureID = 3364, method = "Achat", zone = "Orgrimmar", continent = "Kalimdor", level = 30,
   shop = "Vente documentée", provenance = "Warcraft Forever Wiki", portraitSource = "HandyNotes NPCs (Forever) #3364",
   map = 1454, x = 0.6310, y = 0.5080, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Andrew Hilbert", creatureID = 3556, method = "Achat", zone = "Forêt des Pins-Argentés", continent = "Royaumes de l’Est", level = "18–20",
   shop = "Vente documentée", provenance = "Warcraft Forever Wiki", portraitSource = "HandyNotes NPCs (Forever) #3556",
   map = 1421, x = 0.4320, y = 0.4060, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Tamar", creatureID = 3366, method = "Achat", zone = "Orgrimmar", continent = "Kalimdor", level = 30,
   shop = "Vente documentée", provenance = "Warcraft Forever Wiki", portraitSource = "HandyNotes NPCs (Forever) #3366",
   map = 1454, x = 0.6265, y = 0.4545, locationSource = "HandyNotes NPCs (Forever)"},
  {name = "Kulwia", creatureID = 12043, method = "Achat", zone = "Les Serres-Rocheuses", continent = "Kalimdor", level = 32,
   shop = "Vente documentée", provenance = "Warcraft Forever Wiki", portraitSource = "HandyNotes NPCs (Forever) #12043",
   map = 1442, x = 0.4540, y = 0.5950, locationSource = "HandyNotes NPCs (Forever)"},
 },
 [4340] = {
  {name = "Mahu", creatureID = 3005, method = "Achat", zone = "Les Pitons-du-Tonnerre", continent = "Kalimdor",
   level = 30, shop = "3 pa 50 pc (relevé)", provenance = "Warcraft Forever Wiki",
   map = 1456, x = 0.4365, y = 0.448, approximate = true, locationSource = "Warcraft Forever Wiki"},
 },
 [3356] = {},
 [249409] = {
  {name = "Teinture céruléenne", method = "Fabrication", skill = "Alchimie 1 (données client)",
   context = "2 lichens frangés et une fiole vide. Acquisition de la recette non documentée.", provenance = "WoW Forever Ninja"},
 },
 [249410] = {
  {name = "Acide sulfurique", method = "Fabrication", skill = "Alchimie 1 (données client)",
   context = "2 pyrites et une fiole vide. Acquisition de la recette non documentée.", provenance = "WoW Forever Ninja"},
 },
 [4304] = {
  {name = "Conversion de cuir lourd", method = "Fabrication", skill = "Travail du cuir 175",
   context = "6 cuirs lourds", provenance = "WoW Forever Ninja"},
 },
 [8170] = {
  {name = "Conversion de cuir épais", method = "Fabrication", skill = "Travail du cuir 225",
   context = "6 cuirs épais", provenance = "WoW Forever Ninja"},
 },
 [14048] = {
  {name = "Rouleau d’étoffe runique", method = "Fabrication", skill = "Couture 205",
   context = "5 étoffes runiques", provenance = "WoW Forever Ninja"},
 },
 [2312] = {{name = "Gants en cuir fin", method = "Fabrication", skill = "Travail du cuir", provenance = "Warcraft Forever Wiki · Recettes"}},
 [2313] = {{name = "Renfort d’armure moyen", method = "Fabrication", skill = "Travail du cuir", provenance = "Warcraft Forever Wiki · Recettes"}},
 [4246] = {{name = "Ceinture en cuir fin", method = "Fabrication", skill = "Travail du cuir", provenance = "Warcraft Forever Wiki · Recettes"}},
 [4243] = {{name = "Tunique en cuir fin", method = "Fabrication", skill = "Travail du cuir", provenance = "Warcraft Forever Wiki · Recettes"}},
 [13423] = {
  {name = "Huile de pierre-écaille", method = "Fabrication", skill = "Alchimie 250", provenance = "Icy Veins Database"},
 },
 [3824] = {
  {name = "Huile des ténèbres", method = "Fabrication", skill = "Alchimie 165", provenance = "WoW Forever Addon"},
 },
 [4470] = {
  {name = "Naal Mistrunner", creatureID = 3027, method = "Achat", level = 40, zone = "Les Pitons-du-Tonnerre",
   continent = "Kalimdor", map = 1456, x = 0.5107, y = 0.5218, locationSource = "HandyNotes NPCs (Forever)", provenance = "ForeverDB"},
 },
 [2458] = {
  {name = "Élixir de robustesse mineure", method = "Fabrication", skill = "Alchimie 50", provenance = "WoW Forever Ninja"},
 },
 [2934] = {
  {name = "Mountain Cougar", creatureID = 2961, method = "Dépeçage", provenance = "Forever Drop Rate", level = "3", zone = "Mulgore", continent = "Kalimdor", observedRate = 100, observations = 49, context = "Red Cloud Mesa, Mulgore"},
  {name = "Plainstrider", creatureID = 2955, method = "Dépeçage", provenance = "Forever Drop Rate", level = "1–2", zone = "Mulgore", continent = "Kalimdor", observedRate = 100, observations = 47, context = "Red Cloud Mesa, Mulgore"},
  {name = "Battleboar", creatureID = 2966, method = "Dépeçage", provenance = "Forever Drop Rate", level = "3–4", zone = "Mulgore", continent = "Kalimdor", observedRate = 100, observations = 35, context = "Red Cloud Mesa, Mulgore; Kodo Rock, Mulgore"},
  {name = "Scorpid Worker", creatureID = 3124, method = "Dépeçage", provenance = "Forever Drop Rate", level = "3", zone = "Durotar", continent = "Kalimdor", observedRate = 100, observations = 29, context = "Valley of Trials, Durotar"},
  {name = "Bristleback Battleboar", creatureID = 2954, method = "Dépeçage", provenance = "Forever Drop Rate", level = "4–5", zone = "Mulgore", continent = "Kalimdor", observedRate = 100, observations = 26, context = "Red Cloud Mesa, Mulgore; Brambleblade Ravine, Mulgore"},
  {name = "Ursera Scavenger", creatureID = 250937, method = "Dépeçage", provenance = "Forever Drop Rate", level = "4", zone = "Île de Zéphras", observedRate = 100, observations = 23, context = "Thendal Cave, Zephras Isle"},
 },
 [2318] = {
  {name = "Deviate Crocolisk", creatureID = 5053, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 68.2, observations = 22, context = "Wailing Caverns; Pit of Fangs, Wailing Caverns; Crag of the Everliving, Wailing Caverns; Screaming Gully, Wailing Caverns"},
  {name = "Sunscale Screecher", creatureID = 3255, method = "Dépeçage", provenance = "Forever Drop Rate", level = "13–15", zone = "Les Tarides", continent = "Kalimdor", observedRate = 66.7, observations = 33, context = "The Barrens; Grol'dom Farm, The Barrens; The Forgotten Pools, The Barrens; The Dry Hills, The Barrens; The Stagnant Oasis, The Barrens; Gold Road, The Barrens"},
  {name = "Oasis Snapjaw", creatureID = 3461, method = "Dépeçage", provenance = "Forever Drop Rate", level = "15–16", zone = "Les Tarides", continent = "Kalimdor", observedRate = 65.4, observations = 26, context = "Lushwater Oasis, The Barrens; The Stagnant Oasis, The Barrens"},
  {name = "Fleeting Plainstrider", creatureID = 3246, method = "Dépeçage", provenance = "Forever Drop Rate", level = "12–13", zone = "Les Tarides", continent = "Kalimdor", observedRate = 64.7, observations = 34, context = "The Barrens; Thorn Hill, The Barrens; Grol'dom Farm, The Barrens; The Forgotten Pools, The Barrens; Dreadmist Peak, The Barrens"},
  {name = "Moonrage Glutton", creatureID = 1779, method = "Dépeçage", provenance = "Forever Drop Rate", level = "12–13", zone = "Forêt des Pins-Argentés", continent = "Royaumes de l’Est", observedRate = 64.3, observations = 56, context = "Silverpine Forest; North Tide's Hollow, Silverpine Forest; Deep Elem Mine, Silverpine Forest"},
  {name = "Mottled Worg", creatureID = 1766, method = "Dépeçage", provenance = "Forever Drop Rate", level = "11–12", zone = "Forêt des Pins-Argentés", continent = "Royaumes de l’Est", observedRate = 64.3, observations = 28, context = "Silverpine Forest; The Dead Field, Silverpine Forest; The Ivar Patch, Silverpine Forest; Malden's Orchard, Silverpine Forest"},
 },
 [2319] = {
  {name = "Cave Yeti", creatureID = 2248, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 74.3, observations = 113, context = "Darrow Hill, Hillsbrad Foothills"},
  {name = "Snapjaw", creatureID = 2408, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Contreforts de Hautebrande / Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 70.8, observations = 24, context = "Hillsbrad Foothills; Alterac Mountains; Chillwind Point, Alterac Mountains"},
  {name = "Crystal Spine Basilisk", creatureID = 689, method = "Dépeçage", provenance = "Forever Drop Rate", level = "34–35", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 56.7, observations = 30, context = "Stranglethorn Vale; The Savage Coast, Stranglethorn Vale"},
  {name = "Ferocious Yeti", creatureID = 2249, method = "Dépeçage", provenance = "Forever Drop Rate", level = "31–32", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 49.3, observations = 69, context = "Darrow Hill, Hillsbrad Foothills", map = 1424, x = 0.448, y = 0.284, approximate = true, locationSource = "Questing.wiki"},
  {name = "Deviate Guardian", creatureID = 3637, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 35.3, observations = 34, context = "Wailing Caverns; Screaming Gully, Wailing Caverns"},
  {name = "Deviate Ravager", creatureID = 3636, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 31, observations = 29, context = "Wailing Caverns; Screaming Gully, Wailing Caverns"},
  {name = "Conversion de cuir léger", method = "Fabrication", skill = "Travail du cuir 75", context = "4 cuirs légers", provenance = "WoW Forever Ninja"},
 },
 [4234] = {
  {name = "Ferocious Yeti", creatureID = 2249, method = "Dépeçage", provenance = "Forever Drop Rate", level = "31–32", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 46.4, observations = 69, context = "Darrow Hill, Hillsbrad Foothills", map = 1424, x = 0.448, y = 0.284, approximate = true, locationSource = "Questing.wiki"},
  {name = "Crystal Spine Basilisk", creatureID = 689, method = "Dépeçage", provenance = "Forever Drop Rate", level = "34–35", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 36.7, observations = 30, context = "Stranglethorn Vale; The Savage Coast, Stranglethorn Vale"},
  {name = "Snapjaw", creatureID = 2408, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 20.8, observations = 24, context = "Alterac Mountains; Chillwind Point, Alterac Mountains"},
  {name = "Cave Yeti", creatureID = 2248, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 16.8, observations = 113, context = "Darrow Hill, Hillsbrad Foothills"},
  {name = "Stranglethorn Tiger", creatureID = 682, method = "Dépeçage", provenance = "Forever Drop Rate", level = "32–33", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 100, observations = 2, context = "Stranglethorn Vale"},
  {name = "Cold Eye Basilisk", creatureID = 690, method = "Dépeçage", provenance = "Forever Drop Rate", level = "40", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 100, observations = 2, context = "Stranglethorn Vale"},
  {name = "Panther", creatureID = 736, method = "Dépeçage", provenance = "Forever Drop Rate", level = "32–33", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 100, observations = 1, context = "Stranglethorn Vale"},
  {name = "Sarltooth", creatureID = 1353, method = "Dépeçage", provenance = "Forever Drop Rate", level = "29", zone = "Les Paluns", continent = "Royaumes de l’Est", observedRate = 100, observations = 1, context = "Whelgar's Excavation Site, Wetlands"},
  {name = "Stranglethorn Tigress", creatureID = 772, method = "Dépeçage", provenance = "Forever Drop Rate", level = "37–38", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 88.9, observations = 9, context = "Stranglethorn Vale"},
  {name = "Mountain Lion", creatureID = 2406, method = "Dépeçage", provenance = "Forever Drop Rate", level = "32–33", zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 83.3, observations = 12, context = "Corrahn's Dagger, Alterac Mountains; Chillwind Point, Alterac Mountains"},
  {name = "Shadowmaw Panther", creatureID = 684, method = "Dépeçage", provenance = "Forever Drop Rate", level = "37–38", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 70, observations = 10, context = "Stranglethorn Vale"},
  {name = "Elder Stranglethorn Tiger", creatureID = 1085, method = "Dépeçage", provenance = "Forever Drop Rate", level = "34–35", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 60, observations = 10, context = "Stranglethorn Vale"},
  {name = "Hulking Mountain Lion", creatureID = 2407, method = "Dépeçage", provenance = "Forever Drop Rate", level = "33–34", zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 54.5, observations = 11, context = "Corrahn's Dagger, Alterac Mountains; Chillwind Point, Alterac Mountains"},
  {name = "Nightbane Vile Fang", creatureID = 206, method = "Dépeçage", provenance = "Forever Drop Rate", level = "29–30", zone = "Bois de la Pénombre", continent = "Royaumes de l’Est", observedRate = 50, observations = 4, context = "Duskwood"},
  {name = "Aku'mai Snapjaw", creatureID = 4825, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Profondeurs de Brassenoire", continent = "Kalimdor", observedRate = 50, observations = 2, context = "Aku'mai's Lair, Blackfathom Deeps"},
  {name = "Maddened Rotclaw", creatureID = 271334, method = "Dépeçage", provenance = "Forever Drop Rate", level = "25–26", zone = "Les Paluns", continent = "Royaumes de l’Est", observedRate = 50, observations = 2, context = "The Green Belt, Wetlands"},
  {name = "Elder Razormaw", creatureID = 1019, method = "Dépeçage", provenance = "Forever Drop Rate", level = "29", zone = "Les Paluns", continent = "Royaumes de l’Est", observedRate = 50, observations = 2, context = "Raptor Ridge, Wetlands"},
  {name = "Snapjaw Crocolisk", creatureID = 1152, method = "Dépeçage", provenance = "Forever Drop Rate", level = "35–36", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 40, observations = 15, context = "Stranglethorn Vale; Lake Nazferiti, Stranglethorn Vale"},
  {name = "Nightbane Worgen", creatureID = 898, method = "Dépeçage", provenance = "Forever Drop Rate", level = "26–27", zone = "Bois de la Pénombre", continent = "Royaumes de l’Est", observedRate = 25, observations = 4, context = "Brightwood Grove, Duskwood"},
  {name = "Lashtail Raptor", creatureID = 686, method = "Dépeçage", provenance = "Forever Drop Rate", level = "35–36", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 20, observations = 5, context = "The Savage Coast, Stranglethorn Vale"},
  {name = "Nightbane Tainted One", creatureID = 920, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Bois de la Pénombre", continent = "Royaumes de l’Est", observedRate = 20, observations = 5, context = "Duskwood"},
  {name = "Highland Razormaw", creatureID = 1018, method = "Dépeçage", provenance = "Forever Drop Rate", level = "27–28", zone = "Les Paluns", continent = "Royaumes de l’Est", observedRate = 16.7, observations = 6, context = "Raptor Ridge, Wetlands"},
  {name = "Conversion de cuir moyen", method = "Fabrication", skill = "Travail du cuir 125", context = "5 cuirs moyens", provenance = "WoW Forever Ninja"},
  {name = "Monstrous Threshadon", creatureID = 260244, method = "Butin", level = 42, zone = "Riverglades", continent = "Royaumes de l’Est", map = 2548, x = 0.715, y = 0.749, locationSource = "Bind on Forever", provenance = "ForeverDB.net"},
 },
 [4231] = {{
  name = "Peau légère traitée", method = "Fabrication", skill = "Travail du cuir 30",
  context = "1 peau légère et 1 sel.",
  learnedFrom = "Adele Fielder (forêt d’Elwynn), Randal Worth ou Simon Tanner (Hurlevent), Gretta Finespindle.",
  provenance = "WoW Forever Tavern, recette #3816",
 }},
 [4233] = {{
  name = "Peau moyenne traitée", method = "Fabrication", skill = "Travail du cuir, seuil d’apprentissage non vérifié",
  context = "1 peau moyenne et 1 sel. Recette jaune à 90.",
  learnedFrom = "Maître de Travail du cuir, noms et lieux non vérifiés.",
  provenance = "Warcraft Forever Wiki et ForeverDiff, recette #3817",
 }},
 [4236] = {{
  name = "Peau lourde traitée", method = "Fabrication", skill = "Travail du cuir 125",
  context = "1 peau lourde et 3 sels.",
  learnedFrom = "Simon Tanner (Hurlevent), 5 pa dans la référence consultée.",
  provenance = "WoW Forever Tavern, recette #3818",
 }},
 [5784] = {
  {name = "Murloc Flesheater", creatureID = 422, level = "18–19", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Bluegill Murloc", creatureID = 1024, level = "20–21", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Minor Tidecaller", creatureID = 548, level = "17–18", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Scout", creatureID = 578, level = "19–20", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Shorestriker", creatureID = 1083, level = "17", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Blindlight Muckdweller", creatureID = 4819, level = "25", zone = "Profondeurs de Brassenoire", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Tidehunter", creatureID = 127, level = "18–19", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Blindlight Murloc", creatureID = 4818, level = "22–23", zone = "Profondeurs de Brassenoire", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Bluegill Puddlejumper", creatureID = 1025, level = "21–22", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Oracle", creatureID = 517, level = "17–18", zone = "Royaumes de l’Est", method = "Butin", portraitSource = "QuestCore / TheWoWDB", provenance = "ForeverDB.net"},
  {name = "Murloc Warrior", method = "Butin", provenance = "ForeverDB.net"},
  {name = "Blindlight Oracle", method = "Butin", provenance = "ForeverDB.net"},
 },
 [783] = {
  {name = "Deviate Crocolisk", creatureID = 5053, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 13.6, observations = 22, context = "Crag of the Everliving, Wailing Caverns; Screaming Gully, Wailing Caverns"},
  {name = "Sunscale Scytheclaw", creatureID = 3256, method = "Dépeçage", provenance = "Forever Drop Rate", level = "16–18", zone = "Les Tarides", continent = "Kalimdor", observedRate = 9.4, observations = 64, context = "The Barrens; Honor's Stand, The Barrens; Raptor Grounds, The Barrens"},
  {name = "Moonrage Darksoul", creatureID = 1782, method = "Dépeçage", provenance = "Forever Drop Rate", level = "13–14", zone = "Forêt des Pins-Argentés", continent = "Royaumes de l’Est", observedRate = 8.7, observations = 23, context = "North Tide's Hollow, Silverpine Forest"},
  {name = "Deviate Ravager", creatureID = 3636, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 6.9, observations = 29, context = "Wailing Caverns"},
  {name = "Goretusk", creatureID = 157, method = "Dépeçage", provenance = "Forever Drop Rate", level = "14–15", zone = "Marche de l’Ouest", continent = "Royaumes de l’Est", observedRate = 6.3, observations = 32, context = "Stendel's Pond, Westfall; The Molsen Farm, Westfall"},
  {name = "Zhevra Runner", creatureID = 3242, method = "Dépeçage", provenance = "Forever Drop Rate", level = "13–14", zone = "Les Tarides", continent = "Kalimdor", observedRate = 5.4, observations = 37, context = "The Barrens"},
 },
 [4232] = {
  {name = "Deviate Guardian", creatureID = 3637, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 8.8, observations = 34, context = "Wailing Caverns; Screaming Gully, Wailing Caverns"},
  {name = "Cave Yeti", creatureID = 2248, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 7.1, observations = 113, context = "Darrow Hill, Hillsbrad Foothills"},
  {name = "Ferocious Yeti", creatureID = 2249, method = "Dépeçage", provenance = "Forever Drop Rate", level = "31–32", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 4.3, observations = 69, context = "Darrow Hill, Hillsbrad Foothills", map = 1424, x = 0.448, y = 0.284, approximate = true, locationSource = "Questing.wiki"},
  {name = "Snapjaw", creatureID = 2408, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 4.2, observations = 24, context = "Chillwind Point, Alterac Mountains"},
  {name = "Deviate Ravager", creatureID = 3636, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Cavernes des lamentations", continent = "Kalimdor", observedRate = 3.4, observations = 29, context = "Wailing Caverns"},
  {name = "Sunscale Scytheclaw", creatureID = 3256, method = "Dépeçage", provenance = "Forever Drop Rate", level = "16–18", zone = "Les Tarides", continent = "Kalimdor", observedRate = 3.1, observations = 64, context = "The Barrens; Southern Barrens, The Barrens"},
 },
 [4235] = {
  {name = "Snapjaw", creatureID = 2408, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Montagnes d’Alterac", continent = "Royaumes de l’Est", observedRate = 4.2, observations = 24, context = "Alterac Mountains"},
  {name = "Cave Yeti", creatureID = 2248, method = "Dépeçage", provenance = "Forever Drop Rate", level = "30–31", zone = "Contreforts de Hautebrande", continent = "Royaumes de l’Est", observedRate = 1.8, observations = 113, context = "Darrow Hill, Hillsbrad Foothills"},
  {name = "Old Serra'kis", creatureID = 4830, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Profondeurs de Brassenoire", continent = "Kalimdor", observedRate = 100, observations = 1, context = "The Forgotten Pool, Blackfathom Deeps"},
  {name = "Wolf Master Nandos", creatureID = 3927, method = "Dépeçage", provenance = "Forever Drop Rate", zone = "Donjon d’Ombrecroc", continent = "Royaumes de l’Est", observedRate = 33.3, observations = 3, context = "Shadowfang Keep"},
  {name = "Lashtail Raptor", creatureID = 686, method = "Dépeçage", provenance = "Forever Drop Rate", level = "35–36", zone = "Vallée de Strangleronce", continent = "Royaumes de l’Est", observedRate = 20, observations = 5, context = "Stranglethorn Vale"},
  {name = "Nightbane Shadow Weaver", creatureID = 533, method = "Dépeçage", provenance = "Forever Drop Rate", level = "27–28", zone = "Bois de la Pénombre", continent = "Royaumes de l’Est", observedRate = 14.3, observations = 7, context = "Brightwood Grove, Duskwood"},
 },
 [6470] = {
  {name = "Deviate Ravager", creatureID = 3636, level = "18–19", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Stinglash", creatureID = 3631, level = "16", zone = "Cavernes des lamentations", portraitSource = "Zephras", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Creeper", creatureID = 3632, level = "15–16", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Guardian", creatureID = 3637, level = "18–19", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Viper", creatureID = 5755, level = "19–20", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Venomwing", creatureID = 5756, level = "20–21", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Shambler", creatureID = 5761, level = "19–20", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Slayer", creatureID = 3633, level = "16–17", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Verdan l’Éternel", creatureID = 5775, level = "21", zone = "Cavernes des lamentations", portraitSource = "Azeroth Wiki", method = "Butin", obtained = 2, observations = 24, provenance = "ForeverDB.net"},
  cavernsAccess,
 },
 [6471] = {
  {name = "Deviate Shambler", creatureID = 5761, level = "19–20", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Deviate Venomwing", creatureID = 5756, level = "20–21", zone = "Cavernes des lamentations", portraitSource = "QuestCore", method = "Butin", context = "Observé sur WoW Forever"},
  {name = "Verdan l’Éternel", creatureID = 5775, level = "21", zone = "Cavernes des lamentations", portraitSource = "Azeroth Wiki", method = "Butin", obtained = 1, observations = 24, provenance = "ForeverDB.net"},
  cavernsAccess,
 },
}
-- Zones documentées par le guide d’herboristerie Azeroth Wiki.
-- Les listes de zones ne fournissent pas un point précis pour une plante individuelle.
for continent, zones in pairs({
 ["Kalimdor"] = {"Orneval", "Les Tarides", "Sombrivage", "Feralas", "Désolace", "Azshara", "Marécage d’Âprefange", "Tanaris"},
 ["Royaumes de l’Est"] = {"Vallée de Strangleronce", "Les Paluns", "Contreforts de Hautebrande", "Marche de l’Ouest",
  "Forêt des Pins-Argentés", "Les Hinterlands", "Marais des Chagrins", "Montagnes d’Alterac", "Hautes-terres Arathies"},
}) do
 for _, zone in ipairs(zones) do
  sources[3356][#sources[3356] + 1] = {
   name = "Sang-royal", method = "Récolte", zone = zone, continent = continent,
   skill = "Herboristerie 125", provenance = "Azeroth Wiki",
  }
 end
end

-- Stocks et prix relevés chez Mahu par Warcraft Forever Wiki.
for id, price in pairs({[2320] = "10 pc", [2324] = "25 pc", [4289] = "50 pc", [4291] = "5 pa", [14341] = "50 pa"}) do
 sources[id] = {{
  name = "Mahu", creatureID = 3005, method = "Achat", level = 30, continent = "Kalimdor",
  zone = "Les Pitons-du-Tonnerre", map = 1456, x = 0.4365, y = 0.448, approximate = true,
  shop = price.." (relevé)", locationSource = "Warcraft Forever Wiki", provenance = "Warcraft Forever Wiki",
 }}
end

-- https://foreverdb.net/fr/item/8343
sources[8343] = {
 {name = "Lorelae Wintersong", method = "Achat", zone = "Reflet-de-Lune", continent = "Kalimdor",
  shop = "20 pa (relevé)", provenance = "ForeverDB.net"},
}
-- https://forever-tavern.com/items/12810-enchanted-leather/
-- https://wow-forever.gg/db/spells/17181-enchanted-leather/
sources[12810] = {
 {name = "Cuir enchanté", method = "Fabrication", skill = "Enchantement",
  context = "1 cuir robuste et 1 essence éternelle inférieure", provenance = "WoW Forever Tavern / wow-forever.gg"},
}

local componentGroups = {
 {name = "Cuirs et peaux", icon = 2318, items = {2934, 2318, 2319, 4234, 4304, 8170, 783, 4232, 4235, 8169, 4231, 4233, 4236, 5082, 249427}},
 {name = "Écailles", icon = 6470, items = {6470, 6471, 5784, 7286}},
 {name = "Fils et fournitures", icon = 2321, items = {2320, 2321, 4291, 14341, 14048}},
 {name = "Teintures et colorants", icon = 4340, items = {4340, 2324, 249409}},
 {name = "Plantes et végétaux", icon = 3356, items = {3356}},
 {name = "Réactifs et huiles", icon = 4289, items = {4289, 249410, 8150, 13423, 3824}},
 {name = "Composants spéciaux", icon = 2458, items = {2458, 5498, 1210, 18240}},
 {name = "Autres matériaux de recettes", icon = 2313, items = {2312, 2313, 4246, 4243, 4470}},
}

addon.componentSources = sources
addon.componentGroups = componentGroups

-- Ingredient lists documented for Forever. The client takes precedence when it supplies the recipe.
-- https://www.warcraftforever.wiki/wiki/Leatherworking/Recipes
addon.documentedRecipes = {
 {output = 6468, name = "Ceinture en écailles de déviant", inputs = {{6471, 10}, {6470, 10}, {2321, 2}}},
 {output = 2313, name = "Renfort d’armure moyen", inputs = {{2319, 4}, {2320, 1}}},
 {output = 4243, name = "Tunique en cuir fin", inputs = {{4231, 3}, {2318, 6}, {2320, 4}}},
}
