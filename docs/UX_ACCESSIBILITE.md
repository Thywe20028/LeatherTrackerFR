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

## Refonte 0.7.36

- La fenêtre Métiers garde son cadre natif. Fabrication referme le panneau et rend la main à la page métier.
- La grille vise 18 px de marge, 12 à 17 px entre colonnes, environ 32 % pour le catalogue et 27 % pour les filtres de Sources. Les cartes Sources passent à une colonne sous 470 unités utiles. Les coordonnées et la provenance détaillée sont accessibles via Détails.
- Ma collecte conserve les objectifs et affiche les incomplets en premier. Le réglage de masquage agit sur la liste des objectifs. La carte et le suivi compact ont leurs propres commandes.
- Sources mémorise le dernier composant consulté, le tri et les filtres par composant. Les positions de défilement sont enregistrées en quittant la vue ou au rechargement. Voir la zone utilise un identifiant documenté et ne crée aucun repère.
- Options sépare Suivi compact, Collecte, Carte, Apprentissage et Informations. L’interrupteur d’apprentissage agit sur les futures observations locales et conserve l’historique. Le diagnostic affiché est celui de la session.

### Validation en jeu

- Vérifier à plusieurs échelles UI la barre supérieure, les noms longs, les boutons de chaque objectif et le défilement des deux colonnes.
- Réduire la largeur disponible et vérifier que Sources passe à une carte par rangée. Survoler Détails et tester un repère précis, puis une zone seule.
- Interrompre une recherche pour revenir à Ma collecte. Revenir à Sources et faire `/reload` pour vérifier la restauration des réglages et des filtres.
- Déplacer et verrouiller le suivi compact. Dépecer manuellement et vérifier que le diagnostic se met à jour sans produire de message automatique.
- Vérifier séparément la visibilité du calque dans le panneau natif MelloUI et la restauration de Fabrication.

## Ajustements 0.7.37

- **Mes suivis** liste les objectifs. **Tous les composants** ouvre le catalogue pour une consultation libre.
- **Utilisé dans les recettes** utilise les identifiants d’objets des schémas retournés par le client. La section se replie et affiche cinq recettes par page. L’état appris provient du client, lorsqu’il le fournit. Vérifier sur Forever la couverture de la liste et le passage vers [Fabrication via OpenRecipe](https://warcraft.wiki.gg/wiki/API:C_TradeSkillUI.OpenRecipe).
- Les filtres de méthode et de lieu se combinent. Les noms de zones peuvent occuper deux lignes.
- **Détails** affiche les informations secondaires au survol. Un clic sélectionne l’adresse ForeverDB pour la copier avec le raccourci du système.
- Dans **Options**, la commande des calques est visible lorsque le module de carte expose à la fois la catégorie et l’ouverture du panneau. Le diagnostic technique reste accessible via `/ltmapdebug`. La présence du calque reste à vérifier en jeu.
