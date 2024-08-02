#!/bin/bash

# Script: Google Drive File Transfer
#
# Description:
# This script transfers a Google Drive file from one employee to another using GAMADV-XTD3. 
# It handles the ACL 'Does not exist' error, and allows specifying whether the old owner 
# should retain access to the file with a specified role.
#
# Usage:
# 1. Run the script.
# 2. Enter the old owner's email address when prompted.
# 3. Enter the new owner's email address when prompted.
# 4. Enter the file ID to be transferred when prompted.
# 5. Specify whether the old owner should retain access to the file.
# 6. If retaining access, choose the access level for the old owner.
#
# Notes:
# - Ensure that GAMADV-XTD3 is installed and properly configured.
# - Handle email addresses and file IDs securely.
# - Customize the script as needed for your environment.
#
# - Added handling for ACL 'Does not exist' error.
# - TODO: Add support for multiple files, suspend/unsuspend functionality.
#
# Author: Chad Ramey
# Date: August 2, 2024

# Prompt for the old owner's email address
read -p "Enter old owner's email address: " old_owner_email

# Prompt for the new owner's email address
read -p "Enter new owner's email address: " new_owner_email

# Prompt for the file ID
read -p "Enter the file ID to be transferred: " file_id

# Prompt if old owner should retain access and set the retainrole parameter
read -p "Should the old owner retain access to the file? (yes/no): " retain_access
retain_role="none" # Default to none

if [ "$retain_access" = "yes" ]; then
    # Prompt for the access level for the old owner
    read -p "Choose the access level for the old owner (reader/commenter/writer/editor): " old_owner_access_level
    retain_role="$old_owner_access_level"
fi

# Add the new owner as a writer to the file
~/bin/gamadv-xtd3/gam user "$old_owner_email" add drivefileacl "$file_id" user "$new_owner_email" role writer

# New owner claims ownership of the file with the specified retainrole
~/bin/gamadv-xtd3/gam user "$new_owner_email" claim ownership "$file_id" retainrole "$retain_role"

# Fetch the current permissions of the file
permissions=$(~/bin/gamadv-xtd3/gam user "$new_owner_email" show drivefileacls "$file_id" | grep "$old_owner_email")

# Extract the Permission ID
permission_id=$(echo "$permissions" | grep 'id:' | awk '{print $2}')

# If old owner is not supposed to retain access and the permission exists, remove their access
if [ "$retain_access" = "no" ] && [ -n "$permission_id" ]; then
    ~/bin/gamadv-xtd3/gam user "$new_owner_email" delete drivefileacl "$file_id" "$permission_id"
else
    echo "No permissions to remove for $old_owner_email."
fi

# Find the new owner's drive's root ID
root_id=$(~/bin/gamadv-xtd3/gam user "$new_owner_email" show fileinfo root id | grep 'id:' | awk '{print $2}')

# Move the file to the new owner's drive
~/bin/gamadv-xtd3/gam user "$new_owner_email" move drivefile "$file_id" parentid "$root_id"

echo "File transfer process is complete."
