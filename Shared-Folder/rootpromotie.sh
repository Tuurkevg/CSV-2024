#!/bin/bash



# Function to change root password and modify SSH configuration
change_root_password_and_modify_ssh_config() {
    # Change root password
    echo "root:osboxes.org" | sudo -S chpasswd
    echo "Root password changed to: osboxes.org"

    # Enable root login by modifying sshd_config
    echo "PermitRootLogin yes" | sudo -S tee -a /etc/ssh/sshd_config > /dev/null

    # Restart SSH service to apply changes
   echo 'osboxes.org' | sudo -S systemctl restart ssh
    echo "Root login enabled."
}

# Function to grant root privileges to osboxes user
grant_root_privileges() {
    # Add osboxes to sudo group
   echo 'osboxes.org' | echo sudo -S usermod -aG sudo osboxes
   echo "---------------osboxes added to sudo group.-------------------"

    # Grant NOPASSWD sudo privileges for specific commands
   echo 'osboxes.org' | sudo -S bash -c 'echo "osboxes ALL=(ALL) NOPASSWD: /usr/sbin/chpasswd" > /etc/sudoers.d/osboxes'
    echo 'osboxes.org' | sudo -S bash -c 'echo "osboxes ALL=(ALL) NOPASSWD: /bin/tee -a /etc/ssh/sshd_config" >> /etc/sudoers.d/osboxes'
    echo 'osboxes.org' | sudo -S bash -c 'echo "osboxes ALL=(ALL) NOPASSWD: /bin/systemctl restart sshd" >> /etc/sudoers.d/osboxes'
    echo 'osboxes.org' | sudo -S bash -c 'echo "osboxes ALL=(ALL) NOPASSWD: /bin/chmod, /bin/chown" >> /etc/sudoers.d/osboxes'
    echo "---------------------NOPASSWD sudo privileges granted for osboxes.--------------------"
}

# Execute function to change root password and modify SSH configuration
change_root_password_and_modify_ssh_config

# Execute function to grant root privileges to osboxes user
grant_root_privileges
