# LeatherTracker FR

Assistant de Travail du cuir pour **WoW Forever 1.60.1**. La branche `develop` contient l’onglet intégré aux métiers, basé sur la version 0.2.3 et nécessitant **ForeverCore v1.15.2**.

## Installation et utilisation

1. Installez et activez ForeverCore v1.15.2.
2. Copiez les trois fichiers du dossier `addon/` dans `Interface/AddOns/LeatherTrackerFR/`, puis activez LeatherTracker FR.
3. Ouvrez Travail du cuir, sélectionnez une recette dans Fabrication, puis ouvrez l’onglet latéral LeatherTracker et cliquez sur **Suivre la recette**. Le suivi reste enregistré jusqu’à son arrêt. Pour en choisir une autre, arrêtez le suivi en cours, puis sélectionnez la nouvelle recette dans Fabrication.

La page propose quatre sections. Suivi et Matériaux affichent les quantités par fabrication et les quantités en sac lorsque le client les fournit. Sources et Carte indiquent l’état des données et de l’intégration. Les variantes de composants, les quantités pour plusieurs fabrications, le catalogue de base et les marqueurs MelloUI figurent dans la [feuille de route](docs/ROADMAP.md).

`/ltstatus` indique si l’onglet est enregistré. `/ltpanel` permet de basculer entre LeatherTracker et Fabrication. `/ltfr debug` et `/ltfr scan` aident à examiner la sélection native.

## État des vérifications

- **En jeu, rapporté par Shana** — l’onglet natif s’ouvre et se ferme normalement avec ForeverCore v1.15.2. La version graphique 0.3.1 a été essayée, jugée trop vide, et la sélection restait à fiabiliser.
- **Reproductible hors jeu** — depuis la racine, lancez `texlua tests/selection.lua` pour exercer la sélection avec des API simulées. Le [résumé](docs/RESUME_PROJET.md) détaille les scénarios et l’état de GitHub.
- **À vérifier en jeu sur le nouveau code** — navigation native, sélection rapide, changement de métier, quantités en sac et persistance. Voir la [feuille de route](docs/ROADMAP.md).

[Changelog](CHANGELOG.md) · [Résumé du projet](docs/RESUME_PROJET.md) · [Feuille de route](docs/ROADMAP.md) · [Intégration MelloUI](docs/INTEGRATION_MELLOUI.md)
