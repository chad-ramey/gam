#!/bin/bash

# Script: Google Drive Content Transfer
# Description:
# This script is designed to copy Google Drive content from one employee to another using GAMADV-XTD3.
# It supports transferring the entire Drive, specific folders, or specific files.
# The script handles the following scenarios:
# - Checks if a folder named after the old owner already exists in the new owner's Drive and reuses it.
# - Creates the folder if it doesn't exist and adds the old owner as an editor to facilitate data copying.
# - Copies the selected Drive data to the new folder.
# - Transfers ownership of the copied files to the new owner.
# - Removes the old owner's access to the copied data.

# Functions:
# - transfer_drive_data: Handles the transfer of Drive data.
# - prompt_input: Prompts for user input with validation.
# - prompt_status: Prompts for a valid account status (archived, suspended, or active).
# - prompt_copy_mode: Prompts for a valid copy mode (drive, folder, or file).

# Usage:
# 1. Run the script.
# 2. Enter the email addresses of the old and new owners when prompted.
# 3. Specify the status of the old owner's account.
# 4. Choose the type of data to copy (entire Drive, specific folder, or specific file).
# 5. Provide the necessary IDs for the selected data type.
# 6. The script will handle the transfer and prompt if more data needs to be copied.

# Notes:
# - Ensure that GAMADV-XTD3 is installed and properly configured.
# - Handle email addresses and IDs securely.
# - This script has been tested on zsh and bash.

# Author: Chad Ramey
# Date: August 1, 2024

# Function to handle the transfer of Drive data
transfer_drive_data() {
    local mode="$1"
    local source_id="$2"
    local source_type="$3"

    # Check if the folder already exists in the new owner's Drive
    if [ -z "$folder_id" ]; then
        echo -e "\nChecking if '$old_owner' folder exists in the new owner's drive..."
        folder_check_output=$(~/bin/gamadv-xtd3/gam user "$new_owner" print filelist query "name='$old_owner' and mimeType='application/vnd.google-apps.folder' and trashed=false")
        
        existing_folder_id=$(echo "$folder_check_output" | awk -F, 'NR==2 {print $3}' | sed 's#https://drive.google.com/drive/folders/##')

        if [ -n "$existing_folder_id" ]; then
            folder_id="$existing_folder_id"
            echo "Found existing folder '$old_owner' with ID $folder_id"

            # Add the old owner as an editor to the existing folder to facilitate data copying
            echo "Adding old owner as an editor of the existing '$old_owner' folder..."
            ~/bin/gamadv-xtd3/gam user "$new_owner" add drivefileacl "$folder_id" user "$old_owner" role writer >/dev/null
        else
            echo "Creating '$old_owner' folder in the new owner's drive..."
            folder_creation_output=$(~/bin/gamadv-xtd3/gam user "$new_owner" create drivefile drivefilename "$old_owner" mimetype gfolder)
            folder_id=$(echo "$folder_creation_output" | awk -F'[][]' '{print $2}')

            # Check for successful folder creation
            if [ -z "$folder_id" ]; then
                echo "Failed to create folder or extract folder ID."
                exit 1
            fi

            # Add the old owner as an editor to the new folder to facilitate data copying
            echo "Adding old owner as an editor of '$old_owner' folder..."
            ~/bin/gamadv-xtd3/gam user "$new_owner" add drivefileacl "$folder_id" user "$old_owner" role writer >/dev/null
        fi
    else
        echo -e "\nUsing existing folder '$old_owner' in the new owner's drive..."
    fi

    # Copy the selected Drive data to the new subfolder in the '$old_owner' folder
    echo "Copying $source_type to the new owner's '$old_owner' folder..."
    ~/bin/gamadv-xtd3/gam user "$old_owner" copy drivefile "$source_id" parentid "$folder_id" >/dev/null

    # Transfer ownership of the copied files to the new owner
    echo "Transferring ownership of copied files to the new owner..."
    ~/bin/gamadv-xtd3/gam user "$old_owner" transfer ownership "$folder_id" "$new_owner" >/dev/null

    # Remove the old owner's access to the copied data
    echo "Removing old owner's access to all copied data in the '$old_owner' folder..."
    ~/bin/gamadv-xtd3/gam user "$new_owner" print filelist select id "$folder_id" fields id showparent | gam csv - gam user "~Owner" delete drivefileacl "~id" "$old_owner" >/dev/null
}

# Function to prompt for input with validation
prompt_input() {
    local prompt_message="$1"
    local input_variable

    while true; do
        read -p "$prompt_message" input_variable
        if [ -n "$input_variable" ]; then
            echo "$input_variable"
            return 0
        else
            echo "Input cannot be empty. Please try again."
        fi
    done
}

# Function to prompt for valid status
prompt_status() {
    local prompt_message="$1"
    local input_variable

    while true; do
        read -p "$prompt_message" input_variable
        case "$input_variable" in
            archived|suspended|active)
                echo "$input_variable"
                return 0
                ;;
            *)
                echo "Invalid status. Please enter 'archived', 'suspended', or 'active'."
                ;;
        esac
    done
}

# Function to prompt for valid copy mode
prompt_copy_mode() {
    local prompt_message="$1"
    local input_variable

    while true; do
        read -p "$prompt_message" input_variable
        case "$input_variable" in
            drive|folder|file)
                echo "$input_variable"
                return 0
                ;;
            *)
                echo "Invalid selection. Please enter 'drive', 'folder', or 'file'."
                ;;
        esac
    done
}

# Main loop to handle user interaction and process copying
while true; do
    clear
    echo "=== Google Drive Copy Process ==="

    # Collect email addresses of the old and new owners
    old_owner=$(prompt_input "Enter the email address of the old owner: ")
    new_owner=$(prompt_input "Enter the email address of the new owner: ")

    # Query the status of the old owner's account
    account_status=$(prompt_status "Is the old owner's account archived, suspended, or active? Enter 'archived', 'suspended', or 'active': ")

    # Handle account status: unarchive or unsuspend if necessary
    if [ "$account_status" == "archived" ]; then
        echo "Unarchiving and unsuspending the old owner's account..."
        ~/bin/gamadv-xtd3/gam update user "$old_owner" archived off
        ~/bin/gamadv-xtd3/gam unsuspend user "$old_owner"
    elif [ "$account_status" == "suspended" ]; then
        echo "Unsuspending the old owner's account..."
        ~/bin/gamadv-xtd3/gam unsuspend user "$old_owner"
    fi

    # Initialize folder_id to empty
    folder_id=""

    # Determine what type of data to copy: entire Drive, a specific folder, or a specific file
    copy_mode=$(prompt_copy_mode "Do you want to copy the entire Drive, a specific folder, or a specific file? Enter 'drive', 'folder', or 'file': ")

    case $copy_mode in
        file)
            source_id=$(prompt_input "Enter the file ID to copy: ")
            ;;
        folder)
            source_id=$(prompt_input "Enter the folder ID to copy: ")
            ;;
        drive)
            source_id=$(~/bin/gamadv-xtd3/gam user "$old_owner" show fileinfo root id | awk '/id:/{print $2}')
            if [ -z "$source_id" ]; then
                echo "Failed to find the root ID of the old owner's Drive."
                exit 1
            fi
            ;;
    esac

    transfer_drive_data "$copy_mode" "$source_id" "$copy_mode"

    # Ask if more data needs to be copied, if not exit the loop
    echo -e "\nDo you have other data to copy? (yes/no):"
    read continue_copy
    if [[ ! "$continue_copy" =~ ^[Yy][Ee][Ss]$ && ! "$continue_copy" =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        break
    fi
done
