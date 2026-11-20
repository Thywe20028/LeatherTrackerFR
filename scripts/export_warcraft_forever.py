"""Convert targeted Warcraft Forever item responses to a Lua catalogue."""

import argparse
import json
from pathlib import Path


def export(document):
    dataset = document["dataset"]
    if not isinstance(dataset, str) or not dataset:
        raise ValueError("Identifiant du jeu de données manquant.")
    rows = []
    for key, response in sorted(document["items"].items(), key=lambda entry: int(entry[0])):
        item_id = int(key)
        if not 0 < item_id <= 2147483647 or str(item_id) != key:
            raise ValueError(f"Identifiant invalide : {key}")
        if response["dataset"] != dataset or response["resource"] != "items":
            raise ValueError(f"Réponse hors catalogue : {key}")
        record = response["data"]
        if record is None:
            continue
        name = record.get("name")
        if record.get("nameLocale") != "frFR" or not name:
            continue
        if not isinstance(name, str) or any(ord(char) < 32 for char in name):
            raise ValueError(f"Nom invalide : {key}")
        rows.append(f"  [{item_id}] = {json.dumps(name, ensure_ascii=False)},")
    if not rows:
        raise ValueError("Le catalogue n’a renvoyé aucun nom français exploitable.")
    if any(ord(char) < 32 for char in dataset):
        raise ValueError("Identifiant du jeu de données invalide.")
    return "\n".join([
        "local _, addon = ...",
        "addon.warcraftForever = {",
        f" dataset = {json.dumps(dataset, ensure_ascii=False)},",
        " names = {",
        *rows,
        " },",
        "}",
        "",
    ])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("responses", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        data = json.loads(args.responses.read_text(encoding="utf-8"))
        args.output.write_text(export(data), encoding="utf-8")
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
