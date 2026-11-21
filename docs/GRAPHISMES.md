# Identité graphique LeatherTracker FR

Les textures sont extraites de la planche peinte validée. Le nettoyage conserve la forme principale, retire les pixels de fond et les halos isolés, puis adoucit d’un pixel la transition de l’alpha avant le redimensionnement. Chaque texture est carrée, avec le symbole centré et des marges régulières.

| Textures dans `addon/Media/` | Fichier | Usage |
| --- | --- | --- |
| Logo | `Logo.tga` | Onglet et en-tête LeatherTracker |
| Navigation | `Collecte.tga`, `Sources.tga`, `Fabrication.tga`, `Options.tga` | À côté des libellés des onglets. Texte seul si la barre est étroite. |
| Repères | `Recherche.tga`, `Filtre.tga`, `Recettes.tga`, `Suivi.tga` | Champs de recherche, titre des filtres, bandeau recettes, bouton Mes suivis |
| Actions | `Gauche.tga`, `Droite.tga`, `Plus.tga`, `Moins.tga` | Navigation, replis et modification de la collecte |
| Variantes de la planche | `Patron.tga`, `Peau.tga`, `FilAiguille.tga` | Extraites, disponibles dans le kit. |

Le logo est stocké en 64 × 64 et les autres textures en 32 × 32, au format TGA RGBA 32 bits. Les tailles 16, 24 et 32 px ont été contrôlées dans une planche sur fond sombre. Les composants, objets et recettes conservent leurs icônes de jeu quand elles existent.

Les tests Lua couvrent notamment les actions de collecte, les flèches de navigation, la sélection d’une recette et le repli des filtres. Le rendu aux différentes échelles reste à vérifier dans WoW Forever. [Contraintes des textures TGA](https://warcraft.wiki.gg/wiki/TGA_files)
