local _, addon = ...

-- These item pages explicitly record the NPC as seen dropping the item in Forever.
-- https://foreverdb.net/item/1081
-- https://foreverdb.net/item/1210
-- https://foreverdb.net/item/1475
local creatures = {
 [4007] = {nonSkinnable = true, items = {[1081] = true, [1210] = true, [1475] = true}},
}
for itemID, sources in pairs(addon.componentSources) do
 for _, source in ipairs(sources) do
  local skinning = source.method == "Dépeçage"
  local observed = source.context == "Observé sur WoW Forever"
   or (type(source.observations) == "number" and source.observations > 0
    and (source.provenance == "Forever Drop Rate" or source.provenance == "ForeverDB.net"))
  if source.creatureID and observed and not source.tentative and (skinning or source.method == "Butin") then
   local entry = creatures[source.creatureID] or {items = {}}
   creatures[source.creatureID] = entry
   entry.items[itemID] = true
   if skinning then entry.skinnable = true end
  end
 end
end

local function playerSkill()
 if GetProfessions and GetProfessionInfo then
  local primary, secondary = GetProfessions()
  for index = 1, 2 do
   local profession = index == 1 and primary or index == 2 and secondary
   if profession then
    local _, _, rank, _, _, _, skillLine = GetProfessionInfo(profession)
    if skillLine == 393 then return rank end
   end
  end
 end
 if GetNumSkillLines and GetSkillLineInfo then
  for index = 1, GetNumSkillLines() do
   local name, header, _, rank = GetSkillLineInfo(index)
   if not header and (name == "Dépeçage" or name == "Skinning") then return rank end
  end
 end
end

local function parseSkinning(text)
 if (issecretvalue and issecretvalue(text)) or type(text) ~= "string" then return end
 text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
 local noun = GetLocale and GetLocale() == "frFR" and "Dépeçage" or "Skinning"
 local required = text:match("^"..noun.."%s*%((%d+)%)%s*$")
  or text:match("^"..noun.."%s*:%s*(%d+)%s*$")
  or text:match("^Requires Skinning%s*%((%d+)%)%s*$")
  or text:match("^Nécessite Dépeçage%s*%((%d+)%)%s*$")
 if required then return true, tonumber(required) end
 if text == "Dépeçable" or text == "Skinnable" or text == UNIT_SKINNABLE_LEATHER then return true end
 if text == "Non dépeçable" or text == "Not skinnable" then return false end
end

local function nativeSkinning(tooltip, data)
 local lines = data and data.lines
 if type(lines) == "table" then
  local status
  for _, line in ipairs(lines) do
   local skin, required = parseSkinning(line.leftText)
   if required then return true, required end
   if skin ~= nil then status = skin end
  end
  return status
 end
 for index = 2, tooltip:NumLines() do
  local line = _G["GameTooltipTextLeft"..index]
  local skin, required = parseSkinning(line and line:GetText())
  if skin ~= nil then return skin, required end
 end
end

local function learnSkinning(creatureID, level, required)
 LeatherTrackerFRDB = LeatherTrackerFRDB or {}
 local observations = LeatherTrackerFRDB.skinningObservations
 if type(observations) ~= "table" then
  observations = {}
  LeatherTrackerFRDB.skinningObservations = observations
 end
 local entry = observations[creatureID]
 if type(entry) ~= "table" then
  entry = {}
  observations[creatureID] = entry
 end
 if level and required then entry[level] = required end
 return entry
end

if not GameTooltip then return end

local iconSize, gap = 16, 3
local strip = CreateFrame("Frame", nil, UIParent)
strip:SetFrameStrata("TOOLTIP")
strip:EnableMouse(false)
strip:Hide()
local itemTooltip = CreateFrame("GameTooltip", "LeatherTrackerFRItemTooltip", UIParent, "GameTooltipTemplate")
local icons = {}
local generation, rendered = 0, false
local hoveredIcon

local function hideStrip()
 generation = generation + 1
 hoveredIcon = nil
 itemTooltip:Hide()
 strip:Hide()
end

local function linger()
 rendered = false
 if not strip:IsShown() or hoveredIcon then return end
 generation = generation + 1
 local current = generation
 if not C_Timer or not C_Timer.After then hideStrip(); return end
 C_Timer.After(0.6, function()
  if current == generation then hideStrip() end
 end)
end

local function itemButton(index)
 if icons[index] then return icons[index] end
 local button = CreateFrame("Button", nil, strip)
 button:SetSize(iconSize, iconSize)
 button:SetPoint("LEFT", (index - 1) * (iconSize + gap), 0)
 button.texture = button:CreateTexture(nil, "ARTWORK")
 button.texture:SetAllPoints()
 button:SetScript("OnEnter", function(self)
  generation = generation + 1
  hoveredIcon = self
  itemTooltip:SetOwner(self, "ANCHOR_RIGHT")
  itemTooltip:SetHyperlink("item:"..self.itemID)
  itemTooltip:Show()
 end)
 button:SetScript("OnLeave", function(self)
  if hoveredIcon ~= self then return end
  hoveredIcon = nil
  itemTooltip:Hide()
  if not GameTooltip:IsShown() or not rendered then linger() end
 end)
 icons[index] = button
 return button
end

-- ForeverArtisan documents the standard thresholds through level 60.
-- https://www.foreverartisan.app/guides/skinning/
local function matchingLevel(unit, guid)
 if not UnitLevel then return end
 unit = unit or "mouseover"
 local unitGuid = UnitGUID(unit)
 if (issecretvalue and issecretvalue(unitGuid)) or unitGuid ~= guid then return end
 local level = UnitLevel(unit)
 if (issecretvalue and issecretvalue(level)) or type(level) ~= "number" or level < 1 then return end
 return level
end

local nonSkinnableTypes = {
 Elemental = true, ["Élémentaire"] = true,
 Humanoid = true, ["Humanoïde"] = true,
}

local function nonSkinnableEnemy(unit, guid)
 if not UnitIsEnemy or not UnitCreatureType then return false end
 unit = unit or "mouseover"
 local unitGuid = UnitGUID(unit)
 if (issecretvalue and issecretvalue(unitGuid)) or unitGuid ~= guid then return false end
 local enemy = UnitIsEnemy("player", unit)
 if (issecretvalue and issecretvalue(enemy)) or not enemy then return false end
 local creatureType = UnitCreatureType(unit)
 return not (issecretvalue and issecretvalue(creatureType)) and nonSkinnableTypes[creatureType] == true
end

local function creatureIDFromGUID(guid)
 if (issecretvalue and issecretvalue(guid)) or type(guid) ~= "string" then return end
 return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

-- Pair the player's successful cast with the actual loot source GUID.
-- Only sample loot windows that start after the successful cast.
local pendingSkinning
local lootWindowOpen = false
local lastObservation
SLASH_LEATHERTRACKERSKINDEBUG1 = "/ltskindebug"
if SlashCmdList then
 SlashCmdList.LEATHERTRACKERSKINDEBUG = function()
  print("LeatherTracker — " .. (lastObservation or "Aucune tentative de dépeçage observée pendant cette session."))
 end
end

local function recordSample(bucket, items)
 bucket.samples = bucket.samples + 1
 for itemID in pairs(items) do
  bucket.drops[itemID] = (bucket.drops[itemID] or 0) + 1
 end
end

local function finishSkinning()
 local attempt = pendingSkinning
 if not attempt.succeeded or not attempt.looted then return end
 pendingSkinning = nil
 local entry = learnSkinning(attempt.creatureID)
 if attempt.items then
  entry.loot = entry.loot or {samples = 0, drops = {}}
  entry.loot.name = attempt.name or entry.loot.name
  recordSample(entry.loot, attempt.items)
  if attempt.level then
   entry.loot.byLevel = entry.loot.byLevel or {}
   local bucket = entry.loot.byLevel[attempt.level] or {samples = 0, drops = {}}
   entry.loot.byLevel[attempt.level] = bucket
   recordSample(bucket, attempt.items)
  end
  lastObservation = "Dépeçage et fenêtre complète enregistrés."
  if addon.SkinningSourcesChanged then addon.SkinningSourcesChanged(entry.loot.drops) end
 else
  lastObservation = "Dépeçage confirmé. Objets incomplets, fenêtre exclue du taux."
 end
 if not attempt.level or not attempt.skill then return end
 entry.successes = entry.successes or {}
 local count = entry.successes[attempt.level]
 if not count then
  count = {total = 0, samples = 0}
  entry.successes[attempt.level] = count
 end
 count.samples = count.samples + 1
 count.total = count.total + attempt.skill
 count.lowestSkill = math.min(count.lowestSkill or attempt.skill, attempt.skill)
end

local skinningEvents = CreateFrame("Frame")
skinningEvents:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
skinningEvents:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
skinningEvents:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
skinningEvents:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
skinningEvents:RegisterEvent("LOOT_READY")
skinningEvents:RegisterEvent("LOOT_OPENED")
skinningEvents:RegisterEvent("LOOT_CLOSED")
skinningEvents:SetScript("OnEvent", function(_, event, unit, a, b, spellID)
 if event == "LOOT_READY" or event == "LOOT_OPENED" then
  lootWindowOpen = true
 elseif event == "LOOT_CLOSED" then
  lootWindowOpen = false
 end
 if event == "UNIT_SPELLCAST_SENT" then
  if pendingSkinning then
   lastObservation = "Tentative précédente interrompue par un nouveau sort."
   pendingSkinning = nil
  end
  local spellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
  local skinningName = spellName and spellName(8613)
  if unit ~= "player" or not b or (spellID ~= 8613 and
   (not skinningName or spellName(spellID) ~= skinningName)) then return end
  local candidates = {}
  for _, token in ipairs({"mouseover", "target"}) do
   local guid = UnitGUID(token)
   local creatureID = creatureIDFromGUID(guid)
   if creatureID and UnitIsDead(token) and (not a or a == "" or UnitName(token) == a) then
    candidates[guid] = {creatureID = creatureID, level = matchingLevel(token, guid), name = UnitName(token)}
   end
  end
  if next(candidates) then
   pendingSkinning = {
    castGUID = b, skill = playerSkill(), candidates = candidates, time = GetTime(),
    windowBeforeSuccess = lootWindowOpen,
   }
   lastObservation = "Tentative détectée. En attente du résultat et de la fenêtre de récupération."
  else
   lastObservation = "Tentative ignorée. Cadavre impossible à identifier."
  end
  return
 end
 local attempt = pendingSkinning
 if not attempt then return end
 if GetTime() - attempt.time > 8 then
  pendingSkinning = nil
  lastObservation = "Tentative ignorée. Délai d’attribution dépassé."
  return
 end
 if event == "LOOT_CLOSED" then
  attempt.windowBeforeSuccess = nil
  attempt.ambiguousWindow = nil
  return
 elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
  if not attempt.succeeded then attempt.windowBeforeSuccess = true end
  if attempt.windowBeforeSuccess then
   lastObservation = "Fenêtre ignorée. Elle était ouverte avant la confirmation du dépeçage."
   return
  end
  if attempt.ambiguousWindow then return end
  if not GetLootSourceInfo or not GetNumLootItems then
   lastObservation = "Fenêtre ignorée. Origine des objets inaccessible."
   return
  end
  local matched, items, complete = nil, {}, true
  for slot = 1, GetNumLootItems() do
   local guid, quantity, extra = GetLootSourceInfo(slot)
   local candidate = creatureIDFromGUID(guid) and attempt.candidates[guid]
   -- Skip mixed or unidentifiable loot windows rather than bias the rate.
   if not candidate or type(quantity) ~= "number" or quantity <= 0 or extra ~= nil
    or (matched and matched ~= candidate) then
    attempt.ambiguousWindow = true
    lastObservation = "Fenêtre ignorée. Origine des objets différente ou ambiguë."
    return
   end
   matched = candidate
   local link = GetLootSlotLink and GetLootSlotLink(slot)
   local itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
   if itemID then items[itemID] = true else complete = false end
  end
  if not complete and event == "LOOT_READY" and GetLootSlotLink then return end
  if matched then
   attempt.looted, attempt.creatureID, attempt.level = true, matched.creatureID, matched.level
   attempt.name = matched.name
   attempt.items = complete and items or nil
  else
   lastObservation = "Fenêtre ignorée. Aucun objet attribuable au cadavre."
  end
 elseif unit == "player" and a == attempt.castGUID then
  if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
   pendingSkinning = nil
   lastObservation = "Tentative ignorée. Dépeçage interrompu ou échoué."
   return
  end
  attempt.succeeded = true
 end
 finishSkinning()
end)

local function render(tooltip, data)
 if tooltip ~= GameTooltip or rendered then return end
 local _, unit = tooltip:GetUnit()
 local guid = (data and data.guid) or (unit and UnitGUID(unit))
 local creatureID = creatureIDFromGUID(guid)
 if not creatureID then hideStrip(); return end
 hideStrip()
 rendered = true

 local entry = creatures[creatureID]
 local skin, required = nativeSkinning(tooltip, data)
 local db = LeatherTrackerFRDB and LeatherTrackerFRDB.skinningObservations
 local learned = type(db) == "table" and db[creatureID]
 if type(learned) ~= "table" then learned = nil end
 local level
 if skin == true or learned or (entry and entry.skinnable) then
  level = matchingLevel(unit, guid)
 end
 -- Record only the client's structured data, never lines added to the visible tooltip.
 if skin == true and data and type(data.lines) == "table" then
  learned = learnSkinning(creatureID, level, required)
 end
 if skin == nil and (learned or (entry and entry.skinnable)) then skin = true end
 if skin == true then
  tooltip:AddLine("Dépeçable", 0.25, 0.85, 0.35)
  local recorded = learned and level and learned[level]
  local successes = learned and learned.successes and level and learned.successes[level]
  local threshold = required or recorded or "seuil inconnu"
  local skillText = ("Dépeçage : %s / %s"):format(threshold, playerSkill() or "—")
  if not required and not recorded and successes and successes.lowestSkill then
   skillText = skillText .. (" · réussi à %d"):format(successes.lowestSkill)
  end
  tooltip:AddLine(skillText, 0.86, 0.86, 0.86)
 elseif (entry and entry.nonSkinnable) or nonSkinnableEnemy(unit, guid) then
  if skin ~= false then tooltip:AddLine("Non dépeçable", 0.95, 0.30, 0.30) end
 end

 local items = {}
 local getIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
 local itemIDs = {}
 for itemID in pairs(entry and entry.items or {}) do itemIDs[itemID] = true end
 for itemID in pairs(learned and learned.loot and learned.loot.drops or {}) do itemIDs[itemID] = true end
 for itemID in pairs(itemIDs) do
  local texture = getIcon and getIcon(itemID)
  if texture then items[#items + 1] = {id = itemID, texture = texture} end
 end
 if #items == 0 then return end
 table.sort(items, function(a, b) return a.id < b.id end)
 tooltip:AddLine(string.rep(" ", math.max(1, #items * 5)))
 for index, item in ipairs(items) do
  local button = itemButton(index)
  button.itemID = item.id
  button.texture:SetTexture(item.texture)
  button:Show()
 end
 for index = #items + 1, #icons do icons[index]:Hide() end
 strip:SetSize(#items * (iconSize + gap) - gap, iconSize)
 strip:ClearAllPoints()
 strip:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 9, 7)
 strip:Show()
end

GameTooltip:HookScript("OnTooltipCleared", linger)
GameTooltip:HookScript("OnHide", linger)
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
 TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, render)
else
 GameTooltip:HookScript("OnTooltipSetUnit", render)
end
