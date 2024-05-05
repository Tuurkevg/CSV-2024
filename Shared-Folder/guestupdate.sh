#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
# Fetch VirtualBox Guest Additions version from latest.txt
echo 'osboxes.org' | sudo -S apt update -y &>/dev/null
echo 'osboxes.org' | sudo -S apt install curl -y &>/dev/null


VBOX_VERSION=$(curl -sSL https://download.virtualbox.org/virtualbox/LATEST.TXT)

# Get the currently installed version, if any
INSTALLED_VERSION=$(VBoxClient --version 2>/dev/null || echo "Not installed")
echo "Installed version: ${INSTALLED_VERSION%%r*}"
echo "Latest version: ${VBOX_VERSION}"
# Compare the current installed version with the latest available version
if [ "${VBOX_VERSION}" != "${INSTALLED_VERSION%%r*}" ]; then
    # Update package list and install dependencies
    echo 'osboxes.org' | sudo -S DEBIAN_FRONTEND=noninteractive apt purge virtualbox-guest-utils virtualbox-guest-x11 -y &>/dev/null
    echo 'osboxes.org' | sudo -S DEBIAN_FRONTEND=noninteractive apt autoremove -y &>/dev/null
    echo 'osboxes.org' | sudo -S DEBIAN_FRONTEND=noninteractive apt update -y &>/dev/null
    echo 'osboxes.org' | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y libxt6 libxmu6 wget build-essential dkms linux-headers-$(uname -r) wget &>/dev/null
    echo 'osboxes.org' | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y libxt6 libxmu6 wget build-essential dkms wget &>/dev/null
    # Create a temporary directory for downloading and mounting the Guest Additions ISO
    tmp_dir=$(mktemp -d)

    # Download VirtualBox Guest Additions ISO
    wget -P $tmp_dir https://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
    # Mount the ISO
    echo 'osboxes.org' | sudo -S mount -o loop $tmp_dir/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt

    echo "-------------Remosboxudo -S sh /mnt/VBoxLinuxAdditions.run uninstall"
    
    # Run the installer script with automatic "yes" responses to prompts
    echo "--------Installing the new version of VirtualBox Guest Additions-------------------"
    yes | sudo -S /mnt/VBoxLinuxAdditions.run   
    
    # Clean up
    echo 'osboxes.org' | sudo -S  umount /mnt
    rm -rf $tmp_dir
    echo "-----Updated to version: $VBOX_VERSION-----------"
    echo "-----VirtualBox Guest Additions installed successfully.-----"
    echo "--------------Restarting the server...---------------------"
    echo "klaar"
    echo 'osboxes.org' | sudo -S reboot
else
    echo "-------------------------The latest version of VirtualBox Guest Additions ${VBOX_VERSION} is already installed.------------------------------------"
    echo "klaar"
fi
