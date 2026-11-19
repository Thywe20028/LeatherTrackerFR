# LeatherTracker FR

**French-language Leatherworking assistant for WoW Forever 1.60.1**  
**Status:** experimental v0.1.1 on `develop` (not yet validated in-game). `main` remains v0.1.0.

## Goals

Track recipe ingredients and inventory, find verified skinning/loot/vendor sources, and eventually show gathering locations on the MelloUI map with optional Auctionator prices.

## Current status

- `/ltfr api`: reports available client functions and integrations.
- `/ltfr scan`: experimental; tries reading selection from the professions UI and falls back to the selected-recipe API if available. **Needs testing on WoW Forever**.\n- `/ltfr debug`: reports professions frame and recipe-selection state.\n- `/ltfr id NUMBER`: manually reads a known recipe ID to isolate selection issues.\n- `/ltfr refresh`: refreshes the last recipe and inventory counts.
- `GetRecipeInfo` and `GetRecipeSchematic` were reported available in an in-game diagnostic, but end-to-end reading is **not yet confirmed**.
- No gathering markers, skinning rates, routing, or auction prices are implemented.

## Installation

Copy `addon/LeatherTrackerFR.toc` and `addon/Main.lua` into `Interface/AddOns/LeatherTrackerFR/` in your WoW Forever installation. Then enable the addon. See [French user guide](docs/Guide_utilisateur_v0.2.docx).

## Documentation

- [Cahier des charges v0.4](docs/Cahier_des_charges_v0.4.docx)
- [Guide utilisateur v0.2](docs/Guide_utilisateur_v0.2.docx)
- [Changelog](CHANGELOG.md)

## Planned data sources

- Warcraft Forever: https://warcraftforever.com/developers/data/
- ForeverDB: https://foreverdb.net/developers

Integration is **planned**, not yet implemented or approved. Data will be checked for provenance, license/usage terms, and version, and prepared offline. **Never commit API keys.** If ForeverDB data is used, attribution will be displayed according to its applicable terms.

## Development

The next milestone is to validate the v0.1.1 experimental reader in-game, adjust client-specific selection and reagent structures, then test accurate missing-item counts. This is **not** a finished release.

No license has been selected yet; do not assume permission to redistribute code or third-party datasets.
