-- LeatherTracker FR 0.2.1 - ForeverCore native profession side tab.
-- Requires ForeverCore ProfessionTabs API minor >= 2.
local addon = CreateFrame("Frame")
local KEY = "leathertrackerfr"
local page, detail, follow, basics, missing
local db, registered, lastRecipe, elapsed = nil, false, nil, 0
local selectedCache, selectedNameCache

local function safe(fn, ...)
 if type(fn) ~= "function" then return nil end
 local ok, value = pcall(fn, ...)
 if ok then return value end
 return nil
end

local function currentRecipe()
 local frame = _G.ProfessionsFrame
 if not frame then return nil end
 local crafting = frame.CraftingPage
 local form = crafting and crafting.SchematicForm
 local info = form and safe(form.GetRecipeInfo, form)
 if type(info) == "table" and type(info.recipeID) == "number" then
  selectedCache, selectedNameCache = info.recipeID, info.name
  return info.recipeID, info.name
 end
 return selectedCache, selectedNameCache
end

local function recipeInfo(id)
 if not id or not C_TradeSkillUI then return nil end
 return safe(C_TradeSkillUI.GetRecipeInfo, id)
end

local function itemName(id)
 local name = C_Item and safe(C_Item.GetItemInfo, id)
 if not name then name = safe(_G.GetItemInfo, id) end
 return type(name) == "string" and name or ("Objet #"..id)
end

local function itemCount(id)
 local count = C_Item and safe(C_Item.GetItemCount, id, false)
 if type(count) ~= "number" then count = safe(_G.GetItemCount, id, false) end
 return type(count) == "number" and count or nil
end

local function refresh()
 if not page or not db then return end
 local selected, selectedName = currentRecipe()
 local id = db.trackedRecipeID or selected
 local lines = {"|cffffd100LEATHERTRACKER FR|r", " "}
 if not id then
  lines[#lines+1] = "Selectionnez une recette dans la page Fabrication."
 else
  local info = recipeInfo(id)
  local name = type(info) == "table" and info.name or selectedName or ("Recette #"..id)
  lines[#lines+1] = "|cffffd100RECETTE|r"
  lines[#lines+1] = name
  lines[#lines+1] = db.trackedRecipeID and "Suivi actif" or "Apercu de la selection"
  lines[#lines+1] = " "
  local schematic = C_TradeSkillUI and safe(C_TradeSkillUI.GetRecipeSchematic, id, false)
  lines[#lines+1] = "|cffffd100COMPOSANTS|r"
  local found = false
  if type(schematic) == "table" and type(schematic.reagentSlotSchematics) == "table" then
   for _, slot in ipairs(schematic.reagentSlotSchematics) do
    local reagent = type(slot.reagents) == "table" and slot.reagents[1]
    local itemID = reagent and reagent.itemID
    local required = tonumber(slot.quantityRequired) or 0
    if itemID and required > 0 then
     local owned = itemCount(itemID)
     local deficit = owned and math.max(0, required - owned) or nil
     if not db.onlyMissing or not deficit or deficit > 0 then
      lines[#lines+1] = itemName(itemID).." : "..(owned or "?").." / "..required
     end
     found = true
    end
   end
  end
  if not found then lines[#lines+1] = "Informations des composants indisponibles." end
 end
 lines[#lines+1] = " "
 lines[#lines+1] = "|cffffd100CARTE MELLOUI|r"
 lines[#lines+1] = "Aucun emplacement verifie importe."
 lines[#lines+1] = "Ressources de base : "..(db.showBasics and "activees" or "masquees")
 detail:SetText(table.concat(lines, "\n"))
 follow:SetText(db.trackedRecipeID and "Arreter le suivi" or "Suivre la recette")
 if follow.SetEnabled then follow:SetEnabled(db.trackedRecipeID ~= nil or selectedCache ~= nil) end
 basics:SetText(db.showBasics and "Bases : OUI" or "Bases : NON")
 missing:SetText(db.onlyMissing and "Manquants : OUI" or "Manquants : NON")
 lastRecipe = selected
end

local function makeButton(parent, text, width, x, y)
 local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
 button:SetSize(width, 25)
 button:SetPoint("TOPLEFT", x, y)
 button:SetText(text)
 return button
end

local function register()
 if registered or not db or not _G.ProfessionsFrame then return end
 local core = _G.ForeverCore
 local tabs = core and core.ProfessionTabs
 if type(tabs) ~= "table" or type(tabs.Register) ~= "function" or
    (tonumber(tabs.minor) or 0) < 2 then return end
 if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
 local frame = _G.ProfessionsFrame
 page = CreateFrame("Frame", "LeatherTrackerFRProfessionPage", frame)
 page:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -70)
 page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 35)
 page:Hide()
 local backdrop = page:CreateTexture(nil, "BACKGROUND")
 backdrop:SetAllPoints(page)
 backdrop:SetColorTexture(0.055, 0.07, 0.095, 0.98)
 local accent = page:CreateTexture(nil, "BORDER")
 accent:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -4)
 accent:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -4)
 accent:SetHeight(2)
 accent:SetColorTexture(0.76, 0.56, 0.20, 1)
 detail = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
 detail:SetPoint("TOPLEFT", page, "TOPLEFT", 20, -35)
 detail:SetPoint("RIGHT", page, "RIGHT", -20, 0)
 detail:SetJustifyH("LEFT")
 detail:SetJustifyV("TOP")
 follow = makeButton(page, "Suivre la recette", 165, 20, -360)
 basics = makeButton(page, "Bases : OUI", 120, 195, -360)
 missing = makeButton(page, "Manquants : OUI", 145, 325, -360)
 follow:SetScript("OnClick", function()
  if db.trackedRecipeID then
   db.trackedRecipeID = nil
  else
   local id = selectedCache
   if id then db.trackedRecipeID = id
   else print("LeatherTracker : choisissez d'abord une recette dans Fabrication.") end
  end
  refresh()
 end)
 basics:SetScript("OnClick", function() db.showBasics = not db.showBasics; refresh() end)
 missing:SetScript("OnClick", function() db.onlyMissing = not db.onlyMissing; refresh() end)
 page:SetScript("OnShow", refresh)
 local ok, err = pcall(tabs.Register, KEY, {
  icon = "Interface\\Icons\\INV_Misc_LeatherScrap_02",
  tooltip = "LeatherTracker FR",
  page = page,
  onSelect = refresh,
 })
 if not ok then
  page:Hide()
  print("LeatherTracker : impossible de creer l'onglet : "..tostring(err))
  return
 end
 registered = true
 frame:HookScript("OnHide", function()
  if tabs.Selected and tabs.Selected() == KEY and tabs.ShowNative then tabs.ShowNative() end
 end)
 print("LeatherTracker : onglet metier enregistre.")
end

SLASH_LEATHERTRACKERPANEL1 = "/ltpanel"
SlashCmdList.LEATHERTRACKERPANEL = function()
 register()
 if not registered then
  print("LeatherTracker : ouvrez un metier et verifiez ForeverCore v1.15.2.")
  return
 end
 local tabs = _G.ForeverCore.ProfessionTabs
 if tabs.Selected and tabs.Selected() == KEY then tabs.ShowNative()
 else tabs.Select(KEY) end
end

SLASH_LEATHERTRACKERSTATUS1 = "/ltstatus"
SlashCmdList.LEATHERTRACKERSTATUS = function()
 local tabs = _G.ForeverCore and _G.ForeverCore.ProfessionTabs
 print("LeatherTracker 0.2.1 | ProfessionsFrame="..tostring(_G.ProfessionsFrame ~= nil)..
  " | ForeverCore="..tostring(tabs ~= nil)..
  " | minor="..tostring(tabs and tabs.minor)..
  " | onglet="..tostring(registered))
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("GET_ITEM_INFO_RECEIVED")
addon:SetScript("OnEvent", function(_, event)
 if event == "PLAYER_LOGIN" then
  LeatherTrackerFRDB = type(LeatherTrackerFRDB) == "table" and LeatherTrackerFRDB or {}
  db = LeatherTrackerFRDB
  if type(db.showBasics) ~= "boolean" then db.showBasics = true end
  if type(db.onlyMissing) ~= "boolean" then db.onlyMissing = true end
  register()
 elseif event == "ADDON_LOADED" then
  if db then register() end
 else
  if page and page:IsShown() then refresh() end
 end
end)
addon:SetScript("OnUpdate", function(_, dt)
 elapsed = elapsed + dt
 if elapsed < 1 then return end
 elapsed = 0
 if not registered then register() end
 if _G.ProfessionsFrame and _G.ProfessionsFrame:IsShown() then
  local id = currentRecipe()
  if registered and page and page:IsShown() and id ~= lastRecipe then refresh() end
 end
end)
