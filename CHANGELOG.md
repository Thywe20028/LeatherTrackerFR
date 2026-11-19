# Changelog

## v0.1.1 — development, not yet tested in game
- Added read-only recipe selection detection via ProfessionsFrame SchematicForm with API fallback.
- Added `/ltfr debug`, `/ltfr id NUMBER` and `/ltfr refresh`.
- Added guarded API calls, scrollable diagnostic window and bag update refresh.
- Added basic handling of reagent slot schematics and alternate reagents; requires client-specific verification.
- **Known limitations:** UI hierarchy may differ in WoW Forever; reagent type classification, inventory counts and manual recipe IDs need testing. No map pins, farming routes, source database or auction prices implemented.

# Changelog

## Documentation — 2026-11-19
- Added verified in-game diagnostic results and known recipe selection blocker.
- Added data integration plan for Warcraft Forever and ForeverDB, pending access and validation.
- Updated French specifications to v0.4 and user guide to v0.2.

## v0.1.0 — experimental prototype
- Added diagnostic window and `/ltfr api`, `/ltfr scan` commands.
- Known issue: recipe scan fails when `GetSelectedRecipeID` is absent.
