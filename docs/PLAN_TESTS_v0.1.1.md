# Plan de validation — LeatherTracker FR 0.1.1

## Résultats observés le 19 novembre 2026

D'après deux captures du jeu fournies par l'utilisateur :

- `ProfessionsFrame` présent et visible ; `CraftingPage` et `SchematicForm` présents.
- `SchematicForm:GetRecipeInfo` disponible.
- `IsDataSourceChanging = false`.
- Recette sélectionnée : **7955**, « Ceinture en écailles de déviant ».
- 42 recettes filtrées.
- Trois composants affichés : `#6471 ×10`, `#6470 ×10`, `#2321 ×2`.
- Inventaire affiché : zéro pour chacun. **Aucune vérification indépendante des sacs n'a été fournie.**
- Noms d'objets non résolus (affichage `Objet #ID`).

Ces captures valident le chemin de sélection pour **cette recette et cette session uniquement**, pas l'ensemble des métiers.

## Tests restant à effectuer

1. Confirmer les noms d'objets après chargement des informations d'objets ; vérifier `GetItemInfo` et les éventuels mécanismes de cache.
2. Mettre un composant connu dans les sacs ; comparer `/ltfr scan`, `/ltfr refresh` et le comptage réel.
3. Déplacer un composant entre les sacs et vérifier l'actualisation automatique.
4. Tester plusieurs recettes et les composants facultatifs ou alternatifs.
5. Fermer le métier, changer de métier et vérifier l'absence de données périmées.
6. Vérifier l'absence d'erreurs Lua et de modifications de la sélection native.
7. Avant toute mise en production, tester l'interface intégrée au métier et sa lisibilité.

## Critères de validation

- Recette et quantités conformes au jeu.
- Noms d'objets localisés et fiables, sans invention.
- Inventaire réel et quantités manquantes corrects.
- Interface utilisable sans commande chat.
- Aucune perturbation de la fenêtre de métier.

## État

`develop` est expérimental ; ne pas fusionner dans `main` avant les tests complémentaires.
