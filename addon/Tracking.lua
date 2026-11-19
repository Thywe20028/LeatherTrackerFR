-- LeatherTracker FR 0.1.2 - mouse-driven tracking panel (experimental)
-- No fabricated map coordinates or vendor information.
local addon = CreateFrame("Frame")
local settings
local panel, content, followButton, basicButton, missingButton
local lastDisplayed, lastTracked
local function safe(fn, ...)
 if type(fn) ~= "function" then return nil end
 local ok, a, b = pcall(fn, ...)
 if ok then return a, b end
 return nil
end
local function itemName(id)
 if not id then return "Composant inconnu" end
 local name = C_Item and safe(C_Item.GetItemInfo, id)
 if not name then name = safe(_G.GetItemInfo, id) end
 if not name and C_Item and type(C_Item.GetItemNameByID) == "function" then
  name = safe(C_Item.GetItemNameByID, id)
 end
 if type(name) == "string" and name ~= "" then return name end
 return "Objet #"..id.." (nom en chargement)"
end
local function itemCount(id)
 if not id then return nil end
 local n = C_Item and safe(C_Item.GetItemCount, id, false)
 if type(n) ~= "number" then n = safe(GetItemCount, id, false) end
 return type(n) == "number" and n or nil
end
local function recipeFromUI()
 local p = _G.ProfessionsFrame
 if not p or not p.IsShown or not p:IsShown() then return nil end
 local page = p.CraftingPage
 local form = page and (page.SchematicForm or (page.Schematic and page.Schematic.SchematicForm))
 local info = form and safe(form.GetRecipeInfo, form)
 return type(info) == "table" and type(info.recipeID) == "number" and info.recipeID or nil
end
local function recipeData(id)
 local a = C_TradeSkillUI
 if type(a) ~= "table" or type(id) ~= "number" then return nil end
 if safe(a.IsDataSourceChanging) == true then return nil end
 local info = safe(a.GetRecipeInfo, id)
 local schematic = safe(a.GetRecipeSchematic, id, false)
 if type(schematic) ~= "table" then return nil end
 local name = type(info) == "table" and info.name or schematic.name
 local slots = schematic.reagentSlotSchematics
 local data = {id=id, name=name or ("Recette #"..id), reagents={}}
 if type(slots) == "table" then
  for _,slot in ipairs(slots) do
   if type(slot) == "table" then
    local qty = tonumber(slot.quantityRequired)
    local variants = type(slot.reagents) == "table" and slot.reagents or {}
    local first = variants[1]
    local itemID = type(first) == "table" and first.itemID or nil
    if qty and qty > 0 then
     data.reagents[#data.reagents+1] = {
      itemID=itemID, qty=qty, variants=#variants,
      type=slot.reagentType,
     }
    end
   end
  end
 end
 return data
end
local function button(parent, width, label)
 local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
 b:SetSize(width, 24)
 b:SetText(label)
 return b
end
local function redraw()
 if not settings or not panel or not panel:IsShown() then return end
 local selected = recipeFromUI()
 local tracked = settings.trackedRecipeID
 local id = tracked or selected
 local data = recipeData(id)
 if followButton.SetEnabled then followButton:SetEnabled(selected ~= nil or tracked ~= nil) end
 followButton:SetText(tracked and "Arreter le suivi" or "Suivre la recette")
 basicButton:SetText(settings.showBasics and "Bases : OUI" or "Bases : NON")
 missingButton:SetText(settings.onlyMissing and "Manquants : OUI" or "Manquants : NON")
 local lines = {"|cffffd100LeatherTracker FR|r"}
 if tracked then
  lines[#lines+1] = "Recette suivie : #"..tracked
 elseif selected then
  lines[#lines+1] = "Recette selectionnee : #"..selected
 else
  lines[#lines+1] = "Selectionnez une recette dans le metier."
 end
 if data then
  lines[#lines+1] = "|cffffffff"..data.name.."|r"
  if #data.reagents == 0 then lines[#lines+1] = "Composants indisponibles." end
  for _,r in ipairs(data.reagents) do
   local owned = itemCount(r.itemID)
   local missing = owned and math.max(0, r.qty-owned) or nil
   if not settings.onlyMissing or missing == nil or missing > 0 then
    local countText = owned and (owned.."/"..r.qty) or ("?/"..r.qty)
    local label = itemName(r.itemID)
    lines[#lines+1] = label.." : "..countText..(missing and (" (manque "..missing..")") or "")
    if r.variants > 1 then lines[#lines+1] = "  Plusieurs composants possibles ("..r.variants..")" end
   end
  end
 elseif id then
  lines[#lines+1] = "Informations de recette indisponibles."
 end
 lines[#lines+1] = ""
 if settings.showBasics then
  lines[#lines+1] = "|cff80d0ffRessources de base : activees|r"
  lines[#lines+1] = "Points de recolte en attente de donnees verifiees."
 else
  lines[#lines+1] = "Ressources de base : masquees."
 end
 if tracked then
  lines[#lines+1] = "Carte : filtre sur la recette suivie (prevu)."
 else
  lines[#lines+1] = "Carte : aucun suivi de recette actif."
 end
 lines[#lines+1] = "Aucun emplacement de recolte verifie importe."
 content:SetText(table.concat(lines, "\n"))
 lastDisplayed = id
end
local function createPanel()
 if panel then return end
 panel = CreateFrame("Frame", "LeatherTrackerFRPanel", UIParent)
 panel:SetSize(340, 390)
 panel:SetFrameStrata("HIGH")
 panel:SetClampedToScreen(true)
 panel:SetMovable(true)
 panel:EnableMouse(true)
 panel:RegisterForDrag("LeftButton")
 panel:SetScript("OnDragStart", panel.StartMoving)
 panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
 local bg = panel:CreateTexture(nil, "BACKGROUND")
 bg:SetAllPoints()
 bg:SetColorTexture(0.06, 0.08, 0.12, 0.95)
 local border = panel:CreateTexture(nil, "BORDER")
 border:SetPoint("TOPLEFT", 1, -1)
 border:SetPoint("TOPRIGHT", -1, -1)
 border:SetHeight(2)
 border:SetColorTexture(0.85, 0.65, 0.15, 1)
 local close = button(panel, 24, "X")
 close:SetPoint("TOPRIGHT", -8, -8)
 close:SetScript("OnClick", function() panel:Hide() end)
 followButton = button(panel, 150, "Suivre la recette")
 followButton:SetPoint("TOPLEFT", 12, -36)
 followButton:SetScript("OnClick", function()
  local selected = recipeFromUI()
  if selected and settings.trackedRecipeID ~= selected then
   settings.trackedRecipeID = selected
  else
   settings.trackedRecipeID = nil
  end
  redraw()
 end)
 basicButton = button(panel, 130, "Bases : OUI")
 basicButton:SetPoint("TOPLEFT", 12, -66)
 basicButton:SetScript("OnClick", function()
  settings.showBasics = not settings.showBasics
  redraw()
 end)
 missingButton = button(panel, 170, "Manquants : OUI")
 missingButton:SetPoint("TOPLEFT", 12, -96)
 missingButton:SetScript("OnClick", function()
  settings.onlyMissing = not settings.onlyMissing
  redraw()
 end)
 local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT", 12, -132)
 scroll:SetPoint("BOTTOMRIGHT", -30, 14)
 local inner = CreateFrame("Frame", nil, scroll)
 inner:SetSize(290, 700)
 scroll:SetScrollChild(inner)
 content = inner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
 content:SetPoint("TOPLEFT", 0, 0)
 content:SetWidth(285)
 content:SetJustifyH("LEFT")
 content:SetJustifyV("TOP")
 panel:SetScript("OnShow", redraw)
 panel:Hide()
end
local toggle
local function togglePanel()
 createPanel()
 if panel:IsShown() then panel:Hide()
 else
  panel:ClearAllPoints()
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  panel:Show()
 end
end
SLASH_LEATHERTRACKERPANEL1 = "/ltpanel"
SlashCmdList.LEATHERTRACKERPANEL = togglePanel
local function attach()
 local p = _G.ProfessionsFrame
 if not p then return end
 if not toggle then
  toggle = button(p, 125, "LeatherTracker")
  toggle:SetPoint("TOPLEFT", p, "TOPLEFT", 100, -42)
  toggle:SetFrameLevel(p:GetFrameLevel()+20)
  toggle:Show()
  toggle:SetScript("OnClick", togglePanel)
 end
 if toggle and not toggle:IsShown() and p:IsShown() then toggle:Show() end
 if panel and panel:IsShown() then redraw() end
end
local function initialize()
 if settings then return end
 LeatherTrackerFRDB = type(LeatherTrackerFRDB) == "table" and LeatherTrackerFRDB or {}
 settings = LeatherTrackerFRDB
 if type(settings.showBasics) ~= "boolean" then settings.showBasics = true end
 if type(settings.onlyMissing) ~= "boolean" then settings.onlyMissing = true end
 if type(settings.trackedRecipeID) ~= "number" then settings.trackedRecipeID = nil end
 createPanel()
 attach()
end
-- The slash command is registered at file load; this event confirms module execution.
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("GET_ITEM_INFO_RECEIVED")
addon:SetScript("OnEvent", function(_, event)
 if event == "PLAYER_LOGIN" then initialize()
 elseif event == "ADDON_LOADED" then
  if not settings and IsLoggedIn and IsLoggedIn() then initialize() end
  if settings then attach() end
 elseif settings and (event == "BAG_UPDATE_DELAYED" or event == "GET_ITEM_INFO_RECEIVED") then
  redraw()
 end
end)
local elapsed = 0
addon:SetScript("OnUpdate", function(_, dt)
 if not settings then return end
 elapsed = elapsed + dt
 if elapsed < 0.65 then return end
 elapsed = 0
 if _G.ProfessionsFrame and _G.ProfessionsFrame:IsShown() then attach() end
 if panel and panel:IsShown() then
  local id = recipeFromUI()
  if id ~= lastTracked or (settings.trackedRecipeID or id) ~= lastDisplayed then
   lastTracked = id
   redraw()
  end
 end
end)
