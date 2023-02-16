#!/bin/bash

# Check if user is root
if [ $(id -u) -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Install required packages
apt update
apt install -y libpam-google-authenticator qrencode

# Enable TOTP for SSH login
echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sshd
sed -i '/ChallengeResponseAuthentication/s/ no/ yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable TOTP for su and sudo
echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/su
echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sudo

# Prompt users to set up TOTP
echo "Setting up TOTP for your account..."

# Generate TOTP secret key and show QR code
google-authenticator -t -d -f -r 3 -R 30 -q "OTP for Server login"
qrencode -t UTF8 < ~/.google_authenticator

# Prompt user for TOTP code
read -p "Enter TOTP code: " code

# Verify TOTP code
if google-authenticator -t -d -f -r 3 -R 30 "$code"; then
    echo "Authentication successful."
else
    echo "Invalid TOTP code. Please enter your backup code or try again later."
    read -p "Enter backup code: " backup_code
    if google-authenticator -t -d -f -r 3 -R 30 -b "$backup_code"; then
        echo "Authentication successful with backup code."
    else
        echo "Invalid backup code. Please try again later."
    fi
fi
