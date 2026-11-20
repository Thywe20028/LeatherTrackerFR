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
