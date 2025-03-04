#!/bin/bash

# Check if argument was provided
if [ $# -eq 0 ]; then
    BROWSER="chromium"
elif [ $# -ne 1 ]; then
    echo "Usage: $0 [browser]"
    echo "Where browser is either 'chrome' or 'chromium'"
    echo "(Default: chromium)"
    exit 1
fi

# If argument was provided, validate it
if [ $# -eq 1 ]; then
    case ${1,,} in
        chrome|chromium) 
            # Set google-chrome-stable for chrome option
            if [ "$1" == "chrome" ]; then
                BROWSER="google-chrome-stable"
            else
                BROWSER=$1
            fi
            ;;
        *) 
            echo "Invalid browser specified. Must be 'chrome' or 'chromium'"
            exit 1
        ;;
    esac
fi

# Comment out lines in /etc/apt/sources.list that include "cdrom:"
sed -i '/cdrom:/s/^[^#]/#/' /etc/apt/sources.list

# Update the system
apt update -y

case $BROWSER in
    chrome)
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

# Add "clear", "sleep 5" & "startx" to the end of /home/kiosk/.bashrc if it isn't already
grep -qxF "startx" /home/kiosk/.bashrc || echo "clear" >> /home/kiosk/.bashrc
grep -qxF "startx" /home/kiosk/.bashrc || echo "sleep 5" >> /home/kiosk/.bashrc
grep -qxF "startx" /home/kiosk/.bashrc || echo "startx" >> /home/kiosk/.bashrc

# Create the .xinitrc file for the kiosk user
cat > /home/kiosk/.xinitrc <<EOL
#!/bin/bash

sleep 3

xrandr --output \$(xrandr | grep " connected " | awk '{ print\$1 }' | head -n 1) --mode 1920x1080

xset s off
xset -dpms
xset s noblank

sleep 2

amixer -c 0 sset Master 100%

SCREEN_RESOLUTION=\$(xrandr | grep '*' | awk '{print \$1}')

WIDTH=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 1)
HEIGHT=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 2)

$BROWSER --kiosk --window-position=0,0 --window-size=\$WIDTH,\$HEIGHT "https://example.com"

while pgrep -x "$BROWSER" > /dev/null; do
    sleep 10
done

systemctl reboot
EOL

# Make asound.conf for audio settings
cat > /home/kiosk/.asoundrc <<EOL
defaults.pcm.card 0
defaults.pcm.device 0
EOL

# Fix screen tearing on intel graphics
cat > /etc/X11/xorg.conf.d/20-intel.conf <<EOL
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection
EOL

# Make .xinitrc owned by the kiosk user and executable
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# Update GRUB configuration
sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' /etc/default/grub
update-grub

# Reboot system
reboot
