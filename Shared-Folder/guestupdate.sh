#!/bin/bash
# Fetch VirtualBox Guest Additions version from latest.txt
echo "installeren van curl"
echo 'osboxes.org' | sudo -S apt install curl -y
VBOX_VERSION=$(curl -sSL https://download.virtualbox.org/virtualbox/LATEST.TXT)

# Get the currently installed version, if any
INSTALLED_VERSION=$(VBoxClient --version 2>/dev/null || echo "Not installed" | awk '{print $1}' | cut -d 'r' -f 1)
echo "Installed version: $INSTALLED_VERSION"
echo "Latest version: $VBOX_VERSION"
# Compare the current installed version with the latest available version
if [ "$VBOX_VERSION" != "$INSTALLED_VERSION" ]; then
    # Update package list and install dependencies
    echo 'osboxes.org' | sudo -S apt update
    echo 'osboxes.org' | sudo -S apt install -y libxt6 libxmu6 wget build-essential dkms linux-headers-$(uname -r) wget

    # Create a temporary directory for downloading and mounting the Guest Additions ISO
    tmp_dir=$(mktemp -d)

    # Download VirtualBox Guest Additions ISO
    wget -P $tmp_dir https://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
    # Mount the ISO
    echo 'osboxes.org' | sudo -S mount -o loop $tmp_dir/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt

    echo "-------------Removing old version of VirtualBox Guest Additions if applicable-----------------------------------"
    echo 'osboxes.org' | sudo -S sh /mnt/VBoxLinuxAdditions.run uninstall
    
    # Run the installer script with automatic "yes" responses to prompts
    echo "--------Installing the new version of VirtualBox Guest Additions-------------------"
    yes | sudo -S /mnt/VBoxLinuxAdditions.run
    
    # Clean up
    echo 'osboxes.org' | sudo -S  umount /mnt
    rm -rf $tmp_dir
    echo "-----Updated to version: $VBOX_VERSION-----------"
    echo "-----VirtualBox Guest Additions installed successfully.-----"
    echo "--------------Restarting the server...---------------------"
    echo 'osboxes.org' | sudo -S reboot
else
    echo "-------------------------The latest version of VirtualBox Guest Additions ${VBOX_VERSION} is already installed.------------------------------------"
fi
