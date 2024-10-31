#!/bin/bash

# Script: GAMADV-XTD3 Version Checker and Auto-Updater with Filtered Release Notes
# Description: This script checks the installed version of GAMADV-XTD3, compares it 
#              with the latest version available from GitHub, and updates GAMADV-XTD3 if a newer version is available.
#              It also displays only the relevant release notes for the latest version.
# Requirements: jq, curl
#
# Author: Chad Ramey
# Last Modified: October 31, 2024

# Get the installed version of GAMADV-XTD3 by pointing to the correct executable and stripping "GAMADV-XTD3" prefix
installed_version=$(/Users/chad.ramey/bin/gamadv-xtd3/gam version | grep "GAMADV-XTD3" | awk '{print $2}' | sed 's/[^0-9.]//g')

# Get the latest version and release notes from the GitHub API
latest_version=$(curl -s https://api.github.com/repos/taers232c/GAMADV-XTD3/releases/latest | jq -r '.name' | sed 's/[^0-9.]//g')
release_notes=$(curl -s https://api.github.com/repos/taers232c/GAMADV-XTD3/releases/latest | jq -r '.body')

# Filter out installation instructions and SHA256 hashes from release notes
filtered_notes=$(echo "$release_notes" | sed -E '/^## Installation|^## sha256|^[a-f0-9]{64}/d')

# Check if both versions were retrieved
if [[ -z "$installed_version" || -z "$latest_version" ]]; then
    echo "Error: Could not retrieve the installed or latest version."
    exit 1
fi

# Compare versions (ensure no extra characters)
if [[ "$installed_version" != "$latest_version" ]]; then
    echo "New GAMADV-XTD3 version ($latest_version) available. Updating from version $installed_version..."

    # Display the filtered release notes
    echo "Release Notes for version $latest_version:"
    echo "$filtered_notes"

    # Run the update command using the alias `gamup`
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l

    echo "GAMADV-XTD3 has been updated to version $latest_version."
else
    echo "GAMADV-XTD3 is already up to date (version $installed_version)."
fi