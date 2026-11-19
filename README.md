# LeatherTracker FR

**French-language Leatherworking assistant for WoW Forever 1.60.1**  
**Status:** experimental v0.2.2 on `develop`, not yet validated in-game; `main` unchanged.

## Goals

Help players read crafting recipes, compare ingredients with bag contents, find verified skinning/loot/vendor sources, and eventually display gathering locations on the MelloUI map with optional Auctionator prices.

## Verified in-game on 2026-11-19

User screenshots confirm that `/ltfr debug` detects the active profession window, `ProfessionsFrame.CraftingPage.SchematicForm`, and recipe ID **7955**. `/ltfr scan` identifies **Ceinture en écailles de déviant** and three reagent slots: item IDs **6471 ×10**, **6470 ×10**, **2321 ×2**.

**Still unverified:** accurate bag counts, other recipes, changing/closing professions, and the v0.2.2 UI. User screenshots from v0.1.3 show resolved ingredient names and a working tracking panel.

## Profession-window integration (develop only)

Version 0.2.1 registers a **real side tab** with `ForeverCore.ProfessionTabs.Register` (API minor >= 2), using the implementation verified in user-provided ForeverCore v1.15.2 and SkillUp Forever v1.14.4 archives. Requires installing and enabling ForeverCore separately. The tab opens a LeatherTracker page within `ProfessionsFrame`, and returning to native tabs restores the native page. `/ltpanel` toggles the page and `/ltstatus` reports compatibility. This is an experimental implementation **not yet tested in the WoW client**.

Known limitations: recipe selection may not remain available while the native crafting page is hidden; track a recipe before switching tabs. Source coordinates, MelloUI map layers, vendors and base-resource pins remain unimplemented. Test layout, secure frame behavior, navigation, and interaction with SkillUp before release.

## Commands (temporary diagnostic interface)

- `/ltfr api`: available APIs and integrations.
- `/ltfr debug`: profession UI and selected recipe state.
- `/ltfr scan`: scan selected recipe.
- `/ltfr id NUMBER`: inspect a known recipe ID.
- `/ltfr refresh`: refresh last recipe and inventory counts.

## Accessibility and interface roadmap

The intended final UX is a native-looking LeatherTracker tab inside the profession window, modeled on Auctionator's integration pattern, with one-window navigation and no required slash commands. The current version uses the **ForeverCore profession side-tab API** and an embedded page with four functional navigation sections (recipe, materials, sources, MelloUI). Source catalog and map pins are placeholders until verifiable data is available. Pending in-game validation. Validate the profession UI's tab API and conflicts before replacing its navigation. Map integration will show only verified skinning, loot and vendor sources, filtered by tracked recipe and optionally base leatherworking resources.

## Installation

Install and enable **ForeverCore v1.15.2** first. Copy `addon/LeatherTrackerFR.toc`, `addon/Main.lua` and `addon/Tracking.lua` into `Interface/AddOns/LeatherTrackerFR/` in the WoW Forever installation. Enable the addon. See [French user guide](docs/Guide_utilisateur_v0.2.docx).

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

## Source data and MelloUI contract (planned, not populated)

Every resource record must carry item ID, source type (skinning/loot/vendor), NPC ID/name, map ID, coordinates when verified, level and skinning requirement where applicable, drop-rate numerator/denominator or explicit unknown, and source URL/version. Never invent a rate or location. Map layer controls must filter by selected recipe and optionally by basic materials. MelloUI exposes `MelloUI.Map:AddPin(owner,key,uiMapID,x,y,spec)` and `ClearPins(owner)`; integration has not been coded. Recipe selection must be cached before switching away from Fabrication because ForeverCore hides native pages.

## UI v0.2.2

Four embedded sections: Suivi de recette, Materiaux, Sources et zones, Carte MelloUI. Recipe and material sections display reagent counts from C_TradeSkillUI and inventory APIs when available. Source and map sections explicitly show the absence of a verified dataset, rather than fictional drop rates or coordinates. The side tab is registered via ForeverCore, with minimum custom window width 850. Requires in-game layout validation.
