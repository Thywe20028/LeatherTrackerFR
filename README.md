# LeatherTracker FR

**French-language Leatherworking assistant for World of Warcraft Forever 1.60.1**

🚧 **Status: Early development — Prototype v0.1.0**

LeatherTracker FR is a free addon project designed to help players find the materials needed to craft Leatherworking recipes.

## Planned Features

- Read Leatherworking recipes and required materials.
- Track materials available in the player's inventory.
- Identify missing crafting materials.
- Find creatures that provide leather, hides and scales.
- Display creature levels and Skinning skill requirements.
- Show verified farming locations on the MelloUI map.
- Integrate available Auctionator prices.
- Provide a fully French-language interface.

## Current Development Status

The first prototype includes an API diagnostic interface and experimental recipe reading.

Testing on WoW Forever 1.60.1 has confirmed the availability of `C_TradeSkillUI.GetRecipeInfo` and `C_TradeSkillUI.GetRecipeSchematic`.

Recipe selection detection is currently being improved. Full recipe tracking, gathering locations and map integration are not yet functional.

## Technical Approach

The addon is being developed in Lua for WoW Forever.

Planned integrations:

- MelloUI — Map markers and navigation
- HandyNotes — Location data
- Auctionator — Auction house prices
- ForeverDB — Creature, Skinning, vendor and gathering data
- Warcraft Forever game data — Recipes and items

External data will be prepared during development and stored locally for offline use. No private API keys will be distributed with the addon.

## Data Attribution

ForeverDB: https://foreverdb.net

ForeverDB data integration is planned and subject to API access approval and applicable usage conditions.

## Language

The addon interface will be in French. English documentation is provided for contributors and data providers.

## Development

This project is under active development. Features and compatibility will be validated through in-game testing before release.
