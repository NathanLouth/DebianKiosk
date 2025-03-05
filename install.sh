#!/bin/bash

# Default values
BROWSER="chromium"
BROWSER_FLAGS=""
URL="https://example.com"
CARD="0"
DEVICE="0"
SCREEN_TEARING=""

# Argument parsing with validation
while [[ $# -gt 0 ]]; do
    case "$1" in
        --card|--device)
            [[ "$2" =~ ^[0-9]+$ ]] || exit 1
            declare "$1=$2"
            shift 2
            ;;
        --browser)
            [[ "$2" == @(chrome|chromium) ]] || exit 1
            BROWSER=${2/google-chrome-stable/chrome}
            shift 2
            ;;
        --url) URL="$2"; shift 2;;
        --nourl) URL=""; shift;;
        --incognito|--kiosk) BROWSER_FLAGS+=" --$1"; shift;;
        --amd-st|--intel-st) SCREEN_TEARING="${1:2}"; shift;;
        *) echo "Invalid argument: $1" >&2; exit 1;;
    esac
done

# System configuration
sed -i '/cdrom:/s/^[^#]/#/' /etc/apt/sources.list
apt update -y

# Browser installation
case $BROWSER in
    chrome)
        apt install -y xorg xinit alsa-utils software-properties-common \
            apt-transport-https ca-certificates curl
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg
        echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main > /etc/apt/sources.list.d/google-chrome.list
        apt update -y && apt install -y google-chrome-stable
        ;;
    chromium)
        apt install -y xorg xinit chromium alsa-utils
        ;;
esac

# System setup
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I \$TERM
EOL

for cmd in clear 'sleep 5' startx; do
    grep -qxF "$cmd" /home/kiosk/.bashrc || echo "$cmd" >> /home/kiosk/.bashrc
done

# xinitrc setup
cat > /home/kiosk/.xinitrc <<EOL
#!/bin/bash
sleep 3
xrandr --output \$(xrandr | grep " connected " | awk '{print\$1}' | head -n 1) --mode 1920x1080
xset s off && xset -dpms && xset s noblank
sleep 2
amixer -c $CARD sset Master 100%
SCREEN_RESOLUTION=\$(xrandr | grep '*' | awk '{print \$1}')
WIDTH=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 1)
HEIGHT=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 2)
$BROWSER $BROWSER_FLAGS --window-position=0,0 --window-size=\$WIDTH,\$HEIGHT $URL
while pgrep -x "$BROWSER" > /dev/null; do sleep 10; done
systemctl reboot
EOL

# Audio configuration
cat > /etc/asound.conf <<EOL
defaults.pcm.card $CARD
defaults.pcm.device $DEVICE
EOL

# Permissions
chown kiosk:kiosk /home/kiosk/.xinitrc && chmod +x /home/kiosk/.xinitrc

# Screen tearing fix
[[ -n $SCREEN_TEARING ]] && cat > /etc/X11/xorg.conf.d/20-ScreenTearing.conf <<EOL
Section "Device"
  Identifier "${SCREEN_TEARING} Graphics"
  Driver "${SCREEN_TEARING,,}"
  Option "TearFree" "true"
EndSection
EOL

# GRUB configuration
sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' /etc/default/grub
update-grub

reboot
