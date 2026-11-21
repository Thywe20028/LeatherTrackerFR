# Identité graphique LeatherTracker FR

| Textures | Dimensions stockées | Usage |
| --- | --- | --- |
| `Logo.tga` | 64 × 64 | Onglet LeatherTracker et portrait du panneau |
| `Sources`, `Collecte`, `Fabrication`, `Options` | 32 × 32 | Navigation avec libellés conservés, affichage à 16 px |
| `Gauche`, `Droite` | 32 × 32 | Navigation des composants Sources |
| `Plus`, `Moins` | 32 × 32 | Bandeaux repliables |
| Autres textures `Media/*.tga` | 32 × 32 | Kit graphique issu des planches validées, disponible pour les prochains usages |

Les planches ont été découpées et redimensionnées individuellement. Les fonds extérieurs et les halos hors cadre ont été retirés. Les textures utilisent des TGA RGBA 32 bits et des dimensions en puissance de deux. Une texture 32 px peut être affichée à 24 px sans enregistrer un fichier TGA de largeur 24 px. Les matériaux, sorts et butins utilisent les icônes du client.

Vérifications locales : lecture des 28 textures, dimensions et présence d’alpha transparent. En jeu : contrôler à plusieurs échelles la lisibilité, les marges, le survol, les flèches et les boutons. L’affichage dans WoW Forever reste à confirmer.

[Contraintes TGA du client](https://warcraft.wiki.gg/wiki/TGA_files)
