local addonName, addon = ...
local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.7.41"
local events = CreateFrame("Frame")
local collection, panel, list, scroll, compact, title, activeItem
local rows, compactRows, reagentButtons = {}, {}, {}
local bagStock
local nativePages, nativeHeader = {}, {}
local logo = "Interface\\Icons\\INV_Misc_LeatherScrap_02"

local sources = addon.componentSources

local removed, pendingItem, pendingTime
local optionsOpen = false
local lastSourceItem
local paintingSourceSearch
local collectionScroll = 0
local lastDiagnosticText
local sourceOrder = {}
local sourcesOpen = false
local sourceHeading, sourceFooter, summary
local mapControls, pins, selectedPins = {}, {}, {}
local mapOwner = "LeatherTrackerFR"
local focusedPin, mapPreview
local tomtomPin, tomtomItem, tomtomKind
local beneathMap, preferredMapItem
local mapModes = {manual = "Manuel", automatic = "Automatique", off = "Désactivé"}
local sourceLines, sourceFilters, sourceSelection = {}, {}, {}
local sortSourcesByRate = false
local recipesByItem = {}
local scanLeatherworking
local recipePageSize = 5

local function catalogFor(id)
 local imported = addon and addon.importedSources and addon.importedSources[id]
 local records = {}
 for _, group in ipairs({sources[id] or {}, imported or {}}) do
  for _, record in ipairs(group) do records[#records + 1] = record end
 end
 return records
end

local observationMethods = {
 mob = "Butin", skinning = "Dépeçage", fishing = "Pêche", fishing_pool = "Pêche",
 mining = "Minage", herbalism = "Herboristerie", chest = "Coffre",
 disenchant = "Désenchantement", gameobject = "Objet",
}

local function addLocalObservations(records, id)
 local saved = ForeverDB_Saved
 if type(saved) ~= "table" or type(saved.sources) ~= "table" then return end
 local observed = {}
 for _, source in pairs(saved.sources) do
  if type(source) == "table" and type(source.buckets) == "table" then
   for kind, bucket in pairs(source.buckets) do
    if observationMethods[kind] and type(bucket) == "table" and type(bucket.items) == "table" then
     local item = bucket.items[tostring(id)] or bucket.items[id]
     local attempts = tonumber(bucket.observations)
     local drops = type(item) == "table" and tonumber(item.drops)
     if attempts and drops and drops > 0 and attempts >= drops and attempts < math.huge then
      local level = tonumber(source.sourceLevel)
      observed[#observed + 1] = {
       name = type(source.name) == "string" and source.name ~= "" and source.name or ("Source #"..tostring(source.sourceId)),
       method = observationMethods[kind],
       level = level and level > 0 and level or nil,
       obtained = drops, observations = attempts, provenance = "Observations locales ForeverDB",
      }
     end
    end
   end
  end
 end
 table.sort(observed, function(a, b)
  if a.name == b.name then return a.method < b.method end
  return a.name < b.name
 end)
 for _, record in ipairs(observed) do records[#records + 1] = record end
end

local function addSkinningObservations(records, id)
 local db = LeatherTrackerFRDB and LeatherTrackerFRDB.skinningObservations
 local personal = {}
 for creatureID, entry in pairs(db or {}) do
  local loot = entry.loot
  local obtained = loot and loot.drops[id]
  if obtained and loot.samples > 0 then
   personal[#personal + 1] = {
    creatureID = creatureID, name = loot.name or ("Créature #"..creatureID),
    method = "Dépeçage", obtained = obtained, observations = loot.samples,
    provenance = "Mes dépeçages", personalSkinning = true,
   }
  end
 end
 table.sort(personal, function(a, b) return a.creatureID < b.creatureID end)
 for _, record in ipairs(personal) do records[#records + 1] = record end
end

local function itemID(value)
 local id = tonumber(value) or (type(value) == "string" and tonumber(value:match("item:(%d+)")))
 if id and id > 0 and id == math.floor(id) and id <= 2147483647 then return id end
end

local function quantity(value)
 local number = tonumber(value)
 if number and number == number then return math.max(1, math.min(99999, math.floor(number))) end
end

local requestedItems = {}
local pendingItemRefresh
local catalogRevision = 0

-- Stable item IDs from the Forever item corpus. The client supplies the localized art and names.
local componentGroups = addon.componentGroups
local indexedComponents = {}
for _, group in ipairs(componentGroups) do
 for _, id in ipairs(group.items) do indexedComponents[id] = true end
end
local otherComponents = componentGroups[#componentGroups]


local function itemInfo(id)
 local api = C_Item
 local name = api and api.GetItemInfo and api.GetItemInfo(id)
 local icon = api and api.GetItemIconByID and api.GetItemIconByID(id)
 if (not name or not icon) and api and api.RequestLoadItemDataByID and not requestedItems[id] then
  requestedItems[id] = "pending"
  api.RequestLoadItemDataByID(id)
 end
 local catalogName = addon.warcraftForever and addon.warcraftForever.names[id]
 return name or catalogName or ("Objet #"..id), icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function scanBags()
 local api = C_Container
 if not api or not api.GetContainerNumSlots or not api.GetContainerItemInfo then
  bagStock = nil
  return
 end
 bagStock = {}
 local lastBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or NUM_BAG_SLOTS or 4
 for bag = 0, lastBag do
  for slot = 1, api.GetContainerNumSlots(bag) do
   local info = api.GetContainerItemInfo(bag, slot)
   if info and info.itemID then
    bagStock[info.itemID] = (bagStock[info.itemID] or 0) + (info.stackCount or 1)
   end
  end
 end
end

local function stock(id)
 if bagStock then return bagStock[id] or 0 end
end

local function mapAPI()
 local api = MelloUI and MelloUI.Map
 if api and type(api.AddPin) == "function" and type(api.ClearPin) == "function"
  and type(api.Show) == "function" then return api end
end

local function mapLayersModule()
 local module = MelloUI and type(MelloUI.GetModule) == "function" and MelloUI:GetModule("Map")
 if module and type(module.OpenLayers) == "function" then return module end
end

local layerDefinitions = {
 {id = "merchants", name = "Marchands"},
 {id = "creatures", name = "Créatures et dépeçage"},
 {id = "other", name = "Autres sources vérifiées"},
}
local mapDiagnostics = {available = 0, sent = 0}
local function sourceLayer(source)
 if source.method == "Achat" then return "merchants" end
 if source.creatureID or source.method == "Dépeçage" or source.method == "Butin" then return "creatures" end
 return "other"
end
local function mappable(source)
 return not source.tentative and type(source.map) == "number" and source.map > 0
  and type(source.x) == "number" and source.x >= 0 and source.x <= 1
  and type(source.y) == "number" and source.y >= 0 and source.y <= 1
end

local zoneMaps
local function documentedZoneMap(source)
 if not source.zone then return end
 if not zoneMaps then
  zoneMaps = {}
  for _, records in pairs(addon.componentSources or {}) do
   for _, record in ipairs(records) do
    if mappable(record) and record.zone then
     local previous = zoneMaps[record.zone]
     if previous == nil then
      zoneMaps[record.zone] = record.map
     elseif previous ~= record.map then
      zoneMaps[record.zone] = false
     end
    end
   end
  end
 end
 return zoneMaps[source.zone]
end

local function nativeWaypointAvailable(map)
 return C_Map and type(C_Map.SetUserWaypoint) == "function" and UiMapPoint
  and type(UiMapPoint.CreateFromCoordinates) == "function"
  and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(map))
end

local function showNativeWaypoint(source)
 if not nativeWaypointAvailable(source.map) then return false end
 local point = UiMapPoint.CreateFromCoordinates(source.map, source.x, source.y)
 if not point then return false end
 C_Map.SetUserWaypoint(point)
 if WorldMapFrame then
  WorldMapFrame:Show()
  WorldMapFrame:SetMapID(source.map)
 end
 return true
end

local syncMap
local registeredMap, registeredSetter, registeredFilters
local function setMapLayer(id, enabled)
 local settings = collection.map
 if id == 0 then
  settings.layersHidden = not enabled
 else
  settings.hiddenKinds[id] = not enabled or nil
 end
 syncMap()
end

syncMap = function()
 if not collection then return end
 local api = mapAPI()
 local wanted = {}
 local settings = collection.map
 local function layerVisible()
  return not settings.layersHidden
 end
 local function sourceVisible(source)
  return mappable(source) and not settings.hiddenKinds[sourceLayer(source)]
 end
 local available = {}
 for id in pairs(collection.goals) do
  for index, source in ipairs(catalogFor(id)) do
   if mappable(source) then available[source.sharedPin or (id..":"..index)] = true end
  end
 end
 mapDiagnostics.available = 0
 for _ in pairs(available) do mapDiagnostics.available = mapDiagnostics.available + 1 end
 local setter = api and api.LeatherTrackerSetLayers
 if type(setter) == "function" then
  local filters, flags = {not settings.layersHidden}, {}
  for _, layer in ipairs(layerDefinitions) do filters[#filters + 1] = not settings.hiddenKinds[layer.id] end
  for index, enabled in ipairs(filters) do flags[index] = enabled and "1" or "0" end
  local signature = table.concat(flags)
  if api ~= registeredMap or setter ~= registeredSetter or signature ~= registeredFilters then
   registeredMap, registeredSetter, registeredFilters = api, setter, signature
   local rows = {{id = 0, name = "Afficher les composants suivis", checked = filters[1], available = true}}
   for index, layer in ipairs(layerDefinitions) do
    rows[#rows + 1] = {id = layer.id, name = layer.name, checked = filters[index + 1], available = true}
   end
   local ok, result = pcall(setter, api, rows, setMapLayer)
   mapDiagnostics.registration = not ok and "erreur : "..tostring(result)
    or result == false and "refusé" or "transmis à MelloUI, rendu à vérifier"
  end
 else
  registeredMap, registeredSetter, registeredFilters = nil, nil, nil
  mapDiagnostics.registration = nil
 end
 if tomtomPin then
  local goal = collection.goals[tomtomItem]
  local owned = stock(tomtomItem)
  if api or settings.mode ~= "manual" or not layerVisible() or settings.hiddenKinds[tomtomKind]
   or not goal or (settings.hideDone and owned and owned >= goal) then
   if TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomPin) end
   tomtomPin, tomtomItem, tomtomKind = nil, nil, nil
  end
 end
 local single
 if settings.mode == "automatic" and not settings.multiple then
  for id, goal in pairs(collection.goals) do
   local owned = stock(id)
   if layerVisible() and not (settings.hideDone and owned and owned >= goal) then
    for _, source in ipairs(catalogFor(id)) do
     if sourceVisible(source) and (id == preferredMapItem or
      (single ~= preferredMapItem and (not single or id < single)) or not single) then
      single = id
     end
    end
   end
  end
 end
 if api and settings.mode ~= "off" then
  for id, goal in pairs(collection.goals) do
   local owned = stock(id)
   if layerVisible() and not (settings.hideDone and owned and owned >= goal) then
    for index, source in ipairs(catalogFor(id)) do
     local key = id..":"..index
     if sourceVisible(source) and ((settings.mode == "automatic" and (settings.multiple or id == single)) or
      (settings.mode == "manual" and (settings.manualItems[id] or selectedPins[key]))) then
      local pinKey = source.sharedPin or key
      local entry = wanted[pinKey]
      if not entry then
       entry = {source = source, items = {}}
       wanted[pinKey] = entry
      end
      entry.items[#entry.items + 1] = id
     end
    end
   end
  end
 end
 if api and mapPreview and settings.mode ~= "off" and layerVisible() and sourceVisible(mapPreview.source) and not collection.goals[mapPreview.id] then
  wanted[mapPreview.key] = {source = mapPreview.source, items = {mapPreview.id}}
 end
 if api then
  for key, entry in pairs(wanted) do
   table.sort(entry.items)
   local names = {}
   for index, id in ipairs(entry.items) do names[index] = itemInfo(id) end
   local _, icon = itemInfo(entry.items[1])
   local source = entry.source
   local caption = table.concat(names, " / ")
   local size = focusedPin == key and 32 or 22
   local fingerprint = (settings.tips and caption or "-").."|"..tostring(icon).."|"..size
   if pins[key] ~= fingerprint then
    local spec = {icon = icon or logo, size = size, show = "world", leatherTrackerLayer = true}
    if settings.tips then
     spec.tip = function()
      return caption, source.name.." • "..source.zone..
       (source.approximate and " (position approximative)" or "").."\n"..
       (("%.1f / %.1f • %s"):format(source.x * 100, source.y * 100, source.locationSource or "ForeverDB.net"))
     end
    end
    local ok, added = pcall(api.AddPin, api, mapOwner, key, source.map, source.x, source.y, spec)
    if ok and added then pins[key] = fingerprint end
   end
  end
 end
 for key in pairs(pins) do
  if not wanted[key] then
   if api then pcall(api.ClearPin, api, mapOwner, key) end
   pins[key] = nil
  end
 end
 mapDiagnostics.sent = 0
 for _ in pairs(pins) do mapDiagnostics.sent = mapDiagnostics.sent + 1 end
end

SLASH_LEATHERTRACKERMAPDEBUG1 = "/ltmapdebug"
SlashCmdList.LEATHERTRACKERMAPDEBUG = function()
 local api = mapAPI()
 local function addonStatus(name)
  local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name)
  local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(name, "Version")
  return (loaded and "chargé" or "non chargé")..(version and (" · "..version) or "")
 end
 print("LeatherTracker "..version.." | MelloUI : "..addonStatus("MelloUI").." | MelloUI_Map : "..addonStatus("MelloUI_Map"))
 print("Carte : "..(api and "API de repères disponible" or "API indisponible")..
  " | Panneau Calques : "..(mapLayersModule() and "accessible par le module Carte" or "accès API indisponible"))
 print("Enregistrement du groupe : "..(mapDiagnostics.registration or "API de catégorie absente ou enregistrement non tenté"))
 local state = api and type(api.LeatherTrackerLayerStatus) == "function" and api:LeatherTrackerLayerStatus()
 if state then
  print(("Groupe créé : %s | Cases créées : %d | Groupe visible : %s"):format(state.created and "oui" or "non", state.rows or 0, state.visible and "oui" or "non"))
 else
  print("Groupe et cases : le module ne permet pas de vérifier leur création.")
 end
 if collection then
  local settings = collection.map
  local flags = {settings.layersHidden and "suivi décoché" or "suivi coché"}
  for _, layer in ipairs(layerDefinitions) do
   flags[#flags + 1] = layer.name.." : "..(settings.hiddenKinds[layer.id] and "décoché" or "coché")
  end
  print("Préférences mémorisées : "..table.concat(flags, " | ").." | Mode : "..mapModes[settings.mode])
 end
 local visible = api and type(api.LeatherTrackerVisiblePins) == "function" and api:LeatherTrackerVisiblePins()
 print(("Repères disponibles : %d | Acceptés par la carte : %d | Affichés par MelloUI : %s"):format(
  mapDiagnostics.available, mapDiagnostics.sent, visible or "non mesurables avec ce module"))
end

local function button(parent, label, width, handler)
 local widget = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
 widget:SetSize(width, 26)
 widget:SetText(label)
 widget:SetScript("OnClick", handler)
 return widget
end

local function sourceLayout(records)
 local filters, byKey = {}, {}
 local function add(key, name, index, rank, indent)
  local group = byKey[key]
  if not group then
   group = {key = key, name = name, rank = rank, indent = indent, indices = {}}
   byKey[key] = group
   filters[#filters + 1] = group
  end
  group.indices[#group.indices + 1] = index
 end
 for index, source in ipairs(records) do
  add("allMethods", "Toutes", index, 0)
  add("method:"..source.method, source.method, index, 1)
  if source.personalSkinning then add("personal", "Mes dépeçages", index, 1) end
  add("all", "Toutes les zones", index, 2)
  if source.zone then
   local continent = source.continent
   if continent then
    add("continent:"..continent, continent, index, 3, 0)
   end
   add("zone:"..(continent or "")..":"..source.zone, source.zone, index, 3, continent and 10 or 0)
  else
   add("unknown", "Localisation indisponible", index, 4)
  end
 end
 table.sort(filters, function(a, b)
  if a.rank ~= b.rank then return a.rank < b.rank end
  local function sortKey(group)
   return group.key:gsub("^zone:", ""):gsub("^continent:", "")
  end
  return sortKey(a) < sortKey(b)
 end)
 return filters, byKey
end

local function label(parent, style, x, y)
 local widget = parent:CreateFontString(nil, "OVERLAY", style)
 widget:SetPoint("TOPLEFT", x, y)
 widget:SetJustifyH("LEFT")
 return widget
end

local function learningText()
 if not addon.GetSkinningDiagnostic then return "Diagnostic de dépeçage indisponible." end
 return ("%s\n%d fenêtre(s) complète(s) cette session."):format(
  addon.GetSkinningDiagnostic(), addon.GetSkinningSessionSamples())
end

local function background(frame, red, green, blue)
 local texture = frame:CreateTexture(nil, "BACKGROUND")
 texture:SetAllPoints()
 texture:SetColorTexture(red, green, blue, 0.97)
end

local function categoryBand(parent, text, handler)
 local band = CreateFrame(handler and "Button" or "Frame", nil, parent)
 band:SetHeight(24)
 background(band, 0.15, 0.12, 0.085)
 local divider = band:CreateTexture(nil, "BORDER")
 divider:SetPoint("BOTTOMLEFT", 0, 0)
 divider:SetPoint("BOTTOMRIGHT", 0, 0)
 divider:SetHeight(1)
 divider:SetColorTexture(0.36, 0.28, 0.16, 1)
 band.Text = label(band, "GameFontNormalSmall", 6, -6)
 band.Text:SetPoint("RIGHT", handler and -23 or -6, 0)
 band.Text:SetWordWrap(false)
 band.Text:SetText(text)
 if handler then
  local hover = band:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetColorTexture(0.71, 0.49, 0.24, 0.15)
  band.ToggleMark = band:CreateTexture(nil, "ARTWORK")
  band.ToggleMark:SetSize(15, 15)
  band.ToggleMark:SetPoint("RIGHT", -5, 0)
  band:SetScript("OnClick", handler)
 end
 return band
end

local function setBandExpanded(band, expanded)
 band.ToggleMark:SetTexture("Interface\\Minimap\\UI-Minimap-Zoom"..(expanded and "Out" or "In").."Button-Up")
end

local function input(parent, width, max)
 local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
 box:SetAutoFocus(false)
 box:SetSize(width, 24)
 box:SetMaxLetters(max)
 box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
 return box
end

local refresh

local function track(id, goal)
 id, goal = itemID(id), quantity(goal)
 if not collection or not id or not goal then return end
 collection.goals[id] = math.max(collection.goals[id] or 0, goal)
 refresh()
end

local function rememberScroll()
 if scroll then
  if sourcesOpen and activeItem and sourceSelection[activeItem] then
   local previous = sourceSelection[activeItem]
   previous.resultsScroll = scroll:GetVerticalScroll()
   previous.placesScroll = panel.SourcePlaces.Scroll:GetVerticalScroll()
  elseif not sourcesOpen then
   collectionScroll = scroll:GetVerticalScroll()
  end
 end
end

local function showItem(id, emptySources)
 if not panel or not panel:GetParent():IsVisible() then return end
 rememberScroll()
 activeItem = id
 sourcesOpen = id ~= nil or emptySources == true
 optionsOpen = false
 panel.SourcePicker:Hide()
 local state
 if id then
  lastSourceItem = id
  if collection then collection.lastSourceItem = id end
  state = sourceSelection[id]
  if type(state) ~= "table" then state = {group = "all"} end
  sourceSelection[id] = state
 end
 paintingSourceSearch = true
 panel.SourceSearch:SetText(state and type(state.query) == "string" and state.query or "")
 paintingSourceSearch = false
 if not panel:IsShown() then panel:Show() end
 refresh()
 if scroll then
  local position = state and tonumber(state.resultsScroll) or (not sourcesOpen and collectionScroll) or 0
  scroll:SetVerticalScroll(math.min(position, scroll:GetVerticalScrollRange()))
  local places = panel.SourcePlaces.Scroll
  places:SetVerticalScroll(math.min(state and tonumber(state.placesScroll) or 0, places:GetVerticalScrollRange()))
 end
end

local searchAccents = {
 ["É"] = "e", ["é"] = "e", ["È"] = "e", ["è"] = "e", ["Ê"] = "e", ["ê"] = "e",
 ["À"] = "a", ["à"] = "a", ["Â"] = "a", ["â"] = "a", ["Ç"] = "c", ["ç"] = "c",
 ["Î"] = "i", ["î"] = "i", ["Ô"] = "o", ["ô"] = "o", ["Û"] = "u", ["û"] = "u",
}
local function componentSearchText(text)
 return (text:lower():gsub("[\194-\244][\128-\191]", searchAccents))
end

local function renderComponentCatalog()
 local catalog = panel.Catalog
 local query = componentSearchText(catalog.Search:GetText():match("^%s*(.-)%s*$"))
 local function updateToggle(row)
  local mark = collection.goals[row.item] and "−" or "+"
  if row.Toggle:GetText() ~= mark then row.Toggle:SetText(mark) end
 end
 if catalog.renderedQuery == query and catalog.renderedRevision == catalogRevision then
  for index = 1, catalog.renderedRows do updateToggle(catalog.rows[index]) end
  return
 end
 catalog.renderedQuery, catalog.renderedRevision = query, catalogRevision
 local idQuery = itemID(query)
 local y, used = 0, 0
 for _, group in ipairs(componentGroups) do
  local matching = {}
  for _, id in ipairs(group.items) do
   local name, icon = itemInfo(id)
   if query == "" or idQuery == id or componentSearchText(name):find(query, 1, true) then
    matching[#matching + 1] = {id = id, name = name, icon = icon}
   end
  end
  local header = catalog.headers[group.name]
  header:SetShown(#matching > 0)
  if #matching > 0 then
   local open = query ~= "" or not collection.catalogFolded[group.name]
   header:ClearAllPoints()
   header:SetPoint("TOPLEFT", 0, -y)
   header:SetPoint("TOPRIGHT", 0, -y)
   setBandExpanded(header, open)
   local _, categoryIcon = itemInfo(group.icon)
   header.Icon:SetTexture(categoryIcon)
   y = y + 25
   if open then
    for _, item in ipairs(matching) do
     used = used + 1
     local row = catalog.rows[used]
     if not row then
      row = CreateFrame("Frame", nil, catalog.Body)
      row:SetHeight(54)
      background(row, 0.15, 0.12, 0.09)
      row.IconButton = CreateFrame("Button", nil, row)
      row.IconButton:SetSize(32, 32)
      row.IconButton:SetPoint("LEFT", 3, 0)
      row.Icon = row.IconButton:CreateTexture(nil, "ARTWORK")
      row.Icon:SetAllPoints()
      row.IconButton:SetScript("OnEnter", function(self)
       GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
       if GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(row.item)
       else
        GameTooltip:SetHyperlink("item:"..row.item)
       end
       GameTooltip:Show()
      end)
      row.IconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
      row.IconButton:SetScript("OnClick", function() showItem(row.item) end)
      row.Toggle = button(row, "", 24, function()
       local goal = collection.goals[row.item]
       if goal then
        removed = {id = row.item, goal = goal}
        collection.goals[row.item] = nil
        refresh()
       else
        track(row.item, 1)
       end
      end)
      row.Toggle:SetPoint("BOTTOMRIGHT", -3, 2)
      row.Sources = button(row, "Sources", 54, function() showItem(row.item) end)
      row.Sources:SetPoint("RIGHT", row.Toggle, "LEFT", -3, 0)
      row.NameButton = CreateFrame("Button", nil, row)
      row.NameButton:SetPoint("TOPLEFT", 40, -2)
      row.NameButton:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -3, 25)
      row.Name = label(row.NameButton, "GameFontHighlightSmall", 0, 0)
      row.Name:SetPoint("BOTTOMRIGHT", 0, 0)
      row.Name:SetMaxLines(2)
      row.NameButton:SetScript("OnClick", function() showItem(row.item) end)
      catalog.rows[used] = row
     end
     row.item = item.id
     row:ClearAllPoints()
     row:SetPoint("TOPLEFT", 0, -y)
     row:SetPoint("TOPRIGHT", 0, -y)
     row.Icon:SetTexture(item.icon)
     row.Name:SetText(item.name)
     updateToggle(row)
     if not row:IsShown() then row:Show() end
     y = y + 56
    end
   end
  end
 end
 for index = used + 1, #catalog.rows do catalog.rows[index]:Hide() end
 catalog.renderedRows = used
 catalog.Empty:SetShown(y == 0)
 catalog.Body:SetHeight(math.max(y, 25))
end

local function createRow(index)
 local row = CreateFrame("Frame", nil, list)
 row:SetPoint("TOPLEFT", 0, -(index - 1) * 81)
 row:SetPoint("TOPRIGHT", 0, -(index - 1) * 81)
 row:SetHeight(77)
 background(row, 0.15, 0.12, 0.09)
 row.icon = row:CreateTexture(nil, "ARTWORK")
 row.icon:SetSize(33, 33)
 row.icon:SetPoint("TOPLEFT", 9, -10)
 row.name = label(row, "GameFontNormal", 52, -10)
 row.status = label(row, "GameFontHighlightSmall", 52, -28)
 row.bar = CreateFrame("StatusBar", nil, row)
 row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 row.bar:SetHeight(4)
 row.bar:SetPoint("BOTTOMRIGHT", -8, 5)
 row.bar:SetMinMaxValues(0, 1)
 row.bar:SetPoint("BOTTOMLEFT", 52, 5)
 row.goal = input(row, 51, 5)
 row.goal:SetPoint("BOTTOMLEFT", 36, 13)
 local function currentGoal()
  if row.item and row:IsVisible() then return collection.goals[row.item] end
 end
 row.goal:SetScript("OnEnterPressed", function(self)
  local existing, goal = currentGoal(), quantity(self:GetText())
  if existing and goal then collection.goals[row.item] = goal end
  self:ClearFocus()
  if existing then refresh() end
 end)
 local function adjust(delta)
  local goal = currentGoal()
  if not goal then return end
  row.goal:ClearFocus()
  collection.goals[row.item] = quantity(goal + delta)
  refresh()
 end
 button(row, "−", 24, function() adjust(-1) end):SetPoint("RIGHT", row.goal, "LEFT", -4, 0)
 button(row, "+", 24, function() adjust(1) end):SetPoint("LEFT", row.goal, "RIGHT", 3, 0)
 button(row, "Sources", 67, function()
  if currentGoal() then showItem(row.item) end
 end):SetPoint("BOTTOMRIGHT", -32, 13)
 button(row, "×", 23, function()
  local goal = currentGoal()
  if not goal then return end
  row.goal:ClearFocus()
  removed = {id = row.item, goal = goal}
  collection.goals[row.item] = nil
  refresh()
 end):SetPoint("BOTTOMRIGHT", -5, 13)
 row.name:SetPoint("TOPRIGHT", -8, -10)
 row.status:SetPoint("TOPRIGHT", -8, -28)
 row.status:SetWordWrap(false)
 row.name:SetWordWrap(false)
 return row
end

function LeatherTrackerCloseCollection()
 if panel and panel:IsShown() then panel:Hide() end
 for native, alpha in pairs(nativePages) do native:SetAlpha(alpha) end
 nativePages = {}
 for region, alpha in pairs(nativeHeader) do region:SetAlpha(alpha) end
 nativeHeader = {}
 if LeatherTrackerFRProfessionTab then LeatherTrackerFRProfessionTab:SetChecked(false) end
end

function LeatherTrackerRefreshCollectionFrame()
 if not panel or not panel:IsVisible() then return end
 local frame = panel:GetParent()
 local function mask(native)
  if native and native:IsShown() and nativePages[native] == nil then
   nativePages[native] = native:GetAlpha()
   native:SetAlpha(0)
  end
 end
 for _, native in ipairs(frame.Pages or {}) do mask(native) end
 for _, key in ipairs({"CraftingPage", "BookPage", "SpecPage", "OrdersPage"}) do mask(frame[key]) end
 for region in pairs(nativeHeader) do region:SetAlpha(0) end
 if LeatherTrackerFRProfessionTab then LeatherTrackerFRProfessionTab:SetChecked(true) end
end

local function leatherworkingRecipe(form)
 local api = C_TradeSkillUI
 if not form or type(form.GetRecipeInfo) ~= "function"
  or not api or type(api.GetProfessionInfoByRecipeID) ~= "function" then return end
 local ok, recipe = pcall(form.GetRecipeInfo, form)
 if not ok or type(recipe) ~= "table" or type(recipe.recipeID) ~= "number" then return end
 local found, profession = pcall(api.GetProfessionInfoByRecipeID, recipe.recipeID)
 if found and type(profession) == "table"
  and (profession.parentProfessionID or profession.professionID) == 165 then return api end
end

local function createPanel(frame)
 panel = CreateFrame("Frame", "LeatherTrackerCollection", frame)
 panel:Hide()
 panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -38)
 panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
 panel:SetFrameStrata("FULLSCREEN_DIALOG")
 panel:SetFrameLevel(frame:GetFrameLevel() + 100)
 panel:EnableMouse(true)
 panel:EnableMouseWheel(true)
 local fill = panel:CreateTexture(nil, "BACKGROUND")
 fill:SetAllPoints()
 fill:SetColorTexture(0.09, 0.073, 0.055, 1)
 local nativeTitle = frame.GetTitleText and frame:GetTitleText()
 local nativePortrait = frame.GetPortrait and frame:GetPortrait()
 if nativeTitle then
  local overlay = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  overlay:SetAllPoints(nativeTitle)
  overlay:SetText("LeatherTracker FR  ·  "..version)
 end
 if nativePortrait then
  local overlay = panel:CreateTexture(nil, "OVERLAY")
  overlay:SetAllPoints(nativePortrait)
  if SetPortraitToTexture then SetPortraitToTexture(overlay, logo) else overlay:SetTexture(logo) end
 end
 panel:SetScript("OnShow", function()
  if nativeTitle and nativeHeader[nativeTitle] == nil then nativeHeader[nativeTitle] = nativeTitle:GetAlpha() end
  if nativePortrait and nativeHeader[nativePortrait] == nil then nativeHeader[nativePortrait] = nativePortrait:GetAlpha() end
  LeatherTrackerRefreshCollectionFrame()
 end)
 panel:SetScript("OnHide", function()
  optionsOpen = false
  if panel.SourcePicker then panel.SourcePicker:Hide() end
  if panel.MapSettings then panel.MapSettings:Hide() end
  LeatherTrackerCloseCollection()
 end)
 title = label(panel, "GameFontNormalLarge", 20, -50)
 button(panel, "Fabrication", 110, LeatherTrackerCloseCollection):SetPoint("TOPRIGHT", -18, -7)
 local catalog = CreateFrame("Frame", nil, panel)
 panel.Catalog = catalog
 catalog:SetPoint("TOPLEFT", 18, -45)
 catalog:SetPoint("BOTTOMLEFT", 18, 16)
 catalog:SetWidth(210)
 background(catalog, 0.12, 0.095, 0.075)
 label(catalog, "GameFontNormal", 8, -7):SetText("Catalogue des composants")
 catalog.rows, catalog.headers = {}, {}
 local search = input(catalog, 1, 255)
 catalog.Search = search
 search:SetPoint("TOPLEFT", 10, -28)
 search:SetPoint("TOPRIGHT", -9, -28)
 search:SetScript("OnTextChanged", function()
  catalog.Scroll:SetVerticalScroll(0)
  renderComponentCatalog()
 end)
 search:SetScript("OnEnterPressed", function(self)
  local id = itemID(self:GetText())
  if id then track(id, 1); self:SetText("") end
  self:ClearFocus()
 end)
 catalog.Scroll = CreateFrame("ScrollFrame", nil, catalog, "UIPanelScrollFrameTemplate")
 catalog.Scroll:SetPoint("TOPLEFT", 5, -57)
 catalog.Scroll:SetPoint("BOTTOMRIGHT", -21, 5)
 catalog.Body = CreateFrame("Frame", nil, catalog.Scroll)
 catalog.Body:SetSize(184, 25)
 catalog.Scroll:SetScrollChild(catalog.Body)
 catalog.Empty = label(catalog.Body, "GameFontHighlightSmall", 5, -4)
 catalog.Empty:SetText("Aucun composant trouvé.")
 for _, group in ipairs(componentGroups) do
  local header = categoryBand(catalog.Body, group.name, function()
   collection.catalogFolded[group.name] = not collection.catalogFolded[group.name]
   catalog.renderedRevision = nil
   renderComponentCatalog()
  end)
  header.Icon = header:CreateTexture(nil, "ARTWORK")
  header.Icon:SetSize(17, 17)
  header.Icon:SetPoint("LEFT", 4, 0)
  header.Text:SetPoint("TOPLEFT", 25, -6)
  catalog.headers[group.name] = header
 end
 catalog.Scroll:SetScript("OnSizeChanged", function(_, width)
  catalog.Body:SetWidth(math.max(width, 1))
 end)
 panel:SetScript("OnSizeChanged", function(_, width)
  catalog:SetWidth(math.max(120, (width - 64) * 0.30))
  if panel.CompactControl then panel.CompactControl:SetWidth(width < 500 and 82 or 128) end
  if panel.SourcePlaces then panel.SourcePlaces:SetWidth(math.max(120, (width - 64) * 0.30)) end
  pendingItemRefresh = true
 end)
 panel.Back = button(panel, "<", 26, function() showItem(nil) end)
 panel.Back:SetPoint("TOPLEFT", 19, -44)
 panel.ItemIcon = panel:CreateTexture(nil, "ARTWORK")
 panel.ItemIcon:SetSize(27, 27)
 panel.ItemIcon:SetPoint("LEFT", panel.Back, "RIGHT", 6, 0)
 panel.SourceCounts = label(panel, "GameFontHighlight", 20, -78)
 panel.SourceEmpty = label(panel, "GameFontHighlight", 20, -82)
 panel.SourceEmpty:SetText("Choisis un composant pour trouver ses sources.")
 panel.SourceCatalog = button(panel, "Ouvrir le catalogue", 155, function()
  showItem(nil)
  panel.Catalog.Search:SetFocus()
 end)
 panel.SourceCatalog:SetPoint("TOPLEFT", 20, -108)
 local function stepSource(direction)
  local index = direction > 0 and 0 or #sourceOrder + 1
  for i, id in ipairs(sourceOrder) do
   if id == activeItem then index = i; break end
  end
  local id = sourceOrder[index + direction]
  if id then showItem(id) end
 end
 local function arrow(direction)
  local control = button(panel, "", 25, function() stepSource(direction) end)
  local icon = control:CreateTexture(nil, "OVERLAY")
  icon:SetSize(17, 18)
  icon:SetPoint("CENTER")
  icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-"..(direction < 0 and "Prev" or "Next").."Page-Up")
  control.Arrow = icon
  return control
 end
 panel.SourcePrevious = arrow(-1)
 panel.SourcePrevious:SetPoint("LEFT", panel.ItemIcon, "RIGHT", 5, 0)
 panel.SourceNext = arrow(1)
 panel.SourceIndex = label(panel, "GameFontHighlightSmall", 0, 0)
 panel.SourceIndex:ClearAllPoints()
 panel.SourceIndex:SetPoint("TOPRIGHT", -24, -81)
 local pickerButton = button(panel, "Mes suivis", 155, function()
  local picker = panel.SourcePicker
  picker:SetShown(not picker:IsShown())
  picker.Scroll:SetVerticalScroll(0)
  refresh()
 end)
 panel.SourcePickerButton = pickerButton
 pickerButton:SetPoint("TOPRIGHT", -23, -46)
 panel.SourceNext:SetPoint("LEFT", title, "RIGHT", 5, 0)
 local picker = CreateFrame("Frame", nil, panel)
 panel.SourcePicker = picker
 picker:SetFrameLevel(panel:GetFrameLevel() + 25)
 picker:SetPoint("TOPRIGHT", pickerButton, "BOTTOMRIGHT", 0, -3)
 picker:SetWidth(270)
 background(picker, 0.18, 0.13, 0.08)
 picker:EnableMouse(true)
 picker:Hide()
 local pickerScroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate")
 pickerScroll:SetPoint("TOPLEFT", 4, -4)
 pickerScroll:SetPoint("BOTTOMRIGHT", -24, 4)
 local pickerBody = CreateFrame("Frame", nil, pickerScroll)
 pickerBody:SetSize(242, 1)
 pickerScroll:SetScrollChild(pickerBody)
 picker.Scroll, picker.Body, picker.Rows = pickerScroll, pickerBody, {}
 local allItems = button(picker, "Tous les composants", 238, function()
  showItem(nil)
  panel.Catalog.Search:SetFocus()
 end)
 allItems:SetPoint("TOPLEFT", 4, -4)
 pickerScroll:SetPoint("TOPLEFT", 4, -34)
 picker.Empty = label(picker, "GameFontHighlightSmall", 8, -40)
 picker.Empty:SetText("Aucun composant suivi.")
 local toolbar = CreateFrame("Frame", nil, panel)
 toolbar:SetPoint("TOPLEFT", 18, -5)
 toolbar:SetPoint("TOPRIGHT", -132, -5)
 toolbar:SetHeight(30)
 background(toolbar, 0.18, 0.13, 0.08)
 panel.CompactControl = button(toolbar, "Panneau compact", 128, function()
  collection.compact = not collection.compact
  refresh()
 end)
 panel.CompactControl:SetPoint("LEFT", 5, 0)
 panel.SourcesTab = button(toolbar, "Sources", 73, function()
  showItem(lastSourceItem or sourceOrder[1], true)
 end)
 panel.SourcesTab:SetPoint("LEFT", panel.CompactControl, "RIGHT", 6, 0)
 panel.CollectionTab = button(toolbar, "Ma collecte", 92, function() showItem(nil) end)
 panel.CollectionTab:SetPoint("LEFT", panel.SourcesTab, "RIGHT", 4, 0)
 panel.OptionsButton = button(toolbar, "Options", 65, function()
  optionsOpen = true
  panel.SourcePicker:Hide()
  refresh()
 end)
 panel.OptionsButton:SetPoint("LEFT", panel.CollectionTab, "RIGHT", 4, 0)
 for _, tab in ipairs({panel.SourcesTab, panel.CollectionTab, panel.OptionsButton}) do
  local underline = tab:CreateTexture(nil, "OVERLAY")
  underline:SetPoint("BOTTOMLEFT", 8, 2)
  underline:SetPoint("BOTTOMRIGHT", -8, 2)
  underline:SetHeight(2)
  underline:SetColorTexture(0.90, 0.70, 0.30, 1)
  tab.ActiveLine = underline
 end
 panel.MapSettings = CreateFrame("Frame", nil, panel)
 panel.MapSettings:SetPoint("TOPLEFT", 18, -44)
 panel.MapSettings:SetPoint("BOTTOMRIGHT", -18, 16)
 panel.MapSettings:Hide()
 local settingsPage = CreateFrame("ScrollFrame", nil, panel.MapSettings, "UIPanelScrollFrameTemplate")
 settingsPage:SetPoint("TOPLEFT", 0, 0)
 settingsPage:SetPoint("BOTTOMRIGHT", -18, 0)
 local settingsBody = CreateFrame("Frame", nil, settingsPage)
 settingsBody:SetSize(1, 732)
 settingsPage:SetScrollChild(settingsBody)
 settingsPage:SetScript("OnSizeChanged", function(_, width) settingsBody:SetWidth(math.max(1, width)) end)
 label(settingsBody, "GameFontNormalLarge", 4, -5):SetText("Options")
 local backOptions = button(panel.MapSettings, "", 159, function()
  optionsOpen = false
  refresh()
 end)
 backOptions:SetPoint("TOPRIGHT", -23, 0)
 panel.OptionsBack = backOptions
 local function section(text, y)
  local band = categoryBand(settingsBody, text)
  band:SetPoint("TOPLEFT", 8, y + 5)
  band:SetPoint("TOPRIGHT", -8, y + 5)
 end
 local function help(widget, text)
  widget:SetScript("OnEnter", function(self)
   GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
   GameTooltip:AddLine(text, 0.94, 0.91, 0.82, true)
   GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
 end
 local function setting(key, text, y, handler, description, parent)
  local control = CreateFrame("CheckButton", nil, parent or settingsBody, "UICheckButtonTemplate")
  control:SetSize(24, 24)
  control:SetPoint("TOPLEFT", 8, y)
  local caption = label(control, "GameFontHighlight", 27, -5)
  caption:SetText(text)
  control:SetHitRectInsets(0, -math.ceil(caption:GetStringWidth() or 0) - 4, 0, 0)
  control:SetScript("OnClick", function()
   handler()
   refresh()
  end)
  if description then help(control, description) end
  mapControls[key] = control
 end
 section("Suivi des composants", -41)
 for i, row in ipairs({
  {"compact", "Afficher le suivi", "Garde les objectifs visibles à l’écran pendant que tu joues."},
  {"locked", "Verrouiller la position", "Empêche les déplacements accidentels du suivi à l’écran."},
  {"collapsed", "Réduire le panneau", "Replie la liste en gardant le titre et le résumé."},
  {"notifyComplete", "Notifier les objectifs atteints", "Affiche un message lorsque tes sacs atteignent la quantité fixée."},
 }) do
  local key = row[1]
  setting(key, row[2], -59 - (i - 1) * 25, function() collection[key] = not collection[key] end, row[3])
 end
 section("Collecte", -170)
 setting("hideCompleted", "Masquer les objectifs terminés", -188, function()
  collection.hideCompleted = not collection.hideCompleted
 end, "Masque les lignes terminées dans Ma collecte et conserve leurs objectifs.")
 section("Carte", -224)
 local modeDescriptions = {
  manual = "Manuel : choisis une source dans Sources pour afficher son repère.",
  automatic = "Automatique : affiche les sources documentées de tes suivis dans MelloUI.",
  off = "Désactivé : masque les repères LeatherTracker.",
 }
 mapControls.modeDescription = label(settingsBody, "GameFontHighlightSmall", 8, -277)
 mapControls.modeDescription:SetPoint("TOPRIGHT", -8, -277)
 mapControls.modes = {}
 for i, key in ipairs({"manual", "automatic", "off"}) do
  local mode = button(settingsBody, mapModes[key], 91, function()
   collection.map.mode = key
   refresh()
  end)
  mode:SetPoint("TOPLEFT", 8 + (i - 1) * 95, -243)
  help(mode, modeDescriptions[key])
  mapControls.modes[key] = mode
 end
 local advanced = CreateFrame("Frame", nil, settingsBody)
 advanced:SetPoint("TOPLEFT", 0, -340)
 advanced:SetPoint("TOPRIGHT", 0, -340)
 advanced:SetHeight(181)
 mapControls.advanced = advanced
 local advancedButton = button(settingsBody, "Réglages avancés de la carte", 216, function()
  collection.map.advancedOpen = not collection.map.advancedOpen
  refresh()
 end)
 advancedButton:SetPoint("TOPLEFT", 8, -309)
 mapControls.advancedButton = advancedButton
 for i, row in ipairs({
  {"multiple", "Afficher plusieurs composants", "Conserve les repères de plusieurs composants à la fois."},
  {"hideDone", "Masquer les objectifs atteints sur la carte", "Retire de la carte les repères des objectifs déjà atteints dans tes sacs."},
  {"tips", "Afficher les infobulles", "Affiche les détails des repères LeatherTracker au survol."},
 }) do
  local key = row[1]
  setting(key, row[2], -(i - 1) * 25, function()
   collection.map[key] = not collection.map[key]
   if key == "multiple" and not collection.map.multiple then
    selectedPins, collection.map.manualItems = {}, {}
   end
  end, row[3], advanced)
 end
 setting("mapTracked", "Afficher les composants suivis", -75, function() setMapLayer(0, collection.map.layersHidden) end, nil, advanced)
 for index, layer in ipairs(layerDefinitions) do
  setting(layer.id, layer.name, -75 - index * 25, function()
   setMapLayer(layer.id, collection.map.hiddenKinds[layer.id])
  end, nil, advanced)
 end
 local lower = CreateFrame("Frame", nil, settingsBody)
 lower:SetPoint("TOPLEFT", 0, -345)
 lower:SetPoint("TOPRIGHT", 0, -345)
 lower:SetHeight(186)
 mapControls.lower = lower
 mapControls.settingsBody = settingsBody
 local learningBand = categoryBand(lower, "Apprentissage du dépeçage")
 learningBand:SetPoint("TOPLEFT", 8, 5)
 learningBand:SetPoint("TOPRIGHT", -8, 5)
 setting("learning", "Mémoriser mes dépeçages", -19, function()
  addon.SetSkinningLearningEnabled(LeatherTrackerFRDB.skinningLearningDisabled == true)
 end, "Enregistre les dépeçages observés pour compléter les fiches Sources.", lower)
 mapControls.learningState = label(lower, "GameFontHighlightSmall", 8, -52)
 mapControls.learningState:SetPoint("TOPRIGHT", -8, -52)
 mapControls.learningState:SetText("")
 local infoBand = categoryBand(lower, "Informations")
 infoBand:SetPoint("TOPLEFT", 8, -95)
 infoBand:SetPoint("TOPRIGHT", -8, -95)
 label(lower, "GameFontHighlight", 8, -120):SetText("LeatherTracker FR  ·  "..version)
 mapControls.openLayers = button(lower, "Ouvrir les calques MelloUI", 240, function()
  local module = mapLayersModule()
  if module then
   syncMap()
   if not module:OpenLayers() then print("LeatherTracker : calques MelloUI indisponibles.") end
  end
 end)
 mapControls.openLayers:SetPoint("TOPLEFT", 8, -148)
 scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT", 18, -103)
 scroll:SetPoint("BOTTOMRIGHT", -35, 16)
 list = CreateFrame("Frame", nil, scroll)
 list:SetSize(555, 1)
 scroll:SetScript("OnSizeChanged", function(_, width) list:SetWidth(math.max(width, 1)) end)
 scroll:SetScrollChild(list)
 panel.Message = label(list, "GameFontHighlight", 8, -8)
 panel.Undo = button(panel, "Annuler le retrait", 125, function()
  if removed then track(removed.id, removed.goal); removed = nil; refresh() end
 end)
 panel.Undo:SetPoint("BOTTOMRIGHT", -35, 8)
 summary = label(panel, "GameFontHighlightSmall", 21, -101)
 scroll:SetPoint("TOPLEFT", 18, -123)
 scroll:SetPoint("BOTTOMRIGHT", -35, 37)
 sourceHeading = label(list, "GameFontNormal", 8, -3)
 sourceHeading:SetText("Où obtenir cet objet ?")
 sourceFooter = label(list, "GameFontHighlightSmall", 8, -140)
 sourceFooter:SetPoint("TOPRIGHT", -8, -140)
 local link = input(panel, 250, 160)
 panel.SourceLinkPopup = link
 link:SetPoint("BOTTOMRIGHT", -36, 8)
 link:SetScript("OnEnterPressed", function(self) self:Hide() end)
 link:SetScript("OnEscapePressed", function(self) self:Hide() end)
 link:SetScript("OnEditFocusLost", function(self) self:Hide() end)
 link:Hide()
 local recipeHeader = categoryBand(list, "Recettes utilisant ce composant", function()
  local state = sourceSelection[activeItem]
  state.recipesOpen = not state.recipesOpen
  refresh()
 end)
 recipeHeader:SetPoint("TOPLEFT", 7, 0)
 recipeHeader:SetPoint("TOPRIGHT", -7, 0)
 panel.SourceRecipes = recipeHeader
 panel.SourceRecipeRows = {}
 local function changeRecipePage(delta)
  local state = sourceSelection[activeItem]
  state.recipePage = (state.recipePage or 1) + delta
  refresh()
 end
 panel.RecipePrevious = button(list, "<", 24, function() changeRecipePage(-1) end)
 panel.RecipeNext = button(list, ">", 24, function() changeRecipePage(1) end)
 panel.RecipeNative = button(list, "Voir dans Fabrication", 153, function()
  local state = sourceSelection[activeItem]
  local api = C_TradeSkillUI
  if not state.recipeID or not api or type(api.OpenRecipe) ~= "function" then return end
  local parent = panel:GetParent()
  LeatherTrackerCloseCollection()
  local ok, opened = pcall(api.OpenRecipe, state.recipeID)
  if not ok or opened == false then
   if parent:IsVisible() then panel:Show(); refresh() end
   print("LeatherTracker : cette recette n’a pas pu être ouverte dans Fabrication.")
  end
 end)
 panel.RecipeIngredients = label(list, "GameFontHighlight", 7, 0)
 panel.RecipeIngredients:SetSpacing(3)

 local places = CreateFrame("Frame", nil, panel)
 panel.SourcePlaces = places
 places:SetPoint("TOPLEFT", 18, -107)
 places:SetPoint("BOTTOMLEFT", 18, 37)
 places:SetWidth(190)
 places:Hide()
 background(places, 0.12, 0.095, 0.075)
 label(places, "GameFontNormal", 8, -7):SetText("Filtres des sources")
 local placeScroll = CreateFrame("ScrollFrame", nil, places, "UIPanelScrollFrameTemplate")
 placeScroll:SetPoint("TOPLEFT", 5, -27)
 placeScroll:SetPoint("BOTTOMRIGHT", -21, 5)
 local placeBody = CreateFrame("Frame", nil, placeScroll)
 placeBody:SetSize(164, 1)
 placeScroll:SetScrollChild(placeBody)
 placeScroll:SetScript("OnSizeChanged", function(_, width) placeBody:SetWidth(math.max(width, 1)) end)
 places.Scroll, places.Body = placeScroll, placeBody
 local function filterBand(key, title)
  local band = categoryBand(placeBody, title, function()
   local state = sourceSelection[activeItem]
   state[key] = not state[key]
   refresh()
  end)
  return band
 end
 places.Method = filterBand("methodsFolded", "Méthodes")
 places.Location = filterBand("locationsFolded", "Continents et zones")
 places.Method:SetPoint("TOPLEFT", 0, 0)
 places.Method:SetPoint("TOPRIGHT", 0, 0)

 local searchBar = CreateFrame("Frame", nil, panel)
 panel.SourceSearchBar = searchBar
 searchBar:SetHeight(26)
 searchBar:SetPoint("TOPLEFT", places, "TOPRIGHT", 14, 0)
 searchBar:SetPoint("TOPRIGHT", -35, -107)
 searchBar:Hide()
 local search = input(searchBar, 100, 90)
 panel.SourceSearch = search
 search:SetPoint("TOPLEFT", 8, 0)
 local sort = button(searchBar, "", 116, function()
  sortSourcesByRate = not sortSourcesByRate
  collection.sortSourcesByRate = sortSourcesByRate
  scroll:SetVerticalScroll(0)
  refresh()
 end)
 panel.SourceSort = sort
 sort:SetPoint("TOPRIGHT", -2, 0)
 search:SetPoint("RIGHT", sort, "LEFT", -6, 0)
 local placeholder = label(search, "GameFontDisableSmall", 2, -6)
 placeholder:SetText("Rechercher une source")
 search:SetScript("OnTextChanged", function(self)
  placeholder:SetShown(self:GetText() == "")
  if paintingSourceSearch then return end
  if activeItem and sourceSelection[activeItem] then sourceSelection[activeItem].query = self:GetText() end
  scroll:SetVerticalScroll(0)
  refresh()
 end)

 panel.Message:SetPoint("TOPRIGHT", -8, -8)
end

local function createCompact()
 compact = CreateFrame("Frame", nil, UIParent)
 compact:SetSize(238, 40)
 local pos = collection.position
 compact:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", pos.x or -265, pos.y or -240)
 compact:SetClampedToScreen(true)
 compact:SetMovable(true)
 compact:EnableMouse(true)
 compact:RegisterForDrag("LeftButton")
 compact:SetScript("OnDragStart", function(self)
  if not collection.locked then self:StartMoving() end
 end)
 compact:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  collection.position = {
   x = self:GetRight() - UIParent:GetRight(), y = self:GetTop() - UIParent:GetTop(),
  }
 end)
 background(compact, 0.09, 0.07, 0.05)
 label(compact, "GameFontNormal", 10, -8):SetText("LeatherTracker • Collecte")
 compact.Summary = label(compact, "GameFontHighlightSmall", 10, -59)
 local fold = CreateFrame("Button", nil, compact)
 fold:SetSize(18, 18)
 fold:SetPoint("TOPRIGHT", -7, -5)
 fold:SetFrameLevel(compact:GetFrameLevel() + 2)
 fold:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
 fold:SetScript("OnClick", function()
  collection.collapsed = not collection.collapsed
  refresh()
 end)
 compact.Fold = fold
end

local function openCompactItem(id)
 local frame = ProfessionsFrame
 if frame and frame:IsVisible() then
  if not panel then createPanel(frame) end
  showItem(id)
  return
 end
 if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
  local ok, opened = pcall(C_TradeSkillUI.OpenTradeSkill, 165)
  if ok and opened ~= false then pendingItem, pendingTime = id, 4; return end
 end
 print("LeatherTracker : ouvre la fenêtre Métiers pour consulter ce composant.")
end

local function renderSourceRecipes(state, records)
 local header, rows = panel.SourceRecipes, panel.SourceRecipeRows
 local ingredients, native = panel.RecipeIngredients, panel.RecipeNative
 for _, row in ipairs(rows) do row:Hide() end
 panel.RecipePrevious:Hide()
 panel.RecipeNext:Hide()
 ingredients:Hide()
 native:Hide()
 header:SetShown(#records > 0)
 if #records == 0 then return 0 end
 header.Text:SetText(("Recettes utilisant ce composant (%d)"):format(#records))
 setBandExpanded(header, state.recipesOpen)
 if not state.recipesOpen then return 33 end
 local pages = math.ceil(#records / recipePageSize)
 local page = math.min(pages, math.max(1, tonumber(state.recipePage) or 1))
 state.recipePage = page
 local first = (page - 1) * recipePageSize + 1
 local y, selected = 29, nil
 for index = first, math.min(#records, first + recipePageSize - 1) do
  local record = records[index]
  local rowIndex = index - first + 1
  local row = rows[rowIndex]
  if not row then
   row = CreateFrame("Button", nil, list)
   row:SetHeight(29)
   row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
   row.Icon = row:CreateTexture(nil, "ARTWORK")
   row.Icon:SetSize(22, 22)
   row.Icon:SetPoint("LEFT", 4, 0)
   local name = label(row, "GameFontHighlight", 32, -1)
   name:SetPoint("TOPRIGHT", -6, -1)
   name:SetWordWrap(false)
   row:SetFontString(name)
   row.Status = label(row, "GameFontHighlightSmall", 32, -15)
   rows[rowIndex] = row
  end
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", 7, -y)
  row:SetPoint("TOPRIGHT", -7, -y)
  row:SetText(record.name)
  local _, outputIcon
  if record.output then _, outputIcon = itemInfo(record.output) end
  row.Icon:SetTexture(record.icon or outputIcon or "Interface\\Icons\\INV_Misc_Book_09")
  row.Status:SetText(record.learned == true and "Apprise" or record.learned == false and "Non apprise" or "Statut inconnu")
  row:SetScript("OnClick", function()
   state.recipeID = state.recipeID ~= record.id and record.id or nil
   refresh()
  end)
  if state.recipeID == record.id then
   row:LockHighlight()
   selected = record
  else
   row:UnlockHighlight()
  end
  row:Show()
  y = y + 31
 end
 if pages > 1 then
  panel.RecipePrevious:SetPoint("TOPLEFT", 7, -y)
  panel.RecipeNext:SetPoint("TOPLEFT", 36, -y)
  panel.RecipePrevious:SetEnabled(page > 1)
  panel.RecipeNext:SetEnabled(page < pages)
  panel.RecipePrevious:Show()
  panel.RecipeNext:Show()
  y = y + 29
 end
 if selected then
  local lines = {}
  for _, slot in ipairs(selected.slots) do
   local choices = {}
   for _, id in ipairs(slot.items) do choices[#choices + 1] = itemInfo(id) end
   lines[#lines + 1] = ("%d × %s%s"):format(slot.quantity, table.concat(choices, " ou "),
    slot.optional and " (facultatif)" or "")
  end
  ingredients:ClearAllPoints()
  ingredients:SetPoint("TOPLEFT", 7, -y)
  ingredients:SetPoint("TOPRIGHT", -7, -y)
  ingredients:SetText(table.concat(lines, "\n"))
  ingredients:Show()
  y = y + math.max(#lines * 15, ingredients:GetStringHeight() or 0) + 5
  if selected.learned == true and C_TradeSkillUI and type(C_TradeSkillUI.OpenRecipe) == "function" then
   native:SetPoint("TOPLEFT", 7, -y)
   native:Show()
   y = y + 29
  end
 end
 return y + 7
end

function addon.SkinningSourcesChanged(drops)
 if panel and panel:IsVisible() and sourcesOpen and not optionsOpen and activeItem and drops[activeItem] then
  pendingItemRefresh = true
 end
end

refresh = function()
 if not collection then return end
 pendingItemRefresh = nil
 syncMap()
 local ids = {}
 for id in pairs(collection.goals) do ids[#ids + 1] = id end
 table.sort(ids)
 local missing = 0
 for _, id in ipairs(ids) do missing = missing + math.max(0, collection.goals[id] - (stock(id) or 0)) end
 local overview = ("%d composant(s) suivi(s)  •  %s"):format(#ids, bagStock and (missing.." à récupérer") or "stock indisponible")
 sourceOrder = ids
 if panel and panel:IsShown() then
  local showSourcesTab = sourcesOpen and not optionsOpen
  local showSource = showSourcesTab and activeItem ~= nil
  local showCollection = not sourcesOpen and not optionsOpen
  local objectives = {}
  if showCollection then
   for _, id in ipairs(ids) do
    local owned = stock(id)
    if not collection.hideCompleted or not owned or owned < collection.goals[id] then objectives[#objectives + 1] = id end
   end
   table.sort(objectives, function(a, b)
    local doneA = (stock(a) or 0) >= collection.goals[a]
    local doneB = (stock(b) or 0) >= collection.goals[b]
    if doneA ~= doneB then return not doneA end
    return a < b
   end)
  end
  for index, row in ipairs(rows) do
   local id = showCollection and objectives[index]
   if row.item ~= id then
    row.item = nil
    row.goal:ClearFocus()
   end
   if not id then row:Hide() end
  end
  panel.MapSettings:SetShown(optionsOpen)
  for _, tab in ipairs({panel.SourcesTab, panel.CollectionTab, panel.OptionsButton}) do
   local selected = (tab == panel.SourcesTab and showSourcesTab) or (tab == panel.CollectionTab and showCollection)
    or (tab == panel.OptionsButton and optionsOpen)
   tab.ActiveLine:SetShown(selected)
   if selected then tab:LockHighlight() else tab:UnlockHighlight() end
  end
  panel.OptionsBack:SetText(sourcesOpen and "Retour à la source" or "Retour à ma collecte")
  scroll:SetShown(showSource or showCollection)
  title:SetShown(not optionsOpen)
  title:ClearAllPoints()
  title:SetWidth(0)
  if showSource then
   title:SetPoint("LEFT", panel.SourcePrevious, "RIGHT", 7, 0)
   title:SetJustifyH("LEFT")
   title:SetWordWrap(false)
   local name, icon = itemInfo(activeItem)
   panel.ItemIcon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
   title:SetText(name)
   local maxWidth = math.max(40, panel:GetWidth() - 305)
   title:SetWidth(math.min(maxWidth, math.max(1, title:GetStringWidth() or maxWidth)))
  elseif showSourcesTab then
   title:SetPoint("TOPLEFT", 20, -50)
   title:SetText("Sources")
  else
   title:SetPoint("TOPLEFT", panel.Catalog, "TOPRIGHT", 17, -4)
   title:SetText("Ma collecte")
  end
  panel.Catalog:SetShown(showCollection)
  if showCollection then
   panel.Catalog:SetWidth(math.max(120, (panel:GetWidth() - 64) * 0.30))
   renderComponentCatalog()
  end
  panel.Back:SetShown(showSource)
  panel.ItemIcon:SetShown(showSource)
  panel.SourceCounts:SetShown(showSource)
  panel.SourceEmpty:SetShown(showSourcesTab and not activeItem)
  panel.SourceCatalog:SetShown(showSourcesTab and not activeItem)
  local showNavigation = showSource and #ids > 0
  local itemIndex
  for index, id in ipairs(ids) do if id == activeItem then itemIndex = index; break end end
  panel.SourcePrevious:SetShown(showSource)
  panel.SourceNext:SetShown(showSource)
  local canPrevious = showNavigation and (not itemIndex or itemIndex > 1)
  local canNext = showNavigation and (not itemIndex or itemIndex < #ids)
  panel.SourcePrevious:SetEnabled(canPrevious)
  panel.SourceNext:SetEnabled(canNext)
  panel.SourcePrevious.Arrow:SetAlpha(canPrevious and 1 or 0.4)
  panel.SourceNext.Arrow:SetAlpha(canNext and 1 or 0.4)
  panel.SourceIndex:SetShown(showNavigation and itemIndex ~= nil)
  if showNavigation then
   panel.SourceIndex:SetText(("%s / %d composants"):format(itemIndex or "–", #ids))
  end
  panel.SourcePickerButton:SetShown(showSource)
  local picker = panel.SourcePicker
  if not showSource then picker:Hide() end
  if picker:IsShown() then
   picker:SetHeight(38 + 24 * math.max(1, math.min(#ids, 8)))
   picker.Empty:SetShown(#ids == 0)
   picker.Body:SetHeight(24 * #ids)
   for index, id in ipairs(ids) do
    local row = picker.Rows[index]
    if not row then
     row = button(picker.Body, "", 238, nil)
     row:SetPoint("TOPLEFT", 0, -24 * (index - 1))
     picker.Rows[index] = row
    end
    row:SetText(itemInfo(id))
    row:SetEnabled(id ~= activeItem)
    row:SetScript("OnClick", function() showItem(id) end)
    row:Show()
   end
   for index = #ids + 1, #picker.Rows do picker.Rows[index]:Hide() end
  end
  summary:SetShown(showCollection)
  summary:ClearAllPoints()
  summary:SetPoint("TOPLEFT", panel.Catalog, "TOPRIGHT", 17, -26)
  summary:SetText(overview)
  panel.Undo:SetShown(showCollection and removed ~= nil)
  for _, entry in pairs(sourceLines) do entry:Hide() end

  for _, filter in ipairs(sourceFilters) do filter:Hide() end
  panel.SourcePlaces:SetShown(showSource)
  panel.SourceSearchBar:SetShown(showSource)
  panel.SourceSort:SetText(sortSourcesByRate and "Tri : taux" or "Tri : nom")
  if showSource then panel.SourcePlaces:SetWidth(math.max(120, (panel:GetWidth() - 64) * 0.30)) end
  if not showSource then renderSourceRecipes({}, {}) end
  sourceHeading:SetShown(showSource)
  sourceFooter:SetShown(showSource)
  panel.SourceLinkPopup:Hide()
  local compactLabel = collection.compact and "Masquer le suivi" or "Afficher le suivi"
  if panel:GetWidth() < 500 then compactLabel = collection.compact and "Masquer" or "Afficher" end
  panel.CompactControl:SetText(compactLabel)
  if optionsOpen then
   for _, key in ipairs({"compact", "locked", "collapsed", "notifyComplete", "hideCompleted"}) do
    mapControls[key]:SetChecked(not not collection[key])
   end
   mapControls.learning:SetChecked(not LeatherTrackerFRDB.skinningLearningDisabled)
   mapControls.learning:SetEnabled(type(addon.GetSkinningDiagnostic) == "function")
   lastDiagnosticText = learningText()
   mapControls.learningState:SetText(lastDiagnosticText)
  end
  local settings = collection.map
  local api = mapAPI()
  if optionsOpen then
   local advancedAvailable = api ~= nil or (TomTom and type(TomTom.AddWaypoint) == "function")
    or (C_Map and type(C_Map.SetUserWaypoint) == "function")
   local expanded = advancedAvailable and collection.map.advancedOpen
   mapControls.advanced:SetShown(not not expanded)
   mapControls.advancedButton:SetShown(not not advancedAvailable)
   mapControls.advancedButton:SetText(expanded and "Masquer les réglages avancés" or "Réglages avancés de la carte")
   local lowerY = expanded and -531 or advancedAvailable and -347 or -314
   mapControls.lower:SetPoint("TOPLEFT", 0, lowerY)
   mapControls.lower:SetPoint("TOPRIGHT", 0, lowerY)
   mapControls.settingsBody:SetHeight(-lowerY + 184)
   mapControls.openLayers:SetShown(not not (api and type(api.LeatherTrackerSetLayers) == "function" and mapLayersModule()))
   local descriptions = {
    manual = "Affiche un repère lorsque tu choisis une source.",
    automatic = api and "Affiche les sources documentées de tes suivis dans MelloUI." or "Affichage automatique disponible avec le module Carte de MelloUI.",
    off = "Masque les repères LeatherTracker.",
   }
   mapControls.modeDescription:SetText(descriptions[settings.mode])
   mapControls.mapTracked:SetChecked(not settings.layersHidden)
   for _, layer in ipairs(layerDefinitions) do
    mapControls[layer.id]:SetChecked(not settings.hiddenKinds[layer.id])
   end
   for mode, control in pairs(mapControls.modes) do
    control:SetEnabled(mode ~= settings.mode and (mode ~= "automatic" or api ~= nil))
   end
   for _, key in ipairs({"multiple", "hideDone", "tips"}) do
    mapControls[key]:SetChecked(not not settings[key])
   end
  end
  scroll:ClearAllPoints()
  if showCollection then
   scroll:SetPoint("TOPLEFT", panel.Catalog, "TOPRIGHT", 17, -49)
  else
   scroll:SetPoint("TOPLEFT", panel.SourceSearchBar, "BOTTOMLEFT", 0, -4)
  end
  scroll:SetPoint("BOTTOMRIGHT", -35, 37)
  panel.Message:SetShown(showCollection and #objectives == 0)
  if showSource then
   local owned, goal = stock(activeItem), collection.goals[activeItem]
   local sourcesForItem = catalogFor(activeItem)
   addLocalObservations(sourcesForItem, activeItem)
   addSkinningObservations(sourcesForItem, activeItem)
   panel.SourceCounts:SetText(("En sac : %s   •   Objectif : %s   •   Manquant : %s"):format(
    owned or "–", goal or "–", owned and goal and math.max(0, goal - owned) or "–"))
   if not goal then panel.SourceCounts:SetText(("En sac : %s   •   Composant non suivi"):format(owned or "–")) end
   local api = mapAPI()
   local settings = collection.map
   local filters, groups = sourceLayout(sourcesForItem)
   local selection = sourceSelection[activeItem]
   if not selection then
    selection = {group = "all"}
    sourceSelection[activeItem] = selection
   end
   if selection.group == "craft" or selection.group == "personal" then
    selection.method = selection.group == "craft" and "method:Fabrication" or "personal"
    selection.group = "all"
   end
   local selectedGroup = groups[selection.group] or groups.all
   local selectedMethod = groups[selection.method] or groups.allMethods
   local methodMatches = {}
   for _, index in ipairs(selectedMethod and selectedMethod.indices or {}) do methodMatches[index] = true end
   sourceHeading:SetText(selectedGroup and selectedGroup.key ~= "all" and selectedGroup.name or "Toutes les sources")
   local places = panel.SourcePlaces
   local methodY, locationY = 26, nil
   setBandExpanded(places.Method, not selection.methodsFolded)
   setBandExpanded(places.Location, not selection.locationsFolded)
   places.Method:SetShown(#filters > 0)
   places.Location:SetShown(#filters > 0)
   for i, group in ipairs(filters) do
    local filter = sourceFilters[i]
    if not filter then
     filter = CreateFrame("Button", nil, places.Body)
     filter:SetHeight(34)
     filter.Text = label(filter, "GameFontHighlight", 5, -3)
     filter.Text:SetPoint("BOTTOMRIGHT", -30, 2)
     filter.Count = label(filter, "GameFontHighlightSmall", 0, 0)
     filter.Count:ClearAllPoints()
     filter.Count:SetPoint("RIGHT", -4, 0)
     filter.Selected = filter:CreateTexture(nil, "BACKGROUND")
     filter.Selected:SetAllPoints()
     filter.Selected:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
     filter.Selected:SetVertexColor(0.86, 0.68, 0.37, 0.43)
     filter.Text:SetWordWrap(true)
     filter.Text:SetMaxLines(2)
     sourceFilters[i] = filter
    end
    local isMethod = group.rank < 2
    if not isMethod and not locationY then
     places.Location:ClearAllPoints()
     places.Location:SetPoint("TOPLEFT", 0, -methodY - 5)
     places.Location:SetPoint("TOPRIGHT", 0, -methodY - 5)
     locationY = methodY + 31
    end
    local folded = (isMethod and selection.methodsFolded) or (not isMethod and selection.locationsFolded)
    if not folded then
     local y = isMethod and methodY or locationY
     local height = isMethod and 24 or 34
     filter:SetHeight(height)
     if isMethod then methodY = y + height else locationY = y + height end
     filter:ClearAllPoints()
     filter:SetPoint("TOPLEFT", group.indent or 0, -y)
     filter:SetPoint("TOPRIGHT", 0, -y)
     local isContinent = group.key:find("^continent:") ~= nil
     local icon = isContinent and "INV_Misc_Orb_01" or group.key == "method:Fabrication" and "INV_Hammer_20"
      or group.key == "personal" and "INV_Misc_LeatherScrap_02"
      or group.key == "all" and "INV_Misc_Book_09" or "INV_Misc_Map_01"
     filter.Text:SetText("|TInterface\\Icons\\"..icon..":14:14|t  "..group.name)
     filter.Count:SetText(tostring(#group.indices))
     local selected = selectedGroup == group or selectedMethod == group
     filter.Selected:SetShown(selected)
     if selected then
      filter.Text:SetTextColor(1, 0.83, 0.43)
     elseif isContinent then
      filter.Text:SetTextColor(0.53, 0.85, 1)
     else
      filter.Text:SetTextColor(0.83, 0.87, 0.92)
     end
     filter:SetScript("OnClick", function()
      if isMethod then
       selection.method = group.key
      else
       selection.group = group.key
      end
      scroll:SetVerticalScroll(0)
      refresh()
     end)
     filter:Show()
    end
   end
   places.Body:SetHeight(locationY or methodY)
   local matches = {}
   local query = componentSearchText(panel.SourceSearch:GetText():match("^%s*(.-)%s*$"))
   for _, index in ipairs(selectedGroup and selectedGroup.indices or {}) do
    local source = sourcesForItem[index]
    local haystack = componentSearchText(table.concat({source.name, source.zone or "", source.method}, " "))
    if methodMatches[index] and (query == "" or haystack:find(query, 1, true)) then matches[#matches + 1] = index end
   end
   local function rate(source)
    return source.observedRate or (source.obtained and source.observations and 100 * source.obtained / source.observations) or -1
   end
   table.sort(matches, function(a, b)
    local first, second = sourcesForItem[a], sourcesForItem[b]
    if sortSourcesByRate and rate(first) ~= rate(second) then return rate(first) > rate(second) end
    if first.name == second.name then return a < b end
    return first.name < second.name
   end)
   local recipeHeight = renderSourceRecipes(selection, recipesByItem[activeItem] or {})
   sourceHeading:ClearAllPoints()
   sourceHeading:SetPoint("TOPLEFT", 8, -recipeHeight - 3)
   local rowY, rowHeight = recipeHeight + 27, 0
   local usable = math.max(1, list:GetWidth() - 14)
   local columns = usable >= 470 and 2 or 1
   local cardWidth = (usable - (columns - 1) * 12) / columns
   for rowIndex, index in ipairs(matches) do
    local source = sourcesForItem[index]
    local entry = sourceLines[rowIndex]
    if not entry then
     entry = CreateFrame("Frame", nil, list)
     local divider = entry:CreateTexture(nil, "BORDER")
     divider:SetPoint("BOTTOMLEFT", 8, 0)
     divider:SetPoint("BOTTOMRIGHT", -8, 0)
     divider:SetHeight(1)
     divider:SetColorTexture(0.41, 0.31, 0.18, 0.8)
     entry.Name = label(entry, "GameFontNormal", 10, -7)
     entry.Info = label(entry, "GameFontHighlight", 10, -31)
     entry.Map = button(entry, "Voir sur la carte", 121, nil)
     entry.Details = button(entry, "Détails", 67, nil)
     entry.Details:SetPoint("BOTTOMRIGHT", -8, 9)
     entry.Details:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(entry.sourceName)
      for _, line in ipairs(entry.details) do GameTooltip:AddLine(line, 0.88, 0.85, 0.78, true) end
      GameTooltip:AddLine("Cliquer pour sélectionner le lien ForeverDB.", 0.83, 0.78, 0.61, true)
      GameTooltip:Show()
     end)
     entry.Details:SetScript("OnLeave", function() GameTooltip:Hide() end)
     entry.Details:SetScript("OnClick", function()
      GameTooltip:Hide()
      local link = panel.SourceLinkPopup
      link:SetText("https://foreverdb.net/fr/item/"..activeItem)
      link:Show()
      link:SetFocus()
      link:HighlightText()
     end)
     entry.Map:SetPoint("BOTTOMLEFT", 10, 9)
     local ok, model = pcall(CreateFrame, "PlayerModel", nil, entry)
     if ok and model and type(model.SetCreature) == "function" then
      entry.Model = model
      model:SetSize(42, 42)
      model:SetPoint("TOPLEFT", 9, -7)
      entry.Loading = label(entry, "GameFontHighlightSmall", 12, -28)
      entry.Loading:SetText("")
      entry.Loading:Hide()
      if model.HasScript and model:HasScript("OnModelLoaded") then
       model:SetScript("OnModelLoaded", function()
        entry.modelReady = true
        entry.Loading:Hide()
        if entry.MerchantIcon then entry.MerchantIcon:Hide() end
       end)
      end
     end
     entry.MerchantIcon = entry:CreateTexture(nil, "ARTWORK")
     entry.MerchantIcon:SetSize(40, 40)
     entry.MerchantIcon:SetPoint("TOPLEFT", 10, -8)
     entry.MerchantIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
     local rateBox = CreateFrame("Frame", nil, entry)
     entry.RateBox = rateBox

     rateBox.Value = label(rateBox, "GameFontNormal", 2, -2)
     rateBox.Sample = label(rateBox, "GameFontHighlightSmall", 2, -17)
     rateBox.Sample:SetPoint("TOPRIGHT", -4, -17)
     sourceLines[rowIndex] = entry
    end
    local hasModel = false
    if entry.Model then
     if entry.modelCreatureID ~= source.creatureID then
      entry.Model:Hide()
      entry.Model:ClearModel()
      entry.Loading:SetShown(source.creatureID ~= nil)
      entry.modelCreatureID = source.creatureID
      entry.modelLoaded = false
      entry.modelReady = false
      if source.creatureID then
       local ok, loaded = pcall(entry.Model.SetCreature, entry.Model, source.creatureID)
       entry.modelLoaded = ok and loaded ~= false
       if not entry.modelLoaded then
        entry.Loading:Hide()
       elseif C_Timer and C_Timer.After then
        local requested = source.creatureID
        C_Timer.After(3, function()
         if entry.modelCreatureID == requested then entry.Loading:Hide() end
        end)
       end
      end
     end
     hasModel = entry.modelLoaded
     entry.Model:SetShown(hasModel)
    end
    local merchant = source.method == "Achat"
    local _, sourceIcon = itemInfo(activeItem)
    local fallback = merchant and "INV_Misc_Coin_01" or source.creatureID and "Ability_Hunter_BeastCall" or "INV_Misc_QuestionMark"
    entry.MerchantIcon:SetTexture((not merchant and not source.creatureID and sourceIcon) or ("Interface\\Icons\\"..fallback))
    entry.MerchantIcon:SetShown(not entry.modelReady)
    local rateBox = entry.RateBox
    local hasSample = type(source.observations) == "number" and source.observations > 0
     and (source.obtained ~= nil or source.observedRate ~= nil)
    rateBox:SetShown(hasSample)
    if hasSample then
     rateBox.Value:SetText((("%.1f %%"):format(rate(source)):gsub("%.", ",")))
     rateBox.Sample:SetText(source.personalSkinning and ("%d sur %d fenêtres de dépeçage"):format(source.obtained, source.observations)
      or source.obtained and ("%d obtention(s) sur %d observations"):format(source.obtained, source.observations)
      or (source.method == "Dépeçage" and ("%d corps dépecés"):format(source.observations)
       or ("%d observations"):format(source.observations)))
    end

    entry:ClearAllPoints()
    local column = (rowIndex - 1) % columns
    entry:SetPoint("TOPLEFT", 7 + column * (cardWidth + 12), -rowY)
    entry:SetWidth(cardWidth)
    entry.Map:SetWidth(math.min(121, math.max(75, cardWidth - 96)))

    local textLeft = 56
    entry.Name:ClearAllPoints()
    entry.Name:SetPoint("TOPLEFT", textLeft, -9)
    entry.Name:SetPoint("TOPRIGHT", -8, -9)
    entry.Name:SetWordWrap(true)
    entry.Name:SetMaxLines(2)
    entry.Info:ClearAllPoints()
    entry.Info:SetSpacing(3)
    entry.Name:SetText(source.name)
    local nameHeight = math.max(14, entry.Name:GetStringHeight() or 0)
    entry.Info:SetPoint("TOPLEFT", textLeft, -12 - nameHeight)
    entry.Info:SetPoint("TOPRIGHT", -10, -12 - nameHeight)
    local provenance = source.provenance or source.locationSource or "ForeverDB.net"
    local primary = {source.method .. (source.level and ("  •  Niv. "..source.level) or "")}
    if source.zone then primary[#primary + 1] = source.zone end
    if source.skill then primary[#primary + 1] = source.skill end
    primary[#primary + 1] = source.tentative and "Piste Classic à confirmer" or provenance
    entry.Info:SetText(table.concat(primary, "\n"))
    entry.sourceName = source.name
    local details = {provenance}
    if source.creatureID then details[#details + 1] = "PNJ #"..source.creatureID end
    if mappable(source) then
     details[#details + 1] = ("Position %.1f / %.1f%s"):format(source.x * 100, source.y * 100,
      source.approximate and " (approximative)" or "")
    elseif source.zone then
     details[#details + 1] = "Zone connue. Position précise non vérifiée."
    end
    if source.locationSource and source.locationSource ~= provenance then details[#details + 1] = source.locationSource end
    if source.shop then details[#details + 1] = source.shop end
    if source.context then details[#details + 1] = source.context end
    if source.learnedFrom then details[#details + 1] = source.learnedFrom end
    if hasSample then
     details[#details + 1] = "Fréquence observée dans l’échantillon."
     if source.observations < 30 then details[#details + 1] = "Échantillon limité." end
    end
    entry.details = details
    local infoHeight = math.max(#primary * 14, entry.Info:GetStringHeight() or 0)
    local ratesY = math.max(52, 15 + nameHeight + infoHeight)
    rateBox:ClearAllPoints()
    rateBox:SetPoint("TOPLEFT", 8, -ratesY)
    rateBox:SetPoint("TOPRIGHT", -8, -ratesY)
    local sampleHeight = hasSample and math.max(30, 19 + (rateBox.Sample:GetStringHeight() or 0)) or 0
    rateBox:SetHeight(sampleHeight)
    local height = ratesY + sampleHeight + 37
    entry:SetHeight(height)
    rowHeight = math.max(rowHeight, height)
    if column == columns - 1 or rowIndex == #matches then
     rowY, rowHeight = rowY + rowHeight + 10, 0
    end
    local tomtom = settings.mode == "manual" and TomTom and type(TomTom.AddWaypoint) == "function"
      and C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MelloUI")
    local native = mappable(source) and nativeWaypointAvailable(source.map)
    local canMap = mappable(source) and (api or tomtom or native) and settings.mode ~= "off"
     and not settings.layersHidden and not settings.hiddenKinds[sourceLayer(source)]
     and not (settings.hideDone and owned and goal and owned >= goal)
    local zone = not mappable(source) and ((not source.tentative and type(source.map) == "number" and source.map > 0 and source.map)
     or documentedZoneMap(source))
    local canOpenZone = not not (zone and (api or (WorldMapFrame and type(WorldMapFrame.SetMapID) == "function")))
    entry.Map:SetText(canOpenZone and "Voir la zone" or "Voir sur la carte")
    entry.Map:SetEnabled(not not (canMap or canOpenZone))
    entry.Map:SetShown(canMap or canOpenZone)
    entry.Map:SetScript("OnClick", function()
     if canOpenZone then
      if api then
       local ok, opened = pcall(api.Show, api, zone)
       if ok and opened ~= false then return end
      end
      if WorldMapFrame and type(WorldMapFrame.SetMapID) == "function" then
       WorldMapFrame:Show()
       WorldMapFrame:SetMapID(zone)
      end
      return
     end
     if not canMap then return end
     if api then
      preferredMapItem = activeItem
      if not settings.multiple then selectedPins, settings.manualItems = {}, {} end
      local key = activeItem..":"..index
      selectedPins[key] = true
      mapPreview = not goal and {id = activeItem, key = "preview:"..key, source = source} or nil
      focusedPin = mapPreview and mapPreview.key or source.sharedPin or key
      syncMap()
      if pins[focusedPin] then
       if type(api.LeatherTrackerFocus) == "function" then
        local ok, centered = pcall(api.LeatherTrackerFocus, api, source.map, source.x, source.y)
        if ok and centered then return end
       end
       local ok, opened = pcall(api.Show, api, source.map)
       if ok and opened ~= false then return end
      end
     elseif tomtom then
      if tomtomPin and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomPin) end
      tomtomPin = TomTom:AddWaypoint(source.map, source.x, source.y, {
       title = source.name.." • "..(source.locationSource or "LeatherTracker FR"), persistent = false,
      })
      tomtomItem, tomtomKind = activeItem, sourceLayer(source)
      if tomtomPin then
       print("LeatherTracker : repère envoyé à TomTom. Ouvre la carte MelloUI.")
       return
      end
     end
     local ok, shown = pcall(showNativeWaypoint, source)
     if not ok or not shown then print("LeatherTracker : ce repère est indisponible sur la carte.") end
    end)
    entry:Show()
   end
   local footerY = rowY + 12
   sourceFooter:ClearAllPoints()
   sourceFooter:SetPoint("TOPLEFT", 8, -footerY)
   sourceFooter:SetPoint("TOPRIGHT", -8, -footerY)
   sourceFooter:SetText(#sourcesForItem == 0
    and "Aucune source vérifiée importée pour cet objet.\nLocalisation non vérifiée."
    or (#matches == 0 and "Aucune source ne correspond à la recherche.")
    or "Données documentaires et observations personnelles.")
   list:SetHeight(footerY + 38)
  elseif showCollection and #objectives == 0 then
   list:SetHeight(52)
   panel.Message:SetText(#ids > 0 and "Tous les objectifs sont atteints." or "Utilise + dans le catalogue pour suivre un composant.")
  elseif showCollection then
   list:SetHeight(81 * #objectives)
   for index, id in ipairs(objectives) do
    local row = rows[index] or createRow(index)
    rows[index], row.item = row, id
    local goal, owned = collection.goals[id], stock(id)
    local name, icon = itemInfo(id)
    row.name:SetText(name)
    row.icon:SetTexture(icon)
    row.status:SetText(owned and (owned >= goal and ("%d / %d en sac • Objectif atteint"):format(owned, goal)
     or ("%d / %d en sac   •   %d manquants"):format(owned, goal, goal - owned)) or "Stock indisponible")
    if not row.goal:HasFocus() then row.goal:SetText(tostring(goal)) end
    row.bar:SetValue(math.min(1, (owned or 0) / goal))
    row.bar:SetStatusBarColor(0.35, owned and owned >= goal and 0.72 or 0.55, 0.30)
    row:Show()
   end
  end
 end
 if collection.compact and #ids > 0 then
  if not compact then createCompact() end
  compact:Show()
  for _, row in ipairs(compactRows) do row:Hide() end
  compact.Summary:SetText(overview)
  local art = "Interface\\Minimap\\UI-Minimap-Zoom"..(collection.collapsed and "In" or "Out").."Button-"
  compact.Fold:SetNormalTexture(art.."Up")
  compact.Fold:SetPushedTexture(art.."Down")
  local visible = not collection.collapsed and math.min(8, #ids) or 0
  compact:SetHeight(54 + visible * 24)
  compact.Summary:ClearAllPoints()
  compact.Summary:SetPoint("TOPLEFT", 10, -31 - visible * 24)
  for index = 1, visible do
   local id = ids[index]
   local row = compactRows[index]
   if not row then
    row = CreateFrame("Button", nil, compact)
    row:SetSize(222, 23)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnClick", function(self) openCompactItem(self.item) end)
    row.name = label(row, "GameFontHighlightSmall", 25, -5)
    row.name:SetPoint("RIGHT", -67, 0)
    row.name:SetWordWrap(false)
    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.count:SetPoint("RIGHT", -2, 0)
    row:SetPoint("TOPLEFT", 8, -27 - (index - 1) * 24)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 4, 0)
    compactRows[index] = row
   end
   row.item = id
   local name, icon = itemInfo(id)
   row.icon:SetTexture(icon)
   row.name:SetText(name)
   local owned, goal = stock(id), collection.goals[id]
   row.count:SetText(("%s/%d"):format(owned or "–", goal))
   row.count:SetTextColor(owned and owned >= goal and 0.50 or 0.93, 0.93, 0.64)
   row:Show()
  end
 elseif compact then compact:Hide() end
end

function LeatherTrackerToggleCollection()
 if not collection then return end
 local frame = ProfessionsFrame
 if not frame or not frame:IsVisible() then
  print("LeatherTracker : ouvre la fenêtre Métiers.")
  return
 end
 local ok, failure = pcall(function()
  if not panel then createPanel(frame) end
  if panel:IsShown() then
   LeatherTrackerCloseCollection()
  else
   local api = leatherworkingRecipe(frame.CraftingPage and frame.CraftingPage.SchematicForm)
   if api then scanLeatherworking(api) end
   showItem(nil)
  end
 end)
 if not ok then
  LeatherTrackerCloseCollection()
  print("LeatherTracker : erreur à l’ouverture — "..tostring(failure))
 end
end

local REAGENT_BUTTON_WIDTH = 20

local function reagentActionFits(slot)
 if not slot.Name or not slot.Button then return false end
 local right, nameRight, iconRight = slot:GetRight(), slot.Name:GetRight(), slot.Button:GetRight()
 if not right or not nameRight or not iconRight then return false end
 if right - math.max(nameRight, iconRight) < REAGENT_BUTTON_WIDTH + 4 then return false end
 -- The native checkbox and checkmark can take this same gutter.
 for _, region in ipairs({slot.Checkbox or false, slot.Checkmark or false}) do
  if region and region:IsShown() then return false end
 end
 return true
end

local function styleReagentButton(control)
 local function texture(layer, red, green, blue, alpha)
  local region = control:CreateTexture(nil, layer)
  region:SetAllPoints()
  region:SetColorTexture(red, green, blue, alpha)
  return region
 end
 local rim = texture("BACKGROUND", 0.58, 0.41, 0.21, 1)
 local normal = texture("BORDER", 0.20, 0.12, 0.065, 1)
 local pushed = texture("BORDER", 0.36, 0.20, 0.09, 1)
 local disabled = texture("BORDER", 0.13, 0.12, 0.11, 1)
 for _, region in ipairs({normal, pushed, disabled}) do
  region:ClearAllPoints()
  region:SetPoint("TOPLEFT", rim, "TOPLEFT", 1, -1)
  region:SetPoint("BOTTOMRIGHT", rim, "BOTTOMRIGHT", -1, 1)
 end
 control:SetNormalTexture(normal)
 control:SetPushedTexture(pushed)
 control:SetDisabledTexture(disabled)
 control:SetHighlightTexture(texture("ARTWORK", 0.84, 0.59, 0.27, 0.24))
 local glyph = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
 glyph:SetPoint("CENTER", 0, 1)
 control:SetFontString(glyph)
 control:SetSize(REAGENT_BUTTON_WIDTH, 20)
end

local function indexRecipeOptions(options)
 for _, option in ipairs(options or {}) do
  local id = itemID(option.itemID)
  if id and not indexedComponents[id] then
   indexedComponents[id] = true
   collection.recipeComponents[id] = true
   otherComponents.items[#otherComponents.items + 1] = id
   catalogRevision = catalogRevision + 1
  end
 end
end

local scannedLeatherworking = false
scanLeatherworking = function(api)
 if scannedLeatherworking or not api.GetAllRecipeIDs or not api.GetRecipeSchematic then return end
 local ok, ids = pcall(api.GetAllRecipeIDs)
 if not ok or type(ids) ~= "table" or #ids == 0 then return end
 local read = false
 for _, recipeID in ipairs(ids) do
  local success, profession = pcall(api.GetProfessionInfoByRecipeID, recipeID)
  if success and type(profession) == "table" and (profession.parentProfessionID or profession.professionID) == 165 then
   local fetched, schematic = pcall(api.GetRecipeSchematic, recipeID, false)
   if fetched and type(schematic) == "table" and type(schematic.reagentSlotSchematics) == "table" then
    read = true
    local infoOK, info
    if api.GetRecipeInfo then infoOK, info = pcall(api.GetRecipeInfo, recipeID) end
    if not infoOK or type(info) ~= "table" then info = nil end
    local name = info and info.name or schematic.name
    local record = {id = recipeID, name = type(name) == "string" and name or ("Recette #"..recipeID), slots = {}}
    record.output = itemID(schematic.outputItemID)
    if info then
     record.icon = info.icon
     if type(info.learned) == "boolean" then record.learned = info.learned end
    end
    local inputs = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
     indexRecipeOptions(slot.reagents)
     local count = tonumber(slot.quantityRequired)
     if count and count > 0 then
      local options, seen = {}, {}
      for _, option in ipairs(slot.reagents or {}) do
       local id = itemID(option.itemID)
       if id and not seen[id] then
        inputs[id], seen[id] = true, true
        options[#options + 1] = id
       end
      end
      if #options > 0 then
       record.slots[#record.slots + 1] = {items = options, quantity = count, optional = slot.required == false}
      end
     end
    end
    for id in pairs(inputs) do
     recipesByItem[id] = recipesByItem[id] or {}
     local listForItem = recipesByItem[id]
     listForItem[#listForItem + 1] = record
    end
   end
  end
 end
 if read then
  scannedLeatherworking = true
  table.sort(otherComponents.items)
  for _, records in pairs(recipesByItem) do
   table.sort(records, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
  end
 end
end

local function syncReagents()
 local visible = {}
 local frame = ProfessionsFrame
 local page = frame and frame.CraftingPage
 local form = page and page.SchematicForm
 if not collection or not form or not form:IsVisible() or page:GetAlpha() == 0
  or not form.GetSlots or not form.GetRecipeInfo then
  for _, control in pairs(reagentButtons) do control:Hide() end
  return
 end
 local api = leatherworkingRecipe(form)
 local slotsOK, slots
 if api then slotsOK, slots = pcall(form.GetSlots, form) end
 if not slotsOK or type(slots) ~= "table" then
  for _, control in pairs(reagentButtons) do control:Hide() end
  return
 end
 scanLeatherworking(api)
 for _, slot in ipairs(slots) do
  local schematic = slot.GetReagentSlotSchematic and slot:GetReagentSlotSchematic()
  local candidates = schematic and schematic.reagents
  indexRecipeOptions(candidates)
  local reagent = candidates and #candidates == 1 and candidates[1]
  local id = reagent and itemID(reagent.itemID)
  local goal = schematic and tonumber(schematic.quantityRequired)
  if id and goal and goal > 0 and slot:IsVisible() then
   local control = reagentButtons[slot]
   if not control then
    control = CreateFrame("Button", nil, slot)
    styleReagentButton(control)
    control:SetScript("OnClick", function(self)
     local current = slot:GetReagentSlotSchematic()
     local options = current and current.reagents
     if options and #options == 1 and options[1].itemID == self.item
      and tonumber(current.quantityRequired) == self.goal then
      if collection.goals[self.item] then
       collection.goals[self.item] = nil
       refresh()
      else
       track(self.item, self.goal)
      end
      for _, other in pairs(reagentButtons) do
       if other.item == self.item then other:SetText(collection.goals[self.item] and "-" or "+") end
      end
     end
    end)
    control:SetScript("OnEnter", function(self)
     GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
     local name = itemInfo(self.item)
     GameTooltip:SetText(name)
     local owned = stock(self.item)
     GameTooltip:AddLine(("%s / %d en sac • %s manquants"):format(
      owned or "–", self.goal, owned and math.max(0, self.goal - owned) or "–"))
     GameTooltip:AddLine(collection.goals[self.item] and "Retirer de ma collecte" or "Ajouter à ma collecte")
     GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function() GameTooltip:Hide() end)
    reagentButtons[slot] = control
   end
   local fits = reagentActionFits(slot)
   if control.fits ~= fits then
    control:ClearAllPoints()
    if fits then
     control:SetPoint("RIGHT", slot, "RIGHT", -2, 0)
    else
     control:SetPoint("LEFT", slot, "RIGHT", 3, 0)
    end
    control.fits = fits
   end
   visible[slot] = true
   control.item, control.goal = id, goal
   control:SetText(collection.goals[id] and "-" or "+")
   if not control:IsShown() then control:Show() end
  end
 end
 for slot, control in pairs(reagentButtons) do
  if not visible[slot] then control:Hide() end
 end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, id)
 if event == "PLAYER_LOGOUT" then rememberScroll(); return end
 if event == "GET_ITEM_INFO_RECEIVED" then
  if requestedItems[id] == "pending" then
   requestedItems[id] = "received"
   pendingItemRefresh = true
   catalogRevision = catalogRevision + 1
  end
  return
 end
 if event == "ADDON_LOADED" and id and id ~= "MelloUI" and id ~= "MelloUI_Map"
  and id ~= "ForeverDB" and id ~= "TomTom" then return end
 if event == "PLAYER_LOGIN" then
  LeatherTrackerFRDB = LeatherTrackerFRDB or {}
  LeatherTrackerFRDB.collection = LeatherTrackerFRDB.collection or {}
  collection = LeatherTrackerFRDB.collection
  lastSourceItem = itemID(collection.lastSourceItem)
  collection.catalogFolded = type(collection.catalogFolded) == "table" and collection.catalogFolded or {}
  collection.sourceViews = type(collection.sourceViews) == "table" and collection.sourceViews or {}
  sourceSelection = collection.sourceViews
  sortSourcesByRate = collection.sortSourcesByRate == true
  collection.goals, collection.position = collection.goals or {}, collection.position or {}
  collection.recipeComponents = type(collection.recipeComponents) == "table" and collection.recipeComponents or {}
  for key in pairs(collection.recipeComponents) do
   local id = itemID(key)
   if id and not indexedComponents[id] then
    indexedComponents[id] = true
    otherComponents.items[#otherComponents.items + 1] = id
    catalogRevision = catalogRevision + 1
   end
  end
  table.sort(otherComponents.items)
  collection.map = type(collection.map) == "table" and collection.map or {}
  if not mapModes[collection.map.mode] then collection.map.mode = "manual" end
  collection.map.hiddenKinds = type(collection.map.hiddenKinds) == "table" and collection.map.hiddenKinds or {}
  collection.map.manualItems = type(collection.map.manualItems) == "table" and collection.map.manualItems or {}
  if collection.map.tips == nil then collection.map.tips = true end
  if collection.map.multiple == nil then collection.map.multiple = true end
 end
 if event == "PLAYER_LOGIN" or event == "BAG_UPDATE_DELAYED" then
  local previous = bagStock
  scanBags()
  if event == "BAG_UPDATE_DELAYED" and collection and collection.notifyComplete and previous and bagStock then
   for id, goal in pairs(collection.goals) do
    if (previous[id] or 0) < goal and (bagStock[id] or 0) >= goal then
     print(("LeatherTracker : objectif atteint pour %s (%d)."):format(itemInfo(id), goal))
    end
   end
  end
 end
 refresh()
end)
local elapsed = 0
events:SetScript("OnUpdate", function(_, dt)
 elapsed = elapsed + dt
 if elapsed < 0.2 then return end
 if pendingItemRefresh and panel and panel:IsVisible() then refresh() end
 if optionsOpen and panel and panel:IsVisible() and addon.GetSkinningDiagnostic then
  local diagnostic = learningText()
  if diagnostic ~= lastDiagnosticText then
   mapControls.learningState:SetText(diagnostic)
   lastDiagnosticText = diagnostic
  end
 end
 if panel and panel:IsShown() then
  local api = mapAPI()
  local mapVisible = api and type(api.IsShown) == "function" and api:IsShown() or false
  if beneathMap ~= mapVisible then
   beneathMap = mapVisible
   panel:SetFrameStrata(mapVisible and "MEDIUM" or "FULLSCREEN_DIALOG")
  end
 end
 if pendingItem then
  pendingTime = pendingTime - elapsed
  if ProfessionsFrame and ProfessionsFrame:IsVisible() then
   local id = pendingItem
   pendingItem = nil
   openCompactItem(id)
  elseif pendingTime <= 0 then
   pendingItem = nil
   print("LeatherTracker : ouvre la fenêtre Métiers pour consulter ce composant.")
  end
 end
 elapsed = 0
 syncReagents()
end)
