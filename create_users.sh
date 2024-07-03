#!/bin/bash

# File paths
INPUT_FILE="user_list.txt"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the log and password files exist
touch $LOG_FILE
touch $PASSWORD_FILE

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to generate a random password
generate_password() {
    < /dev/urandom tr -dc 'A-Za-z0-9' | head -c 16
}

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Check if the user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping."
        continue
    fi

    # Create groups if they do not exist
    IFS=',' read -ra group_list <<< "$groups"
    for group in "${group_list[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log_message "Group $group created."
        else
            log_message "Group $group already exists. Skipping."
        fi
    done

    # Create the user with the specified groups
    useradd -m -G "$groups" "$username"
    if [ $? -eq 0 ]; then
        log_message "User $username created and added to groups $groups."

        # Set home directory permissions
        chmod 700 /home/$username
        chown $username:$username /home/$username
        log_message "Set permissions for /home/$username."

        # Generate and set a password
        password=$(generate_password)
        echo "$username:$password" | chpasswd
        log_message "Password set for user $username."

        # Store the password securely
        echo "$username:$password" >> $PASSWORD_FILE
    else
        log_message "Failed to create user $username."
    fi
done < "$INPUT_FILE"

log_message "User creation process completed."

# Ensure the password file is readable only by root
chmod 600 $PASSWORD_FILE
chown root:root $PASSWORD_FILE

log_message "Password file permissions set."

exit 0
