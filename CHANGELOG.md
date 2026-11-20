## 0.7.43

- Scinde le rafraîchissement de Ma collecte pour respecter la limite de variables externes par fonction du client WoW.

## 0.7.42

- Enregistre /ltpanel et /ltfr au chargement du fichier principal. La commande indique les problèmes de chargement ou d’initialisation de Ma collecte dans le chat.

## 0.7.41

- Permet d’ouvrir Ma collecte pendant une transition de la fenêtre Métiers et signale les erreurs d’ouverture dans le chat.

## 0.7.40

- Affiche dans /ltstatus la version déclarée par l’addon chargé.

## 0.7.39

- Présente les recettes en lignes compactes avec icône et statut d’apprentissage.
- Dimensionne chaque fiche Sources selon son contenu et remplace les fonds répétés par des séparateurs.
- Réutilise les textures Warcraft pour le repli des bandeaux et la sélection dans Sources.

## 0.7.38

- Harmonise les bandeaux du catalogue, des filtres, des recettes et des options dans la fenêtre Métiers.
- Aligne le catalogue et les filtres sur une grille approximative 30/70. Les groupes Méthodes et Continents et zones se replient indépendamment.
- Mémorise les replis du catalogue, de chaque fiche Sources et des réglages avancés de la carte.

## 0.7.37

- Remplace les flèches typographiques par des textures, simplifie le sélecteur Mes suivis et distingue les composants non suivis.
- Ajoute les recettes retournées par le client, leurs ingrédients et un raccourci vers Fabrication pour les recettes apprises lorsque le client le propose.
- Sépare les filtres Méthode et Localisation, réduit les portraits et déplace la copie du lien ForeverDB dans Détails.
- Réserve la mention « corps dépecés » à la méthode Dépeçage. Les chiffres importés conservent leur provenance.
- Clarifie les options avec des explications au survol et des réglages de carte repliables.

## 0.7.36

- Revoit la grille des onglets et mémorise le composant, son filtre géographique, sa recherche, son défilement et le tri de Sources.
- Affiche les objectifs incomplets en premier et propose de masquer les objectifs terminés dans Ma collecte.
- Raccourcit les fiches Sources, déporte les détails au survol et permet d’ouvrir une zone documentée sans ajouter de repère.
- Regroupe les Options, avec cases à cocher, sélection directe du mode carte et commande d’enregistrement local.
- Ajuste les quantités du suivi compact et indique le statut inconnu dans l’infobulle des ennemis non documentés.

## 0.7.35

- Exclut la fouille déjà ouverte et les fenêtres de récupération ambiguës du relevé de dépeçage.
- Conserve les nouveaux échantillons par niveau de créature en plus du total historique.
- Ajoute `/ltskindebug` et actualise la fiche Sources ouverte si le relevé la concerne.

## 0.7.34

- Affiche le seuil natif ou la plus basse compétence relevée lors d’un dépeçage réussi, avec un libellé explicite.
- Précise que les taux personnels portent sur les fenêtres de dépeçage attribuées au bon corps.
- Documente les prochaines étapes de l’apprentissage local.

## 0.7.33

- Ajoute un accès direct aux fiches Sources depuis le catalogue et un filtre Mes dépeçages pour les relevés personnels.

## 0.7.32

- Enregistre les fréquences de butin observées par espèce après un dépeçage réussi et identifié. Les taux personnels sont visibles dans Sources.

## 0.7.31

- Confirme le dépeçage par un sort réussi associé au butin du cadavre, et mémorise la moyenne des compétences observées par créature et niveau.

## 0.7.30

- Mémorise les confirmations de dépeçage fournies par les données natives de l’infobulle, avec le seuil exact par niveau lorsqu’il est disponible.

## 0.7.29

- Affiche « Non dépeçable » pour le Venimeux des mousses profondes et pour les humanoïdes et élémentaires ennemis, sauf indication contraire du jeu ou des relevés de dépeçage.

## 0.7.28

- Affiche une estimation du seuil standard de dépeçage pour les créatures confirmées, avec priorité aux données du jeu.

## 0.7.27

- Affiche les lignes de dépeçage uniquement pour les créatures confirmées comme dépeçables.

## 0.7.26

- Ajoute trois objets dont le butin sur le Venimeux des mousses profondes est observé sur Forever.

## 0.7.25

- Infobulle de créature compacte avec le statut de dépeçage, le seuil du client et les icônes des objets observés sur Forever.

## 0.7.24

- Réutilise les lignes du catalogue lors des changements de collecte et regroupe les réponses de chargement des objets.
- Actualise les cases MelloUI uniquement si leur état ou leur interface change.

## 0.7.23

- Protège les contrôles de quantité quand une ligne est retirée ou réutilisée.
- Filtres des repères dans Options, avec repère natif depuis une fiche si MelloUI est absent ou refuse le point.

## 0.7.22

- Diagnostic /ltmapdebug, ouverture des calques par le module Carte et quatre filtres de collecte persistants pour les ponts compatibles.
- Proposition de patch MelloUI 2.1.60 séparée de l’archive installable.

## 0.7.21

- Navigation entre composants suivis depuis Sources, avec flèches, liste déroulante et indicateur de position.
- La fiche mémorisée se retrouve dans Sources et les filtres se réinitialisent au changement de composant.

## 0.7.20

- Les cases par composant affichent les repères en mode manuel et mémorisent la sélection. Les fiches peuvent localiser un composant hors collecte.
- Le correctif MelloUI projette les repères LeatherTracker sur les cartes de ville compatibles.
- Les fiches des peaux traitées détaillent leurs ingrédients et leur apprentissage documenté.

## 0.7.19

- Correctif MelloUI 2.1.60 livré avec l’addon. La section LeatherTracker apparaît sous Quêtes dans le menu natif des calques après installation du correctif.
- Deux pistes Classic documentées séparément pour la peau épaisse et le tanin ogre.

## 0.7.18

- Audit reproductible des sources du catalogue, composant par composant.
- Six fiches alimentées à partir des observations et données disponibles pour Forever.

## 0.7.17

- Sources complétées pour le sang-royal, les fournitures de Mahu et des composants fabriqués.

## 0.7.16

- Trois onglets dans la fenêtre des métiers : Sources, Ma collecte et Options.
- Fiches Sources en grille adaptative, recherche et tri par nom ou taux observé.

## 0.7.15

- Fiches Sources en deux colonnes avec filtres par lieu, détail et états explicites de localisation.

## 0.7.13

- Niveaux des créatures sources des écailles de déviant, nouvelles fiches de composants et distinction entre butin, dépeçage et fabrication.

## 0.7.12

- Catalogue latéral de composants avec recherche, catégories dépliables, icônes natives et suivi direct.

## 0.7.10

- Sources de la bobine regroupées par continent et par zone, avec 17 vendeurs documentés.
- Indication de chargement des modèles de PNJ.
- Accès direct à la section LeatherTracker via le correctif MelloUI Map 2.1.60.

## 0.7.9

- Positions, identifiants et niveaux des trois vendeurs de fil recoupés avec HandyNotes : PNJ (Forever) 0.7.0.

## 0.7.6

- Encadrés de fréquence observée et modèles natifs pour les trois vendeurs de fil.

## 0.7.5

- Les neuf créatures référencées pour les écailles ont désormais un aperçu natif associé à leur identifiant de PNJ.

## 0.7.4

- Page Options intégrée avec retour à la collecte ou à la source d’origine.
- Réglages persistants du suivi compact, verrouillage et notification d’objectif.
- En-tête Sources compact avec icône, provenance et mise en évidence du repère sélectionné.

## 0.7.3

- Version dans le titre et panneau Options interne avec diagnostic MelloUI.
- Accès vérifié en tête de fiche, boutons de carte masqués pour les sources non cartographiables et modèles natifs pour les créatures identifiées.
- Taux observés des deux écailles sur Verdan, avec les effectifs ForeverDB.

## 0.7.2

- Le menu Options indique si MelloUI expose le calque dédié ou le calque commun.

## 0.7.1

- Fiches des écailles limitées aux observations de butin Forever et au repère documenté de l’accès des Cavernes.
- Repères MelloUI visibles sans seuil de zoom, avec installateur Windows pour le calque dédié.

# Changelog

## v0.7.0 — ForeverDB et calque dédié

- Lecture facultative des observations locales ForeverDB et affichage des fréquences avec leur échantillon.
- Capture HTTP d’objets, de marchands ou de zones de dépeçage, puis export Lua de fiches relues.
- Correctif MelloUI facultatif pour le calque Suivi de collecte sous Quêtes.

## v0.6.7 — accès aux Cavernes des lamentations

- Les fiches des deux écailles proposent un repère d’accès documenté, partagé quand les deux composants sont suivis.
- L’infobulle indique les composants associés au même repère.

## v0.6.6 — barre Options et repères marchands

- La barre de suivi dégage le portrait et regroupe les réglages de carte sous Options.
- Les fiches de Ranik et Vizzklick proposent chacune un repère sourcé pour la Bobine de fil raffiné.

## v0.6.5 — chargement de Ma collecte

- Correction des clés de catégories accentuées pour les interpréteurs Lua qui les refusent comme identifiants.

## v0.6.4 — navigation native

- Retrait du catalogue fusionné et de la commande historique qui permettait encore de l’ouvrir. LeatherTracker ouvre Ma collecte.

## v0.6.3 — suivi compact et carte

- Contrôle rond et état de réduction sauvegardé. Réglage du suivi dans la barre supérieure de Métiers.
- Fiches individuelles d’obtention et repères MelloUI via son API lorsque disponible.
- Modes Manuel, Automatique et Désactivé avec filtres de collecte et infobulles.

## v0.6.2 — commandes natives et premières sources

- Boutons d’ingrédients à deux états dans la marge disponible.
- Titre et portrait dédiés à la collecte, sans modifier ceux des métiers.
- Liste et panneau compact allégés, retrait annulable et premières sources ForeverDB.net.
- Repère marchand transmis à MelloUI via TomTom.

## v0.6.1 — onglet Ma collecte intégré

- Ma collecte remplace le contenu de Métiers sans ouvrir de fenêtre flottante. Le retour à Fabrication restaure l’affichage natif.

## v0.6.0 — Ma collecte

- Objectifs par identifiant d’objet et stock des sacs actualisé automatiquement.
- Boutons d’ajout dans Travail du cuir pour les emplacements à ingrédient unique.
- Panneau compact facultatif et fonctions historiques accessibles via `/ltrecipes`.

## v0.5.0 — refonte de la navigation

- Espaces Travail du cuir et Dépeçage, accès à la fiche native, historique, retour et fil d’Ariane.
- Cartes de suivi avec progression, synthèse des besoins, sections Matériaux, Sources et Carte.

## v0.4.8 — lisibilité de Métiers

- Le catalogue et les recettes suivies sont dans une colonne séparée de la fiche de fabrication.
- Les matériaux affichent le stock, les besoins et les manquants à droite de leur nom.

## v0.4.7 — Travail du cuir et Dépeçage

- Les deux catalogues sont accessibles dans la même page Métiers.
- La recette choisie peut être fabriquée depuis la page, avec la quantité suivie.

## v0.4.6 — catalogue de recettes intégré

- L’onglet Recettes charge le catalogue du Travail du cuir au premier accès et le conserve.
- La sélection pour le suivi se fait dans LeatherTracker.

## v0.4.5 — masquage de la page métier

- La page du métier actif est masquée pendant le suivi et son opacité est restaurée à la fermeture de LeatherTracker.

## v0.4.4 — page Métiers indépendante

- La page LeatherTracker se superpose au contenu de Métiers. Un onglet de métier natif rend la main au jeu.
- Les recettes sont vérifiées par métier avant ajout et avant calcul des stocks. Les anciens suivis d’autres métiers sont ignorés.

## v0.4.3 — onglet latéral Métiers

- Le bouton utilise le modèle latéral du client et suit le dernier onglet natif visible lors du réagencement de Métiers.

## v0.4.2 — visibilité du bouton

- Le bouton reste dans la barre Métiers lorsque Fabrication est masquée et utilise une couche au-dessus des panneaux de métier.
- `/ltstatus` indique aussi si le bouton est visible.

## v0.4.1 — bouton Métiers

- Le bouton s’enregistre avant la construction du panneau et se rattache au cadre Métiers.
- Le panneau utilise des textures simples et se construit à la première ouverture.

## v0.4.0 — aperçu intégré et suivi multiple

- Panneau rattaché à Fabrication, avec les onglets Suivi, Matériaux et Sources.
- Quantité indépendante par recette, totaux regroupés par matériau et migration du suivi précédent.
- Script de lecture ForeverDB hors jeu. Catalogue de sources et repères MelloUI en attente.

## v0.3.4 — accès direct au panneau

- Le panneau se charge indépendamment du bouton de métier et s’ouvre via `/ltpanel` ou `/ltfr`, y compris lorsque la fenêtre de métier est fermée.

## v0.3.3 — panneau intégré autonome

- Suppression de la dépendance ForeverCore. Le bouton latéral LeatherTracker et `/ltpanel` ouvrent le panneau depuis Fabrication.
- Capture de la sélection au clic et fermeture du panneau au retour à Fabrication ou à la fermeture du métier.
- Les réglages et la recette suivie restent dans `LeatherTrackerFRDB`. Validation en jeu en attente.

## En développement — sélection dans l’onglet intégré

- L’aperçu est capturé dans Fabrication visible. Le formulaire masqué ne remplace plus la dernière sélection visible.
- Fermeture et changement de source détecté effacent l’aperçu. La recette suivie reste enregistrée et conserve son propre libellé.
- Test de régression reproductible avec `texlua tests/selection.lua`. Validation du nouveau code dans WoW Forever en attente.

## v0.3.1 et v0.3.2 — essais hors de l’historique Git inspecté

- 0.3.1 graphique essayée par Shana. L’interface a été jugée trop vide et la sélection restait à fiabiliser. ZIP GitHub introuvable dans les branches, tags et releases consultés le 19 novembre 2026.
- 0.3.2 autonome inspectée dans son ZIP. Le TOC ne déclare pas ForeverCore. Essais en jeu en attente.

## v0.2.3 — base de l’onglet ForeverCore

- Correction des ancrages et suppression du rappel qui forçait le retour à la page native à la fermeture.
- ForeverCore déclaré comme dépendance sur `develop`.
- Ouverture et fermeture normales de l’onglet rapportées par Shana avec ForeverCore v1.15.2. Le commit exact utilisé pour cet essai n’a pas été précisé.

## v0.2.2 — develop, non testée en jeu
- Quatre sections accessibles par boutons dans la page LeatherTracker : suivi, matériaux, sources et zones, carte MelloUI.
- Présentation des composants en lignes et comparaison des quantités avec l'inventaire quand l'API répond.
- Largeur personnalisée 850 via ForeverCore ; navigation par son véritable onglet latéral.
- Sources et carte : états vides explicites, sans créatures, taux ou coordonnées inventés.
- Contrôles de suivi, ressources de base et filtre manquants conservés.
- À vérifier en jeu : géométrie, visibilité de l'onglet, changement de page, sélection et inventaire.


## v0.2.1 — develop, non validée en jeu
- Cache de la recette sélectionnée avant de changer d'onglet ; le bouton Suivre utilise cette sélection même lorsque la page Fabrication est masquée.
- Géométrie de la page rattachée à ProfessionsFrame, réduction des coordonnées fixes.
- Actualisation des composants et diagnostic de version.
- Documentation des données indispensables pour les taux de butin, les créatures et les repères MelloUI ; aucune donnée non vérifiée ajoutée.
- À tester : affichage, retour à Fabrication, comportement de la sélection, dimensions et sauvegarde.


## v0.2.0 — develop, non validée en jeu
- Remplacement du faux onglet par une page enregistrée via `ForeverCore.ProfessionTabs.Register` (minor >= 2).
- Suppression du bouton positionné manuellement et du panneau externe.
- Ajout d'un diagnostic `/ltstatus` et navigation de secours `/ltpanel`.
- ForeverCore v1.15.2 nécessaire à l'onglet (installation distincte).
- Code basé sur les fichiers `UI/ProfessionTabs.lua` de ForeverCore et `UI/Pages.lua` de SkillUp Forever fournis par l'utilisateur.
- À tester : onglet, navigation, retour natif, comportement en combat, sélection et affichage des recettes.
- MelloUI, marchands et emplacements de récolte : non implémentés.


## v0.1.5 — develop, à tester en jeu
- Ajout d'un bouton « LeatherTracker » à la fenêtre `ProfessionsFrame`, ouvrant un panneau de détails rattaché à la fenêtre.
- Affichage des composants, des quantités et des options de suivi dans le panneau.
- Panneau masqué par défaut, état mémorisé ; commande `/ltpanel` conservée.
- Il ne s'agit **pas encore d'un véritable onglet natif** : l'API des onglets de WoW Forever reste à vérifier.
- Carte MelloUI, emplacements de récolte, marchands et ressources de base : non implémentés.
- À tester : bouton visible, chevauchement, taille de l'écran, suivi de recette et compatibilité des API.

## v0.1.4 — develop
- Remplacement du panneau flottant par une barre rattachée à la fenêtre des métiers ; non validée indépendamment en jeu.


## v0.1.3 — develop, non validée en jeu
- Utilisation prioritaire de `C_Item.GetItemInfo` avec repli sur `GetItemInfo` pour les noms des composants.
- Actualisation du diagnostic lorsque des informations d'objets deviennent disponibles.
- Protection contre les initialisations multiples du panneau, et vérification des réglages avant actualisation.
- Possibilité de remplacer une recette suivie par une autre.
- Suppression provisoire des `OptionalDeps` dans le TOC pour isoler le chargement.
- À confirmer : disponibilité de `C_Item.GetItemInfo` dans le client, exécution de `Tracking.lua`, compatibilité de l'interface et du panneau.


## v0.1.2 — develop, untested in-game
- Added `Tracking.lua`: clickable profession-window button, mouse-driven recipe follow/unfollow, missing-material and basic-resource toggles, saved preferences.
- Added a reagent summary using game item names when cached, otherwise item IDs; refreshes on bag and item-info events.
- **Not implemented:** resource locations, MelloUI markers/layer registration, merchant lookup, basic-resource item database, routes. No data locations were invented.
- **Requires testing:** profession window attachment, frame layout, selection updates, bag counts, saved settings, reagent variants.


## v0.1.1 — develop (partial in-game validation 2026-11-19)
- Confirmed selected recipe ID 7955 and name “Ceinture en écailles de déviant” from ProfessionsFrame SchematicForm.
- Confirmed three reagent slots displayed with IDs 6471 ×10, 6470 ×10, 2321 ×2.
- Added read-only selection detection, `/ltfr debug`, `/ltfr id NUMBER`, `/ltfr refresh`, scrollable diagnostics, and bag-update refresh logic.
- Known issues: item names appear as numeric IDs; inventory count accuracy is not established; other recipes and event behavior require testing.
- Added accessibility roadmap for a native profession-window panel. Not yet implemented.

## Documentation — 2026-11-19
- Updated specifications to v0.4 and user guide to v0.2.
- Documented planned Warcraft Forever and ForeverDB data integration.

## v0.1.0 — experimental prototype
- Added diagnostic window and `/ltfr api`, `/ltfr scan` commands.
- Known issue: selected-recipe API unavailable on the tested client.
