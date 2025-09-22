import json
import re
import sys
import urllib.parse
from typing import Any, Dict, Iterable, Iterator, List, Sequence, Tuple, Union

# ----------------------------
# Decoding helpers
# ----------------------------


def is_url_encoded(value: Any) -> bool:
    """Return True if value looks URL encoded."""
    return (
        isinstance(value, str)
        and "%" in value
        and re.search(r"%[0-9A-Fa-f]{2}", value) is not None
    )


def decode_value(value: Any) -> Any:
    """URL decode a value iff it looks encoded; otherwise return as-is."""
    if not isinstance(value, str) or not is_url_encoded(value):
        return value
    try:
        return urllib.parse.unquote(value)
    except Exception:  # pragma: no cover - defensive, keep original on failure
        return value


# ----------------------------
# Unflatten core helpers
# ----------------------------

NestedType = Union[Dict[str, Any], List[Any]]


def _iter_relevant_items(
    flattened_map: Dict[str, Any], prefix: Union[str, None], separator: str
) -> Iterator[Tuple[str, Any]]:
    """Yield key/value pairs filtered & trimmed by prefix."""
    if not prefix:
        for k, v in flattened_map.items():
            yield k, v
        return
    plen = len(prefix)
    for k, v in flattened_map.items():
        if k.startswith(prefix):
            trimmed = k[plen:].lstrip(separator)
            if trimmed:  # Skip empty after trimming
                yield trimmed, v


def _ensure_container(parent: NestedType, key: str, next_is_index: bool) -> NestedType:
    """Ensure the container for a dict key exists and return it."""
    if isinstance(parent, list):  # list index path handled elsewhere
        raise ValueError(
            "_ensure_container should not be called with list parent for dict key"
        )
    if key not in parent:
        parent[key] = [] if next_is_index else {}
    return parent[key]  # type: ignore[index]


def _assign(root: NestedType, parts: Sequence[str], value: Any, decode_values: bool):
    """Recursively assign value into the nested structure based on parts."""
    key = parts[0]
    is_index = key.isdigit()

    # Base case: last segment -> place the value
    if len(parts) == 1:
        final_value = decode_value(value) if decode_values else value
        if is_index:
            target_list = root if isinstance(root, list) else []
            # Grow list as needed
            while len(target_list) <= int(key):
                target_list.append(None)
            target_list[int(key)] = final_value
            if not isinstance(
                root, list
            ):  # Replace root reference if root was dict placeholder (shouldn't happen normally)
                root = target_list  # pragma: no cover - safety fallback
        else:  # dict assignment
            if isinstance(root, list):
                raise ValueError("Attempting to set dict key inside list without index")
            root[key] = final_value
        return

    next_key = parts[1]
    next_is_index = next_key.isdigit()

    if is_index:
        # Ensure root is a list
        if not isinstance(root, list):
            raise ValueError(
                "List index path encountered but current container is not a list"
            )
        # Grow list up to index
        idx = int(key)
        while len(root) <= idx:
            root.append([] if next_is_index else {})
        if root[idx] is None:
            root[idx] = [] if next_is_index else {}
        _assign(root[idx], parts[1:], value, decode_values)  # type: ignore[index]
    else:  # dict key path
        if isinstance(root, list):
            raise ValueError(
                "Dict key path encountered but current container is a list"
            )
        child = _ensure_container(root, key, next_is_index)
        _assign(child, parts[1:], value, decode_values)


def unflatten_map(
    flattened_map: Dict[str, Any],
    separator: str = "/",
    prefix: Union[str, None] = None,
    decode_values: bool = False,
) -> NestedType:
    """Convert flattened path keys (with optional prefix + list indices) into nested structures.

    Examples:
        {"a/b": 1} -> {"a": {"b": 1}}
        {"0/name": "alice"} -> [{"name": "alice"}]
    """
    # Start with dict; may switch to list if first relevant key begins with index
    nested: NestedType = {}
    for key, value in _iter_relevant_items(flattened_map, prefix, separator):
        parts = key.split(separator) if key else []
        if not parts:
            continue
        # If top-level is list path, convert once
        if parts[0].isdigit() and not isinstance(nested, list):
            nested = []  # type: ignore[assignment]
        _assign(nested, parts, value, decode_values)
    return nested


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
