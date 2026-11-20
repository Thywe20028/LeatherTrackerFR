-- LeatherTracker FR 0.1.1 - diagnostic reader for WoW Forever
-- Read-only: never changes Blizzard recipe selection.
local addonName = ...
local api = C_TradeSkillUI
local frame = CreateFrame("Frame", "LeatherTrackerFRWindow", UIParent)
frame:SetSize(520, 440)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.06, 0.08, 0.12, 0.96)
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("LeatherTracker FR - Diagnostic")
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -4, -4)
local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 16, -50)
scroll:SetPoint("BOTTOMRIGHT", -34, 18)
local body = CreateFrame("Frame", nil, scroll)
body:SetSize(460, 1000)
scroll:SetScrollChild(body)
local output = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
output:SetPoint("TOPLEFT", 0, 0)
output:SetWidth(455)
output:SetJustifyH("LEFT")
output:SetJustifyV("TOP")
output:SetText("Ouvrez un metier et selectionnez une recette. /ltfr help")
local function show(s)
 output:SetText(tostring(s or ""))
 body:SetHeight(math.max(380, output:GetStringHeight() + 25))
 frame:Show()
end
local function call(fn, ...)
 if type(fn) ~= "function" then return nil end
 local ok, a, b, c = pcall(fn, ...)
 if ok then return a, b, c end
 return nil
end
local function getApi()
 return type(C_TradeSkillUI) == "table" and C_TradeSkillUI or nil
end
local function changing()
 local a = getApi()
 return a and call(a.IsDataSourceChanging) == true
end
local function fromSchematicForm()
 local p = _G.ProfessionsFrame
 if not p or not p.IsShown or not p:IsShown() then return nil, "Fenetre Professions fermee" end
 local page = p.CraftingPage
 local form = page and (page.SchematicForm or (page.Schematic and page.Schematic.SchematicForm))
 if not form then return nil, "SchematicForm introuvable" end
 local info = call(form.GetRecipeInfo, form)
 if type(info) == "table" and type(info.recipeID) == "number" then
  return info.recipeID, "ProfessionsFrame.CraftingPage.SchematicForm"
 end
 return nil, "SchematicForm:GetRecipeInfo sans recipeID"
end
local function fromSelectedAPI()
 local a = getApi()
 local id = a and call(a.GetSelectedRecipeID)
 if type(id) == "number" and id > 0 then return id, "GetSelectedRecipeID" end
 return nil
end
local function findRecipe()
 if changing() then return nil, "Changement de metier en cours" end
 local id, source = fromSchematicForm()
 if id then return id, source end
 id, source = fromSelectedAPI()
 if id then return id, source end
 return nil, source or "Selection indisponible"
end
local function bagCount(itemID)
 if not itemID then return nil end
 local n
 if C_Item then n = call(C_Item.GetItemCount, itemID, false) end
 if type(n) ~= "number" then n = call(_G.GetItemCount, itemID, false) end
 if type(n) == "number" then return n end
 return nil
end
local lastRecipeID
local function readRecipe(recipeID, origin)
 local a = getApi()
 if not a then return "C_TradeSkillUI indisponible." end
 if changing() then return "Donnees en cours de chargement : reessayez." end
 if type(recipeID) ~= "number" or recipeID <= 0 then return "Identifiant de recette invalide." end
 local info = call(a.GetRecipeInfo, recipeID)
 local schematic = call(a.GetRecipeSchematic, recipeID, false)
 if type(schematic) ~= "table" then
  return "GetRecipeSchematic n'a retourne aucune structure pour #"..recipeID
 end
 local name = (type(info) == "table" and info.name) or schematic.name or ("Recette #"..recipeID)
 local lines = {"Recette : "..tostring(name), "ID : "..recipeID.." | source : "..tostring(origin or "manuel"), ""}
 local slots = schematic.reagentSlotSchematics
 if type(slots) ~= "table" then return table.concat(lines, "\n").."Aucun reagentSlotSchematics disponible." end
 local count = 0
 for _, slot in ipairs(slots) do
  if type(slot) == "table" then
   local reagents = slot.reagents
   local reagent = type(reagents) == "table" and reagents[1] or nil
   local id = type(reagent) == "table" and reagent.itemID or nil
   local qty = tonumber(slot.quantityRequired)
   local basic = (slot.reagentType == nil or slot.reagentType == 1)
   if basic and qty and qty > 0 then
    count = count + 1
    local nameItem
    if id then
     nameItem = (C_Item and call(C_Item.GetItemInfo, id)) or call(_G.GetItemInfo, id)
     if type(nameItem) ~= "string" or nameItem == "" then
      nameItem = "Objet #"..id.." (nom indisponible)"
     end
    else nameItem = "Composant sans itemID" end
    local n = bagCount(id)
    local text = tostring(nameItem).." : "..qty
    if n then text = text.." | sacs : "..n.." | manque : "..math.max(0, qty-n)
    else text = text.." | sacs : inconnu" end
    if type(reagents) == "table" and #reagents > 1 then text = text.." | alternatives : "..#reagents end
    lines[#lines+1] = text
   end
  end
 end
 if count == 0 then lines[#lines+1] = "Aucun composant obligatoire reconnu ; structure a diagnostiquer." end
 lastRecipeID = recipeID
 return table.concat(lines, "\n")
end
local function scan()
 local id, source = findRecipe()
 if not id then
  return "Recette non detectee : "..tostring(source).."\nUtilisez /ltfr debug ou /ltfr id NUMERO pour tester."
 end
 return readRecipe(id, source)
end
local function status()
 local a = getApi() or {}
 local keys = {"GetSelectedRecipeID","GetRecipeInfo","GetRecipeSchematic","GetFilteredRecipeIDs","GetAllRecipeIDs","IsDataSourceChanging","GetTradeSkillLineForRecipe"}
 local lines = {"API WoW Forever (presence uniquement) :"}
 for _, k in ipairs(keys) do lines[#lines+1] = k.." : "..(type(a[k]) == "function" and "oui" or "non") end
 lines[#lines+1] = "MelloUI.Map:AddPin : "..((_G.MelloUI and _G.MelloUI.Map and type(_G.MelloUI.Map.AddPin) == "function") and "oui" or "non")
 lines[#lines+1] = "Auctionator : "..(type(_G.Auctionator) == "table" and "charge" or "absent")
 return table.concat(lines, "\n")
end
local function debugInfo()
 local p = _G.ProfessionsFrame
 local form = p and p.CraftingPage and p.CraftingPage.SchematicForm
 local id, source = findRecipe()
 local a = getApi()
 local filtered = a and call(a.GetFilteredRecipeIDs)
 local lines = {"Diagnostic selection (aucune modification du jeu) :",
  "ProfessionsFrame : "..(p and "present" or "absent"),
  "Fenetre visible : "..(p and p.IsShown and tostring(p:IsShown()) or "non"),
  "CraftingPage : "..(p and p.CraftingPage and "oui" or "non"),
  "SchematicForm : "..(form and "oui" or "non"),
  "GetRecipeInfo sur form : "..(form and type(form.GetRecipeInfo) or "absent"),
  "IsDataSourceChanging : "..tostring(changing()),
  "Recette ID : "..tostring(id),
  "Source : "..tostring(source),
  "Recettes filtrees : "..(type(filtered) == "table" and tostring(#filtered) or "inconnu")}
 return table.concat(lines, "\n")
end
SLASH_LEATHERTRACKERFR1 = "/ltfr"
SlashCmdList.LEATHERTRACKERFR = function(msg)
 local action, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
 if action == "" then SlashCmdList.LEATHERTRACKERPANEL()
 elseif action == "api" then show(status())
 elseif action == "debug" then show(debugInfo())
 elseif action == "scan" then show(scan())
 elseif action == "id" then
  local id = tonumber(arg)
  show(id and readRecipe(id, "identifiant manuel") or "Syntaxe : /ltfr id 12345")
 elseif action == "refresh" then
  show(lastRecipeID and readRecipe(lastRecipeID, "derniere recette") or "Aucune recette precedente.")
 else show("Commandes : /ltfr scan | /ltfr api | /ltfr debug | /ltfr id NUMERO | /ltfr refresh\nOuvrez Travail du cuir et cliquez sur une recette.") end
end
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", function(_, event)
 if frame:IsShown() and lastRecipeID then
  show(readRecipe(lastRecipeID, event == "GET_ITEM_INFO_RECEIVED" and "chargement des objets" or "actualisation des sacs"))
 end
end)
