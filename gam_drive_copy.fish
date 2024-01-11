#!/usr/bin/env fish

echo "Starting the Google Drive transfer process..."

# Ask for the old and new owner's email addresses
echo "Enter the email address of the old owner: "
read old_owner
echo "Enter the email address of the new owner: "
read new_owner

# Ask about the status of the old owner's account
echo "Is the old owner's account archived, suspended, or active? Enter 'archived', 'suspended', or 'active':"
read account_status

# If archived, unarchive then unsuspend
switch $account_status
    case archived
        echo "Unarchiving the old owner's account..."
        gam update user $old_owner archived off
        echo "Unsuspending the old owner..."
        gam unsuspend user $old_owner
    case suspended
        echo "Unsuspending the old owner..."
        gam unsuspend user $old_owner
end

# 2. Create folder in new owner's drive
echo "Creating 'Drive Copy' folder in the new owner's drive..."
set folder_creation_output (gam user $new_owner create drivefile drivefilename "Drive Copy" mimetype gfolder)
set folder_id (echo $folder_creation_output | awk -F'[()]' '{print $2}')

if test -z "$folder_id"
    echo "Failed to create folder or extract folder ID."
    exit 1
end

# 3. Add old owner as editor of the Drive Copy folder
echo "Adding old owner as an editor of 'Drive Copy' folder..."
gam user $new_owner add drivefileacl $folder_id user $old_owner role writer

# 4. Find root id of old owner's Drive
echo "Finding root ID of the old owner's Drive..."
set old_root_id (gam user $old_owner show fileinfo root id | awk '/id:/{print $2}')

if test -z "$old_root_id"
    echo "Failed to find the root ID of the old owner's Drive."
    exit 1
end

# 5. Copy old owner's drive to new owner's Drive Copy folder
echo "Copying old owner's Drive to the new owner's 'Drive Copy' folder..."
gam user $old_owner copy drivefile $old_root_id parentid $folder_id recursive depth -1

# 6. Transfer ownership of copied files
echo "Transferring ownership of copied files to the new owner..."
gam user $old_owner transfer ownership $folder_id $new_owner

# 7. Remove old owner's access to all copied data in the 'Drive Copy' folder
echo "Removing old owner's access to all copied data in the 'Drive Copy' folder..."
gam user $new_owner print filelist select id $folder_id fields id | gam csv - gam user "~Owner" delete drivefileacl "~id" $old_owner

# Suspend and archive old owner after completion if the account was archived initially
switch $account_status
    case archived
        echo "Suspending the old owner again..."
        gam suspend user $old_owner
        echo "Archiving the old owner's account..."
        gam update user $old_owner archived on
    case suspended
        echo "Suspending the old owner again..."
        gam suspend user $old_owner
end

echo "Google Drive transfer process completed!"
