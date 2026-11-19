-- Run from the repository root: texlua tests/selection.lua
local frames = {}
local function noop() end
local function frame(parent)
 local widget = {shown = true, scripts = {}, text = "", parent = parent}
 setmetatable(widget, {__index = function() return noop end})
 function widget:SetScript(event, callback) self.scripts[event] = callback end
 function widget:HookScript(event, callback)
  local previous = self.scripts[event] or noop
  self.scripts[event] = function() previous(); callback() end
 end
 function widget:IsVisible() return self.shown and (not parent or parent:IsVisible()) end
 function widget:Show()
  self.shown = true
  if self.scripts.OnShow then self.scripts.OnShow() end
 end
 function widget:Hide()
  self.shown = false
  if self.scripts.OnHide then self.scripts.OnHide() end
 end
 function widget:SetText(value) self.text = value end
 function widget:SetEnabled(value) self.enabled = value end
 function widget:CreateFontString() return frame(self) end
 function widget:CreateTexture() return frame(self) end
 return widget
end

function CreateFrame(_, name, parent)
 local widget = frame(parent)
 frames[#frames + 1] = widget
 if name then _G[name] = widget end
 return widget
end

SlashCmdList = {}
ProfessionsFrame = frame()
local crafting = frame(ProfessionsFrame)
ProfessionsFrame.CraftingPage = crafting
local info, fallbackID, changing, registration
crafting.SchematicForm = {GetRecipeInfo = function() return info end}
C_TradeSkillUI = {
 GetSelectedRecipeID = function() return fallbackID end,
 GetRecipeInfo = function(id)
  if id == 42 then return {name = "Recette de repli"} end
 end,
 IsDataSourceChanging = function() return changing end,
}
ForeverCore = {ProfessionTabs = {
 minor = 2,
 Register = function(_, spec) registration = spec end,
 Select = function()
  crafting:Hide()
  registration.page:Show()
  registration.onSelect()
 end,
}}

assert(loadfile("addon/Main.lua"))
dofile("addon/Tracking.lua")
local events = frames[1].scripts
events.OnEvent(nil, "PLAYER_LOGIN")
local function tick() events.OnUpdate(nil, 0.016) end
local follow
for _, widget in ipairs(frames) do
 if widget.text == "Suivre la recette" then follow = widget end
end
assert(follow)
local function click() follow.scripts.OnClick() end

info = {recipeID = 7955, name = "Ceinture"}
tick()
info = {recipeID = 100, name = "Deuxième recette"}
tick()
ForeverCore.ProfessionTabs.Select()
info = {recipeID = 200, name = "Formulaire masqué"}
tick()
click()
assert(LeatherTrackerFRDB.trackedRecipeID == 100)
click()

ProfessionsFrame:Hide()
ProfessionsFrame:Show()
registration.onSelect()
assert(not follow.enabled, "Un aperçu ne doit pas survivre à la fermeture")

registration.page:Hide()
crafting:Show()
info = {recipeID = 0}
fallbackID = 42
SlashCmdList.LEATHERTRACKERPANEL()
click()
assert(LeatherTrackerFRDB.trackedRecipeID == 42)
changing = true
tick()
assert(LeatherTrackerFRDB.trackedRecipeID == 42)
click()
assert(not follow.enabled, "Un changement de métier invalide l’aperçu")
changing = false

registration.page:Hide()
crafting:Show()
info = {recipeID = 100, name = "Deuxième recette"}
tick()
info, fallbackID = nil, nil
tick()
ForeverCore.ProfessionTabs.Select()
assert(not follow.enabled, "Une sélection effacée ne doit pas être réutilisée")
print("Sélection LeatherTracker : contrôles réussis")
