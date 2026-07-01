#!/bin/bash

# Define file paths
TEMPLATE_FILE="/etc/amnezia/amneziawg/wg0.conf.template"
OUTPUT_FILE="/etc/amnezia/amneziawg/wg0.conf"

# Check if the template file is readable
if [[ ! -r "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file $TEMPLATE_FILE is not found or not readable." >&2
    exit 1
fi

# Process the file and write the output
# The regular expression searches for:
# 'I' followed by one or more digits, optional whitespace, an equals sign, 
# and optional whitespace until the end of the line.
sed -E 's/^(I[0-9]+[[:space:]]*=[[:space:]]*\r?)$/#\1/' "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# Check the execution status
if [[ $? -eq 0 ]]; then
    echo "Operation completed successfully. Output saved to $OUTPUT_FILE."
else
    echo "Critical error: Failed to write to $OUTPUT_FILE." >&2
    exit 2
fi
