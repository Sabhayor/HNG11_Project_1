#!/bin/bash

# Check if the input file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure log file and password file have the correct permissions
sudo touch "$LOG_FILE"
sudo touch "$PASSWORD_FILE"
sudo chmod 600 "$LOG_FILE"
sudo chmod 600 "$PASSWORD_FILE"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found!" | sudo tee -a "$LOG_FILE"
  exit 1
fi

# Function to generate a random password
generate_password() {
  tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?' </dev/urandom | head -c 16
}

# Read the input file line by line
while IFS=';' read -r username groups; do
  # Check if the username is empty
  if [ -z "$username" ]; then
    echo "Error: Username is empty in the line '$username;$groups'" | sudo tee -a "$LOG_FILE"
    continue
  fi
  
  # Create the user if not exists
  if id "$username" &>/dev/null; then
    echo "User '$username' already exists" | sudo tee -a "$LOG_FILE"
  else
    password=$(generate_password)
    sudo useradd -m -s /bin/bash "$username"
    echo "$username:$password" | sudo chpasswd
    echo "User '$username' created with home directory and default shell" | sudo tee -a "$LOG_FILE"
    echo "$username:$password" | sudo tee -a "$PASSWORD_FILE"
    
    # Set permissions for the user's home directory
    sudo chmod 700 "/home/$username"
    sudo chown "$username:$username" "/home/$username"
    echo "Set permissions for /home/$username" | sudo tee -a "$LOG_FILE"
  fi

  # Add the user to the specified groups
  if [ -n "$groups" ]; then
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
      if getent group "$group" &>/dev/null; then
        sudo usermod -aG "$group" "$username"
        echo "User '$username' added to group '$group'" | sudo tee -a "$LOG_FILE"
      else
        sudo groupadd "$group"
        sudo usermod -aG "$group" "$username"
        echo "Group '$group' created and user '$username' added to it" | sudo tee -a "$LOG_FILE"
      fi
    done
  fi
done < "$INPUT_FILE"

echo "User creation and group assignment completed" | sudo tee -a "$LOG_FILE"
