# LeatherTracker FR

**French-language Leatherworking assistant for WoW Forever 1.60.1**  
**Status:** experimental prototype v0.1.0 — recipe selection currently fails on the tested client.

## Goals

Track recipe ingredients and inventory, find verified skinning/loot/vendor sources, and eventually show gathering locations on the MelloUI map with optional Auctionator prices.

## Current status

- `/ltfr api`: reports available client functions and integrations.
- `/ltfr scan`: experimental; **currently blocked** because `C_TradeSkillUI.GetSelectedRecipeID` is unavailable in the tested WoW Forever client.
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

The next milestone (v0.1.1) is reliable selection of a Leatherworking recipe and extraction of its required reagents, verified by in-game tests.

No license has been selected yet; do not assume permission to redistribute code or third-party datasets.
