#!/bin/bash

# Default browser, audio setting & screen tearing fix
BROWSER="chromium"
BROWSER_FLAGS=""
URL=" https://example.com"
CARD="0"
DEVICE="0"
SCREEN_TEARING=""
SCREEN_RESOLUTION="1920x1080"
STARTXCMD="startx"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --card)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: CARD must be a number" >&2
                exit 1
            fi
            CARD="$2"
            shift 2
            ;;
            
        --device)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: DEVICE must be a number" >&2
                exit 1
            fi
            DEVICE="$2"
            shift 2
            ;;
            
        --browser)
            if [[ ! "$2" =~ ^(chrome|chromium)$ ]]; then
                echo "Invalid browser specified. Must be either 'chrome' or 'chromium'" >&2
                exit 1
            fi
            # Set google-chrome-stable for chrome option
            if [[ "$2" == "chrome" ]]; then
                BROWSER="google-chrome-stable"
            else
                BROWSER="$2"
            fi
            shift 2
            ;;
            
        --url)
            URL=" $2"
            shift 2
            ;;
     
        --screen)
            if ! [[ "$2" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]]; then
                echo "Error: SCREEN must be a screen resolution eg 1920x1080" >&2
                exit 1
            fi
            SCREEN_RESOLUTION="$2"
            shift 2
            ;;
            
        --no-url)
            URL=""
            shift
            ;;
            
        --incognito)
            BROWSER_FLAGS="$BROWSER_FLAGS --incognito"
            shift
            ;;
        
        --kiosk)
            BROWSER_FLAGS="$BROWSER_FLAGS --kiosk"
            shift
            ;;

        --no-cursor)
            STARTXCMD="startx -- -nocursor"
            shift
            ;;

        --TearFree)
            SCREEN_TEARING=" --set TearFree on"
            shift
            ;;
            
        *)
            echo "Usage: $0 [--card X] [--device X] [--screen X] [--browser X] [--url X] [--nourl] [--incognito] [--kiosk] [--no-cursor] [--TearFree]" >&2
            exit 1
            ;;
    esac
done

# Comment out lines in /etc/apt/sources.list that include "cdrom:"
sed -i '/cdrom:/s/^[^#]/#/' /etc/apt/sources.list

# Update the system
apt update -y

case $BROWSER in
    google-chrome-stable)
        # Install necessary packages (chrome)
        apt install -y xorg xinit alsa-utils software-properties-common apt-transport-https ca-certificates curl
        
        # Import the Google Chrome GPG Key
        curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >> /dev/null
        
        # Add the Google Chrome Repository
        echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | tee /etc/apt/sources.list.d/google-chrome.list
        
        # Update the system
        apt update -y
        
        # Install google-chrome-stable
        apt install -y google-chrome-stable
        ;;
    chromium)
        # Install necessary packages (chromium)
        apt install -y xorg xinit chromium alsa-utils
        ;;
esac

# Create the directory for the systemd service override
mkdir -p /etc/systemd/system/getty@tty1.service.d/

# Create the override.conf file
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I \$TERM
EOL

# Create the .kioskstartx file
cat > /home/kiosk/.kioskstartx <<EOL
#!/bin/bash
clear
sleep 5
$STARTXCMD
EOL

# Make .xinitrc owned by the kiosk user and executable
chown kiosk:kiosk /home/kiosk/.kioskstartx
chmod +x /home/kiosk/.kioskstartx

# Add ".kioskstartx file to bashrc (if not already)
grep -qxF "source /home/kiosk/.kioskstartx" /home/kiosk/.bashrc || echo "source /home/kiosk/.kioskstartx" >> /home/kiosk/.bashrc

# Create the .xinitrc file for the kiosk user
cat > /home/kiosk/.xinitrc <<EOL
#!/bin/bash

sleep 3

xrandr --output \$(xrandr | grep " connected " | awk '{ print\$1 }' | head -n 1) --mode $SCREEN_RESOLUTION$SCREEN_TEARING

xset s off
xset -dpms
xset s noblank

sleep 2

amixer -c $CARD sset Master 100%

SCREEN_RESOLUTION=\$(xrandr | grep '*' | awk '{print \$1}')

WIDTH=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 1)
HEIGHT=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 2)

$BROWSER$BROWSER_FLAGS --window-position=0,0 --window-size=\$WIDTH,\$HEIGHT$URL

while pgrep -x "$BROWSER" > /dev/null; do
    sleep 10
done

systemctl reboot
EOL

# Make asound.conf for audio settings
cat > /etc/asound.conf <<EOL
defaults.pcm.card $CARD
defaults.pcm.device $DEVICE
EOL

# Make .xinitrc owned by the kiosk user and executable
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# Update GRUB configuration
sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' /etc/default/grub
update-grub

# Reboot system
reboot
