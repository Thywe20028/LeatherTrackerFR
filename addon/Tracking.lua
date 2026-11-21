local addonName = ...
local addon = CreateFrame("Frame")
local tab
local elapsed = 0
local loggedIn = false

local function register()
 local frame = _G.ProfessionsFrame
 local crafting = frame and frame.CraftingPage
 if tab or not loggedIn or not crafting then return end
 if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
 tab = CreateFrame("Button", "LeatherTrackerFRProfessionTab", frame, "LargeSideTabButtonTemplate")
 tab.Icon:SetTexture("Interface\\AddOns\\"..(addonName or "LeatherTrackerFR").."\\Media\\Logo.tga")
 tab.tooltipText = "LeatherTracker FR"
 tab:EnableMouse(true)
 tab:SetCustomOnMouseUpHandler(function(_, mouseButton, upInside)
  if mouseButton == "LeftButton" and upInside ~= false then
   LeatherTrackerToggleCollection()
  end
 end)

 local nativeHooks = {}
 local function hookNative(native)
  if not native or nativeHooks[native] then return end
  nativeHooks[native] = true
  native:HookScript("OnMouseUp", function(_, mouseButton, upInside)
   if mouseButton == "LeftButton" and upInside ~= false then
    LeatherTrackerCloseCollection()
   end
  end)
 end
 local function anchor()
  if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
  local native = frame.ProfessionsOverviewTab
  hookNative(native)
  for _, candidate in ipairs(frame.rightProfessionTabs or {}) do
   hookNative(candidate)
   if candidate:IsShown() then native = candidate end
  end
  if native then
   tab:ClearAllPoints()
   tab:SetPoint("TOPLEFT", native, "BOTTOMLEFT", 0, -3)
   tab:Show()
  else
   tab:Hide()
  end
 end
 frame:HookScript("OnShow", anchor)
 if EventRegistry and type(EventRegistry.RegisterCallback) == "function" then
  local function returnToProfession()
   LeatherTrackerRefreshCollectionFrame()
   anchor()
  end
  EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", returnToProfession, tab)
  EventRegistry:RegisterCallback("ProfessionsFrame.Show", anchor, tab)
  EventRegistry:RegisterCallback("Professions.ProfessionSelected", returnToProfession, tab)
 end
 tab:RegisterEvent("PLAYER_REGEN_ENABLED")
 tab:SetScript("OnEvent", anchor)
 anchor()

 frame:HookScript("OnHide", LeatherTrackerCloseCollection)
end

SLASH_LEATHERTRACKERSTATUS1 = "/ltstatus"
SlashCmdList.LEATHERTRACKERSTATUS = function()
 local frame = _G.ProfessionsFrame
 local collection = _G.LeatherTrackerCollection
 local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
 local version = getMetadata and getMetadata(addonName or "LeatherTrackerFR", "Version")
 print("LeatherTracker "..(version or "version inconnue").." | Métiers="..tostring(frame ~= nil)..
  " | Ma collecte="..tostring(collection ~= nil and collection:IsVisible())..
  " | ongletVisible="..tostring(tab ~= nil and tab:IsVisible()))
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(_, event)
 if event == "PLAYER_LOGIN" then loggedIn = true end
 register()
end)
addon:SetScript("OnUpdate", function(_, dt)
 if tab or not loggedIn then return end
 elapsed = elapsed + dt
 if elapsed < 0.2 then return end
 elapsed = 0
 register()
end)
