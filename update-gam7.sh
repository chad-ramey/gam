#!/bin/bash

# Script: GAM 7 Version Checker and Auto-Updater
# Description: This script checks the installed version of GAM 7 and compares it 
#              with the latest version available from the official GitHub repository.
#              If a new version is available, the script automatically updates GAM 7.
# Requirements: jq, curl
#
# Author: Chad Ramey
# Last Modified: September 30, 2024
#
# Instructions for Users:
# 1. Ensure jq and curl are installed on your system.
#    - For macOS: Use 'brew install jq curl' if Homebrew is installed.
#    - For Linux: Use the package manager specific to your distribution.
#
# 2. Update the GAM path in the 'installed_version' command below:
#    Replace '~/bin/gam7/gam' with the correct path to your local GAM 7 installation.
#    You can find the GAM binary location by running 'which gam' or checking your installation directory.
# 
# 3. Run this script using 'bash' or add it to a cron job for periodic checks.
#
# 4. Ensure you have sufficient permissions to execute GAM updates.

# Get the installed version of gam7 by pointing to the correct executable and stripping "GAM" prefix
installed_version=$(~/bin/gam7/gam version | grep "GAM " | awk '{print $2}' | sed 's/[^0-9.]//g')

# Get the correct version from the release 'name' field, stripping any potential "GAM" prefix and removing any non-numeric characters
latest_version=$(curl -s https://api.github.com/repos/GAM-team/GAM/releases/latest | jq -r '.name' | sed 's/[^0-9.]//g')

# Check if both versions were retrieved
if [[ -z "$installed_version" || -z "$latest_version" ]]; then
    echo "Error: Could not retrieve the installed or latest version."
    exit 1
fi

# Compare versions (ensure no extra characters)
if [[ "$installed_version" != "$latest_version" ]]; then
    echo "New GAM 7 version ($latest_version) available. Updating from version $installed_version..."

    # Run the update command directly
    bash <(curl -s -S -L https://git.io/install-gam) -l

    echo "GAM 7 has been updated to version $latest_version."
else
    echo "GAM 7 is already up to date (version $installed_version)."
fi
