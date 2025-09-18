"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3
#
This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh


"""

"""
unflatten.py  ──  turn path-style keys into nested dicts / lists.

  python unflatten.py <json_file|-> [prefix] [--decode] [--pretty]

Examples
~~~~~~~~
  cat structure.json | python unflatten.py - /platform --decode --pretty
  python unflatten.py structure.json               # whole file, raw output
"""
import json, sys, re, urllib.parse
from typing import Any, Dict, List, Union
import re


# ─────────────────────────────────── helpers ──────────────────────────────────
def _looks_urlencoded(s: str) -> bool:
    return "%" in s and bool(re.search(r"%[0-9A-Fa-f]{2}", s))


def _maybe_decode(v: Any, decode: bool) -> Any:
    return (
        urllib.parse.unquote(v)
        if decode and isinstance(v, str) and _looks_urlencoded(v)
        else v
    )


def _upgrade_slot(container: Union[list, dict], key: Union[int, str]) -> dict:
    """
    If <container>[key] is currently a scalar and we now need it to be a dict,
    replace it with an empty dict.  (Feel free to store the old value under a
    special key like '__value' instead – marked as TODO.)
    """
    # ★ collision policy
    old = container[key]
    if not isinstance(old, (list, dict)):
        # TODO: keep old value?  container[key] = {"__value": old}
        container[key] = {}
    return container[key]


_index_re = re.compile(r"^_(\d+)_$")  #  ⇠  ➜  matches "_0_", "_12_", …


def _is_index_segment(seg: str) -> bool:
    """Return True if seg is like '_0_' and therefore marks a list index."""
    return bool(_index_re.match(seg))


def _index_number(seg: str) -> int:
    """Extract the integer  n  from '_n_'  (assumes caller already checked)."""
    return int(_index_re.match(seg).group(1))


# ─────────────────────────────────── core ─────────────────────────────────────
def unflatten_map(
    flat: Dict[str, Any],
    *,
    separator: str = "/",
    prefix: str = "",
    decode_values: bool = False,
) -> Union[Dict[str, Any], List[Any]]:
    """
    Turn {"/a/b/_0_": "x", "/a/b/_1_": "y"}
         into {"a": {"b": ["x", "y"]}}
    """
    # decide root type: list if *every* first segment is an index-marker
    root: Union[Dict[str, Any], List[Any]] = (
        [] if all(_is_index_segment(k.split(separator)[0]) for k in flat) else {}
    )

    # (optional) sort deepest paths first if you kept that optimisation
    for raw_key, value in flat.items():
        if prefix and not raw_key.startswith(prefix):
            continue
        path = raw_key[len(prefix) :].lstrip(separator) if prefix else raw_key
        parts = [p for p in path.split(separator) if p]

        here: Union[Dict[str, Any], List[Any]] = root
        for i, part in enumerate(parts):
            last = i == len(parts) - 1
            part_is_index = _is_index_segment(part)

            if last:
                idx_or_key = _index_number(part) if part_is_index else part
                if isinstance(here, list) and not part_is_index:
                    raise TypeError("Dict-style key inside list not allowed")
                if isinstance(here, dict) and part_is_index:
                    raise TypeError("Index-style key inside dict not allowed")

                if isinstance(here, list):
                    while len(here) <= idx_or_key:
                        here.append(None)
                    here[idx_or_key] = _maybe_decode(value, decode_values)
                else:
                    here[idx_or_key] = _maybe_decode(value, decode_values)
            else:
                next_is_index = _is_index_segment(parts[i + 1])

                if isinstance(here, dict):
                    here = here.setdefault(part, [] if next_is_index else {})
                else:  # list
                    idx = _index_number(part)
                    while len(here) <= idx:
                        here.append(None)
                    if here[idx] is None:
                        here[idx] = [] if next_is_index else {}
                    here = here[idx]

    return root


def main():
    """Main function to handle command line arguments."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing required input argument"}))
        sys.exit(1)

    try:
        input_text = sys.argv[1]
        prefix = sys.argv[2] if len(sys.argv) > 2 else ""
        decode_values = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else False

        input_map = json.loads(input_text)
        unflattened_configuration_items = unflatten_map(
            input_map, prefix=prefix, decode_values=decode_values
        )

        print(json.dumps({"result": json.dumps(unflattened_configuration_items)}))

    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {str(e)}"}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": f"Processing error: {str(e)}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
