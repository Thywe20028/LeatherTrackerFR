# Catalogue Warcraft Forever

L’import ciblé utilise la bibliothèque publique Warcraft Forever, puis génère un petit catalogue Lua hors jeu. Par défaut, il demande seulement la bobine de fil raffiné et les deux écailles. Le nom issu du client reste prioritaire. Si le client n’a pas encore le nom en cache, l’addon peut utiliser le nom français du catalogue. Une réponse sans nom français reste absente du catalogue.

Depuis la racine du paquet, avec Node.js 20 et Python 3 :

```text
node --experimental-network-imports scripts/fetch_warcraft_forever.mjs warcraft-forever-items.json
python scripts/export_warcraft_forever.py warcraft-forever-items.json LeatherTrackerFR/WarcraftForeverData.lua
```

Dans le dépôt, la destination est `addon/WarcraftForeverData.lua`. Des identifiants peuvent être ajoutés après le nom du fichier JSON. La collecte en jeu fonctionne hors connexion. L’archive de cette version inclut le raccordement et les outils. Elle ne contient pas de fiches Warcraft Forever préimportées, car les réponses individuelles n’ont pas pu être récupérées depuis l’environnement de développement.

Les taux et les méthodes d’obtention restent identifiés séparément. Warcraft Forever ne publie pas de corpus de PNJ ni de butin. Les fiches des trois marchands déjà connus de LeatherTracker affichent la provenance QuestCore de leur identifiant. Le portrait en jeu est demandé au client par identifiant. Les nouvelles fiches vérifiées peuvent ajouter `creatureID` et `portraitSource` via `export_sources.py`. Aucun PNG de PNJ n’est inclus.

[Documentation Warcraft Forever](https://warcraftforever.com/developers/data/) · [Manifeste](https://warcraftforever.com/api/data/v1/manifest)
