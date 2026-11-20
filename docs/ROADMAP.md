# LeatherTracker FR — feuille de route

Cible : WoW Forever 1.60.1. L’interface de fabrication reste native. LeatherTracker suit des composants choisis dans les recettes ou ajoutés manuellement. Il affiche **Ma collecte** dans la fenêtre Métiers.

## État de la version 0.7.32

- Collecte intégrée à Métiers, catalogue, liste d’objectifs et suivi compact.
- Fiches Sources avec provenance, échantillons et repères par type de source.
- Infobulles de dépeçage avec seuil exact ou estimé et icônes de butin.
- Apprentissage local à partir du tooltip natif et des dépeçages réussis. Fréquences personnelles d’obtention par espèce.
- Intégrations facultatives ForeverDB, MelloUI et TomTom. Repli par point de passage sur la carte native compatible.
- Tests Lua de collecte, de cartographie et d’apprentissage.

## À vérifier dans WoW Forever

- [ ] Vérifier le retour aux onglets natifs, le placement des contrôles à différentes échelles et la conservation des objectifs après mise à jour.
- [ ] Depuis les deux fiches d’écailles, ouvrir l’accès aux Cavernes sur MelloUI. Activer les deux composants en mode automatique et vérifier le repère commun et son infobulle.
- [ ] Vérifier le masquage des objectifs atteints et le retrait des seuls repères LeatherTracker lorsque la carte est désactivée.

## Données et calques

- [ ] Valider les positions de créatures, les seuils de dépeçage et les taux Forever avant de les afficher. Le point des Cavernes est un accès au donjon.
- [ ] Vérifier en jeu le calque proposé **LeatherTracker FR** sous **Quêtes**. Sans le correctif, les repères restent dans le calque commun des autres addons.
- [ ] Exécuter une requête authentifiée et examiner la réponse réelle avant d’automatiser la transformation du schéma ForeverDB.

[Accès aux Cavernes — Questing.wiki](https://questing.wiki/wow-forever/dungeons/wailing-caverns/) · [API cartographique MelloUI](https://github.com/MelloCro/MelloUI/blob/8fe0da73b0d56030bf5a7ed587b173eed19d1f38/MelloUI_Map/MapAddonPins.lua#L1276)

## Apprentissage local

- Dépeçage manuel. Associer le sort réussi au GUID du corps et compter une occurrence par objet et par fenêtre complète. Ignorer les sacs, le butin ordinaire et les fenêtres ambiguës.
- Compétence. Afficher le seuil exact seulement si le client le fournit. Conserver la plus basse compétence observée lors d'une réussite pour la même espèce et le même niveau. Les anciens agrégats ne permettent pas de retrouver cette valeur.
- Sources. Présenter clairement les relevés personnels et leur échantillon. Vérifier en jeu l'ordre des événements, les cas sans objet identifiable et la persistance après `/reload`.
- Étape suivante. Étudier la lecture de l'inventaire des marchands sur Forever, un diagnostic dans Options et la mémorisation des zones observées. Vérifier séparément les repères et les cases à cocher du panneau MelloUI.
- Performances. Rafraîchir les vues ouvertes à la demande et vérifier les FPS après avoir vidé puis rempli Ma collecte.

Références de conception

- [AzerDex — Collecte et publication des observations WoW Forever](https://azerdex.com/about/data)
- [GatherMate2 — Mémorisation des lieux de collecte](https://www.curseforge.com/wow/addons/gathermate2)
- [Questie — Carte et suivi des objectifs](https://github.com/Questie/Questie)
- [Jakob Nielsen, 2006 — Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)
