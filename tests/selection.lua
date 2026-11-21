-- Run from the repository root: texlua tests/selection.lua
local frames = {}
local function noop() end
local children = {}
local function frame(parent)
 local widget = {shown = true, scripts = {}, text = "", parent = parent}
 children[widget] = {}
 if parent then table.insert(children[parent], widget) end
 setmetatable(widget, {__index = function() return noop end})
 function widget:SetPoint(...) self.point = {...} end
 function widget:SetCustomOnMouseUpHandler(handler) self.mouseUp = handler end
 function widget:GetScript(event) return self.scripts[event] end
 function widget:SetScript(event, callback) self.scripts[event] = callback end
 function widget:HookScript(event, callback)
  local previous = self.scripts[event] or noop
  self.scripts[event] = function(...) previous(...); callback(...) end
 end
 function widget:SetHeight(value) self.height = value end
 function widget:SetTexture(value) self.texture = value end
 function widget:GetRight() return rawget(self, "right") or 180 end
 function widget:GetAlpha() return rawget(self, "alpha") or 1 end
 function widget:SetAlpha(value) self.alpha = value end
 function widget:GetFrameStrata() return "MEDIUM" end
 function widget:GetWidth() return rawget(self, "simulatedWidth") or 650 end
 function widget:HasFocus() return false end
 function widget:GetParent() return self.parent end
 function widget:GetFrameLevel() return 1 end
 function widget:SetShown(value) if value then self:Show() else self:Hide() end end
 function widget:IsShown() return self.shown end
 function widget:IsVisible() return self.shown and (not parent or parent:IsVisible()) end
 function widget:Show()
  self.shown = true
  local function notifyShow(widget)
   if widget.scripts.OnShow then widget.scripts.OnShow() end
   for _, child in ipairs(children[widget]) do
    if child:IsShown() then notifyShow(child) end
   end
  end
  if self:IsVisible() then notifyShow(self) end
 end
 local function notifyHide(widget)
  if widget.scripts.OnHide then widget.scripts.OnHide() end
  for _, child in ipairs(children[widget]) do
   if child:IsShown() then notifyHide(child) end
  end
 end
 function widget:Hide()
  local visible = self:IsVisible()
  self.shown = false
  if visible then notifyHide(self) end
 end
 function widget:GetVerticalScrollRange() return 0 end
 function widget:GetVerticalScroll() return rawget(self, "scrollOffset") or 0 end
 function widget:SetVerticalScroll(offset) self.scrollOffset = offset end
 function widget:SetMaxLines(count) self.maxLines = count end
 function widget:SetText(value) self.text = value end
 function widget:GetText() return self.text end
 function widget:SetEnabled(value) self.enabled = value end
 function widget:CreateFontString() return frame(self) end
 function widget:CreateTexture() return frame(self) end
 return widget
end

function CreateFrame(kind, name, parent, template)
 assert(template ~= "BackdropTemplate", "Simulation : BackdropTemplate indisponible")
 local widget = frame(parent)
 frames[#frames + 1] = widget
 if kind == "CheckButton" then
  local createFontString = widget.CreateFontString
  function widget:CreateFontString()
   local caption = createFontString(self)
   caption.checkControl = self
   frames[#frames + 1] = caption
   return caption
  end
 end
 if template == "BasicFrameTemplateWithInset" then widget.TitleText = widget:CreateFontString() end
 if template == "LargeSideTabButtonTemplate" then widget.Icon = widget:CreateTexture() end
 if name then _G[name] = widget end
 return widget
end

SlashCmdList = {}
local callbacks = {}
EventRegistry = {RegisterCallback = function(_, event, callback) callbacks[event] = callback end}
ProfessionsFrame = frame()
local firstNative, lastNative = frame(ProfessionsFrame), frame(ProfessionsFrame)
ProfessionsFrame.ProfessionsOverviewTab = false
ProfessionsFrame.rightProfessionTabs = {firstNative, lastNative}
local crafting = frame(ProfessionsFrame)
ProfessionsFrame.CraftingPage = crafting
ProfessionsFrame.Pages = {crafting}
ProfessionsFrame.BookPage, ProfessionsFrame.SpecPage, ProfessionsFrame.OrdersPage = false, false, false
crafting:SetAlpha(0.75)
local title = ProfessionsFrame:CreateFontString()
title:SetText("Cuisine")
function title:GetText() return self.text end
ProfessionsFrame.TitleContainer = {TitleText = title}
local openedProfession, openedRecipe
C_TradeSkillUI = {
 OpenTradeSkill = function(id) openedProfession = id end,
 GetProfessionInfoByRecipeID = function() return {professionID = 165} end,
 GetAllRecipeIDs = function() return {100, 101} end,
 GetRecipeInfo = function(id) return {name = "Recette de test "..id, learned = id == 100} end,
 GetRecipeSchematic = function(id)
  return {reagentSlotSchematics = {{quantityRequired = id == 100 and 2 or 4, reagents = {{itemID = 6471}}}}}
 end,
 OpenRecipe = function(id) openedRecipe = id end,
}
local function button(text)
 for _, widget in ipairs(frames) do
  if widget.text == text and widget:IsVisible() then
   return rawget(widget, "checkControl") or widget
  end
 end
 error("Bouton visible introuvable : "..text)
end
UIParent = frame()
local newEventIndex = #frames + 1
local inBags = 2
C_Container = {
 GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end,
 GetContainerItemInfo = function() return {itemID = 6471, stackCount = inBags} end,
}
local profession = ProfessionsFrame
local portrait = profession:CreateTexture()
function profession:GetPortrait() return portrait end
function profession:GetTitleText() return title end
local reagent = frame(crafting)
reagent.Name = frame(reagent)
reagent.Name.right = 154
reagent.Button = frame(reagent)
reagent.Button.right = 40
reagent.Checkbox, reagent.Checkmark = false, false
reagent.Name:SetText("Un composant au nom particulièrement long")
function reagent:GetReagentSlotSchematic()
 return {quantityRequired = 10, reagents = {{itemID = 6471}}}
end
local second = frame(crafting)
second.Name, second.Button = frame(second), frame(second)
second.Name:SetText("Un deuxième ingrédient au nom encore plus long")
second.Name.right, second.Button.right = 154, 40
second.Checkbox, second.Checkmark = false, false
function second:GetReagentSlotSchematic()
 return {quantityRequired = 2, reagents = {{itemID = 2321}}}
end
crafting.SchematicForm = {
 IsVisible = function() return true end,
 GetRecipeInfo = function() return {recipeID = 100} end,
 GetSlots = function() return {reagent, second} end,
}
local namespace = {}
assert(loadfile("addon/SourceData.lua"))("LeatherTrackerFR", namespace)
namespace.importedSources[6471] = {
 {name = "Marchand de test", method = "Achat", provenance = "Jeu simulé"},
}
ForeverDB_Saved = {sources = {
 specimen = {name = "Créature de test", sourceLevel = 19, buckets = {
  skinning = {observations = 8, items = {["6471"] = {itemId = 6471, drops = 2}}},
 }},
}}
assert(loadfile("addon/ComponentData.lua"))("LeatherTrackerFR", namespace)
local collectionSource = assert(io.open("addon/Collection.lua"))
local chunk = assert((loadstring or load)(collectionSource:read("*a") .. [[

local count = 0
for index = 1, debug.getinfo(refresh, "u").nups do
 if debug.getupvalue(refresh, index) ~= "_ENV" then count = count + 1 end
end
assert(count <= 60, "Ma collecte doit respecter la limite de 60 upvalues de Lua 5.1")
]], "@addon/Collection.lua"))
collectionSource:close()
chunk("LeatherTrackerFR", namespace)
local collectionEvents = frames[newEventIndex].scripts
local trackingIndex = #frames + 1
dofile("addon/Tracking.lua")
local trackingEvents = frames[trackingIndex].scripts
LeatherTrackerFRDB = {recipes = {[42] = 2}}
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
trackingEvents.OnEvent(nil, "PLAYER_LOGIN")
local tab = assert(LeatherTrackerFRProfessionTab)
assert(tab.point[2] == lastNative)
lastNative:Hide()
callbacks["ProfessionsFrame.TabSet"]()
assert(tab.point[2] == firstNative)
lastNative:Show()
callbacks["ProfessionsFrame.Show"]()
assert(tab.point[2] == lastNative)
assert(not SlashCmdList.LEATHERTRACKERLEGACY and not SLASH_LEATHERTRACKERLEGACY1)
assert(LeatherTrackerFRDB.recipes[42] == 2)
collectionEvents.OnUpdate(nil, 0.2)
local plus = button("+")
assert(plus.parent == reagent and plus.point[1] == "RIGHT")
local aligned
for _, widget in ipairs(frames) do
 if widget.parent == second and widget.text == "+" then aligned = widget end
end
assert(aligned and aligned.point[1] == plus.point[1] and aligned.point[4] == plus.point[4])
plus.scripts.OnClick(plus)
assert(not LeatherTrackerCollection, "Ajouter ne crée ni n’ouvre la page")
assert(plus.text == "-" and LeatherTrackerFRDB.collection.goals[6471] == 10)
plus.scripts.OnClick(plus)
assert(plus.text == "+" and not LeatherTrackerFRDB.collection.goals[6471])
reagent.right = 174
collectionEvents.OnUpdate(nil, 0.2)
assert(plus:IsShown() and plus.point[1] == "LEFT" and plus.point[3] == "RIGHT",
 "Le bouton reste accessible après le bord de la ligne quand la place intérieure manque")
reagent.right = 180
collectionEvents.OnUpdate(nil, 0.2)
plus.scripts.OnClick(plus)
assert(LeatherTrackerFRDB.collection.goals[6471] == 10)
local getRecipeInfo = crafting.SchematicForm.GetRecipeInfo
crafting.SchematicForm.GetRecipeInfo = function() error("Métier en transition") end
tab.mouseUp(tab, "LeftButton")
crafting.SchematicForm.GetRecipeInfo = getRecipeInfo
assert(not openedProfession and not LeatherTrackerFRProfessionPage)
local collectionPanel = LeatherTrackerCollection
assert(collectionPanel:IsVisible() and collectionPanel:GetParent() == profession)
assert(crafting:GetAlpha() == 0 and crafting:IsShown(), "Fabrication est masquée sans fermeture")
local exported = namespace.ExportLeatherworkingRecipes()
assert(exported:find("2 recettes", 1, true))
local export = LeatherTrackerFRDB.recipeExport
assert(export.professionID == 165 and export.recipes[1].learned and export.recipes[2].learned == false)
assert(export.recipes[1].slots[1].quantity == 2 and export.recipes[1].slots[1].items[1] == 6471)
local status
for _, widget in ipairs(frames) do
 if widget.status and type(widget.status) == "table" and widget.status.text:find("2 / 10 en sac", 1, true) then
  status = widget.status
 end
end
assert(status)
inBags = 10
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(status.text:find("Objectif atteint", 1, true))
inBags = 4
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(status.text:find("6 manquants", 1, true))
button("Sources").scripts.OnClick()
assert(collectionPanel.SourceCounts.text:find("Manquant : 6", 1, true))
local function filterSources(query)
 local field = collectionPanel.SourceSearch
 field:SetText(query)
 field.scripts.OnTextChanged(field)
end
local function sourceDetails()
 for _, widget in ipairs(frames) do
  if type(rawget(widget, "Info")) == "table" and widget:IsVisible() then return widget end
 end
 error("Aucune fiche source visible")
end
assert(collectionPanel.SourcePrevious.Arrow.texture:find("Gauche.tga", 1, true))
assert(collectionPanel.SourceNext.Arrow.texture:find("Droite.tga", 1, true))
assert(collectionPanel.SourcePickerButton.text == "Mes suivis")
assert(collectionPanel.SourceRecipes:IsVisible())
collectionPanel.SourceRecipes.scripts.OnClick()
assert(button("Ceinture en écailles de déviant").Status.text:find("Documentée", 1, true))
local recipe = button("Recette de test 100")
assert(recipe.Status.text:find("Apprise", 1, true) and recipe.Icon.texture)
recipe.scripts.OnClick()
assert(collectionPanel.RecipeIngredients.text:find("Composants nécessaires", 1, true))
local ingredientRow = collectionPanel.RecipeIngredientRows[1]
assert(ingredientRow.item == 6471 and ingredientRow.Count.text == "4 / 2")
assert(recipe.Amount.text == "× 2")
assert(not collectionPanel.RecipeFollow.enabled)
inBags = 1
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(ingredientRow.Count.text == "1 / 2" and not collectionPanel.RecipeFollow.enabled)
LeatherTrackerFRDB.collection.goals[6471] = nil
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(collectionPanel.RecipeFollow.enabled)
collectionPanel.RecipeFollow.scripts.OnClick()
assert(LeatherTrackerFRDB.collection.goals[6471] == 2)
LeatherTrackerFRDB.collection.goals[6471], inBags = 10, 4
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
local query = collectionPanel.RecipeSearch
query:SetText("101")
query.scripts.OnTextChanged(query)
assert(button("Recette de test 101"):IsVisible())
query:SetText("")
query.scripts.OnTextChanged(query)
button("Voir dans Fabrication").scripts.OnClick()
assert(openedRecipe == 100 and not collectionPanel:IsVisible())
tab.mouseUp(tab, "LeftButton", true)
collectionPanel.SourcesTab.scripts.OnClick()
collectionPanel.SourceRecipes.scripts.OnClick()
local places = collectionPanel.SourcePlaces
local sourceState = LeatherTrackerFRDB.collection.sourceViews[6471]
places.Method.scripts.OnClick()
assert(sourceState.methodsFolded and not sourceState.locationsFolded)
assert(places.Method.ToggleMark.texture:find("Plus.tga", 1, true) and places.Location.ToggleMark.texture:find("Moins.tga", 1, true))
places.Location.scripts.OnClick()
assert(sourceState.locationsFolded and places.Location.ToggleMark.texture:find("Plus.tga", 1, true))
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
assert(places.Method.ToggleMark.texture:find("Plus.tga", 1, true) and places.Location.ToggleMark.texture:find("Plus.tga", 1, true))
places.Method.scripts.OnClick()
places.Location.scripts.OnClick()
assert(not sourceState.methodsFolded and not sourceState.locationsFolded)
assert(places.Scroll ~= collectionPanel.Catalog.Scroll)
places.Scroll:SetVerticalScroll(12)
collectionPanel.Catalog.Scroll:SetVerticalScroll(28)
assert(places.Scroll:GetVerticalScroll() == 12 and collectionPanel.Catalog.Scroll:GetVerticalScroll() == 28)
local firstRow = {}
for _, widget in ipairs(frames) do
 if type(rawget(widget, "Info")) == "table" and widget:IsVisible() then
  firstRow[#firstRow + 1] = widget
 end
end
local resultScroll = firstRow[1]:GetParent():GetParent()
assert(resultScroll ~= places.Scroll)
resultScroll:SetVerticalScroll(21)
assert(places.Scroll:GetVerticalScroll() == 12)
assert(#firstRow >= 3 and firstRow[1].point[3] == firstRow[2].point[3]
 and firstRow[1].point[2] ~= firstRow[2].point[2] and firstRow[3].point[3] < firstRow[1].point[3])
local results = firstRow[1]:GetParent()
results.simulatedWidth = 370
filterSources("")
assert(firstRow[1].point[2] == firstRow[2].point[2] and firstRow[2].point[3] < firstRow[1].point[3])
results.simulatedWidth = nil
filterSources("Créature de test")
local sampledHeight = sourceDetails().height
local observed = sourceDetails().RateBox
assert(observed:IsVisible() and observed.Value.text == "25,0 %"
 and observed.Sample.text == "2 obtention(s) sur 8 observations")
filterSources("Marchand de test")
assert(sourceDetails().height < sampledHeight)
assert(sourceDetails().Info.text:find("Jeu simulé", 1, true))
button("Options").scripts.OnClick()
assert(collectionPanel.MapSettings:IsVisible() and not collectionPanel.SourceCounts:IsVisible())
button("Retour à la source").scripts.OnClick()
assert(not collectionPanel.MapSettings:IsVisible() and collectionPanel.SourceCounts:IsVisible())
assert(collectionPanel.SourceCounts.text:find("Manquant : 6", 1, true))
assert(sourceDetails().Info.text:find("Jeu simulé", 1, true))
button("<").scripts.OnClick()
assert(status:IsVisible())
button("Options").scripts.OnClick()
assert(collectionPanel.MapSettings:IsVisible() and not status:IsVisible())
button("Verrouiller la position").scripts.OnClick()
assert(LeatherTrackerFRDB.collection.locked)
button("Retour à ma collecte").scripts.OnClick()
assert(not collectionPanel.MapSettings:IsVisible() and status:IsVisible())
local schematicBefore = crafting.SchematicForm
button("Fabrication").scripts.OnClick()
assert(not collectionPanel:IsShown() and crafting:GetAlpha() == 0.75)
assert(crafting.SchematicForm == schematicBefore and crafting:IsShown())
for _, name in ipairs({"Travail du cuir", "Cuisine", "Dépeçage"}) do
 title:SetText(name)
 portrait:SetTexture(name)
 LeatherTrackerToggleCollection()
 assert(title:GetAlpha() == 0 and portrait:GetAlpha() == 0)
 title:SetText(name.." actualisé")
 portrait:SetTexture(name.." actualisé")
 callbacks["Professions.ProfessionSelected"]()
 callbacks["ProfessionsFrame.TabSet"]()
 assert(collectionPanel:IsShown() and title:GetAlpha() == 0 and portrait:GetAlpha() == 0)
 firstNative.scripts.OnMouseUp(firstNative, "LeftButton", true)
 assert(not collectionPanel:IsShown() and crafting:GetAlpha() == 0.75)
 assert(title:GetAlpha() == 1 and title:GetText() == name.." actualisé")
 assert(portrait:GetAlpha() == 1 and portrait.texture == name.." actualisé")
end
LeatherTrackerToggleCollection()
ProfessionsFrame:Hide()
assert(not collectionPanel:IsShown() and crafting:GetAlpha() == 0.75)
ProfessionsFrame:Show()
LeatherTrackerToggleCollection()
local catalogue = collectionPanel.Catalog
C_Item = {GetItemIconByID = function(id) return id + 100000 end}
catalogue.Search:SetText("2321")
catalogue.Search.scripts.OnTextChanged()
local result
for _, row in ipairs(catalogue.rows) do
 if row:IsVisible() then
  assert(not result and row.item == 2321)
  result = row
 end
end
assert(result and result.Icon.texture == 102321 and result.Toggle.text == "+")
result.Sources.scripts.OnClick()
assert(collectionPanel.SourcePlaces:IsVisible() and not LeatherTrackerFRDB.collection.goals[2321])
collectionPanel.CollectionTab.scripts.OnClick()
assert(catalogue:IsVisible() and catalogue.Search:GetText() == "2321")
result.Toggle.scripts.OnClick()
assert(LeatherTrackerFRDB.collection.goals[2321] == 1 and result.Toggle.text == "−")
result.Toggle.scripts.OnClick()
assert(not LeatherTrackerFRDB.collection.goals[2321] and result.Toggle.text == "+")
result.Toggle.scripts.OnClick()
local waypoint
TomTom = {AddWaypoint = function(_, map, x, y) waypoint = {map, x, y}; return 1 end}
C_AddOns = {IsAddOnLoaded = function(name) return name == "MelloUI" end}
for _, widget in ipairs(frames) do
 if widget.text == "Sources" and widget:IsVisible() and widget.parent.item == 2321 then
  widget.scripts.OnClick()
  break
 end
end
local foundZone
for _, widget in ipairs(frames) do
 local label = rawget(widget, "Text")
 if widget:IsVisible() and type(label) == "table" and label.text:find("Désolace", 1, true) then
  foundZone = widget
  break
 end
end
assert(assert(foundZone).Text.maxLines == 2)
foundZone.scripts.OnClick()
filterSources("Vendor-Tron 1000")
assert(table.concat(sourceDetails().details, " "):find("60.2 / 38.2", 1, true))
button("Voir sur la carte").scripts.OnClick()
assert(waypoint[1] == 1443 and waypoint[2] == 0.602 and waypoint[3] == 0.382)
local publicPins, shownMap = {}, nil
MelloUI = {Map = {
 AddPin = function(_, owner, key, map, x, y, spec)
  assert(owner == "LeatherTrackerFR" and map > 0)
  assert(spec.show == "world" and spec.leatherTrackerLayer)
  if key == "cavernes-acces" then assert(map == 1413 and x == 0.46 and y == 0.365) end
  publicPins[key] = spec
  return true
 end,
 ClearPin = function(_, owner, key)
  assert(owner == "LeatherTrackerFR")
  publicPins[key] = nil
 end,
 Show = function(_, map) shownMap = map end,
}}
collectionEvents.OnEvent(nil, "ADDON_LOADED")
button("Voir sur la carte").scripts.OnClick()
assert(shownMap == 1443 and publicPins["2321:1"].tip and publicPins["2321:1"].size == 32)
local focused
MelloUI.Map.LeatherTrackerFocus = function(_, map, x, y)
 focused = {map, x, y}
 return true
end
shownMap = nil
button("Voir sur la carte").scripts.OnClick()
assert(focused[1] == 1443 and focused[2] == 0.602 and focused[3] == 0.382 and not shownMap)
button("Options").scripts.OnClick()
button("Automatique").scripts.OnClick()
assert(publicPins["2321:1"] and publicPins["2321:2"] and publicPins["2321:3"])
local entrance = assert(publicPins["cavernes-acces"])
assert((entrance.tip()):find("6471", 1, true))
LeatherTrackerFRDB.collection.goals[6470] = 10
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
local caption = publicPins["cavernes-acces"].tip()
assert(caption:find("6470", 1, true) and caption:find("6471", 1, true))
local layerRows, toggleLayer
MelloUI.Map.LeatherTrackerSetLayers = function(_, rows, setter) layerRows, toggleLayer = rows, setter end
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(#layerRows == 4 and layerRows[1].id == 0)
assert(layerRows[1].name == "Afficher les composants suivis")
assert(layerRows[2].id == "merchants" and layerRows[3].id == "creatures" and layerRows[4].id == "other")
toggleLayer("merchants", false)
assert(not publicPins["2321:1"] and publicPins["cavernes-acces"])
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
assert(LeatherTrackerFRDB.collection.map.hiddenKinds.merchants and not publicPins["2321:1"])
toggleLayer("merchants", true)
toggleLayer("other", false)
assert(not publicPins["cavernes-acces"] and publicPins["2321:1"])
toggleLayer("other", true)
toggleLayer("creatures", false)
assert(not layerRows[3].checked and publicPins["cavernes-acces"] and publicPins["2321:1"])
toggleLayer("creatures", true)
toggleLayer(0, false)
assert(not next(publicPins))
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
assert(not next(publicPins))
toggleLayer(0, true)
assert(publicPins["cavernes-acces"] and publicPins["2321:1"])
LeatherTrackerFRDB.collection.goals[6470] = nil
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(#layerRows == 4)
button("Réglages avancés de la carte").scripts.OnClick()
button("Afficher les infobulles").scripts.OnClick()
assert(not publicPins["2321:1"].tip)
button("Désactivé").scripts.OnClick()
assert(not next(publicPins))
button("Masquer les objectifs atteints sur la carte").scripts.OnClick()
button("Manuel").scripts.OnClick()
toggleLayer("merchants", false)
assert(not publicPins["2321:1"])
toggleLayer("merchants", true)
assert(publicPins["2321:1"])
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
assert(not LeatherTrackerFRDB.collection.map.hiddenKinds.merchants and publicPins["2321:1"])
button("Automatique").scripts.OnClick()
C_Container.GetContainerItemInfo = function() return {itemID = 2321, stackCount = 1} end
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
assert(not publicPins["2321:1"] and not publicPins["2321:2"] and not publicPins["2321:3"])
assert(publicPins["cavernes-acces"])
button("Afficher le suivi").scripts.OnClick()
for _, widget in ipairs(frames) do
 if type(rawget(widget, "Fold")) == "table" then
  widget.Fold.scripts.OnClick()
  assert(LeatherTrackerFRDB.collection.collapsed == true)
  collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
  assert(LeatherTrackerFRDB.collection.collapsed == true)
 end
end
if collectionPanel.MapSettings:IsVisible() then button("Retour à la source").scripts.OnClick() end
button("<").scripts.OnClick()
for _, sample in ipairs({
 {id = 4234, name = "Crystal Spine Basilisk", expected = "34–35", rate = "36,7 %", corpses = "30 corps dépecés"},
 {id = 6470, name = "Deviate Ravager", expected = "PNJ #3636"},
 {id = 2321, name = "Vendor-Tron 1000", expected = "60.2 / 38.2"},
 {id = 4340, name = "Mahu", expected = "approximative"},
 {id = 3356, name = "Sang-royal", expected = "Herboristerie 125"},
 {id = 1210, name = "Ragefire Shaman", expected = "Butin", rate = "6,5 %", corpses = "31 observations"},
}) do
 catalogue.Search:SetText(tostring(sample.id))
 catalogue.Search.scripts.OnTextChanged()
 for _, row in ipairs(catalogue.rows) do
  if row:IsVisible() and row.item == sample.id then
   row.NameButton.scripts.OnClick()
   break
  end
 end
 assert(collectionPanel.SourcePlaces:IsVisible() and not catalogue:IsVisible())
 filterSources(sample.name)
 local details = sourceDetails()
 assert((details.Info.text..table.concat(details.details, " ")):find(sample.expected, 1, true), sample.name)
 if sample.rate then
  assert(details.RateBox.Value.text == sample.rate and details.RateBox.Sample.text == sample.corpses)
  if details.Map:IsShown() then
   assert(details.Map:GetText() == "Voir la zone")
   local previousWaypoint = waypoint
   details.Map.scripts.OnClick()
   assert(waypoint == previousWaypoint)
  end
  if sample.id == 4234 then assert(table.concat(details.details, " "):find("Position précise non vérifiée", 1, true)) end
 end
 button("<").scripts.OnClick()
end
local goals = {[2321] = 2, [4234] = 5, [6470] = 10}
LeatherTrackerFRDB.collection.goals = goals
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
collectionPanel.SourcesTab.scripts.OnClick()
assert(not collectionPanel.SourceIndex:IsShown() and collectionPanel.SourceCounts.text:find("non suivi", 1, true))
collectionPanel.SourceNext.scripts.OnClick()
assert(collectionPanel.SourceIndex:GetText() == "1 / 3 composants")
assert(not collectionPanel.SourcePrevious.enabled)
filterSources("Vendor-Tron 1000")
collectionPanel.SourceNext.scripts.OnClick()
assert(collectionPanel.SourceIndex:GetText() == "2 / 3 composants")
assert(collectionPanel.SourceSearch:GetText() == "Crystal Spine Basilisk")
assert(sourceDetails().Info.text ~= "")
collectionPanel.SourcePickerButton.scripts.OnClick()
assert(#collectionPanel.SourcePicker.Rows == 3)
collectionPanel.SourcePicker.Rows[3].scripts.OnClick()
assert(collectionPanel.SourceIndex:GetText() == "3 / 3 composants")
assert(not collectionPanel.SourceNext.enabled and not collectionPanel.SourcePicker:IsShown())
collectionPanel.CollectionTab.scripts.OnClick()
assert(catalogue:IsVisible() and not collectionPanel.SourcePlaces:IsShown())
collectionPanel.SourcesTab.scripts.OnClick()
assert(collectionPanel.SourceIndex:GetText() == "3 / 3 composants")
collectionPanel.SourcePrevious.scripts.OnClick()
assert(collectionPanel.SourceIndex:GetText() == "2 / 3 composants" and goals[4234] == 5)
collectionPanel.SourcePrevious.scripts.OnClick()
assert(collectionPanel.SourceSearch:GetText() == "Vendor-Tron 1000")
assert(LeatherTrackerFRDB.collection.lastSourceItem == 2321)
LeatherTrackerFRDB.collection.goals = {}
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
collectionPanel.SourcesTab.scripts.OnClick()
assert(not collectionPanel.SourceEmpty:IsVisible() and collectionPanel.SourcePlaces:IsShown())
local messages = {}
local originalPrint = print
print = function(message) messages[#messages + 1] = message end
MelloUI.Map.LeatherTrackerLayerStatus = function() return {created = true, rows = 4, visible = true} end
MelloUI.Map.LeatherTrackerVisiblePins = function() return 0 end
SlashCmdList.LEATHERTRACKERMAPDEBUG()
assert(table.concat(messages):find("Cases créées : 4", 1, true))
assert(table.concat(messages):find("Affichés par MelloUI : 0", 1, true))
MelloUI.Map.LeatherTrackerSetLayers, MelloUI.Map.LeatherTrackerLayerStatus = nil, nil
collectionEvents.OnEvent(nil, "ADDON_LOADED")
messages = {}
SlashCmdList.LEATHERTRACKERMAPDEBUG()
assert(table.concat(messages):find("API de catégorie absente", 1, true))
print = originalPrint
local function goalRow(id)
 for _, widget in ipairs(frames) do
  if rawget(widget, "item") == id and type(rawget(widget, "goal")) == "table" and widget:IsVisible() then
   return widget
  end
 end
 error("Ligne de collecte introuvable")
end
local function rowButton(row, text)
 for _, widget in ipairs(children[row]) do
  if widget:GetText() == text then return widget end
 end
 error("Commande de ligne introuvable : "..text)
end
collectionPanel.CollectionTab.scripts.OnClick()
local currentGoals = LeatherTrackerFRDB.collection.goals
currentGoals[2321], currentGoals[4234] = 2, 5
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
local previousInventory = C_Container.GetContainerItemInfo
C_Container.GetContainerItemInfo = function() return {itemID = 2321, stackCount = 2} end
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
local complete, incomplete = goalRow(2321), goalRow(4234)
assert(complete.point[3] < incomplete.point[3])
button("Options").scripts.OnClick()
button("Masquer les objectifs terminés").scripts.OnClick()
button("Retour à ma collecte").scripts.OnClick()
assert(not pcall(goalRow, 2321) and currentGoals[2321] == 2)
collectionEvents.OnEvent(nil, "PLAYER_LOGIN")
assert(LeatherTrackerFRDB.collection.hideCompleted and not pcall(goalRow, 2321))
button("Options").scripts.OnClick()
button("Masquer les objectifs terminés").scripts.OnClick()
button("Retour à ma collecte").scripts.OnClick()
C_Container.GetContainerItemInfo = previousInventory
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
local first, last = goalRow(2321), goalRow(4234)
first.goal:SetText("999")
local focusCleared = false
first.goal.ClearFocus = function() focusCleared = true end
rowButton(first, "×").scripts.OnClick()
assert(focusCleared and not currentGoals[2321] and currentGoals[4234] == 5)
rowButton(last, "+").scripts.OnClick()
last.goal.scripts.OnEnterPressed(last.goal)
assert(not currentGoals[2321] and currentGoals[4234] == 5)
local remaining = goalRow(4234)
rowButton(remaining, "+").scripts.OnClick()
assert(currentGoals[4234] == 6)
remaining.goal:SetText("14")
remaining.goal.scripts.OnEnterPressed(remaining.goal)
assert(currentGoals[4234] == 14)
rowButton(remaining, "×").scripts.OnClick()
rowButton(remaining, "−").scripts.OnClick()
remaining.goal.scripts.OnEnterPressed(remaining.goal)
assert(not next(currentGoals))

local nativePoint, nativeMap
C_Map = {CanSetUserWaypointOnMap = function(map) return map == 1443 end,
 SetUserWaypoint = function(point) nativePoint = point end}
UiMapPoint = {CreateFromCoordinates = function(map, x, y) return {map, x, y} end}
WorldMapFrame = {Show = noop, SetMapID = function(_, map) nativeMap = map end}
TomTom, MelloUI = nil, nil
currentGoals[2321] = 2
collectionEvents.OnEvent(nil, "BAG_UPDATE_DELAYED")
rowButton(goalRow(2321), "Sources").scripts.OnClick()
filterSources("Vendor-Tron 1000")
button("Voir sur la carte").scripts.OnClick()
assert(nativePoint[1] == 1443 and nativePoint[2] == 0.602 and nativePoint[3] == 0.382 and nativeMap == 1443)
MelloUI = {Map = {AddPin = function() error("repère rejeté") end, ClearPin = noop, Show = noop}}
collectionEvents.OnEvent(nil, "ADDON_LOADED")
nativePoint = nil
button("Voir sur la carte").scripts.OnClick()
assert(nativePoint and nativePoint[1] == 1443)
button("Options").scripts.OnClick()
button("Marchands").scripts.OnClick()
assert(LeatherTrackerFRDB.collection.map.hiddenKinds.merchants)
button("Retour à la source").scripts.OnClick()
assert(not sourceDetails().Map:IsShown())
local registrations = 0
MelloUI.Map.LeatherTrackerSetLayers = function() registrations = registrations + 1 end
collectionPanel.CollectionTab.scripts.OnClick()
assert(registrations == 1)
catalogue.Search:SetText("2321")
catalogue.Search.scripts.OnTextChanged()
local catalogRow = catalogue.rows[1]
local layouts = 0
local originalSetPoint = catalogRow.SetPoint
catalogRow.SetPoint = function(self, ...)
 layouts = layouts + 1
 originalSetPoint(self, ...)
end
rowButton(goalRow(2321), "×").scripts.OnClick()
catalogRow.Toggle.scripts.OnClick()
rowButton(goalRow(2321), "+").scripts.OnClick()
assert(registrations == 1 and layouts == 0 and currentGoals[2321] == 2)
C_Item.RequestLoadItemDataByID = noop
catalogue.Search:SetText("4234")
catalogue.Search.scripts.OnTextChanged()
layouts = 0
for _ = 1, 30 do
 collectionEvents.OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 987654)
 collectionEvents.OnEvent(nil, "GET_ITEM_INFO_RECEIVED", 4234)
end
assert(layouts == 0 and registrations == 1)
collectionEvents.OnUpdate(nil, 0.2)
assert(layouts == 2 and registrations == 1)
collectionEvents.OnUpdate(nil, 0.2)
assert(layouts == 2 and registrations == 1)
print("Collecte, filtres et repli carte, réutilisation du catalogue et regroupement des rafraîchissements : contrôles réussis")
