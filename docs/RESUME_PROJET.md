# Résumé du projet

État du 19 novembre 2026. LeatherTracker FR vise à suivre les recettes et les composants du Travail du cuir dans WoW Forever 1.60.1, puis à afficher les sources vérifiées dans MelloUI.

## Historique et distribution

| Référence | Constat |
| --- | --- |
| `main` au début de l’audit | Prototype 0.1.0. [Thywe20028, 19 novembre 2026](https://github.com/Thywe20028/LeatherTrackerFR/commit/16cd7d56bfd750bc50e3ff6495461347678b08d0) |
| `develop` au début de l’audit | 0.2.3, ForeverCore déclaré comme dépendance. Point de retour pour les essais. [Thywe20028, 19 novembre 2026](https://github.com/Thywe20028/LeatherTrackerFR/commit/ba0c417d5e557ad97a7c083dc3a722b017afa1f3) |
| ZIP graphique 0.3.1 | Essai rapporté par Shana. Aucun ZIP trouvé dans l’historique accessible des branches inspectées. Les listes GitHub de tags et de releases étaient vides lors de l’audit. [Tags](https://api.github.com/repos/Thywe20028/LeatherTrackerFR/tags) · [Releases](https://api.github.com/repos/Thywe20028/LeatherTrackerFR/releases) |
| ZIP autonome 0.3.2 | Archive inspectée. Son TOC cible l’interface 16001 et ne déclare aucune dépendance. Le code présente une fenêtre autonome et son cache peut conserver une sélection précédente. La compatibilité en jeu reste à vérifier. [Archive du 19 novembre 2026](https://chatgpt.com/library?file_id=libfile_c360e58e337c8191a0c2757abf60f9f8&account_id=personal) |

## Tests en jeu rapportés

Shana confirme l’ouverture et la fermeture normales via l’onglet natif avec ForeverCore v1.15.2. Elle a essayé l’interface graphique 0.3.1, qu’elle a trouvée trop vide. La fiabilité de la sélection restait à améliorer. Source : contexte fourni par Shana le 19 novembre 2026.

Le diagnostic historique identifie la **Ceinture en écailles de déviant**, recette **7955**, et trois composants **6471 ×10**, **6470 ×10** et **2321 ×2**. L’exactitude des quantités en sac reste à vérifier. [Plan de tests v0.1.1](PLAN_TESTS_v0.1.1.md)

## Audit et contrôles reproductibles

L’ancien cache interrogeait le formulaire même quand Fabrication était masquée et pouvait conserver une sélection après fermeture. Un nom issu de l’aperçu pouvait aussi être affiché pour un autre ID suivi.

Le nouveau code lit la sélection pendant que Fabrication est visible, conserve cet aperçu pendant la navigation interne et l’efface à la fermeture ou lors d’un changement de source détecté. Le suivi enregistré conserve son propre ID. Le rappel de fermeture efface uniquement l’aperçu. ForeverCore conserve la gestion de la navigation.

`texlua tests/selection.lua` simule le changement de recette avant l’ouverture de l’onglet, la page Fabrication masquée, la fermeture et la réouverture, le repli sur `GetSelectedRecipeID`, le changement de métier et la disparition de la sélection. Le comportement lors d’un clic immédiat sur l’onglet natif, avant le prochain cycle de lecture, reste à contrôler dans le client.
