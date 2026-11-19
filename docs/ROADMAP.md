# Feuille de route

| Ordre | Étape | Critère de validation |
| --- | --- | --- |
| 1 | Sélection et navigation | Sous WoW Forever 1.60.1 avec ForeverCore v1.15.2, sélectionner A puis B et ouvrir l’onglet immédiatement. Vérifier B, le retour à Fabrication, la fermeture normale depuis les deux pages, la réouverture et le changement de métier. Tester avec SkillUp lorsqu’il est installé. |
| 2 | Suivi et quantités | Comparer les composants de la recette 7955 puis d’autres recettes avec Fabrication et les sacs. Tester les variantes, les composants facultatifs, le filtre des manquants, les mises à jour de sacs et la sauvegarde après rechargement. Ajouter le nombre de fabrications et calculer les besoins et manquants à partir de cette quantité. |
| 3 | Catalogue de base | Recenser les ingrédients par ID et nom français dans le client. Enregistrer la provenance et la version de chaque donnée. Confirmer les conditions d’utilisation avant d’importer des données externes. |
| 4 | Créatures, lieux et butin | Renseigner le type de source, le PNJ ou la créature, la zone et les coordonnées vérifiées. Documenter la source, la version et l’échantillon des taux mesurés. Afficher « inconnu » pour un taux invérifiable. |
| 5 | Marqueurs MelloUI | Valider l’API de carte dans le client, afficher les coordonnées vérifiées et tester les filtres par recette et matériaux de base, l’effacement des repères et l’absence de MelloUI. Voir [l’intégration MelloUI](INTEGRATION_MELLOUI.md). |
| 6 | Addon autonome | Évaluer le prototype 0.3.2 dans un environnement sans ForeverCore. Reprendre les tests de sélection, navigation, sauvegarde et validation des quantités avant d’intégrer cette piste sur `develop`. |

Pour chaque essai en jeu, consigner le commit ou ZIP, les versions du client et des dépendances, le scénario, le résultat et les captures disponibles.
