import json
import sys
import urllib.parse
import re

def is_url_encoded(value):
    """Check if a value appears to be URL encoded."""
    if not isinstance(value, str):
        return False
    return '%' in value and re.search(r'%[0-9A-Fa-f]{2}', value)

def decode_value(value):
    """URL decode a value if it appears to be encoded."""
    if not isinstance(value, str):
        return value
    
    # Only decode if it looks like it's URL encoded
    if is_url_encoded(value):
        try:
            return urllib.parse.unquote(value)
        except Exception:
            # If decoding fails, return original value
            return value
    else:
        return value

def unflatten_map(flattened_map, separator='/', prefix=None, decode_values=False):
    """
    Convert a flattened dictionary with path-style keys into a nested dictionary with support for lists.
    
    Args:
        flattened_map: The flat dictionary to unflatten
        separator: Separator used in the flattened keys
        prefix: Prefix to filter keys by
        decode_values: Whether to URL decode values that appear encoded
    """
    def assign(d, keys, value):
        key = keys[0]
        is_index = key.isdigit()

        if len(keys) == 1:
            # Apply decoding if requested
            final_value = decode_value(value) if decode_values else value
            
            if is_index:
                while len(d) <= int(key):
                    d.append(None)
                d[int(key)] = final_value
            else:
                d[key] = final_value
            return

        next_key = keys[1]
        is_next_index = next_key.isdigit()

        if is_index:
            while len(d) <= int(key):
                d.append([] if is_next_index else {})
            if d[int(key)] is None:
                d[int(key)] = [] if is_next_index else {}
            assign(d[int(key)], keys[1:], value)
        else:
            if key not in d:
                d[key] = [] if is_next_index else {}
            assign(d[key], keys[1:], value)

    nested = {}
    for key, value in flattened_map.items():
        if prefix and key.startswith(prefix):
            key = key[len(prefix):].lstrip(separator)
        elif prefix:
            continue

        parts = key.split(separator)
        if parts[0].isdigit():
            if not isinstance(nested, list):
                nested = []
        assign(nested, parts, value)
    return nested

def main():
    """Main function to handle command line arguments."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing required input argument"}))
        sys.exit(1)
    
    try:
        input_text = sys.argv[1]
        prefix = sys.argv[2] if len(sys.argv) > 2 else ''
        decode_values = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else False
        
        input_map = json.loads(input_text)
        unflattened_configuration_items = unflatten_map(
            input_map, 
            prefix=prefix,
            decode_values=decode_values
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
