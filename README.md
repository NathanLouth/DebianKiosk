# Kiosk System Setup Script

## Overview
This script configures a Linux system to run as a kiosk. It sets up an automatic login for the kiosk user, starts the X server, and launches Chromium in kiosk mode to display a predefined web page. The system also disables the GRUB boot menu and boots directly into the kiosk interface.

## Prerequisites
- A fresh installation of Debian Linux with no GUI installed.
- A user account named kiosk (ensure this user exists before running the script).
- root privileges to run administrative commands.

## What the Script Does
1. **Remove CD-ROM as APT Source:**
   It comments out lines in /etc/apt/sources.list that reference cdrom:, so package updates do not try to access the CD-ROM.

2. **Update the System:**
   The script updates the APT package list to ensure the system is up-to-date.

3. **Install Necessary Packages:**
   It installs the following essential packages:
   - xorg: The X Window System.
   - xinit: A utility for starting the X server.
   - chromium: The Chromium browser for kiosk mode.
   - alsa-utils: Audio utilities including amixer for volume control.

4. **Create Systemd Service Override for Getty Service:**
   The script creates a custom systemd service configuration to enable automatic login for the kiosk user at the first terminal (tty1).

5. **Configure Autologin for the kiosk User:**
   It modifies the systemd service configuration to allow the kiosk user to log in automatically without a password.

6. **Configure X11 to Start Chromium in Kiosk Mode:**
   The script adds the startx command to the .bashrc file of the kiosk user, ensuring the X server starts upon login. It also creates a custom .xinitrc file to configure:
   - Screen resolution
   - Launch Chromium in full-screen kiosk mode
   - Set system volume to maximum using amixer

7. **Update the GRUB Configuration:**
   It disables the GRUB boot menu timeout by setting GRUB_TIMEOUT=0, ensuring the system boots directly to the kiosk interface.

8. **Update GRUB:**
   The script runs update-grub to apply the new GRUB settings.

9. **Reboot the System:**
   The system is rebooted automatically, and upon restart, the kiosk setup will be active.

## How to Use the Script

### Note: You must be logged in as the root user

### Step 1: Remove the CD-ROM as an APT Source
To prevent the system from attempting to access the CD-ROM during package updates, comment out the lines in /etc/apt/sources.list that reference the CD-ROM:

```bash
sed -i '/cdrom:/s/^/#/' /etc/apt/sources.list
```

Alternatively, manually edit the file with nano:

```bash
nano /etc/apt/sources.list
```

Then, place a # at the start of any lines that include cdrom:.

### Step 2: Install wget

Ensure that wget is installed, as it is required to download the script:

```bash
apt install wget
```

### Step 3: Download the Script

Download the kiosk setup script using wget:

```bash
wget https://raw.githubusercontent.com/NathanLouth/DebianKiosk/refs/heads/main/install.sh
```

### Step 4: Make the Script Executable

Change the script's permissions to make it executable:

```bash
chmod +x install.sh
```

### Step 5: Run the Script

Execute the script with sudo to start the kiosk setup process:

```bash
./install.sh
```

The script will complete the setup, automatically logging in as the kiosk user, starting the X server, and launching Chromium in kiosk mode. Once the script finishes, the system will reboot. After the reboot, the kiosk interface will start automatically.

## Troubleshooting

### Startx Error
If startx fails to launch, try running the script again. This will reinstall the necessary packages.

### Chromium Not Launching
If Chromium does not launch, ensure that the kiosk user has the appropriate permissions and that xinit and Chromium are properly installed.

### Screen Resolution Issues
If the screen resolution does not appear correctly, modify the xrandr settings in the .xinitrc file (/home/kiosk/.xinitrc).

### Autologin Not Working
Verify that the getty@tty1.service.d/override.conf file is created correctly and that the kiosk user is configured to log in automatically.

### Audio Issues
If audio is not working in Chromium:
1. First, identify available sound cards:
   ```bash
   aplay -l
   ```
   
2. Modify /home/kiosk/.xinitrc file to specify the correct audio device before launching Chromium:
   ```bash
   mixer -c 1 sset Master 100%
   
   AUDIODEV=hw:1.0 chromium --no-sandbox --kiosk --window-position=0,0 --window-size=$WIDTH,$HEIGHT "https://example.com"
   ```
   Replace "hw:1.0" & "-c 1" with your actual sound card identifier from step 1.

## Additional Customizations

* To change the web page Chromium displays, modify the URL in the .xinitrc file (/home/kiosk/.xinitrc).
* Adjust the screen resolution or other display settings by modifying the xrandr command in the .xinitrc file (/home/kiosk/.xinitrc).
* To customize the behavior of autologin, you can modify the systemd service configuration at /etc/systemd/system/getty@tty1.service.d/override.conf.
* To adjust the system volume, modify the amixer command in the .xinitrc file. The current setting uses card 0 (first sound card) and sets the master channel to 100%:

```bash
amixer -c 0 sset Master 100%
```

You can change the card number (-c 0) or volume percentage (100%) as needed.

## License
MIT License

This script is provided as-is and can be freely used and modified. No warranty or guarantee is provided.
