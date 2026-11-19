-- LeatherTracker FR 0.2.3 - ForeverCore native profession side tab.
-- Requires ForeverCore ProfessionTabs API minor >= 2.
local addon = CreateFrame("Frame")
local KEY = "leathertrackerfr"
local page, detail, follow, basics, missing, header, subtitle, sectionButtons = nil, nil, nil, nil, nil, nil, nil, {}
local currentSection = "recipe"
local sectionNames = {recipe="Suivi de recette",materials="Materiaux",sources="Sources et zones",map="Carte MelloUI"}
local sectionOrder = {"recipe","materials","sources","map"}
local lines = {}
local db, registered, lastRecipe, elapsed = nil, false, nil, 0
local selectedCache, selectedNameCache

local function safe(fn, ...)
 if type(fn) ~= "function" then return nil end
 local ok, value = pcall(fn, ...)
 if ok then return value end
 return nil
end

local function recipeInfo(id)
 if not id or not C_TradeSkillUI then return nil end
 return safe(C_TradeSkillUI.GetRecipeInfo, id)
end

local function validRecipeID(id)
 return type(id) == "number" and id > 0
end

local function clearSelection()
 selectedCache, selectedNameCache = nil, nil
end

local function captureSelection(frame)
 local api = C_TradeSkillUI
 if not frame or not frame:IsVisible() or (api and safe(api.IsDataSourceChanging) == true) then
  clearSelection()
  return
 end

 local crafting = frame.CraftingPage
 -- ForeverCore hides Fabrication when displaying the LeatherTracker page.
 if not crafting or not crafting:IsVisible() then return end
 local form = crafting.SchematicForm or (crafting.Schematic and crafting.Schematic.SchematicForm)
 local info = form and safe(form.GetRecipeInfo, form)
 local id = type(info) == "table" and info.recipeID
 if not validRecipeID(id) then
  id = api and safe(api.GetSelectedRecipeID)
  info = validRecipeID(id) and recipeInfo(id)
 end

 if validRecipeID(id) then
  selectedCache = id
  selectedNameCache = type(info) == "table" and info.name or nil
 else
  clearSelection()
 end
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
 local selected, selectedName = selectedCache, selectedNameCache
 local id = db.trackedRecipeID or selected
 local info = id and recipeInfo(id)
 local recipeName = (type(info) == "table" and info.name) or (id == selected and selectedName) or (id and ("Recette #"..id))
 header:SetText(sectionNames[currentSection])
 subtitle:SetText(recipeName and (recipeName .. (db.trackedRecipeID and "  |cff88ff88(Suivi actif)|r" or "  |cffcccccc(Apercu)|r")) or "Selectionnez une recette dans Fabrication.")
 for _, label in ipairs(lines) do label:Hide() end
 local n=0
 local function add(text)
  n=n+1
  if n>8 then return end
  local label=lines[n]
  if not label then
   label=page:CreateFontString(nil,"OVERLAY","GameFontHighlight")
   label:SetPoint("TOPLEFT",page,"TOPLEFT",35,-170-(n-1)*34)
   label:SetWidth(730)
   label:SetJustifyH("LEFT")
   lines[n]=label
  end
  label:SetText(text)
  label:Show()
 end
 if currentSection=="recipe" or currentSection=="materials" then
  local schematic = id and C_TradeSkillUI and safe(C_TradeSkillUI.GetRecipeSchematic,id,false)
  local slots=type(schematic)=="table" and schematic.reagentSlotSchematics
  local found=false
  if type(slots)=="table" then
   for _, slot in ipairs(slots) do
    local reagent=type(slot.reagents)=="table" and slot.reagents[1]
    local itemID=reagent and reagent.itemID
    local required=tonumber(slot.quantityRequired)
    if itemID and required and required>0 then
     found=true
     local owned=itemCount(itemID)
     local deficit=owned and math.max(0,required-owned) or nil
     if not db.onlyMissing or deficit==nil or deficit>0 then
      add(itemName(itemID).."  |  "..(owned or "?").." / "..required..
       (deficit and ("  |  manquant : "..deficit) or ""))
     end
    end
   end
  end
  if not found then add("Composants indisponibles : selectionnez une recette dans Fabrication.") end
 elseif currentSection=="sources" then
  add("Creatures, marchands, zones et taux de butin")
  add("Aucune base de sources verifiee n'a encore ete importee.")
  add("Les taux inconnus ne sont pas inventes.")
 elseif currentSection=="map" then
  local m=_G.MelloUI and _G.MelloUI.Map
  add("MelloUI Map : "..(m and "API detectee" or "non detectee"))
  add("Aucun point de recolte verifie importe.")
  add("Les futurs reperes seront filtres par recette suivie.")
  add("Materiaux de base : "..(db.showBasics and "affiches" or "masques"))
 end
 for _, section in ipairs(sectionOrder) do
  if sectionButtons[section] then sectionButtons[section]:SetText((section==currentSection and "[ " or "")..sectionNames[section]..(section==currentSection and " ]" or "")) end
 end
 follow:SetText(db.trackedRecipeID and "Arreter le suivi" or "Suivre la recette")
 follow:SetEnabled(db.trackedRecipeID~=nil or selectedCache~=nil)
 basics:SetText(db.showBasics and "Bases : OUI" or "Bases : NON")
 missing:SetText(db.onlyMissing and "Manquants : OUI" or "Manquants : NON")
 lastRecipe=selected
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
 page:EnableMouse(false)
 local backdrop=page:CreateTexture(nil,"BACKGROUND")
 backdrop:SetPoint("TOPLEFT",page,"TOPLEFT",12,-76)
 backdrop:SetPoint("BOTTOMRIGHT",page,"BOTTOMRIGHT",-12,42)
 backdrop:SetColorTexture(0.075,0.07,0.065,0.97)
 local accent=page:CreateTexture(nil,"BORDER")
 accent:SetPoint("TOPLEFT",page,"TOPLEFT",28,-120)
 accent:SetPoint("TOPRIGHT",page,"TOPRIGHT",-28,-120)
 accent:SetHeight(2)
 accent:SetColorTexture(0.7,0.47,0.17,1)
 header=page:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 header:SetPoint("TOPLEFT",page,"TOPLEFT",30,-90)
 subtitle=page:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 subtitle:SetPoint("TOPLEFT",page,"TOPLEFT",30,-133)
 subtitle:SetWidth(740)
 subtitle:SetJustifyH("LEFT")
 local widths={150,112,140,128}
 local offsets={30,186,304,450}
 for i,section in ipairs(sectionOrder) do
  local b=makeButton(page,sectionNames[section],widths[i],offsets[i],-410)
  b:SetScript("OnClick",function() currentSection=section;refresh() end)
  sectionButtons[section]=b
 end
 follow=makeButton(page,"Suivre la recette",170,30,-455)
 basics=makeButton(page,"Bases : OUI",125,208,-455)
 missing=makeButton(page,"Manquants : OUI",150,340,-455)
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
 -- Only clear the preview on close. ForeverCore still owns native navigation.
 frame:HookScript("OnHide", clearSelection)
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
 else
  captureSelection(_G.ProfessionsFrame)
  tabs.Select(KEY)
 end
end

SLASH_LEATHERTRACKERSTATUS1 = "/ltstatus"
SlashCmdList.LEATHERTRACKERSTATUS = function()
 local tabs = _G.ForeverCore and _G.ForeverCore.ProfessionTabs
 print("LeatherTracker 0.2.3 | ProfessionsFrame="..tostring(_G.ProfessionsFrame ~= nil)..
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
  if page and page:IsVisible() then refresh() end
 end
end)
addon:SetScript("OnUpdate", function(_, dt)
 if not registered then
  elapsed = elapsed + dt
  if elapsed < 1 then return end
  elapsed = 0
  register()
  if not registered then return end
 end
 -- Sample before switching tabs, without changing the client's recipe selection.
 captureSelection(_G.ProfessionsFrame)
 if page:IsVisible() and selectedCache ~= lastRecipe then refresh() end
end)
