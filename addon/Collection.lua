local addonName, addon = ...
local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.7.32"
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
local sourceOrder = {}
local sourcesOpen = false
local sourceHeading, sourceFooter, sourceLink, summary
local mapControls, pins, selectedPins = {}, {}, {}
local mapOwner = "LeatherTrackerFR"
local focusedPin, mapPreview
local tomtomPin, tomtomItem, tomtomKind
local beneathMap, preferredMapItem
local mapModes = {manual = "Manuel", automatic = "Automatique", off = "Désactivé"}
local sourceLines, sourceFilters, sourceSelection = {}, {}, {}
local sortSourcesByRate = false

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
 return name or catalogName or ("Objet #"..id), icon
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
 widget:SetSize(width, 23)
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
  add("all", "Toutes les sources", index, 0)
  if source.method == "Fabrication" then
   add("craft", "Fabrication", index, 1)
  elseif source.zone then
   local continent = source.continent
   if continent then
    add("continent:"..continent, continent, index, 2, 0)
   end
   add("zone:"..(continent or "")..":"..source.zone, source.zone, index, 2, continent and 10 or 0)
  else
   add("unknown", "Localisation indisponible", index, 3)
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

local function background(frame, red, green, blue)
 local texture = frame:CreateTexture(nil, "BACKGROUND")
 texture:SetAllPoints()
 texture:SetColorTexture(red, green, blue, 0.97)
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

local function showItem(id, emptySources)
 if not panel or not panel:GetParent():IsVisible() then return end
 activeItem = id
 sourcesOpen = id ~= nil or emptySources == true
 optionsOpen = false
 panel.SourcePicker:Hide()
 if id and id ~= lastSourceItem then
  lastSourceItem = id
  sourceSelection[id] = nil
  panel.SourceSearch:SetText("")
 end
 if scroll then scroll:SetVerticalScroll(0) end
 if panel.SourcePlaces then panel.SourcePlaces.Scroll:SetVerticalScroll(0) end
 if not panel:IsShown() then panel:Show() end
 refresh()
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
   local open = query ~= "" or not catalog.folded[group.name]
   header:ClearAllPoints()
   header:SetPoint("TOPLEFT", 0, -y)
   header:SetPoint("TOPRIGHT", 0, -y)
   header.Text:SetText((open and "− " or "+ ")..group.name)
   local _, categoryIcon = itemInfo(group.icon)
   header.Icon:SetTexture(categoryIcon)
   y = y + 25
   if open then
    for _, item in ipairs(matching) do
     used = used + 1
     local row = catalog.rows[used]
     if not row then
      row = CreateFrame("Frame", nil, catalog.Body)
      row:SetHeight(37)
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
      row.Toggle:SetPoint("RIGHT", -3, 0)
      row.NameButton = CreateFrame("Button", nil, row)
      row.NameButton:SetPoint("TOPLEFT", 40, -2)
      row.NameButton:SetPoint("BOTTOMRIGHT", row.Toggle, "LEFT", -5, -5)
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
     y = y + 39
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
 catalog.rows, catalog.headers, catalog.folded = {}, {}, {}
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
  local header = CreateFrame("Button", nil, catalog.Body)
  header:SetHeight(23)
  background(header, 0.19, 0.155, 0.105)
  local hover = header:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetColorTexture(0.71, 0.49, 0.24, 0.18)
  header.Icon = header:CreateTexture(nil, "ARTWORK")
  header.Icon:SetSize(17, 17)
  header.Icon:SetPoint("LEFT", 4, 0)
  header.Text = label(header, "GameFontNormalSmall", 25, -5)
  header.Text:SetPoint("RIGHT", -5, 0)
  header.Text:SetWordWrap(false)
  header:SetScript("OnClick", function()
   catalog.folded[group.name] = not catalog.folded[group.name]
   catalog.renderedRevision = nil
   renderComponentCatalog()
  end)
  catalog.headers[group.name] = header
 end
 catalog.Scroll:SetScript("OnSizeChanged", function(_, width)
  catalog.Body:SetWidth(math.max(width, 1))
 end)
 panel:SetScript("OnSizeChanged", function(_, width)
  catalog:SetWidth(math.max(145, (width - 54) * 0.35))
  if panel.SourcePlaces then panel.SourcePlaces:SetWidth(math.max(145, (width - 54) * 0.32)) end
 end)
 panel.Back = button(panel, "<", 26, function() showItem(nil) end)
 panel.Back:SetPoint("TOPLEFT", 19, -44)
 panel.ItemIcon = panel:CreateTexture(nil, "ARTWORK")
 panel.ItemIcon:SetSize(27, 27)
 panel.ItemIcon:SetPoint("LEFT", panel.Back, "RIGHT", 6, 0)
 panel.SourceCounts = label(panel, "GameFontHighlight", 20, -78)
 panel.SourceEmpty = label(panel, "GameFontHighlight", 20, -82)
 panel.SourceEmpty:SetText("Ajoute un composant dans Ma collecte pour consulter ses sources.")
 local function stepSource(direction)
  local index = direction > 0 and 0 or #sourceOrder + 1
  for i, id in ipairs(sourceOrder) do
   if id == activeItem then index = i; break end
  end
  local id = sourceOrder[index + direction]
  if id then showItem(id) end
 end
 panel.SourcePrevious = button(panel, "◀", 25, function() stepSource(-1) end)
 panel.SourcePrevious:SetPoint("LEFT", panel.ItemIcon, "RIGHT", 5, 0)
 panel.SourceNext = button(panel, "▶", 25, function() stepSource(1) end)
 panel.SourceIndex = label(panel, "GameFontHighlightSmall", 0, 0)
 panel.SourceIndex:ClearAllPoints()
 panel.SourceIndex:SetPoint("TOPRIGHT", -24, -81)
 local pickerButton = button(panel, "Choisir un composant ▾", 155, function()
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
 local toolbar = CreateFrame("Frame", nil, panel)
 toolbar:SetPoint("TOPLEFT", 65, -5)
 toolbar:SetPoint("TOPRIGHT", -132, -5)
 toolbar:SetHeight(30)
 background(toolbar, 0.18, 0.13, 0.08)
 panel.CompactControl = button(toolbar, "Panneau compact", 140, function()
  collection.compact = not collection.compact
  refresh()
 end)
 panel.CompactControl:SetPoint("LEFT", 5, 0)
 panel.SourcesTab = button(toolbar, "Sources", 73, function()
  showItem(#sourceOrder > 0 and (lastSourceItem or sourceOrder[1]) or nil, true)
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
 panel.MapSettings = CreateFrame("Frame", nil, panel)
 panel.MapSettings:SetPoint("TOPLEFT", 18, -44)
 panel.MapSettings:SetPoint("BOTTOMRIGHT", -18, 16)
 panel.MapSettings:Hide()
 local settingsPage = CreateFrame("ScrollFrame", nil, panel.MapSettings, "UIPanelScrollFrameTemplate")
 settingsPage:SetPoint("TOPLEFT", 0, 0)
 settingsPage:SetPoint("BOTTOMRIGHT", -18, 0)
 local settingsBody = CreateFrame("Frame", nil, settingsPage)
 settingsBody:SetSize(530, 550)
 settingsPage:SetScrollChild(settingsBody)
 label(settingsBody, "GameFontNormalLarge", 4, -5):SetText("Options de LeatherTracker")
 local backOptions = button(panel.MapSettings, "", 159, function()
  optionsOpen = false
  refresh()
 end)
 backOptions:SetPoint("TOPRIGHT", -23, 0)
 panel.OptionsBack = backOptions
 label(settingsBody, "GameFontNormal", 8, -49):SetText("Suivi compact")
 local function setting(key, y, handler)
  local control = button(settingsBody, "", 270, function()
   handler()
   refresh()
  end)
  control:SetPoint("TOPLEFT", 8, y)
  mapControls[key] = control
 end
 for i, key in ipairs({"compact", "locked", "collapsed", "notifyComplete"}) do
  setting(key, -67 - (i - 1) * 26, function() collection[key] = not collection[key] end)
 end
 label(settingsBody, "GameFontNormal", 8, -178):SetText("Carte et filtres")
 local nextMode = {manual = "automatic", automatic = "off", off = "manual"}
 setting("mode", -196, function() collection.map.mode = nextMode[collection.map.mode] end)
 for i, key in ipairs({"multiple", "hideDone", "tips"}) do
  setting(key, -196 - i * 26, function()
   collection.map[key] = not collection.map[key]
   if key == "multiple" and not collection.map.multiple then
    selectedPins, collection.map.manualItems = {}, {}
   end
  end)
 end
 setting("mapTracked", -301, function() setMapLayer(0, collection.map.layersHidden) end)
 for index, layer in ipairs(layerDefinitions) do
  setting(layer.id, -301 - index * 26, function()
   setMapLayer(layer.id, collection.map.hiddenKinds[layer.id])
  end)
 end
 label(settingsBody, "GameFontNormal", 8, -421):SetText("Informations")
 label(settingsBody, "GameFontHighlight", 8, -442):SetText("LeatherTracker FR  ·  "..version)
 mapControls.layer = label(settingsBody, "GameFontHighlight", 8, -464)
 mapControls.layerHelp = label(settingsBody, "GameFontHighlightSmall", 8, -486)
 mapControls.layerHelp:SetWidth(460)
 mapControls.openLayers = button(settingsBody, "Ouvrir les calques MelloUI", 240, function()
  local module = mapLayersModule()
  if module then
   syncMap()
   if not module:OpenLayers() then print("LeatherTracker : calques MelloUI indisponibles.") end
  end
 end)
 mapControls.openLayers:SetPoint("TOPLEFT", 8, -514)
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
 sourceLink = input(list, 264, 160)
 sourceLink:SetPoint("TOPLEFT", 14, -180)
 sourceLink:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
 local places = CreateFrame("Frame", nil, panel)
 panel.SourcePlaces = places
 places:SetPoint("TOPLEFT", 18, -107)
 places:SetPoint("BOTTOMLEFT", 18, 37)
 places:SetWidth(190)
 places:Hide()
 background(places, 0.12, 0.095, 0.075)
 label(places, "GameFontNormal", 8, -7):SetText("Lieux et méthodes")
 local placeScroll = CreateFrame("ScrollFrame", nil, places, "UIPanelScrollFrameTemplate")
 placeScroll:SetPoint("TOPLEFT", 5, -27)
 placeScroll:SetPoint("BOTTOMRIGHT", -21, 5)
 local placeBody = CreateFrame("Frame", nil, placeScroll)
 placeBody:SetSize(164, 1)
 placeScroll:SetScrollChild(placeBody)
 placeScroll:SetScript("OnSizeChanged", function(_, width) placeBody:SetWidth(math.max(width, 1)) end)
 places.Scroll, places.Body = placeScroll, placeBody
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
  for index, row in ipairs(rows) do
   local id = showCollection and ids[index]
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
   panel.ItemIcon:SetTexture(icon)
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
   panel.Catalog:SetWidth(math.max(145, (panel:GetWidth() - 54) * 0.35))
   renderComponentCatalog()
  end
  panel.Back:SetShown(showSource)
  panel.ItemIcon:SetShown(showSource)
  panel.SourceCounts:SetShown(showSource)
  panel.SourceEmpty:SetShown(showSourcesTab and not activeItem)
  local showNavigation = showSource and #ids > 0
  local itemIndex
  for index, id in ipairs(ids) do if id == activeItem then itemIndex = index; break end end
  panel.SourcePrevious:SetShown(showSource)
  panel.SourceNext:SetShown(showSource)
  panel.SourcePrevious:SetEnabled(showNavigation and (not itemIndex or itemIndex > 1))
  panel.SourceNext:SetEnabled(showNavigation and (not itemIndex or itemIndex < #ids))
  panel.SourceIndex:SetShown(showNavigation)
  if showNavigation then
   panel.SourceIndex:SetText(("%s / %d composants"):format(itemIndex or "–", #ids))
  end
  panel.SourcePickerButton:SetShown(showNavigation)
  local picker = panel.SourcePicker
  if not showNavigation then picker:Hide() end
  if picker:IsShown() then
   picker:SetHeight(8 + 24 * math.min(#ids, 8))
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
  if showSource then panel.SourcePlaces:SetWidth(math.max(145, (panel:GetWidth() - 54) * 0.32)) end
  sourceHeading:SetShown(showSource)
  sourceFooter:SetShown(showSource)
  sourceLink:Hide()
  panel.CompactControl:SetText(collection.compact and "Masquer le suivi" or "Afficher le suivi")
  mapControls.compact:SetText(collection.compact and "Suivi compact : affiché" or "Suivi compact : masqué")
  mapControls.locked:SetText(collection.locked and "Position : verrouillée" or "Position : déverrouillée")
  mapControls.collapsed:SetText(collection.collapsed and "Panneau : réduit" or "Panneau : développé")
  mapControls.notifyComplete:SetText("Notification d’objectif : "..(collection.notifyComplete and "oui" or "non"))
  local settings = collection.map
  local api = mapAPI()
  mapControls.openLayers:SetShown(mapLayersModule() ~= nil)
  mapControls.layer:SetText(not api and "Carte MelloUI indisponible"
   or type(api.LeatherTrackerSetLayers) == "function" and "Interface de catégorie détectée"
   or "Calque dédié indisponible")
  mapControls.layerHelp:SetText(not api and "Active le module Carte de MelloUI."
   or type(api.LeatherTrackerSetLayers) == "function" and "Carte → Calques → LeatherTracker FR. Choisis le mode automatique pour afficher toutes les sources connues."
   or "Utilise les filtres ci-dessus. Diagnostic : /ltmapdebug.")
  mapControls.mapTracked:SetText("Composants suivis : "..(settings.layersHidden and "masqués" or "affichés"))
  for _, layer in ipairs(layerDefinitions) do
   mapControls[layer.id]:SetText(layer.name.." : "..(settings.hiddenKinds[layer.id] and "masqués" or "affichés"))
  end
  mapControls.mode:SetText("Mode : "..mapModes[settings.mode])
  mapControls.multiple:SetText("Plusieurs composants : "..(settings.multiple and "oui" or "non"))
  mapControls.hideDone:SetText("Masquer les objectifs atteints : "..(settings.hideDone and "oui" or "non"))
  mapControls.tips:SetText("Infobulles : "..(settings.tips and "oui" or "non"))
  scroll:ClearAllPoints()
  if showCollection then
   scroll:SetPoint("TOPLEFT", panel.Catalog, "TOPRIGHT", 17, -49)
  else
   scroll:SetPoint("TOPLEFT", panel.SourceSearchBar, "BOTTOMLEFT", 0, -4)
  end
  scroll:SetPoint("BOTTOMRIGHT", -35, 37)
  panel.Message:SetShown(showCollection and #ids == 0)
  if showSource then
   local owned, goal = stock(activeItem), collection.goals[activeItem]
   local sourcesForItem = catalogFor(activeItem)
   addLocalObservations(sourcesForItem, activeItem)
   addSkinningObservations(sourcesForItem, activeItem)
   panel.SourceCounts:SetText(("En sac : %s   •   Objectif : %s   •   Manquant : %s"):format(
    owned or "–", goal or "–", owned and goal and math.max(0, goal - owned) or "–"))
   local mapped = false
   for _, source in ipairs(sourcesForItem) do if source.map then mapped = true; break end end
   local api = mapAPI()
   local settings = collection.map
   local types = {["Récolte"] = "Récolte", Achat = "Marchand", Ouverture = "Contenant", Butin = "Créature", ["Pêche"] = "Pêche", ["Dépeçage"] = "Dépeçage", Fabrication = "Fabrication", ["Accès"] = "Accès au donjon"}
   local filters, groups = sourceLayout(sourcesForItem)
   local selection = sourceSelection[activeItem]
   if not selection then
    selection = {group = "all"}
    sourceSelection[activeItem] = selection
   end
   local selectedGroup = groups[selection.group] or groups.all
   sourceHeading:SetText(selectedGroup and selectedGroup.name or "Sources")
   local places = panel.SourcePlaces
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
     filter.Text:SetWordWrap(true)
     filter.Text:SetMaxLines(2)
     sourceFilters[i] = filter
    end
    filter:ClearAllPoints()
    filter:SetPoint("TOPLEFT", group.indent or 0, -(i - 1) * 35)
    filter:SetPoint("TOPRIGHT", 0, -(i - 1) * 35)
    local isContinent = group.key:find("^continent:") ~= nil
    local icon = isContinent and "INV_Misc_Orb_01" or group.key == "craft" and "INV_Hammer_20"
     or group.key == "all" and "INV_Misc_Book_09" or "INV_Misc_Map_01"
    filter.Text:SetText("|TInterface\\Icons\\"..icon..":14:14|t  "..group.name)
    filter.Count:SetText(tostring(#group.indices))
    if selectedGroup == group then
     filter.Text:SetTextColor(1, 0.83, 0.43)
    elseif isContinent then
     filter.Text:SetTextColor(0.53, 0.85, 1)
    else
     filter.Text:SetTextColor(0.83, 0.87, 0.92)
    end
    filter:SetScript("OnClick", function()
     selection.group = group.key
     scroll:SetVerticalScroll(0)
     refresh()
    end)
    filter:Show()
   end
   places.Body:SetHeight(math.max(1, #filters * 35))
   local matches = {}
   local query = componentSearchText(panel.SourceSearch:GetText():match("^%s*(.-)%s*$"))
   for _, index in ipairs(selectedGroup and selectedGroup.indices or {}) do
    local source = sourcesForItem[index]
    local haystack = componentSearchText(table.concat({source.name, source.zone or "", source.method}, " "))
    if query == "" or haystack:find(query, 1, true) then matches[#matches + 1] = index end
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
   local rowY, rowHeight = 27, 0
   local usable = math.max(1, list:GetWidth() - 14)
   local columns = usable >= 470 and 2 or 1
   local cardWidth = (usable - (columns - 1) * 10) / columns
   for rowIndex, index in ipairs(matches) do
    local source = sourcesForItem[index]
    local entry = sourceLines[rowIndex]
    if not entry then
     entry = CreateFrame("Frame", nil, list)
     background(entry, 0.17, 0.13, 0.095)
     entry.Name = label(entry, "GameFontNormalLarge", 10, -9)
     entry.Info = label(entry, "GameFontHighlight", 10, -31)
     entry.Map = button(entry, "Voir sur MelloUI", 127, nil)
     entry.Map:SetPoint("BOTTOMLEFT", 10, 9)
     local ok, model = pcall(CreateFrame, "PlayerModel", nil, entry)
     if ok and model and type(model.SetCreature) == "function" then
      entry.Model = model
      model:SetSize(70, 64)
      model:SetPoint("TOPLEFT", 4, -2)
      entry.Loading = label(entry, "GameFontHighlightSmall", 12, -28)
      entry.Loading:SetText("Chargement…")
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
     entry.MerchantIcon:SetPoint("TOPLEFT", 18, -14)
     entry.MerchantIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
     local rateBox = CreateFrame("Frame", nil, entry)
     entry.RateBox = rateBox

     background(rateBox, 0.10, 0.085, 0.065)
     rateBox.Title = label(rateBox, "GameFontNormal", 12, -7)
     rateBox.Value = label(rateBox, "GameFontNormalLarge", 12, -26)
     rateBox.Sample = label(rateBox, "GameFontHighlight", 12, -48)
     rateBox.Sample:SetPoint("TOPRIGHT", -8, -48)
     rateBox.Source = label(rateBox, "GameFontHighlightSmall", 12, -74)
     rateBox.Source:SetPoint("TOPRIGHT", -8, -74)
     rateBox.Bar = CreateFrame("StatusBar", nil, rateBox)
     rateBox.Bar:SetPoint("BOTTOMLEFT", 12, 6)
     rateBox.Bar:SetPoint("BOTTOMRIGHT", -12, 6)
     rateBox.Bar:SetHeight(4)
     rateBox.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
     rateBox.Bar:SetStatusBarColor(0.82, 0.58, 0.23)
     rateBox.Bar:SetMinMaxValues(0, 100)
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
    entry.MerchantIcon:SetTexture(sourceIcon or (merchant and "Interface\\Icons\\INV_Misc_Coin_01" or nil))
    entry.MerchantIcon:SetShown(not entry.modelReady and (sourceIcon ~= nil or merchant))
    local rateBox = entry.RateBox
    local hasRateBox = not merchant and source.method ~= "Accès" and source.method ~= "Fabrication"
    local hasSample = source.observations and (source.obtained ~= nil or source.observedRate ~= nil)
    rateBox:SetShown(hasRateBox)
    rateBox.Title:SetText(hasSample and "Taux de récupération observé" or "Taux non disponible")
    rateBox.Value:SetShown(hasSample)
    rateBox.Sample:SetShown(hasSample)
    rateBox.Source:SetShown(hasSample)
    rateBox.Bar:SetShown(hasSample)
    if hasSample then
     local observedRate = source.observedRate or 100 * source.obtained / source.observations
     rateBox.Value:SetText((("%.1f %%"):format(observedRate):gsub("%.", ",")))
     rateBox.Sample:SetText(source.personalSkinning and ("%d sur %d dépeçages"):format(source.obtained, source.observations)
      or source.obtained and ("%d obtention(s) sur %d observations"):format(source.obtained, source.observations)
      or ("%d corps dépecés"):format(source.observations))
     rateBox.Source:SetText((source.provenance or "ForeverDB.net")..
      (source.observations < 30 and "  •  Échantillon limité" or "  •  Fréquence observée"))
     rateBox.Bar:SetValue(observedRate)
    end
    rateBox:SetHeight(hasSample and 106 or 25)

    entry:ClearAllPoints()
    local column = (rowIndex - 1) % columns
    entry:SetPoint("TOPLEFT", 7 + column * (cardWidth + 10), -rowY)
    entry:SetWidth(cardWidth)

    local textLeft = (hasModel or merchant or sourceIcon) and 82 or 10
    entry.Name:ClearAllPoints()
    entry.Name:SetPoint("TOPLEFT", textLeft, -9)
    entry.Name:SetPoint("TOPRIGHT", -8, -9)
    entry.Name:SetWordWrap(true)
    entry.Name:SetMaxLines(2)
    entry.Info:ClearAllPoints()
    entry.Info:SetPoint("TOPLEFT", 10, -69)
    entry.Info:SetPoint("TOPRIGHT", -10, -69)
    entry.Info:SetSpacing(4)
    entry.Name:SetText(source.name.."  •  "..(types[source.method] or "Autre source"))
    local details = {}
    local function field(icon, name, value, color)
     details[#details + 1] = "|TInterface\\Icons\\"..icon..":15:15|t  |cff83c9ff"..name.."|r  |cff"..color..value.."|r"
    end
    field("INV_Misc_Bag_10", "Méthode", source.method, source.tentative and "ffc477" or "a5e7ad")
    if source.tentative then field("INV_Misc_Note_01", "Vérification", "Piste Classic à confirmer sur Forever", "ffc477") end
    if source.level or source.creatureID then
     field("Ability_Warrior_BattleShout", "Niveau", tostring(source.level or "Non vérifié"), source.level and "a5e7ad" or "ff9c87")
    end
    if source.skill or source.method == "Dépeçage" then
     field("INV_Misc_LeatherScrap_02", "Compétence", source.skill or "Seuil de dépeçage non vérifié", source.skill and "a5e7ad" or "ffc477")
    end
    if source.zone then field("INV_Misc_Map_01", "Zone", source.zone, source.tentative and "ffc477" or "a5e7ad") end
    if source.map then
     field("INV_Misc_Map_01", "Position", ("%.1f / %.1f%s"):format(source.x * 100, source.y * 100,
      source.approximate and " (approximative)" or ""), source.approximate and "ffc477" or "a5e7ad")
    elseif source.method ~= "Fabrication" then
     field("INV_Misc_Map_01", "Position", source.zone and "Zone connue — position précise non vérifiée" or "Localisation indisponible", "ff9c87")
    end
    if source.map and source.locationSource and source.provenance and source.locationSource ~= source.provenance then
     field("INV_Misc_Map_01", "Source du repère", source.locationSource, "a4d5ff")
    end
    if source.shop then field("INV_Misc_Coin_01", "Achat", source.shop, "e6e0d9") end
    if source.creatureID then field("INV_Misc_Note_01", "Identifiant", "PNJ #"..source.creatureID, "a4d5ff") end
    if source.learnedFrom then field("INV_Misc_Book_09", "Apprentissage", source.learnedFrom, "a4d5ff") end
    if source.context then field("INV_Misc_Note_01", "Détail", source.context, "e6e0d9") end
    field("INV_Misc_Book_09", "Source", source.provenance or source.locationSource or "ForeverDB.net", "a4d5ff")
    entry.Info:SetText(table.concat(details, "\n"))
    local infoHeight = math.max(#details * 19, entry.Info:GetStringHeight() or 0)
    local ratesY = 79 + infoHeight
    rateBox:ClearAllPoints()
    rateBox:SetPoint("TOPLEFT", 8, -ratesY)
    rateBox:SetPoint("TOPRIGHT", -8, -ratesY)
    local height = ratesY + (hasRateBox and (hasSample and 106 or 25) or 0) + 36
    entry:SetHeight(height)
    rowHeight = math.max(rowHeight, height)
    if column == columns - 1 or rowIndex == #matches then
     local first = rowIndex - column
     for i = first, rowIndex do sourceLines[i]:SetHeight(rowHeight) end
     rowY, rowHeight = rowY + rowHeight + 10, 0
    end
    local tomtom = settings.mode == "manual" and TomTom and type(TomTom.AddWaypoint) == "function"
      and C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("MelloUI")
    local native = mappable(source) and nativeWaypointAvailable(source.map)
    local canMap = mappable(source) and (api or tomtom or native) and settings.mode ~= "off"
     and not settings.layersHidden and not settings.hiddenKinds[sourceLayer(source)]
     and not (settings.hideDone and owned and goal and owned >= goal)
    entry.Map:SetText((api or tomtom) and "Voir sur MelloUI" or "Voir sur la carte")
    entry.Map:SetEnabled(not not canMap)
    entry.Map:SetShown(canMap)
    entry.Map:SetScript("OnClick", function()
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
    or (mapped and "Coordonnées et provenance indiquées sur chaque fiche.\nProvenance indiquée sur chaque source."
     or "Localisation : zone indiquée lorsqu’elle est documentée. Aucun point vérifié.\nProvenance indiquée sur chaque source."))
   if #sourcesForItem > 0 then
    sourceLink:ClearAllPoints()
    sourceLink:SetPoint("TOPLEFT", 14, -footerY - 40)
    sourceLink:SetPoint("TOPRIGHT", -20, -footerY - 40)
    sourceLink:SetText("https://foreverdb.net/fr/item/"..activeItem)
    sourceLink:Show()
   end
   list:SetHeight(footerY + 72)
  elseif showCollection and #ids == 0 then
   list:SetHeight(52)
   panel.Message:SetText("Utilise + dans le catalogue pour suivre un composant.")
  elseif showCollection then
   list:SetHeight(81 * #ids)
   for index, id in ipairs(ids) do
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
    row.name:SetWidth(150)
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
   row.count:SetText(("%s/%d"):format(stock(id) or "–", collection.goals[id]))
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
 if not panel then createPanel(frame) end
 if panel:IsShown() then LeatherTrackerCloseCollection() else showItem(nil) end
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
local function scanLeatherworking(api)
 if scannedLeatherworking or not api.GetAllRecipeIDs or not api.GetRecipeSchematic then return end
 local ok, ids = pcall(api.GetAllRecipeIDs)
 if not ok or type(ids) ~= "table" or #ids == 0 then return end
 local read = false
 for _, recipeID in ipairs(ids) do
  local success, profession = pcall(api.GetProfessionInfoByRecipeID, recipeID)
  if success and profession and (profession.parentProfessionID or profession.professionID) == 165 then
   local fetched, schematic = pcall(api.GetRecipeSchematic, recipeID, false)
   if fetched and schematic then
    read = true
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
     indexRecipeOptions(slot.reagents)
    end
   end
  end
 end
 if read then
  scannedLeatherworking = true
  table.sort(otherComponents.items)
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
 local recipe = form:GetRecipeInfo()
 local api = C_TradeSkillUI
 local profession = recipe and api and api.GetProfessionInfoByRecipeID and api.GetProfessionInfoByRecipeID(recipe.recipeID)
 if not profession or (profession.parentProfessionID or profession.professionID) ~= 165 then
  for _, control in pairs(reagentButtons) do control:Hide() end
  return
 end
 scanLeatherworking(api)
 for _, slot in ipairs(form:GetSlots()) do
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
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, id)
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
 if pendingItemRefresh then refresh() end
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
