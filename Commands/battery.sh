#!/bin/bash

# Script to set the battery charge control end threshold

# Function to safely read the sudo password
get_sudo_password() {
    read -r -s -p "[sudo] password for $USER: " SUDO_PASSWORD
    echo # Print a newline after the password input
}

# Function to validate and set the threshold
set_charge_threshold() {
    local threshold=$1
    local file_path="/sys/class/power_supply/BAT0/charge_control_end_threshold"
    
    # Check if the file exists (using sudo for the check)
    if ! echo "$SUDO_PASSWORD" | sudo -S test -f "$file_path" 2>/dev/null; then
        echo "Error: Battery control file not found at $file_path"
        echo "Your system may not support this feature."
        exit 1
    fi
    
    # Validate input is a number between 40 and 100 (common valid range)
    if [[ ! "$threshold" =~ ^[0-9]+$ ]] || [[ "$threshold" -lt 40 ]] || [[ "$threshold" -gt 100 ]]; then
        echo "Error: Please enter a valid number between 40 and 100"
        exit 1
    fi
    
    # Use the stored password with sudo to write to the file
    if echo "$SUDO_PASSWORD" | sudo -S tee "$file_path" > /dev/null <<< "$threshold"; then
        echo "Successfully set charge threshold to ${threshold}%"
        
        # Verify the new value - use the same sudo session
        current_value=$(echo "$SUDO_PASSWORD" | sudo -S cat "$file_path" 2>/dev/null)
        if [[ -n "$current_value" ]]; then
            echo "Current threshold is now: ${current_value}%"
        else
            echo "Warning: Could not verify the new threshold value"
        fi
    else
        echo "Error: Failed to set charge threshold. Please check your password and permissions."
        exit 1
    fi
}

# Main script execution
echo "Battery Charge Threshold Setter"
echo "================================"

# Get the sudo password first
get_sudo_password

# Ask for the desired threshold value
read -r -p "Enter desired charge threshold (40-100): " desired_threshold

# Set the charge threshold
set_charge_threshold "$desired_threshold"

# Clear the password variable from memory for security
unset SUDO_PASSWORD