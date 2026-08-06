#!/bin/bash

# Path to the preferences file
PREFERENCES_FILE="/home/aly/.config/BraveSoftware/Brave-Browser/Default/Preferences"

# Check if the file exists
if [ ! -f "$PREFERENCES_FILE" ]; then
    echo "Error: Preferences file not found at $PREFERENCES_FILE"
    exit 1
fi

# Create a backup of the original file with timestamp
BACKUP_FILE="${PREFERENCES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "Creating backup at $BACKUP_FILE"
cp "$PREFERENCES_FILE" "$BACKUP_FILE"

# Use sed to replace "exit_type":"Crashed" with "exit_type":"Normal"
# The -i flag edits the file in-place
# Using a more flexible pattern to handle variations in whitespace
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/g' "$PREFERENCES_FILE"

# Alternative if there might be spaces (uncomment if needed):
# sed -i 's/"exit_type":[[:space:]]*"Crashed"/"exit_type":"Normal"/g' "$PREFERENCES_FILE"

# Verify the change was made
if grep -q '"exit_type":"Normal"' "$PREFERENCES_FILE"; then
    echo "Successfully changed exit_type from Crashed to Normal"
else
    echo "Warning: Could not verify the change. The pattern may not have matched."
    echo "Restoring from backup..."
    cp "$BACKUP_FILE" "$PREFERENCES_FILE"
    exit 1
fi

echo "Done! You may need to restart Brave Browser for changes to take effect."