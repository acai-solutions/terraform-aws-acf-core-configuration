import json
import re
import sys
import urllib.parse
from typing import Any, Dict, Iterator, List, Sequence, Tuple, Union

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


# noqa: C901
def _assign(
    root: NestedType, parts: Sequence[str], value: Any, decode_values: bool
): 
    """Recursively assign value into the nested structure based on parts."""

    def place_value(container: NestedType, key: str, val: Any):
        if key.isdigit():
            idx = int(key)
            if not isinstance(container, list):
                raise ValueError("Expected list for numeric key assignment")
            while len(container) <= idx:
                container.append(None)
            container[idx] = val
        else:
            if not isinstance(container, dict):
                raise ValueError("Expected dict for non-numeric key assignment")
            container[key] = val

    def get_or_create_child(
        container: NestedType, key: str, next_is_index: bool
    ) -> NestedType:
        if key.isdigit():
            idx = int(key)
            if not isinstance(container, list):
                raise ValueError("Expected list for numeric key path")
            while len(container) <= idx:
                container.append([] if next_is_index else {})
            if container[idx] is None:
                container[idx] = [] if next_is_index else {}
            return container[idx]
        else:
            if not isinstance(container, dict):
                raise ValueError("Expected dict for non-numeric key path")
            return _ensure_container(container, key, next_is_index)

    key = parts[0]
    is_last = len(parts) == 1
    next_key = parts[1] if not is_last else None
    next_is_index = next_key.isdigit() if next_key else False

    if is_last:
        final_value = decode_value(value) if decode_values else value
        place_value(root, key, final_value)
    else:
        child = get_or_create_child(root, key, next_is_index)
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
