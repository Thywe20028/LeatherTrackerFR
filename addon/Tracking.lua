-- LeatherTracker FR 0.1.4: extension non destructive de la fenetre Professions.
-- Pas de marqueurs MelloUI tant que les sources ne sont pas verifiees.
local addon = CreateFrame("Frame")
local settings, bar, title, follow, basics, missing, status, tab, detail, selectedName
local lastSelected, elapsed = nil, 0

local function safe(fn, ...)
 if type(fn) ~= "function" then return nil end
 local ok, value = pcall(fn, ...)
 if ok then return value end
 return nil
end

local function selectedRecipe()
 local p = _G.ProfessionsFrame
 if not p or not p.IsShown or not p:IsShown() then return nil end
 local page = p.CraftingPage
 local form = page and (page.SchematicForm or (page.Schematic and page.Schematic.SchematicForm))
 local info = form and safe(form.GetRecipeInfo, form)
 if type(info) == "table" and type(info.recipeID) == "number" then
  return info.recipeID, info.name
 end
 return nil
end

local function button(parent, label, width)
 local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
 b:SetSize(width, 23)
 b:SetText(label)
 return b
end

local function update()
 if not settings or not bar then return end
 local id, name = selectedRecipe()
 local tracked = settings.trackedRecipeID
 selectedName = name
 title:SetText("|cffffd100LeatherTracker|r")
 if tracked then
  local info = C_TradeSkillUI and safe(C_TradeSkillUI.GetRecipeInfo, tracked)
  local recipeName = type(info) == "table" and info.name or name
  status:SetText("|cff9bdcaeSuivie :|r "..(recipeName or ("#"..tracked)))
 elseif id then
  status:SetText("Recette selectionnee : "..(name or ("#"..id)))
 else
  status:SetText("Choisissez une recette.")
 end
 if follow.SetEnabled then follow:SetEnabled(id ~= nil or tracked ~= nil) end
 follow:SetText(tracked and tracked == id and "Arreter le suivi" or "Suivre la recette")
 basics:SetText(settings.showBasics and "Bases : OUI" or "Bases : NON")
 missing:SetText(settings.onlyMissing and "Manquants : OUI" or "Manquants : NON")
 if detail then
  local activeID = tracked or id
  if activeID then
   local recipe = C_TradeSkillUI and safe(C_TradeSkillUI.GetRecipeInfo, activeID)
   local schematic = C_TradeSkillUI and safe(C_TradeSkillUI.GetRecipeSchematic, activeID, false)
   local recipeName = type(recipe) == "table" and recipe.name or name or ("#"..activeID)
   local lines = {"|cffffd100RECETTE|r", recipeName, " "}
   if type(schematic) == "table" and type(schematic.reagentSlotSchematics) == "table" then
    lines[#lines+1] = "|cffffd100COMPOSANTS|r"
    for _,slot in ipairs(schematic.reagentSlotSchematics) do
     local reagent = type(slot.reagents) == "table" and slot.reagents[1]
     local itemID = reagent and reagent.itemID
     local required = tonumber(slot.quantityRequired) or 0
     if itemID and required > 0 then
      local item = C_Item and safe(C_Item.GetItemInfo, itemID)
      if not item then item = safe(_G.GetItemInfo, itemID) end
      local owned = C_Item and safe(C_Item.GetItemCount, itemID, false)
      if type(owned) ~= "number" then owned = safe(_G.GetItemCount, itemID, false) end
      local missingCount = type(owned) == "number" and math.max(0, required-owned) or nil
      if not settings.onlyMissing or missingCount == nil or missingCount > 0 then
       lines[#lines+1] = (item or ("Objet #"..itemID)).." : "..(owned or "?").."/"..required
      end
     end
    end
   else lines[#lines+1] = "Composants indisponibles." end
   lines[#lines+1] = " "
   lines[#lines+1] = "|cffffd100CARTE|r"
   lines[#lines+1] = "Emplacements verifies non encore importes."
   lines[#lines+1] = settings.showBasics and "Ressources de base : activees" or "Ressources de base : masquees"
   detail:SetText(table.concat(lines, "\\n"))
  else
   detail:SetText("Selectionnez une recette dans Travail du cuir.")
  end
 end
 lastSelected = id
end

local function makeBar()
 local p = _G.ProfessionsFrame
 if not p or bar then return end
 -- Enfant de la fenetre native : disparait automatiquement avec elle.
 bar = CreateFrame("Frame", "LeatherTrackerFRBar", p)
 bar:SetSize(390, 300)
 bar:SetPoint("TOPLEFT", p, "TOPRIGHT", 5, -38)
 bar:SetFrameStrata("DIALOG")
 bar:SetFrameLevel(p:GetFrameLevel()+8)
 local bg = bar:CreateTexture(nil, "BACKGROUND")
 bg:SetAllPoints()
 bg:SetColorTexture(0.055, 0.075, 0.11, 0.94)
 local line = bar:CreateTexture(nil, "BORDER")
 line:SetPoint("TOPLEFT", 0, 0)
 line:SetPoint("TOPRIGHT", 0, 0)
 line:SetHeight(2)
 line:SetColorTexture(0.78, 0.59, 0.22, 1)
 title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
 title:SetPoint("TOPLEFT", 9, -8)
 status = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
 status:SetPoint("TOPRIGHT", -9, -30)
 status:SetWidth(235)
 status:SetJustifyH("RIGHT")
 follow = button(bar, "Suivre la recette", 145)
 follow:SetPoint("TOPLEFT", 8, -62)
 basics = button(bar, "Bases : OUI", 100)
 basics:SetPoint("TOPLEFT", 8, -91)
 missing = button(bar, "Manquants : OUI", 117)
 missing:SetPoint("LEFT", basics, "RIGHT", 5, 0)
 follow:SetScript("OnClick", function()
  local id = selectedRecipe()
  if id and settings.trackedRecipeID ~= id then
   settings.trackedRecipeID = id
  else
   settings.trackedRecipeID = nil
  end
  update()
 end)
 basics:SetScript("OnClick", function()
  settings.showBasics = not settings.showBasics
  update()
 end)
 missing:SetScript("OnClick", function()
  settings.onlyMissing = not settings.onlyMissing
  update()
 end)
 detail = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
 detail:SetPoint("TOPLEFT", 12, -130)
 detail:SetWidth(365)
 detail:SetJustifyH("LEFT")
 detail:SetJustifyV("TOP")
 tab = button(p, "LeatherTracker", 124)
 tab:SetPoint("TOPRIGHT", p, "TOPRIGHT", -48, -40)
 tab:SetFrameLevel(p:GetFrameLevel()+12)
 tab:SetScript("OnClick", function()
  settings.hiddenBar = bar:IsShown()
  if settings.hiddenBar then bar:Hide() else bar:Show() end
  update()
 end)
 bar:Hide()
 update()
end

local function initialize()
 if settings then return end
 LeatherTrackerFRDB = type(LeatherTrackerFRDB) == "table" and LeatherTrackerFRDB or {}
 settings = LeatherTrackerFRDB
 if type(settings.showBasics) ~= "boolean" then settings.showBasics = true end
 if type(settings.onlyMissing) ~= "boolean" then settings.onlyMissing = true end
 if type(settings.trackedRecipeID) ~= "number" then settings.trackedRecipeID = nil end
 makeBar()
end

SLASH_LEATHERTRACKERPANEL1 = "/ltpanel"
SlashCmdList.LEATHERTRACKERPANEL = function()
 if not settings then initialize() end
 makeBar()
 if not bar then
  print("LeatherTracker : ouvrez Travail du cuir.")
  return
 end
 local p = _G.ProfessionsFrame
 if not p:IsShown() then
  print("LeatherTracker : ouvrez la fenetre de metier.")
  return
 end
 settings.hiddenBar = bar:IsShown()
 if settings.hiddenBar then bar:Hide() else bar:Show() end
 update()
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("GET_ITEM_INFO_RECEIVED")
addon:SetScript("OnEvent", function(_, event)
 if event == "PLAYER_LOGIN" then initialize()
 elseif event == "ADDON_LOADED" then
  if settings then makeBar() end
 elseif settings then update() end
end)
addon:SetScript("OnUpdate", function(_, dt)
 elapsed = elapsed + dt
 if elapsed < 0.5 then return end
 elapsed = 0
 if not settings then return end
 makeBar()
 if not bar then return end
 local p = _G.ProfessionsFrame
 if p and p:IsShown() then
  if not settings.hiddenBar and not bar:IsShown() then bar:Show() end
  local id = selectedRecipe()
  if id ~= lastSelected then update() end
 else
  bar:Hide()
 end
end)
