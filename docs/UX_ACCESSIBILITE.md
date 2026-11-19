# UX et accessibilité — LeatherTracker FR

Statut : **exigences produit**, pas fonctionnalités déjà livrées.

## Principe

Les commandes `/ltfr` restent utiles aux développeurs, mais l'usage normal doit être possible **sans saisir de commande**.

## Interface métier

- Ajouter un panneau LeatherTracker accessible depuis la fenêtre native Travail du cuir / Professions, sans masquer les commandes existantes.
- Afficher automatiquement la recette actuellement sélectionnée et actualiser le panneau au changement de recette.
- Prévoir un bouton pour afficher/masquer le panneau et mémoriser ce choix localement.
- Montrer nom de recette, icônes et noms localisés des composants, quantités nécessaires, possédées et manquantes.
- Indiquer explicitement « donnée indisponible » plutôt que remplacer une valeur inconnue par zéro.
- À terme : provenance des matériaux, conditions de dépeçage, coordonnées vérifiées et navigation MelloUI, puis prix Auctionator.
- Éviter les superpositions avec l'interface de base et les autres addons ; contrôler l'échelle et la position.

## Accessibilité

- Taille de texte lisible, contraste suffisant, information jamais communiquée uniquement par couleur.
- Zones cliquables assez grandes et intitulés explicites.
- Navigation clavier lorsque les widgets WoW utilisés le permettent ; ne pas prétendre à une compatibilité clavier sans test.
- Messages d'erreur compréhensibles, sans jargon API.
- Aucun panneau imposé en permanence ; contrôle utilisateur.

## Étapes

1. **0.1.x** : fiabiliser noms des composants, comptage des sacs et changements de recette.
2. **0.2.x** : prototype de panneau métier à la souris ; tester l'intégration avec WoW Forever et les autres addons.
3. **Versions suivantes** : sources et navigation vérifiées, prix, préférences et tests d'accessibilité.

## Validation

Tester à plusieurs résolutions et échelles UI, avec et sans MelloUI / Auctionator, en vérifiant que le panneau ne bloque jamais la fabrication native.
