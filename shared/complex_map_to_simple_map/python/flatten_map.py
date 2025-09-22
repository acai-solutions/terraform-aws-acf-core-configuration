import json
import sys
import urllib.parse


def needs_encoding(value):
    """Check if a value needs URL encoding."""
    if not isinstance(value, str):
        return False

    # Characters that cause issues in Parameter Store or are part of URLs
    problematic_chars = [
        " ",
        "&",
        "=",
        "?",
        "#",
        "@",
        "%",
        "+",
        '"',
        "'",
        "/",
        ":",
        ";",
        "<",
        ">",
        "[",
        "]",
        "{",
        "}",
        "|",
        "\\",
    ]
    return any(char in value for char in problematic_chars)


def encode_value(value, safe_chars=""):
    """URL encode a value if it needs encoding."""
    if not isinstance(value, str):
        value = str(value)

    # Only encode if the value contains problematic characters
    if needs_encoding(value):
        return urllib.parse.quote(value, safe=safe_chars)
    else:
        return value


def flatten_map(
    input_map, parent_key="", separator="/", encode_values=False, safe_chars=""
):
    """
    Flatten a nested dictionary/list structure into a flat dictionary.

    Args:
        input_map: The nested structure to flatten
        parent_key: Current parent key for recursion
        separator: Separator for key path construction
        encode_values: Whether to URL encode values that need it
        safe_chars: Characters to not encode when URL encoding
    """
    items = []
    if isinstance(input_map, dict):
        for key, value in input_map.items():
            new_key = f"{parent_key}{separator}{key}" if parent_key else key
            items.extend(
                flatten_map(
                    value,
                    new_key,
                    separator=separator,
                    encode_values=encode_values,
                    safe_chars=safe_chars,
                ).items()
            )
    elif isinstance(input_map, list):
        for idx, item in enumerate(input_map):
            new_key = f"{parent_key}{separator}{idx}"
            items.extend(
                flatten_map(
                    item,
                    new_key,
                    separator=separator,
                    encode_values=encode_values,
                    safe_chars=safe_chars,
                ).items()
            )
    else:
        # Apply encoding if requested
        final_value = (
            encode_value(input_map, safe_chars) if encode_values else input_map
        )
        items.append((parent_key, final_value))
    return dict(items)


def main():
    """Main function to handle command line arguments."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing required input argument"}))
        sys.exit(1)

    try:
        input_text = sys.argv[1]
        prefix = sys.argv[2] if len(sys.argv) > 2 else ""
        encode_values = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else False
        safe_chars = sys.argv[4] if len(sys.argv) > 4 else ""

        input_map = json.loads(input_text)
        flattened_configuration_items = flatten_map(
            input_map,
            parent_key=prefix,
            encode_values=encode_values,
            safe_chars=safe_chars,
        )

        print(json.dumps({"result": json.dumps(flattened_configuration_items)}))

    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {str(e)}"}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": f"Processing error: {str(e)}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
