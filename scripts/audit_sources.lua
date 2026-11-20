-- Depuis la racine du dépôt : texlua scripts/audit_sources.lua
local addon = {}
for _, file in ipairs({"SourceData", "WarcraftForeverData", "ComponentData"}) do
 assert(loadfile("addon/"..file..".lua"))("LeatherTrackerFR", addon)
end

local function row(...)
 local fields = {...}
 for index, value in ipairs(fields) do
  fields[index] = tostring(value):gsub("|", "&#124;"):gsub("[\r\n]", " ")
 end
 print("| "..table.concat(fields, " | ").." |")
end

local total, covered, mapped = 0, 0, 0
local recipes, recipesWithoutTrainer, recipesWithoutDetails = 0, 0, 0
local seen, issues = {}, {}
local function issue(id, message)
 issues[#issues + 1] = ("- #%d — %s"):format(id, message)
end

print("# Audit des sources de LeatherTracker FR\n")
print("Périmètre : catalogue livré et sources importées livrées. Les ingrédients découverts en jeu et les observations locales ne sont pas comptés. Cet audit contrôle les champs présents dans les données, sans authentifier leur contenu ni vérifier MelloUI en jeu.\n")

for _, group in ipairs(addon.componentGroups) do
 print("## "..group.name.."\n")
 row("Objet", "Source", "Méthode", "Zone / lieu", "Repère", "Niveau / compétence", "Achat / fabrication / détails", "Taux / observations", "Provenance")
 print("|---|---|---|---|---|---|---|---|---|")
 for _, id in ipairs(group.items) do
  if seen[id] then issue(id, "Identifiant en double dans le catalogue.") end
  seen[id] = true
  total = total + 1
  local label = addon.warcraftForever.names[id]
  local item = ("[%s](https://foreverdb.net/fr/item/%d)"):format(label or "#"..id, id)
  local hasSource, hasMap = false, false
  for _, records in ipairs({addon.componentSources[id] or {}, addon.importedSources[id] or {}}) do
   for _, source in ipairs(records) do
    if not source.tentative and source.method ~= "Accès" and source.method and source.name then hasSource = true end
    local validPoint = type(source.map) == "number" and source.map > 0
     and type(source.x) == "number" and source.x >= 0 and source.x <= 1
     and type(source.y) == "number" and source.y >= 0 and source.y <= 1
    local point = "Manquant"
    if validPoint then
     if source.locationSource then hasMap = true end
     point = ("%.1f / %.1f%s"):format(source.x * 100, source.y * 100, source.approximate and " (approx.)" or "")
     if not source.locationSource then issue(id, source.name.." — provenance du repère manquante.") end
    elseif source.map or source.x or source.y then
     issue(id, (source.name or "?").." — coordonnées partielles ou invalides.")
    end
    local recipe = source.method == "Fabrication"
    local skillNeeded = recipe or source.method == "Dépeçage" or source.method == "Récolte" or source.method == "Herboristerie"
     or source.method == "Minage" or source.method == "Pêche"
    local skills = source.skill or (skillNeeded and "Compétence non renseignée" or "Sans objet")
    local level = source.level or (source.creatureID and "Niveau non renseigné")
    local details = source.context or (recipe and "Détails de recette manquants" or "Sans objet")
    if recipe then
     recipes = recipes + 1
     if not source.context then recipesWithoutDetails = recipesWithoutDetails + 1 end
     if not source.learnedFrom then recipesWithoutTrainer = recipesWithoutTrainer + 1 end
     details = details.." · Apprentissage : "..(source.learnedFrom or "Non renseigné")
    end
    if source.method == "Achat" then details = source.shop or "Conditions de vente manquantes" end
    local rate = "—"
    if source.observations then
     rate = ("%s / %s observations"):format(source.obtained or "?", source.observations)
    end
    if source.observedRate then rate = source.observedRate.."% · "..rate end
    local provenance = source.provenance or "Méthode non sourcée"
    if source.locationSource and source.locationSource ~= source.provenance then
     provenance = provenance.." · Repère : "..source.locationSource
    end
    row(item, source.name or "Manquante", (source.method or "Manquante")..(source.tentative and " (Classic, à confirmer)" or ""),
     source.zone or (recipe and "Lieu de fabrication non renseigné" or "Zone manquante"),
     validPoint and point or (recipe and "—" or point),
     level and tostring(level).." · "..skills or skills, details, rate, provenance)
   end
  end
  if hasMap then mapped = mapped + 1 end
  if hasSource then
   covered = covered + 1
  else
   row(item, "Aucune méthode d’obtention confirmée pour Forever", "—", "—", "—", "—", "—", "—", "—")
  end
 end
 print("")
end

print(("## Bilan\n\n- %d composants audités.\n- %d avec au moins une méthode d’obtention renseignée.\n- %d sans méthode confirmée pour Forever.\n- %d avec au moins un repère attribué à une source, accès aux donjons compris.\n"):format(total, covered, total-covered, mapped))
print(("- %d méthodes par fabrication, dont %d sans renseignement sur l’apprentissage et %d sans détail de recette.\n"):format(recipes, recipesWithoutTrainer, recipesWithoutDetails))
if #issues > 0 then
 print("## Anomalies structurelles\n")
 print(table.concat(issues, "\n"))
end
