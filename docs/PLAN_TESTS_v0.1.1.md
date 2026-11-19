# Plan de validation — LeatherTracker FR 0.1.1

Version de travail : branche `develop`. Aucune validation en jeu n'a encore été effectuée pour cette version.

## Installation

Copier le contenu du dossier `addon/` dans `Interface/AddOns/LeatherTrackerFR/` (les fichiers `.toc` et `Main.lua` doivent se trouver directement dans ce dossier). Recharger l'interface.

## Tests à réaliser

1. Exécuter `/ltfr api` et conserver le diagnostic.
2. Ouvrir Travail du cuir, sélectionner « Ceinture en écailles de déviant », exécuter `/ltfr debug` puis `/ltfr scan`.
3. Si la sélection échoue, comparer avec `/ltfr id NUMERO` en utilisant **un identifiant de recette confirmé**, sans inventer de numéro.
4. Comparer chaque composant et quantité affichés avec la fenêtre du métier.
5. Déplacer des matériaux entre les sacs, puis contrôler `/ltfr refresh` et l'actualisation automatique.
6. Fermer le métier et changer de métier ; vérifier qu'aucune recette obsolète n'est présentée comme sélectionnée.
7. Tester l'ouverture et la fermeture de la fenêtre, le défilement et les erreurs Lua.

## Critères de validation

- Aucun blocage ou erreur Lua.
- Recette sélectionnée correctement reconnue.
- Composants, quantités et inventaire conformes au jeu.
- Aucune modification de la sélection native des métiers.

## Limitations connues

Le chemin `ProfessionsFrame.CraftingPage.SchematicForm` et les valeurs `reagentType` restent des hypothèses d'intégration à confirmer sur le client. Le code ne couvre pas encore toutes les structures alternatives de métiers. Les intégrations MelloUI, Auctionator, ForeverDB et Warcraft Forever restent prévues, non réalisées.
