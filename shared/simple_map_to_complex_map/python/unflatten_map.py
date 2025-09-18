#!/usr/bin/env python3
"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3

This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh
"""

"""
unflatten_map.py  ──  turn path-style keys into nested dicts / lists.

Usage:
  cat structure.json | python unflatten_map.py - --prefix /platform --decode --pretty
  python unflatten_map.py structure.json               # whole file, raw output
"""

import argparse
import json
import re
import sys
import urllib.parse
import os
from typing import Any, Dict, List, Union

# ─────────────────────────────────── helpers ──────────────────────────────────

_index_re = re.compile(r"^_(\d+)_$")  # matches "_0_", "_12_", etc.


def _looks_urlencoded(s: str) -> bool:
    return "%" in s and bool(re.search(r"%[0-9A-Fa-f]{2}", s))


def _maybe_decode(v: Any, decode: bool) -> Any:
    return (
        urllib.parse.unquote(v)
        if decode and isinstance(v, str) and _looks_urlencoded(v)
        else v
    )


def _is_index_segment(seg: str) -> bool:
    return bool(_index_re.match(seg))


def _index_number(seg: str) -> int:
    return int(_index_re.match(seg).group(1))


def _parse_path(path: str, prefix: str, separator: str) -> List[str]:
    if prefix and path.startswith(prefix):
        path = path[len(prefix) :].lstrip(separator)
    return [p for p in path.split(separator) if p]


def _ensure_list_length(lst: List[Any], idx: int) -> None:
    while len(lst) <= idx:
        lst.append(None)


def _set_value_at_path(
    root: Union[Dict[str, Any], List[Any]], path_parts: List[str], value: Any
) -> None:
    here = root
    for i, part in enumerate(path_parts):
        last = i == len(path_parts) - 1
        part_is_index = _is_index_segment(part)
        key_or_index = _index_number(part) if part_is_index else part

        if last:
            _assign_value(here, part_is_index, key_or_index, value)
        else:
            next_is_index = _is_index_segment(path_parts[i + 1])
            here = _ensure_next_container(
                here, part_is_index, key_or_index, next_is_index
            )


def _assign_value(container, is_index, key, value):
    if isinstance(container, list):
        if not is_index:
            raise TypeError("Dict-style key inside list not allowed")
        _ensure_list_length(container, key)
        container[key] = value
    elif isinstance(container, dict):
        if is_index:
            raise TypeError("Index-style key inside dict not allowed")
        container[key] = value
    else:
        raise TypeError("Invalid container type")


def _ensure_next_container(container, is_index, key, next_is_index):
    if isinstance(container, dict):
        if key not in container or not isinstance(container[key], (list, dict)):
            container[key] = [] if next_is_index else {}
        return container[key]
    elif isinstance(container, list):
        _ensure_list_length(container, key)
        if container[key] is None or not isinstance(container[key], (list, dict)):
            container[key] = [] if next_is_index else {}
        return container[key]
    else:
        raise TypeError("Invalid intermediate container")


# ─────────────────────────────────── core ─────────────────────────────────────


def unflatten_map(
    flat: Dict[str, Any],
    *,
    separator: str = "/",
    prefix: str = "",
    decode_values: bool = False,
) -> Union[Dict[str, Any], List[Any]]:
    if not flat:
        return {}

    first_keys = [k.split(separator)[0] for k in flat if k.startswith(prefix)]
    root_is_list = all(_is_index_segment(k) for k in first_keys)
    root: Union[Dict[str, Any], List[Any]] = [] if root_is_list else {}

    for raw_key, value in flat.items():
        if prefix and not raw_key.startswith(prefix):
            continue
        parts = _parse_path(raw_key, prefix, separator)
        decoded_value = _maybe_decode(value, decode_values)
        _set_value_at_path(root, parts, decoded_value)

    return root


# ─────────────────────────────────── cli ──────────────────────────────────────


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert flattened JSON to nested format"
    )
    parser.add_argument("input", help="JSON string or path to file")
    parser.add_argument(
        "prefix_positional",
        nargs="?",
        default=None,
        help="(Optional) path prefix to trim (positional form)",
    )
    parser.add_argument(
        "--prefix", default="", help="Path prefix to trim before processing"
    )
    parser.add_argument(
        "--decode", action="store_true", help="Decode URL-encoded strings"
    )
    parser.add_argument("--pretty", action="store_true", help="Pretty-print the output")
    parser.add_argument(
        "--wrap-external",
        action="store_true",
        help="Wrap output for Terraform external data source as {'result': '<json string>'}",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    # Determine final prefix (positional overrides if provided)
    effective_prefix = (
        args.prefix_positional if args.prefix_positional is not None else args.prefix
    )

    # Load input JSON
    try:
        if args.input == "-":
            input_text = sys.stdin.read()
            input_map = json.loads(input_text)
        elif os.path.exists(args.input):
            with open(args.input, "r", encoding="utf-8") as f:
                input_text = f.read()
            input_map = json.loads(input_text)
        else:
            # Treat as inline JSON string
            input_map = json.loads(args.input)
    except Exception as e:
        print(json.dumps({"error": f"Invalid input: {str(e)}"}), file=sys.stderr)
        sys.exit(1)

    # Convert
    try:
        result = unflatten_map(
            input_map,
            prefix=effective_prefix,
            decode_values=args.decode,
        )
        if args.wrap_external:
            # Compact JSON for embedding
            nested_json = json.dumps(result, separators=(",", ":"))
            print(json.dumps({"result": nested_json}))
        else:
            print(json.dumps(result, indent=2 if args.pretty else None))
    except Exception as e:
        print(json.dumps({"error": f"Processing error: {str(e)}"}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
