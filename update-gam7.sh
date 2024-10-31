#!/bin/bash

# Script: GAM 7 Version Checker and Auto-Updater with Filtered Release Notes
# Description: This script checks the installed version of GAM 7, compares it with the latest version available from GitHub,
#              and updates GAM 7 if a newer version is available. It also displays only the relevant release notes.
# Requirements: jq, curl
#
# Author: Chad Ramey
# Last Modified: October 31, 2024

# Get the installed version of GAM 7 by pointing to the correct executable and stripping "GAM" prefix
installed_version=$(/Users/chad.ramey/bin/gam7/gam version | grep "GAM " | awk '{print $2}' | sed 's/[^0-9.]//g')

# Get the latest version and release notes from the GitHub API
latest_version=$(curl -s https://api.github.com/repos/GAM-team/GAM/releases/latest | jq -r '.name' | sed 's/[^0-9.]//g')
release_notes=$(curl -s https://api.github.com/repos/GAM-team/GAM/releases/latest | jq -r '.body')

# Filter out installation instructions and SHA256 hashes from release notes
filtered_notes=$(echo "$release_notes" | sed -E '/^## Installation|^## sha256|^[a-f0-9]{64}/d')

# Check if both versions were retrieved
if [[ -z "$installed_version" || -z "$latest_version" ]]; then
    echo "Error: Could not retrieve the installed or latest version."
    exit 1
fi

# Compare versions (ensure no extra characters)
if [[ "$installed_version" != "$latest_version" ]]; then
    echo "New GAM 7 version ($latest_version) available. Updating from version $installed_version..."

    # Display the filtered release notes
    echo "Release Notes for version $latest_version:"
    echo "$filtered_notes"

    # Run the update command directly
    bash <(curl -s -S -L https://git.io/install-gam) -l

    echo "GAM 7 has been updated to version $latest_version."
else
    echo "GAM 7 is already up to date (version $installed_version)."
fi