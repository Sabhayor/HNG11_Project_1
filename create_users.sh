#!/bin/bash

# Script: create_users.sh
# Description: Creates users and groups based on input file, sets up home directories,
#              generates random passwords, and logs all actions.
# Usage: sudo ./create_users.sh <input_file>

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure log file and password file exist and have correct permissions
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12
}

# Read input file line by line
while IFS=';' read -r username groups
do
    # Skip empty lines
    [ -z "$username" ] && continue

    # Create user if it doesn't exist
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        log_message "Created user: $username"
    else
        log_message "User already exists: $username"
    fi

    # Generate and set password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    echo "$username:$password" >> "$PASSWORD_FILE"
    log_message "Set password for user: $username"

    # Create groups and add user to groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log_message "Created group: $group"
        fi
        usermod -aG "$group" "$username"
        log_message "Added user $username to group: $group"
    done

    # Set appropriate permissions for home directory
    home_dir="/home/$username"
    chown "$username:$username" "$home_dir"
    chmod 700 "$home_dir"
    log_message "Set permissions for $home_dir"

done < "$INPUT_FILE"

echo "User creation process completed. Check $LOG_FILE for details."