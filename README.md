# LeatherTracker FR

Assistant de collecte pour **WoW Forever 1.60.1**, version **0.7.37**. LeatherTracker s’ouvre dans la fenêtre Métiers et conserve l’interface de fabrication de WoW.

## Installation

Copier le contenu de `addon/` dans `Interface/AddOns/LeatherTrackerFR/`, puis activer LeatherTracker FR dans le jeu. ForeverDB, MelloUI et TomTom servent d’intégrations facultatives.

## Ma collecte

- Ouvrir une recette et cliquer sur **+** à côté d’un ingrédient, ou ajouter un objet depuis le catalogue, son lien ou son identifiant.
- Ouvrir **Ma collecte** via l’icône LeatherTracker dans Métiers ou la commande `/ltpanel`. **Fabrication** permet de retrouver la recette précédente.
- Modifier un objectif avec **− / +** ou saisir la quantité et valider avec Entrée. Le stock est lu dans les sacs. Le panneau compact permet de suivre la collecte à l’écran.

## Sources et repères

Dans **Catalogue des composants**, le bouton **Sources** ouvre la fiche de l’objet directement. Le bouton **+** ajoute un objectif de collecte. Le filtre **Mes dépeçages** apparaît dans une fiche dès que tu as enregistré du butin personnel pour cet objet.

Les fiches **Sources** distinguent les marchands, la fabrication, le butin et le dépeçage. Elles donnent la provenance et la taille d’échantillon lorsqu’elles sont disponibles. L’onglet **Options** permet de filtrer les repères et de choisir le mode automatique, manuel ou désactivé. MelloUI peut afficher les repères et la carte native offre un repli par point de passage pour les cartes compatibles. Le calque MelloUI dédié reste une [intégration proposée](docs/INTEGRATION_MELLOUI.md).

## Apprentissage en jeu

- L’infobulle reconnaît les créatures dépeçables à partir des données natives et des observations. Le seuil exact fourni par le jeu a la priorité et `~` indique une estimation.
- Un dépeçage réussi rattaché à un cadavre est mémorisé par espèce. Si le seuil natif est inconnu, l’infobulle indique la plus basse compétence relevée lors d’une réussite pour cette espèce et ce niveau. Les anciens relevés restent consultables dans Sources.
- Les objets d’un butin complet et attribué au dépeçage alimentent **Mes dépeçages** dans les fiches **Sources**. Le taux compte une apparition par objet et par dépeçage. Exemple, 6 apparitions sur 40 donnent **15 % observés**. Le butin ordinaire et les sacs sont exclus.

## Vérification

Lancer `texlua tests/selection.lua` et `texlua tests/creature_tooltip.lua` depuis la racine du dépôt. Les tests simulent la collecte, les intégrations cartographiques et l’apprentissage du dépeçage. L’affichage, la détection du butin et le ramassage automatique restent à valider dans WoW Forever.

Toutes les nouveautés sont détaillées dans le [journal des versions](CHANGELOG.md).

## Connexions ForeverDB

Si l’addon ForeverDB est installé, LeatherTracker lit ses observations locales pour les objets consultés. Les fréquences sont affichées avec leur taille d’échantillon. Aucune donnée locale n’est envoyée et l’addon ne déduit pas de coordonnées d’une observation.

L’API HTTP s’utilise hors du jeu. La documentation et le crédit figurent sur [ForeverDB.net](https://foreverdb.net/developers). La clé est lue depuis `FOREVERDB_API_KEY` ou saisie sans écho. Ne pas placer de clé dans les fichiers Lua.

```powershell
py scripts/foreverdb_probe.py 6471 --output ecailles.json
py scripts/foreverdb_probe.py --vendor 12245 --output marchand.json
py scripts/foreverdb_probe.py --skinning-zone 1413 --output depecage.json
```

Examiner les réponses et conserver dans un JSON indexé par identifiant d’objet les champs confirmés. Chaque fiche requiert `name`, `method` et `provenance`. Un repère requiert `map`, `x` et `y` dans l’intervalle 0–1 pour les coordonnées, ainsi que `locationSource`. Les champs `zone`, `level`, `skill`, `rate` et `context` sont facultatifs. L’exporteur valide les champs et ouvre une étape de vérification explicite avant publication.

```powershell
py scripts/export_sources.py sources-validees.json addon/SourceData.lua
```

Copier le fichier produit dans le dossier LeatherTrackerFR de WoW. Les sources initiales restent disponibles et le fichier généré les complète.

`/ltskindebug` affiche la décision la plus récente sur l’apprentissage du dépeçage, sur demande.
