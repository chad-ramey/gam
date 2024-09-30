#!/bin/bash

# Script: update-gamadv-xtd3.sh
# Description: This script checks the installed version of GAMADV-XTD3, compares it with the latest version from GitHub, and updates GAMADV-XTD3 if a newer version is available.
# Author: Chad Ramey
# Last Modified: September 30, 2024

# Instructions:
# 1. Make sure to replace the path to your GAMADV-XTD3 installation in the variable `installed_version` below.
#    Currently, it points to "~/bin/gamadv-xtd3/gam". Adjust this path if your GAMADV-XTD3 executable is located elsewhere.
# 2. Save the script as `update-gamadv-xtd3.sh` and make it executable by running:
#    chmod +x update-gamadv-xtd3.sh
# 3. Run the script using:
#    ./update-gamadv-xtd3.sh

# Get the installed version of gamadv-xtd3 by pointing to the correct executable and stripping "GAMADV-XTD3" prefix
installed_version=$(~/bin/gamadv-xtd3/gam version | grep "GAMADV-XTD3" | awk '{print $2}' | sed 's/[^0-9.]//g')

# Get the correct version from the release 'name' field from the GAMADV-XTD3 GitHub repo
latest_version=$(curl -s https://api.github.com/repos/taers232c/GAMADV-XTD3/releases/latest | jq -r '.name' | sed 's/[^0-9.]//g')

# Check if both versions were retrieved
if [[ -z "$installed_version" || -z "$latest_version" ]]; then
    echo "Error: Could not retrieve the installed or latest version."
    exit 1
fi

# Compare versions (ensure no extra characters)
if [[ "$installed_version" != "$latest_version" ]]; then
    echo "New GAMADV-XTD3 version ($latest_version) available. Updating from version $installed_version..."

    # Run the update command using the alias `gamup`
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l

    echo "GAMADV-XTD3 has been updated to version $latest_version."
else
    echo "GAMADV-XTD3 is already up to date (version $installed_version)."
fi
