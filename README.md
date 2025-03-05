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
   - adds "sleep 5" before startx (fixes xorg crashing)

7. **Display Settings Configuration**
   - Disables screen saver and blanking with `xset s off` and `xset s noblank`
   - Prevents DPMS (Energy Star) features with `xset -dpms`
   - These settings ensure continuous operation without display interruptions

8. **Audio Configuration**
   - Creates `/etc/asound.conf` for consistent audio device setup
   - Ensures reliable audio functionality across reboots

9. **Fixes Screen Tearing on Intel Graphics:**
   Sets Xorg option TearFree for Intel Graphics

10. **Update the GRUB Configuration:**
    It disables the GRUB boot menu timeout by setting GRUB_TIMEOUT=0, ensuring the system boots directly to the kiosk interface.

11. **Update GRUB:**
    The script runs update-grub to apply the new GRUB settings.

12. **Reboot the System:**
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

## Command-Line Arguments

The script supports the following optional command-line arguments for customizing the kiosk setup:

    --card X
        Set the audio card number. The value of X should be a number. (default is 0)

    --device X
        Set the audio device number. The value of X should be a number. (default is 0)

    --browser X
        Specify which browser to use. Valid options are:
            chrome (will install Google Chrome)
            chromium (will install Chromium) (default option)
    
    --screen
        Set the screen resolution e.g 1920x1080 (default is 1920x1080)
            
    --url
        Specify the URL to display in kiosk mode. Encloses the URL in quotes.

    --no-url
        Don't use default url of https://example.com and open on the chrome(ium) new tab page

    --incognito
        launch browser using incognito mode
        
    --kiosk
        launch browser in kiosk mode (hides url bar)

    --no-cursor
        Hides the mouse cursor 

    --amd-st
        Apply screen tearing fix for AMD GPU

    --intel-st
        Apply screen tearing fix for Intel GPU
        

## Example Usage

Default setup:

```bash
./install.sh
```

Set custom audio card and device:

```bash
./install.sh --card 1 --device 0
```

Choose Chrome as the browser:

```bash
./install.sh --browser chrome
```

Set both a custom audio card and browser to Chromium:

```bash
./install.sh --card 1 --device 0 --browser chromium
```

Set specific screen resolution:

```bash
./install.sh --screen 3840x2160
```

Launch Chrome in kiosk mode with incognito and custom URL:

```bash
./install.sh --browser chrome --kiosk --incognito --url "https://example.org"
```

Configure AMD GPU with screen tearing fix:

```bash
./install.sh --browser chrome --amd-st --kiosk --screen 1920x1080
```

Minimal setup without default URL & hidden cursor:

```bash
./install.sh --nourl --no-cursor
```

## Troubleshooting

### Startx Error
If startx fails to launch, try running the script again. This will reinstall the necessary packages.

### Chromium Not Launching
If Chromium does not launch, ensure that the kiosk user has the appropriate permissions and that xinit and Chromium are properly installed.

### Screen Resolution Issues
If the screen resolution does not appear correctly, modify the xrandr settings in the .xinitrc file (/home/kiosk/.xinitrc).

### Autologin Not Working
Verify that the getty@tty1.service.d/override.conf file is created correctly and that the kiosk user is configured to log in automatically.

### Audio Problems
If audio isn't working:

1. Get audio device(s) info:
   ```bash
   aplay -l
   ```
2. Verify ALSA configuration in `/etc/asound.conf` edit card and device numbers as needed.
   
3. Check volume levels:
   ```bash
   amixer -c 0 sset Master unmute
   ```
### Screen Tearing
If you are having screen tearing issues create file `/etc/X11/xorg.conf.d/20-intel.conf` and add the following contents:

for Intel GPUs use:
```bash
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
```

For AMD GPUs use:
```bash
Section "Device"
  Identifier "AMD Graphics"
  Driver "amdgpu"
  Option "TearFree" "true"
EndSection
```

## Additional Customizations

### Note: To drop to a terminal session press `Ctrl+Alt+F2`

* To change the web page Chromium displays, modify the URL in the .xinitrc file (/home/kiosk/.xinitrc). By default the page is set to `https://example.com`

* To make Chromium open using incognito mode or show the url bar you can edit the following chromium flags in the .xinitrc file (/home/kiosk/.xinitrc):
  `--kiosk`
  `--incognito`
  
* Adjust the screen resolution or other display settings by modifying the xrandr command in the .xinitrc file (/home/kiosk/.xinitrc).
  
* To customize the behavior of autologin, you can modify the systemd service configuration at /etc/systemd/system/getty@tty1.service.d/override.conf.
  
* To set what audio output to use edit `/etc/asound.conf` you can find audio information running the command `aplay -l`
  
* To adjust the system volume, modify the amixer command in the .xinitrc file. The current setting uses card 0 (first sound card) and sets the master channel to 100%.

```bash
amixer -c 0 sset Master 100%
```

* To hide the mouse edit `/home/kiosk/.bashrc` change `startx` to `startx -- -nocursor`

## License
MIT License

This script is provided as-is and can be freely used and modified. No warranty or guarantee is provided.
