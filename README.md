README for Kiosk System Setup Script
Overview

This script configures a Linux system to run as a kiosk. It sets up an automatic login for the kiosk user, starts the X server, and launches Chromium in kiosk mode to display a predefined web page. The system also disables the GRUB boot menu and boots directly into the kiosk interface.
Prerequisites

    A fresh installation of a Debian-based Linux distribution (e.g., Ubuntu).
    A user account named kiosk (ensure this user exists before running the script).
    sudo or root privileges to run administrative commands.

What the Script Does

    Remove CD-ROM as APT Source: It comments out lines in /etc/apt/sources.list that reference cdrom:, so package updates do not try to access the CD-ROM.

    Update the System: The script updates the APT package list to ensure the system is up-to-date.

    Install Necessary Packages: It installs the following essential packages:
        xorg: The X Window System.
        xinit: A utility for starting the X server.
        chromium: The Chromium browser for kiosk mode.

    Create Systemd Service Override for Getty Service: The script creates a custom systemd service configuration to enable automatic login for the kiosk user at the first terminal (tty1).

    Configure Autologin for the kiosk User: It modifies the systemd service configuration to allow the kiosk user to log in automatically without a password.

    Configure X11 to Start Chromium in Kiosk Mode: The script adds the startx command to the .bashrc file of the kiosk user, ensuring the X server starts upon login. It also creates a custom .xinitrc file to configure the screen resolution and launch Chromium in full-screen kiosk mode.

    Update the GRUB Configuration: It disables the GRUB boot menu timeout by setting GRUB_TIMEOUT=0, ensuring the system boots directly to the kiosk interface.

    Update GRUB: The script runs update-grub to apply the new GRUB settings.

    Reboot the System: The system is rebooted automatically, and upon restart, the kiosk setup will be active.

How to Use the Script
Step 1: Remove the CD-ROM as an APT Source

To prevent the system from attempting to access the CD-ROM during package updates, comment out the lines in /etc/apt/sources.list that reference the CD-ROM:

    Option 1: Run the following command:

sed -i '/cdrom:/s/^/#/' /etc/apt/sources.list

Option 2: Alternatively, manually edit the file with nano:

    nano /etc/apt/sources.list

    Then, place a # at the start of any lines that include cdrom:.

Step 2: Install wget

Ensure that wget is installed, as it is required to download the script:

apt install wget

Step 3: Download the Script

Download the kiosk setup script using wget:

wget https://raw.githubusercontent.com/NathanLouth/DebianKiosk/refs/heads/main/install.sh

Step 4: Make the Script Executable

Change the script's permissions to make it executable:

chmod +x install.sh

Step 5: Run the Script

Execute the script with sudo to start the kiosk setup process:

sudo ./install.sh

The script will complete the setup, automatically logging in as the kiosk user, starting the X server, and launching Chromium in kiosk mode. Once the script finishes, the system will reboot. After the reboot, the kiosk interface will start automatically.
Troubleshooting

    Chromium Not Launching: If Chromium does not launch, ensure that the kiosk user has the appropriate permissions and that xinit and Chromium are properly installed.
    Screen Resolution Issues: If the screen resolution does not appear correctly, modify the xrandr settings in the .xinitrc file.
    Autologin Not Working: Verify that the getty@tty1.service.d/override.conf file is created correctly and that the kiosk user is configured to log in automatically.

Additional Customizations

    To change the web page Chromium displays, modify the URL in the .xinitrc file.
    Adjust the screen resolution or other display settings by modifying the xrandr command in the .xinitrc file.
    To customize the behavior of autologin, you can modify the systemd service configuration at /etc/systemd/system/getty@tty1.service.d/override.conf.

License

This script is provided as-is and can be freely used and modified. No warranty or guarantee is provided.
