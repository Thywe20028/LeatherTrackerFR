# LeatherTracker FR et les calques de MelloUI 2.1.60

## Référence vérifiée

Le ZIP MelloUI fourni indique 2.1.60 pour le cœur et le module Carte. Les fichiers officiels de la branche main, téléchargés le 19 novembre 2026, correspondent au ZIP pour Map.lua, MapQuestLog.lua, MapAddonPins.lua et MelloUI_Map.toc, après normalisation des fins de ligne. La version effectivement chargée sur le poste du joueur reste à relever avec `/ltmapdebug`.

| Besoin | Code vérifié |
|---|---|
| Groupes natifs | Map.lua, tables locales GROUPS et SWITCHES. Build transmet les groupes à QuestLog.Layers. |
| Panneau et cases | MapQuestLog.lua, LayersPage. Le pager, les titres et les cases sont créés avec les widgets MelloUI. |
| Persistance native | Map.lua, LayerOn et SetLayer lisent ou écrivent M.db.layers. |
| HandyNotes | Map.lua ajoute les lignes de MapTownMarks.KINDS au groupe 5. MapQuestLog.Missing les grise si le plugin ou son intégration est indisponible. |
| Actualisation | Log.Layers reçoit la définition. LayersPage crée les lignes une seule fois, Log.LayersChanged rafraîchit les interrupteurs déjà créés. |
| Ouverture | Map.lua, OpenLayers sur le module retourné par MelloUI:GetModule("Map"). |
| Marqueurs | MapAddonPins.lua expose AddPin, ClearPin, ClearPins, OnViewChanged, IsShown et Show sur MelloUI.Map. Ces méthodes n’étendent pas le panneau. |

[Source officielle MelloUI](https://github.com/MelloCro/MelloUI/tree/main/MelloUI_Map)

## Intégration proposée

MelloUI 2.1.60 d’origine n’expose aucune API d’ajout de groupe. Le [patch de revue](PROPOSITION_MELLOUI_2.1.60.patch), accompagné de la [licence MIT de MelloUI](MELLOUI_LICENSE.txt), est une proposition côté MelloUI, à examiner par son mainteneur. Il passe par les widgets natifs et insère les quatre interrupteurs entre Quêtes et Voyage, en conservant les fonctions natives de lecture et d’écriture pour les autres groupes. Il ajoute un retour d’état du groupe et un comptage des marqueurs rendus. L’archive ordinaire de LeatherTracker installe uniquement LeatherTracker. Les anciens ponts reconnus continuent à recevoir les quatre lignes, avec des diagnostics de rendu limités.

Les quatre cases sont enregistrées dans LeatherTrackerFRDB. Elles filtrent les repères sélectionnés en mode manuel ou calculés en mode automatique. Avec la proposition, un enregistrement après la création du panneau sans la section est refusé pour la session. L’enregistrement normal a lieu au chargement de LeatherTracker.

## Diagnostic et validation

`/ltmapdebug` affiche les modules et versions, la présence de l’API, le résultat d’enregistrement, les préférences et les compteurs. Sur une installation officielle 2.1.60, l’API de catégorie est absente. Un pont qui reçoit les lignes ne prouve pas leur rendu. La proposition compte séparément les cases créées et les marqueurs rendus par MelloUI.

Tests réalisés en local : comparaison ZIP et dépôt officiel, application du patch à une copie de référence, compilation Lua, simulations du filtrage, du rechargement des préférences et des diagnostics.

Validation dans le client WoW à effectuer sur une version MelloUI intégrant la proposition :

1. Relever les versions avec `/ltmapdebug`, ouvrir Carte → Calques et vérifier le groupe entre Quêtes et Voyage.
2. En mode automatique, cocher puis décocher chaque interrupteur. Vérifier les repères de marchand, de créature et les autres sources disponibles, puis la case générale.
3. Fermer et rouvrir la carte. Faire `/reload`, revenir dans Calques et vérifier les quatre états.
4. Basculer des calques natifs, dont Quêtes, Voyage et HandyNotes si ce dernier est présent.
5. Relancer `/ltmapdebug` avec Calques ouvert et comparer la sortie à la carte affichée.
