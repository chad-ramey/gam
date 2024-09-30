# GAM Lab 
## Google Workspace GAM Scripts

This repository contains a collection of shell scripts designed to automate various tasks using [GAMADV-XTD3](https://github.com/taers232c/GAMADV-XTD3), a command-line tool for managing Google Workspace.

## Table of Contents
  - [Scripts Overview](#scripts-overview)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Contributing](#contributing)
  - [License](#license)

## Scripts Overview

### 1. [gam_cal_wipe.sh](gam_cal_wipe.sh)
**Description**: This script removes all calendar events from a specific user's calendar using GAMADV-XTD3. It is useful when needing to wipe calendar data for offboarding or account cleanup.

### 2. [gam_drive_copy.sh](gam_drive_copy.sh)
**Description**: This script copies all files from one Google Drive user to another, retaining the folder structure. It ensures that the data is transferred correctly to the new owner while retaining file and folder permissions.

### 3. [gam_drive_file_folder_copy.sh](gam_drive_file_folder_copy.sh)
**Description**: A more advanced script for transferring Google Drive content between users. It:
- Checks if a folder named after the old owner exists in the new owner's Drive.
- Reuses the folder or creates a new one.
- Copies the files and transfers ownership.
- Removes old owner access after the transfer is complete.

### 4. [gam_drive_file_transfer.sh](gam_drive_file_transfer.sh)
**Description**: This script transfers ownership of specific files from one Google Drive user to another. It ensures that the new owner has full control over the files, and it can be used for bulk file transfers during offboarding.

### 5. [gam_drive_folder_file_transfer.sh](gam_drive_folder_file_transfer.sh)
**Description**: This script transfers both folders and files from one user to another. It:
- Recursively checks folder permissions.
- Adds the new owner as an editor, then claims ownership.
- Removes the old owner from the permissions list.

### 6. [update-gam7.sh](update-gam7.sh)
**Description**: This script checks if a new version of GAM is available and updates it. Useful for automating the update process for GAM version 7.

### 7. [update-gamadv-xtd3.sh](update-gamadv-xtd3.sh)
**Description**: Similar to the `update-gam7.sh` script, this checks if a new version of GAMADV-XTD3 is available on GitHub and updates it if necessary.

## Requirements
- **GAMADV-XTD3**: You need to have [GAMADV-XTD3](https://github.com/taers232c/GAMADV-XTD3) installed and configured.
- **Google Workspace Admin Permissions**: Ensure that your service account or admin account has the necessary permissions to manage Google Workspace data.

## Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo-name/gam-scripts.git
   ```
2. Ensure you have GAMADV-XTD3 installed and the correct OAuth credentials are in place.

## Usage
1. **Calendar Wipe**:
   ```bash
   ./gam_cal_wipe.sh
   ```

2. **Drive File Copy**:
   ```bash
   ./gam_drive_copy.sh
   ```

3. **Drive File and Folder Transfer**:
   ```bash
   ./gam_drive_file_transfer.sh
   ```

4. **Update GAM**:
   ```bash
   ./update-gam7.sh
   ```

5. **Update GAMADV-XTD3**:
   ```bash
   ./update-gamadv-xtd3.sh
   ```

## Contributing
Feel free to submit issues or pull requests. Contributions are welcome to enhance the functionality or improve the automation of Google Workspace management.

## License
This project is licensed under the MIT License.
