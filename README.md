# LeatherTracker FR

**French-language Leatherworking assistant for WoW Forever 1.60.1**  
**Status:** experimental v0.1.5 on `develop` (not yet validated in-game); `main` remains v0.1.0.

## Goals

Help players read crafting recipes, compare ingredients with bag contents, find verified skinning/loot/vendor sources, and eventually display gathering locations on the MelloUI map with optional Auctionator prices.

## Verified in-game on 2026-11-19

User screenshots confirm that `/ltfr debug` detects the active profession window, `ProfessionsFrame.CraftingPage.SchematicForm`, and recipe ID **7955**. `/ltfr scan` identifies **Ceinture en écailles de déviant** and three reagent slots: item IDs **6471 ×10**, **6470 ×10**, **2321 ×2**.

**Still unverified:** accurate bag counts, other recipes, changing/closing professions, and the v0.1.5 UI. User screenshots from v0.1.3 show resolved ingredient names and a working tracking panel.

## Profession-window integration (develop only)

Version 0.1.5 adds a **LeatherTracker launcher button** on `ProfessionsFrame` and a profession-anchored details panel inspired by Auctionator's workflow. It is **not yet a native WoW tab** and does **not replace the profession's CraftingPage**. The button toggles the panel; `/ltpanel` is a fallback. The panel starts hidden, and the preference is stored in `LeatherTrackerFRDB`. It displays the selected or tracked recipe and ingredients where available.

**Known limitations:** the panel is attached outside the right edge of the profession frame and may extend beyond the screen; its position and click behavior must be tested. The map, vendors, and base-resource source data are not implemented. `Bases` and `Manquants` control display preferences, not MelloUI layers.

## Commands (temporary diagnostic interface)

- `/ltfr api`: available APIs and integrations.
- `/ltfr debug`: profession UI and selected recipe state.
- `/ltfr scan`: scan selected recipe.
- `/ltfr id NUMBER`: inspect a known recipe ID.
- `/ltfr refresh`: refresh last recipe and inventory counts.

## Accessibility and interface roadmap

The intended final UX is a native-looking LeatherTracker tab inside the profession window, modeled on Auctionator's integration pattern, with one-window navigation and no required slash commands. The current version is an **experimental launcher + anchored panel**, not the final tab system. Validate the profession UI's tab API and conflicts before replacing its navigation. Map integration will show only verified skinning, loot and vendor sources, filtered by tracked recipe and optionally base leatherworking resources.

## Installation

Copy `addon/LeatherTrackerFR.toc`, `addon/Main.lua` and `addon/Tracking.lua` into `Interface/AddOns/LeatherTrackerFR/` in the WoW Forever installation. Enable the addon. See [French user guide](docs/Guide_utilisateur_v0.2.docx).

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
