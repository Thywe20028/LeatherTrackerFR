"""Convert reviewed item source records into addon/SourceData.lua."""

import argparse
import json
import math
from pathlib import Path
import re

METHODS = {"Achat", "Butin", "Pêche", "Dépeçage", "Fabrication", "Accès", "Récolte"}
TEXT_FIELDS = {"name", "method", "zone", "level", "skill", "rate", "context", "provenance", "locationSource", "portraitSource"}
POINT_FIELDS = {"map", "x", "y"}
PORTRAIT_FIELDS = {"creatureID", "portraitSource"}


def lua_value(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    return repr(value)


def generate(document):
    if not isinstance(document, dict):
        raise ValueError("Le catalogue doit être un objet JSON indexé par identifiant d’objet.")
    output = ["local _, addon = ...", "addon.importedSources = {"]
    for item, records in document.items():
        if not re.fullmatch(r"[1-9][0-9]{0,9}", item) or not isinstance(records, list):
            raise ValueError(f"Entrée invalide : {item}")
        output.append(f" [{int(item)}] = {{")
        for record in records:
            if not isinstance(record, dict) or not all(record.get(key) for key in ("name", "method", "provenance")):
                raise ValueError(f"Nom, méthode et provenance sont requis pour {item}.")
            if set(record) - TEXT_FIELDS - POINT_FIELDS - PORTRAIT_FIELDS or record["method"] not in METHODS:
                raise ValueError(f"Champ ou méthode non pris en charge pour {item}.")
            for key in TEXT_FIELDS & record.keys():
                value = record[key]
                if not isinstance(value, str) or not value.strip() or any(ord(char) < 32 for char in value):
                    raise ValueError(f"Valeur texte invalide : {item}/{key}")
            if PORTRAIT_FIELDS & record.keys():
                npc_id = record.get("creatureID")
                if type(npc_id) is not int or not 0 < npc_id <= 2147483647 or not record.get("portraitSource"):
                    raise ValueError(f"Identifiant de PNJ ou provenance de portrait invalide : {item}")
            if POINT_FIELDS & record.keys():
                if not POINT_FIELDS <= record.keys() or not record.get("locationSource"):
                    raise ValueError(f"Point incomplet ou provenance manquante : {item}")
                if type(record["map"]) is not int or record["map"] < 1 or any(
                    type(record[axis]) not in (int, float)
                    or not math.isfinite(record[axis]) or not 0 <= record[axis] <= 1
                    for axis in ("x", "y")
                ):
                    raise ValueError(f"Coordonnées invalides : {item}")
            fields = ", ".join(f"{key} = {lua_value(record[key])}" for key in sorted(record))
            output.append(f"  {{{fields}}},")
        output.append(" },")
    return "\n".join(output + ["}", ""])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reviewed_json", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        data = json.loads(args.reviewed_json.read_text(encoding="utf-8"))
        result = generate(data)
        args.output.write_text(result, encoding="utf-8")
    except (OSError, ValueError, TypeError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
