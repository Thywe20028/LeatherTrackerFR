"""Fetch one ForeverDB item to inspect its schema outside the game."""

import argparse
import getpass
import json
import os
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from pathlib import Path
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("item_id", type=int, nargs="?")
    parser.add_argument("--vendor", type=int)
    parser.add_argument("--skinning-zone")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if sum(value is not None for value in (args.item_id, args.vendor, args.skinning_zone)) != 1:
        parser.error("Indique un objet, --vendor ou --skinning-zone.")
    if args.item_id is not None and args.item_id < 1 or args.vendor is not None and args.vendor < 1:
        parser.error("L’identifiant doit être positif.")
    if args.item_id is not None:
        endpoint = f"items/{args.item_id}"
    elif args.vendor is not None:
        endpoint = f"vendors/{args.vendor}"
    else:
        endpoint = "gathering/skinning?" + urlencode({"zone": args.skinning_zone})

    key = os.getenv("FOREVERDB_API_KEY") or getpass.getpass("Clé ForeverDB : ")
    if not key.strip():
        parser.error("Aucune clé ForeverDB fournie.")

    request = Request(
        f"https://foreverdb.net/api/v1/{endpoint}",
        headers={
            "Accept": "application/json",
            "User-Agent": "LeatherTrackerFR/0.7.0 (catalogue probe)",
            "X-API-Key": key.strip(),
        },
    )
    try:
        with build_opener(NoRedirects()).open(request, timeout=15) as response:
            payload = json.load(response)
    except HTTPError as error:
        print(f"ForeverDB a répondu HTTP {error.code}.", file=sys.stderr)
        return 1
    except (URLError, OSError, ValueError):
        print("Impossible de lire la réponse ForeverDB.", file=sys.stderr)
        return 1

    if not isinstance(payload, dict) or "data" not in payload or not isinstance(payload.get("meta"), dict):
        print("Réponse ForeverDB inattendue.", file=sys.stderr)
        return 1
    result = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(result, encoding="utf-8")
    else:
        print(result, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
