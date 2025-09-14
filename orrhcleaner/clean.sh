#!/bin/bash

TARGET_DIR="/config/OnlyRetroRobloxHere"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for placeholder files
JPG_PLACEHOLDER="$SCRIPT_DIR/placeholderjpg"
PNG_PLACEHOLDER="$SCRIPT_DIR/placeholderpng"

rm -rf "$TARGET_DIR/redist"

if [ ! -f "$JPG_PLACEHOLDER" ]; then
    echo "Error: JPG placeholder file not found at '$JPG_PLACEHOLDER'"
    exit 1
fi

if [ ! -f "$PNG_PLACEHOLDER" ]; then
    echo "Error: PNG placeholder file not found at '$PNG_PLACEHOLDER'"
    exit 1
fi

# Find and replace files
find "$TARGET_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | while read -r file; do
    # Get file extension
    extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    # Determine which placeholder to use
    if [ "$extension" = "jpg" ] || [ "$extension" = "jpeg" ]; then
        placeholder="$JPG_PLACEHOLDER"
    elif [ "$extension" = "png" ]; then
        placeholder="$PNG_PLACEHOLDER"
    else
        continue  # Skip unsupported formats
    fi
    
    # Replace file
    if cp "$placeholder" "$file"; then
        echo "Replaced: $file"
    else
        echo "Failed to replace: $file"
    fi
done

echo "Replacement complete!"
