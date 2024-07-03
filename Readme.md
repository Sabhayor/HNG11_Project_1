### Usage Instructions

1. **Prepare the Input File**: Create a file named `user_list.txt` with each line containing a username and groups in the format `user;group1,group2,...`.
   Example:
   ```
   alice;staff,developers
   bob;admin,staff
   ```

2. **Run the Script**: Execute the script with superuser privileges:
   ```bash
   sudo ./create_users.sh
   ```

### Script Breakdown

- **Logging**: All actions are logged to `/var/log/user_management.log` using the `log_message` function.
- **Password Generation**: Passwords are randomly generated using `/dev/urandom`.
- **User and Group Creation**: The script checks if users or groups already exist and creates them if they don't.
- **Home Directory Setup**: Home directories are created with `useradd`, and permissions are set to `700`.
- **Password Management**: Passwords are set and stored in `/var/secure/user_passwords.txt` with strict permissions.

Ensure the script is executable:
```bash
chmod +x create_users.sh
```

Make sure the necessary directories and permissions exist for `/var/log` and `/var/secure`.