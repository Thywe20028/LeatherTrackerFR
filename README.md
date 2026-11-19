# LeatherTracker FR

**French-language Leatherworking assistant for WoW Forever 1.60.1**  
**Status:** experimental v0.1.2 on `develop` (new UI **not yet tested in-game**); `main` remains v0.1.0.

## Goals

Help players read crafting recipes, compare ingredients with bag contents, find verified skinning/loot/vendor sources, and eventually display gathering locations on the MelloUI map with optional Auctionator prices.

## Verified in-game on 2026-11-19

User screenshots confirm that `/ltfr debug` detects the active profession window, `ProfessionsFrame.CraftingPage.SchematicForm`, and recipe ID **7955**. `/ltfr scan` identifies **Ceinture en écailles de déviant** and three reagent slots: item IDs **6471 ×10**, **6470 ×10**, **2321 ×2**.

**Still unverified:** resolved item names (currently displayed as `Objet #ID`), bag counts (all zero in the screenshot), refresh after bag changes, other recipes, and switching/closing professions. The screenshot does not prove correct inventory counting.

## Experimental tracking panel (develop only)

The panel is created by `addon/Tracking.lua`, loaded after `Main.lua`. Its options are saved via `LeatherTrackerFRDB`. The **Bases** toggle only changes the UI setting: **it does not yet draw basic leather/hide sources**. Tracking a recipe similarly does not yet create MelloUI pins. A future verified location dataset and map-layer API integration are required.

## Commands (temporary diagnostic interface)

- `/ltfr api`: available APIs and integrations.
- `/ltfr debug`: profession UI and selected recipe state.
- `/ltfr scan`: scan selected recipe.
- `/ltfr id NUMBER`: inspect a known recipe ID.
- `/ltfr refresh`: refresh last recipe and inventory counts.

## Accessibility and interface roadmap

**Slash commands are for testing, not the intended user experience.** The experimental v0.1.2 adds a clickable **LeatherTracker** button on the profession window and a separate panel with **Suivre la recette**, **Bases** and **Manquants** toggles. This integration is not yet validated in-game; the map still has no markers or source database. It should show localized ingredient names, required/owned/missing counts, clear status indicators, and later verified sources and map navigation. Design for readable text, keyboard support where feasible, and no required command memorization. Full native integration, verified map markers, and accessibility validation are **not implemented yet**.

## Installation

Copy `addon/LeatherTrackerFR.toc` and `addon/Main.lua` into `Interface/AddOns/LeatherTrackerFR/` in the WoW Forever installation. Enable the addon. See [French user guide](docs/Guide_utilisateur_v0.2.docx).

## Documentation

- [Cahier des charges v0.4](docs/Cahier_des_charges_v0.4.docx)
- [Guide utilisateur v0.2](docs/Guide_utilisateur_v0.2.docx)
- [Test plan and observed results](docs/PLAN_TESTS_v0.1.1.md)
- [UX and accessibility requirements](docs/UX_ACCESSIBILITE.md)
- [Changelog](CHANGELOG.md)

## Planned data sources

- Warcraft Forever: https://warcraftforever.com/developers/data/
- ForeverDB: https://foreverdb.net/developers

Integration is planned, not yet implemented or approved. Data provenance, permissions, and versions must be checked. **Never commit API keys.** Attribution will follow applicable terms.

No license has been selected yet; do not assume permission to redistribute code or third-party datasets.
