# Changelog

## v0.1.2 — develop, untested in-game
- Added `Tracking.lua`: clickable profession-window button, mouse-driven recipe follow/unfollow, missing-material and basic-resource toggles, saved preferences.
- Added a reagent summary using game item names when cached, otherwise item IDs; refreshes on bag and item-info events.
- **Not implemented:** resource locations, MelloUI markers/layer registration, merchant lookup, basic-resource item database, routes. No data locations were invented.
- **Requires testing:** profession window attachment, frame layout, selection updates, bag counts, saved settings, reagent variants.


## v0.1.1 — develop (partial in-game validation 2026-11-19)
- Confirmed selected recipe ID 7955 and name “Ceinture en écailles de déviant” from ProfessionsFrame SchematicForm.
- Confirmed three reagent slots displayed with IDs 6471 ×10, 6470 ×10, 2321 ×2.
- Added read-only selection detection, `/ltfr debug`, `/ltfr id NUMBER`, `/ltfr refresh`, scrollable diagnostics, and bag-update refresh logic.
- Known issues: item names appear as numeric IDs; inventory count accuracy is not established; other recipes and event behavior require testing.
- Added accessibility roadmap for a native profession-window panel. Not yet implemented.

## Documentation — 2026-11-19
- Updated specifications to v0.4 and user guide to v0.2.
- Documented planned Warcraft Forever and ForeverDB data integration.

## v0.1.0 — experimental prototype
- Added diagnostic window and `/ltfr api`, `/ltfr scan` commands.
- Known issue: selected-recipe API unavailable on the tested client.
