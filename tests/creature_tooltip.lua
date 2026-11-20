local function noop() end
local frames, timers = {}, {}
local function frame()
 return setmetatable({scripts = {}, shown = true, Hide = function(self) self.shown = false end,
  Show = function(self) self.shown = true end, IsShown = function(self) return self.shown end,
  SetScript = function(self, key, fn) self.scripts[key] = fn end,
  HookScript = function(self, key, fn) self.scripts[key] = fn end,
  CreateTexture = function() return {SetTexture = noop, SetAllPoints = noop} end},
  {__index = function() return noop end})
end
function CreateFrame(kind)
 local widget = frame()
 frames[#frames + 1] = widget
 if kind == "GameTooltip" then
  widget.SetHyperlink = function(self, link) self.link = link end
 end
 return widget
end
GameTooltip = frame()
local lines
function GameTooltip:NumLines() return #lines end
function GameTooltip:AddLine(text) lines[#lines + 1] = text end
function GetLocale() return "frFR" end
function GetProfessions() return 1, 2 end
function GetProfessionInfo(profession) return nil, nil, 144, nil, nil, nil, profession == 2 and 393 or 165 end
C_Item = {GetItemIconByID = function(id) return id + 1 end}
C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
Enum = {TooltipDataType = {Unit = 2}}
local render
TooltipDataProcessor = {AddTooltipPostCall = function(_, callback) render = callback end}

SlashCmdList = {}
local addon = {}
assert(loadfile("addon/ComponentData.lua"))("LeatherTrackerFR", addon)
assert(loadfile("addon/CreatureTooltip.lua"))("LeatherTrackerFR", addon)
local function unit(id, native, nativeData)
 GameTooltip.scripts.OnTooltipCleared()
 lines = native and {"Créature", native} or {"Créature"}
 GameTooltipTextLeft2 = native and {GetText = function() return native end}
 render(GameTooltip, {guid = ("Creature-0-0-0-0-%d-0000"):format(id), lines = nativeData})
end

unit(2961, "Dépeçage (75)")
assert(lines[3] == "Dépeçable" and lines[4] == "Dépeçage : 75 / 144")
assert(lines[5]:match("^%s+$") and #lines == 5)
local strip, tooltip, icon = frames[1], frames[2], frames[4]
assert(strip:IsShown() and icon.itemID == 2934)
GameTooltip.scripts.OnHide()
icon.scripts.OnEnter(icon)
timers[#timers]()
assert(strip:IsShown() and tooltip.link == "item:2934")
icon.scripts.OnLeave(icon)
assert(not tooltip:IsShown())
unit(876543, nil)
assert(#lines == 1 and not strip:IsShown())
unit(876543, "Non dépeçable")
assert(#lines == 2 and not strip:IsShown())
unit(3636)
assert(strip:IsShown() and lines[2] == "Dépeçable" and lines[3] == "Dépeçage : seuil inconnu / 144")
unit(4007, nil)
assert(#lines == 3 and lines[2] == "Non dépeçable" and lines[3]:match("^%s+$") and strip:IsShown())
assert(frames[4].itemID == 1081 and frames[5].itemID == 1210 and frames[6].itemID == 1475)
function GameTooltip:GetUnit() return "Créature", "mouseover" end
local level, guid
function UnitLevel() return level end
function UnitGUID() return guid end
guid = "Creature-0-0-0-0-3636-0000"
for _, creatureLevel in ipairs({1, 10, 11, 17, 20, 21, 60}) do
 level = creatureLevel
 unit(3636)
 assert(lines[3] == "Dépeçage : seuil inconnu / 144")
end
unit(3636, "Dépeçage (125)")
assert(lines[4] == "Dépeçage : 125 / 144")
level = -1
unit(3636)
assert(lines[3] == "Dépeçage : seuil inconnu / 144")
level = 17
unit(4007)
assert(#lines == 3 and lines[2] == "Non dépeçable" and strip:IsShown())
guid = "Creature-0-0-0-0-4007-0000"
unit(3636)
assert(lines[3] == "Dépeçage : seuil inconnu / 144")
guid = "Creature-0-0-0-0-876543-0000"
local hostile, creatureType = true, "Humanoïde"
function UnitIsEnemy() return hostile end
function UnitCreatureType() return creatureType end
for _, kind in ipairs({"Humanoïde", "Élémentaire", "Humanoid", "Elemental"}) do
 creatureType = kind
 unit(876543)
 assert(#lines == 2 and lines[2] == "Non dépeçable")
end
unit(876543, "Dépeçage (125)")
assert(lines[3] == "Dépeçable" and lines[4] == "Dépeçage : 125 / 144")
creatureType = "Bête"
unit(876543)
assert(lines[2] == "Dépeçage inconnu")
hostile = false
unit(876543)
assert(#lines == 1)
hostile = true
guid = "Creature-0-0-0-0-876543-0000"
level = 17
unit(876543, "Dépeçage (73)", {{leftText = "Dépeçage (73)"}})
assert(LeatherTrackerFRDB.skinningObservations[876543][17] == 73)
unit(876543)
assert(lines[2] == "Dépeçable" and lines[3] == "Dépeçage : 73 / 144")
level = 18
unit(876543)
assert(lines[3] == "Dépeçage : seuil inconnu / 144")
unit(876543, "Non dépeçable", {{leftText = "Non dépeçable"}})
assert(#lines == 2 and LeatherTrackerFRDB.skinningObservations[876543][17] == 73)
guid = "Creature-0-0-0-0-876544-0000"
unit(876544, "Dépeçable")
assert(not LeatherTrackerFRDB.skinningObservations[876544])
unit(876544, "Dépeçable", {{leftText = "Dépeçable"}})
unit(876544)
assert(lines[2] == "Dépeçable" and lines[3] == "Dépeçage : seuil inconnu / 144")
C_Map = {
 GetBestMapForUnit = function() return 1413 end,
 GetPlayerMapPosition = function() return {GetXY = function() return 0.461, 0.365 end} end,
 GetMapInfo = function() return {name = "Les Tarides"} end,
}
local gameEvent = frames[3].scripts.OnEvent
local corpseGUID = "Creature-0-0-0-0-876545-0001"
local lootGUID, skill, now = corpseGUID, 65, 100
function UnitGUID(token) if token == "mouseover" then return corpseGUID end end
function UnitIsDead() return true end
function UnitName() return "Créature" end
function GetTime() return now end
local lootItems = {99999}
function GetNumLootItems() return #lootItems end
function GetLootSlotLink(slot) return "item:" .. lootItems[slot] end
function GetLootSourceInfo() return lootGUID, 1 end
function GetProfessionInfo(profession) return nil, nil, skill, nil, nil, nil, profession == 2 and 393 or 165 end
level = 17
gameEvent(nil, "LOOT_READY")
gameEvent(nil, "UNIT_SPELLCAST_SENT", "player", "Créature", "cast1", 8613)
assert(not LeatherTrackerFRDB.skinningObservations[876545])
gameEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast1", 8613)
gameEvent(nil, "LOOT_OPENED")
assert(not LeatherTrackerFRDB.skinningObservations[876545])
gameEvent(nil, "LOOT_CLOSED")
lootItems = {2318, 2318}
gameEvent(nil, "LOOT_READY")
gameEvent(nil, "LOOT_OPENED")
local learned = LeatherTrackerFRDB.skinningObservations[876545]
assert(learned.successes[17].samples == 1)
assert(addon.ExportSkinningCreatures():find("1 positions", 1, true))
assert(#LeatherTrackerFRDB.skinningExport.documented > 0)
local point = learned.locations["1413:92:73"]
assert(point.x == 0.46 and point.y == 0.365 and point.observations == 1)
assert(learned.loot.samples == 1 and learned.loot.name == "Créature")
assert(learned.loot.drops[2318] == 1 and not learned.loot.drops[99999])
gameEvent(nil, "LOOT_CLOSED")
skill, corpseGUID = 85, "Creature-0-0-0-0-876545-0002"
gameEvent(nil, "UNIT_SPELLCAST_SENT", "player", "Créature", "cast2", 8613)
gameEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast2", 8613)
gameEvent(nil, "LOOT_READY")
assert(learned.successes[17].samples == 1)
lootGUID = corpseGUID
lootItems = {2934}
gameEvent(nil, "LOOT_OPENED")
assert(learned.loot.samples == 1) -- A later partial view cannot rehabilitate that window.
gameEvent(nil, "LOOT_CLOSED")
gameEvent(nil, "LOOT_READY")
assert(learned.successes[17].samples == 2 and learned.successes[17].total == 150)
assert(learned.loot.samples == 2 and learned.loot.drops[2318] == 1 and learned.loot.drops[2934] == 1)
assert(learned.loot.byLevel[17].samples == 2 and learned.loot.byLevel[17].drops[2934] == 1)
local report
do
 local originalPrint = print
 print = function(message) report = message end
 SlashCmdList.LEATHERTRACKERSKINDEBUG()
 print = originalPrint
end
assert(report:find("fenêtre complète", 1, true))
gameEvent(nil, "LOOT_CLOSED")
corpseGUID = "Creature-0-0-0-0-876545-0000"
unit(876545)
assert(lines[3] == "Dépeçage : seuil inconnu / 85 · réussi à 65")
gameEvent(nil, "UNIT_SPELLCAST_SENT", "player", "Créature", "cast3", 8613)
gameEvent(nil, "UNIT_SPELLCAST_FAILED", "player", "cast3", 8613)
lootGUID = corpseGUID
gameEvent(nil, "LOOT_READY")
assert(learned.successes[17].samples == 2 and learned.loot.samples == 2)
gameEvent(nil, "LOOT_CLOSED")
gameEvent(nil, "UNIT_SPELLCAST_SENT", "player", "Créature", "cast4", 8613)
gameEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast4", 8613)
function GetLootSlotLink() return nil end
gameEvent(nil, "LOOT_READY")
assert(learned.successes[17].samples == 2)
gameEvent(nil, "LOOT_OPENED")
assert(learned.successes[17].samples == 3 and learned.loot.samples == 2)
addon.SetSkinningLearningEnabled(false)
corpseGUID = "Creature-0-0-0-0-876546-0000"
unit(876546, "Dépeçage (80)", {{leftText = "Dépeçage (80)"}})
assert(not LeatherTrackerFRDB.skinningObservations[876546])
assert(addon.GetSkinningDiagnostic():find("désactivé", 1, true))
addon.SetSkinningLearningEnabled(true)
corpseGUID = "Creature-0-0-0-0-876545-0000"
assert(loadfile("addon/CreatureTooltip.lua"))("LeatherTrackerFR", addon)
unit(876545)
assert(lines[3] == "Dépeçage : seuil inconnu / 85 · réussi à 65")
assert(LeatherTrackerFRDB.skinningObservations[876545].loot.byLevel[17].samples == 2)
print("Infobulle de créature : données vérifiées, valeurs inconnues et survol des objets")
