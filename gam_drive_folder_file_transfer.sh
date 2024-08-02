#!/bin/bash

# Script: Transfer Google Drive File or Folder
#
# Description:
# This script transfers a Google Drive file or folder and its contents from one employee to another 
# using GAMADV-XTD3. It supports previewing the changes before executing the transfer and handles 
# scenarios where the folder contains other owners.
#
# TODO:
# - Handle folders with other owners by using skipusers ~ownerid
# - Improve user interface for better user experience
#
# Notes:
# - Ensure that GAMADV-XTD3 is installed and properly configured.
# - Handle email addresses and item IDs securely.
# - Customize the paths and commands as needed for your environment.
# Author: Chad Ramey
# Date: August 2, 2024

clear_screen() {
    echo "--------------------------------------------------"
}

while true; do
    clear_screen
    # Prompt for user inputs
    read -p "Enter old owner's email address: " old_owner_email
    read -p "Enter new owner's email address: " new_owner_email
    read -p "Is this a file or a folder? (file/folder): " item_type
    read -p "Enter the ${item_type} ID to be transferred: " item_id
    read -p "Do you want to preview the changes before transferring? (yes/no): " preview_choice

    clear_screen
    echo "Initiating the transfer process..."
    echo "Adding new owner as an editor to the ${item_type}..."
    ~/bin/gamadv-xtd3/gam user "$old_owner_email" add drivefileacl "$item_id" user "$new_owner_email" role editor >/dev/null
    echo "Update applied. Processing..."
    sleep 10  # Pause script execution for 10 seconds

    if [ "$preview_choice" = "yes" ]; then
        clear_screen
        echo "Preview mode enabled. Generating preview..."
        ~/bin/gamadv-xtd3/gam user "$new_owner_email" claim ownership "$item_id" retainrole none preview
        echo "--------------------------------------------------"
        read -p "Confirm actual transfer after reviewing the preview? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Transfer not executed."
            echo "--------------------------------------------------"
            read -p "Do you want to transfer another file or folder? (yes/no): " repeat
            if [ "$repeat" != "yes" ]; then
                break
            else
                continue
            fi
        fi
    fi

    clear_screen
    echo "Executing actual transfer..."
    ~/bin/gamadv-xtd3/gam user "$new_owner_email" claim ownership "$item_id" retainrole none >/dev/null
    sleep 10
    echo "Finalizing the transfer..."
    root_id=$(~/bin/gamadv-xtd3/gam user "$new_owner_email" show fileinfo root id | grep 'id:' | awk '{print $2}')
    ~/bin/gamadv-xtd3/gam user "$new_owner_email" move drivefile "$item_id" parentid "$root_id" >/dev/null
    echo "Transfer complete."
    echo "--------------------------------------------------"

    read -p "Do you want to transfer another file or folder? (yes/no): " repeat
    if [ "$repeat" != "yes" ]; then
        break
    fi
done

echo "No further transfers. Exiting."
