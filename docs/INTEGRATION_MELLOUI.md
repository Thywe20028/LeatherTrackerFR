# Intégration des calques MelloUI — LeatherTracker FR

Statut : **spécification**, aucune intégration de calque réalisée ni validée en jeu.

## Constat visuel (captures utilisateur, 2026-11-19)

La carte MelloUI affiche un panneau latéral « Calques de la carte » avec des catégories et des cases à cocher (quêtes, voyage, niveaux, personnes et autres). Une option « Repères des autres add-ons » est visible. La mini-carte propose également un panneau « Services » et une liste « Extensions ».

## Objectif

Ajouter une catégorie « RÉCOLTE ET ARTISANAT » au panneau de calques, avec :
- Matériaux de la recette suivie ;
- Créatures à dépecer ;
- Marchands de composants ;
- Parcours de récolte (phase ultérieure).

Chaque calque doit pouvoir être activé/désactivé séparément, sans modifier les réglages des autres extensions. L'utilisateur doit pouvoir masquer tous les repères LeatherTracker.

## Comportement attendu

1. Depuis la fenêtre de métier, l'utilisateur choisit une recette et ouvre le panneau LeatherTracker sans commande chat.
2. L'addon détermine les composants manquants **uniquement lorsque l'inventaire est confirmé**.
3. Les repères sont filtrés par matériau, source et zone. Ne jamais inventer de position, niveau, taux de butin ou compétence requise.
4. Une infobulle précise la source, le composant et la provenance des données.
5. Si les données de localisation manquent, indiquer « Emplacement non vérifié » plutôt qu'afficher un repère fictif.
6. Le calque doit rester indépendant des repères des autres addons.

## Vérifications techniques avant codage

- Confirmer dans le code de MelloUI la méthode officielle d'enregistrement d'un calque dans le panneau « Calques de la carte » ; la disponibilité de `MelloUI.Map:AddPin` **ne prouve pas** l'existence d'une API d'enregistrement de catégorie.
- Confirmer la gestion des coordonnées, des identifiants de cartes, des marqueurs, des clics et de la suppression des repères.
- Vérifier le comportement de l'option « Repères des autres add-ons » et la compatibilité HandyNotes.
- Vérifier le chargement facultatif de MelloUI, la persistance des préférences et l'absence de conflits.
- Tester l'affichage sur la carte du monde et la mini-carte, à plusieurs échelles.

## Ordre de développement

1. Fiabiliser noms d'objets et comptage des sacs.
2. Intégrer le panneau à la fenêtre de métier.
3. Valider une première source de localisation avec données vérifiables.
4. Afficher un repère test sur MelloUI.
5. Intégrer les options de calque, uniquement après confirmation de l'API.
6. Ajouter filtres, infobulles et éventuellement parcours.

Les captures ne permettent pas de confirmer une API MelloUI pour ajouter une catégorie de calque. Cette fonctionnalité reste donc à investiguer.

## Décision produit — deux modes de ressources (2026-11-19)

### Mode « Ressources de base »
- Disponible sans recette suivie, lorsque le calque LeatherTracker est activé.
- Affichage automatique **filtré** des sources vérifiées de matériaux courants du Travail du cuir : cuirs (léger, moyen, lourd, épais, robuste), peaux et autres ressources confirmées dans la base de données du client.
- Filtres par famille de matériau, zone et éventuellement niveau de créature / compétence de dépeçage lorsque vérifiés.
- Ne pas confondre « automatique » et « tout afficher partout » : limiter le nombre de marqueurs, regrouper ceux qui se chevauchent et respecter les préférences utilisateur.
- Les noms exacts, les objets existants et leurs sources doivent être validés dans les données WoW Forever avant publication.

### Mode « Suivre cette recette »
- Action explicite depuis la fenêtre du métier ; aucune recette n'est suivie automatiquement.
- Afficher en priorité les sources vérifiées des composants de la recette suivie et, si demandé, les marchands correspondants.
- Option « Matériaux manquants uniquement » ; si le nombre possédé est inconnu, afficher un état inconnu plutôt que zéro.
- Masquer temporairement les ressources de base sans rapport avec la recette pour réduire l'encombrement, avec possibilité de les réactiver.
- Exemple de test : recette 7955 « Ceinture en écailles de déviant », composants observés #6471 ×10, #6470 ×10, #2321 ×2 ; noms et inventaire encore à fiabiliser.

### Comportements communs
- Deux options indépendantes dans les calques : « Ressources de base » et « Recette suivie ».
- Activer/désactiver sans perturber les repères d'autres addons.
- Afficher uniquement des emplacements et marchands documentés ; aucune position ou disponibilité inventée.
- Ces deux modes sont **spécifiés, pas encore implémentés**.
