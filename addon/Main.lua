-- LeatherTracker FR 0.1 : prototype exploratoire, aucune base de positions ou de taux inventee.
local addonName = ...
local frame = CreateFrame('Frame', 'LeatherTrackerFRWindow', UIParent)
frame:SetSize(430, 350)
frame:SetPoint('CENTER')
frame:SetFrameStrata('DIALOG')
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag('LeftButton')
frame:SetScript('OnDragStart', frame.StartMoving)
frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
frame:Hide()
local bg = frame:CreateTexture(nil, 'BACKGROUND')
bg:SetAllPoints()
bg:SetColorTexture(0.06, 0.08, 0.12, 0.95)
local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
title:SetPoint('TOPLEFT', 14, -15)
title:SetText('LeatherTracker FR - prototype')
local close = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
close:SetPoint('TOPRIGHT', -4, -4)
local output = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
output:SetPoint('TOPLEFT', 16, -52)
output:SetPoint('BOTTOMRIGHT', -16, 15)
output:SetJustifyH('LEFT')
output:SetJustifyV('TOP')
output:SetText('Ouvrez Travail du cuir puis tapez /ltfr scan.\n/ltfr api pour les fonctions disponibles.')
local function safe(fn, ...)
 if type(fn) ~= 'function' then return nil end
 local ok, result = pcall(fn, ...)
 if ok then return result end
 return nil
end
local function owned(itemID)
 if not itemID then return nil end
 if C_Item and type(C_Item.GetItemCount)=='function' then
  local n=safe(C_Item.GetItemCount, itemID, false)
  if type(n)=='number' then return n end
 end
 if type(GetItemCount)=='function' then
  local n=safe(GetItemCount, itemID, false)
  if type(n)=='number' then return n end
 end
 return nil
end
local function readRecipe()
 local api=C_TradeSkillUI
 if type(api)~='table' then return nil, 'C_TradeSkillUI indisponible.' end
 local recipeID=safe(api.GetSelectedRecipeID)
 if not recipeID then return nil, 'Aucune recette selectionnee ou GetSelectedRecipeID indisponible.' end
 local info=safe(api.GetRecipeInfo, recipeID)
 local name=(type(info)=='table' and info.name) or ('Recette #'..tostring(recipeID))
 local lines={'Recette : '..name, 'ID : '..tostring(recipeID), ''}
 local schematic=safe(api.GetRecipeSchematic, recipeID, false)
 if type(schematic)=='table' and type(schematic.reagentSlotSchematics)=='table' then
  for _,slot in ipairs(schematic.reagentSlotSchematics) do
   local quantity=tonumber(slot.quantityRequired) or 0
   local reagent=type(slot.reagents)=='table' and slot.reagents[1] or nil
   local itemID=reagent and reagent.itemID
   local itemName=itemID and (safe(GetItemInfo, itemID) or ('Objet #'..itemID)) or 'Composant non resolu'
   local have=owned(itemID)
   local suffix=have and (' | sacs : '..have..' | manque : '..math.max(0, quantity-have)) or ' | sacs : inconnu'
   lines[#lines+1]=itemName..' : '..quantity..suffix
  end
 elseif type(api.GetRecipeNumReagents)=='function' and type(api.GetRecipeReagentInfo)=='function' then
  local n=safe(api.GetRecipeNumReagents, recipeID)
  if type(n)~='number' then return nil, 'Lecture des composants indisponible (signature API a confirmer).' end
  for i=1,n do
   local r=safe(api.GetRecipeReagentInfo, recipeID, i)
   if type(r)=='table' then
    local itemID=r.itemID
    local count=tonumber(r.requiredQuantity or r.quantityRequired or r.quantity) or 0
    local have=owned(itemID)
    lines[#lines+1]=(r.name or (itemID and ('Objet #'..itemID)) or 'Inconnu')..' : '..count..(have and (' | sacs : '..have) or '')
   end
  end
 else return nil, 'Aucune methode de lecture des composants confirmee sur ce client.' end
 return table.concat(lines, '\n')
end
local function apiStatus()
 local api=C_TradeSkillUI or {}
 local names={'GetSelectedRecipeID','GetRecipeInfo','GetRecipeSchematic','GetRecipeNumReagents','GetRecipeReagentInfo'}
 local lines={'Diagnostic API WoW Forever :'}
 for _,name in ipairs(names) do lines[#lines+1]=name..' : '..(type(api[name])=='function' and 'oui' or 'non') end
 lines[#lines+1]='MelloUI.Map:AddPin : '..((_G.MelloUI and _G.MelloUI.Map and type(_G.MelloUI.Map.AddPin)=='function') and 'oui' or 'non')
 lines[#lines+1]='Auctionator : '..(type(_G.Auctionator)=='table' and 'charge' or 'absent')
 return table.concat(lines, '\n')
end
SLASH_LEATHERTRACKERFR1='/ltfr'
SlashCmdList.LEATHERTRACKERFR=function(msg)
 local action=(msg or ''):lower():match('^%s*(%S*)')
 if action=='api' then output:SetText(apiStatus())
 elseif action=='scan' then
  local result, err=readRecipe()
  output:SetText(result or ('Lecture impossible : '..(err or 'erreur inconnue')))
 else output:SetText('Commandes : /ltfr scan | /ltfr api\nSelectionnez une recette dans Travail du cuir.') end
 frame:Show()
end
