README for Kiosk System Setup Script
Overview

This script sets up a simple kiosk environment on a Linux system. It configures the system to automatically log in as the kiosk user, start the X server, and launch Chromium in kiosk mode to display a predefined web page. The system is configured to bypass the GRUB boot timeout and to automatically launch the kiosk interface after booting.
Prerequisites

    A fresh installation of a Debian-based Linux distribution (such as Ubuntu).
    A user account named kiosk (ensure the user exists before running the script).
    sudo or root privileges to run administrative commands.

What the Script Does

    Comment Out CD-ROM Lines in /etc/apt/sources.list:
    It ensures that any lines referencing cdrom: in the APT sources list are commented out, so package updates do not try to access the CD-ROM.

    Update the System:
    The script updates the package lists to ensure the system is up-to-date.

    Install Necessary Packages:
    It installs essential packages for the kiosk setup, including:
        xorg: The X Window System.
        xinit: A utility for starting the X server.
        chromium: The Chromium browser for kiosk use.

    Create Systemd Service Override for Getty Service:
    The script creates a custom systemd service configuration for the getty@tty1 service, enabling automatic login for the kiosk user at the first terminal (tty1).

    Configure Autologin for the kiosk User:
    It edits the systemd service configuration to allow the kiosk user to automatically log in without requiring a password.

    Configure X11 to Start Chromium in Kiosk Mode:
    It adds the startx command to the .bashrc file of the kiosk user, ensuring the X server starts upon login. It also creates a custom .xinitrc file, which configures the screen resolution and launches Chromium in full-screen kiosk mode.

    Update the GRUB Configuration:
    The script disables the GRUB boot menu timeout by setting GRUB_TIMEOUT=0, ensuring the system boots directly to the kiosk interface.

    Update GRUB Configuration:
    It runs update-grub to apply the new GRUB settings.

    Reboot the System:
    Finally, the system is rebooted, and upon restart, the kiosk setup should be active.

How to Use the Script
Step 1: Remove the CD-ROM as an APT Source

To ensure the system doesn't attempt to access the CD-ROM during package updates, comment out the lines that reference the CD-ROM:

    Option 1: Run the following command:

sed -i '/cdrom:/s/^/#/' /etc/apt/sources.list

Option 2: Alternatively, you can manually edit the file using nano:

    nano /etc/apt/sources.list

    Then, put a # at the start of the lines that include cdrom:.

Step 2: Install wget

Install wget to be able to download the script:

apt install wget

Step 3: Download the Script

Download the kiosk setup script using wget:

wget https://raw.githubusercontent.com/NathanLouth/DebianKiosk/refs/heads/main/install.sh

Step 4: Make the Script Executable

Change the script permissions to make it executable:

chmod +x install.sh

Step 5: Run the Script

Execute the script with sudo to start the kiosk setup process:

sudo ./install.sh

The script will automatically complete the setup, including logging in as the kiosk user, configuring the kiosk mode, and rebooting the system. Upon restart, the system will boot directly into the kiosk interface.

Troubleshooting

    Chromium Not Launching: Ensure the kiosk user has access to the necessary files and that the xinit and Chromium commands are installed correctly.
    Screen Resolution Issues: If the screen resolution does not display correctly, adjust the xrandr settings in the .xinitrc file.
    Autologin Not Working: Ensure the getty@tty1.service.d/override.conf file was created successfully and the kiosk user is configured correctly in the systemd service.

Additional Customizations

    You can change the web page that Chromium loads by modifying the URL in the .xinitrc file.
    If you want a different screen resolution or settings for the kiosk, modify the xrandr line in the .xinitrc file.
    To modify the behavior of the autologin feature, you can adjust the systemd service configuration at /etc/systemd/system/getty@tty1.service.d/override.conf.

License

This script is provided as-is and can be freely used and modified. No warranty or guarantee is provided.
chmod +x ./install.sh

Run script:
./install.sh
