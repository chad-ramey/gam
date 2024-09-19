#!/bin/bash

# Batch Processing Script for Handling Suspended and Archived Accounts
#
# Description:
# This script processes user accounts by unsuspending them, wiping calendar events, 
# and then optionally archiving and suspending them again. It reads email addresses 
# from a CSV file and processes the accounts in batches to avoid overloading the API.
# 
# The script asks the user whether the accounts are both suspended and archived or 
# just suspended. Based on the user's input, it will either include or skip the 
# unarchive and archive steps.
#
# Features:
# - Handles accounts in batches to avoid API rate limits
# - Supports retries for calendar wipes in case of failure
# - Logs failed calendar wipe attempts to an error log for later review
# - Offers a user prompt to handle accounts that are either only suspended or both 
#   suspended and archived
#
# Requirements:
# - GAMADV-XTD3 (GAM) must be installed and configured for the domain
# - The CSV file should contain a single column labeled "Email" with user email addresses
#
# Usage:
# 1. Place the CSV file containing the email addresses on your system.
# 2. Run this script. You will be prompted to specify whether the accounts are both
#    suspended and archived.
# 3. The script will process the accounts in batches and handle errors gracefully.
#
# CSV Format Example (Email.csv):
# Email
# user1@domain.com
# user2@domain.com
#
# Author: Chad Ramey
# Date: September 2024

# Ask the user if the accounts are both suspended and archived or just suspended
read -p "Are the accounts both suspended and archived? (y/n): " IS_ARCHIVED

# Path to the CSV file containing the emails
CSV_FILE=~/Desktop/Email.csv

# Maximum number of retries for calendar wipe
MAX_RETRIES=3

# Number of accounts to process in each batch
BATCH_SIZE=10

# Log file for errors
ERROR_LOG="error_log.txt"

# Ensure the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "CSV file not found: $CSV_FILE"
    exit 1
fi

# Read the emails from the CSV file (skip the header)
EMAILS=($(tail -n +2 "$CSV_FILE"))

# Function to process a single email
process_email() {
    EMAIL="$1"
    echo "Processing $EMAIL..."

    # If the accounts are suspended and archived, unarchive the user
    if [[ "$IS_ARCHIVED" == "y" ]]; then
        echo "Unarchiving $EMAIL..."
        gam update user "$EMAIL" archived off
    fi

    # Unsuspend the user
    echo "Unsuspending $EMAIL..."
    gam unsuspend user "$EMAIL"

    # Add a delay to allow changes to sync up
    echo "Waiting for 2 minutes to allow changes to sync..."
    sleep 120  # 2-minute delay

    # Retry logic for wiping calendar events
    RETRY_COUNT=0
    SUCCESS=false

    while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
        echo "Wiping calendar events for $EMAIL (Attempt $((RETRY_COUNT+1)))..."
        OUTPUT=$(gam user "$EMAIL" wipe events primary 2>&1)

        # Check if the wipe was successful
        if echo "$OUTPUT" | grep -q "Wipe Events from"; then
            echo "Calendar wipe successful for $EMAIL"
            SUCCESS=true
            break
        else
            echo "$OUTPUT"
            echo "Calendar wipe failed for $EMAIL. Retrying in 1 minute..."
            sleep 60  # Wait 1 minute before retrying
            RETRY_COUNT=$((RETRY_COUNT+1))
        fi
    done

    if [[ $SUCCESS = false ]]; then
        echo "Failed to wipe calendar for $EMAIL after $MAX_RETRIES attempts. Logging to error log."
        echo "$EMAIL" >> "$ERROR_LOG"
    fi

    # Suspend the user again
    echo "Suspending $EMAIL..."
    gam suspend user "$EMAIL"

    # If the accounts are suspended and archived, archive the user again
    if [[ "$IS_ARCHIVED" == "y" ]]; then
        echo "Archiving $EMAIL..."
        gam update user "$EMAIL" archived on
    fi

    echo "Process completed for $EMAIL"
    echo "--------------------------------"
}

# Batch processing
total_emails=${#EMAILS[@]}
for ((i=0; i<total_emails; i+=BATCH_SIZE)); do
    echo "Processing batch $((i / BATCH_SIZE + 1)) of $(((total_emails + BATCH_SIZE - 1) / BATCH_SIZE))..."

    # Process emails in the current batch
    for ((j=0; j<BATCH_SIZE && i+j<total_emails; j++)); do
        EMAIL="${EMAILS[i+j]}"
        process_email "$EMAIL" &
        sleep 5  # Small delay between starting each process to avoid rate limit spikes
    done

    # Wait for the current batch to complete
    wait

    echo "Batch $((i / BATCH_SIZE + 1)) completed."
    echo "Waiting 5 minutes before starting the next batch..."
    sleep 300  # Wait 5 minutes between batches to prevent API rate limiting
done

echo "All batches completed!"
