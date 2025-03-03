#!/bin/bash

# 1. Comment out lines in /etc/apt/sources.list that include "cdrom:"
sed -i '/cdrom:/s/^[^#]/#/' /etc/apt/sources.list

# 2. Update the system
apt update -y

# 3. Install necessary packages
apt install -y xorg xinit alsa-utils software-properties-common apt-transport-https ca-certificates curl

# 4. Import the Google Chrome GPG Key
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >> /dev/null

# 5. Add the Google Chrome Repository
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | tee /etc/apt/sources.list.d/google-chrome.list

# 6. Update the system
apt update -y

# 7. Install google-chrome-stable
apt install -y google-chrome-stable

# 8. Create the directory for the systemd service override
mkdir -p /etc/systemd/system/getty@tty1.service.d/

# 9. Create the override.conf file
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I \$TERM
EOL

# 10. Add "sleep 5" & "startx" to the end of /home/kiosk/.bashrc if it isn't already
grep -qxF "startx" /home/kiosk/.bashrc || echo "clear" >> /home/kiosk/.bashrc
grep -qxF "startx" /home/kiosk/.bashrc || echo "sleep 5" >> /home/kiosk/.bashrc
grep -qxF "startx" /home/kiosk/.bashrc || echo "startx" >> /home/kiosk/.bashrc

# 11. Create the .xinitrc file for the kiosk user
cat > /home/kiosk/.xinitrc <<EOL
#!/bin/bash

sleep 3

xrandr --output \$(xrandr | grep " connected " | awk '{ print$1 }' | head -n 1) --mode 1920x1080

xset s off
xset -dpms
xset s noblank

sleep 2

amixer -c 0 sset Master 100%

SCREEN_RESOLUTION=\$(xrandr | grep '*' | awk '{print \$1}')

WIDTH=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 1)
HEIGHT=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 2)

google-chrome-stable --kiosk --window-position=0,0 --window-size=\$WIDTH,\$HEIGHT "https://example.com"

while pgrep -x "google-chrome-stable" > /dev/null; do
    sleep 10
done

systemctl reboot
EOL

# 12. Make asound.conf for audio settings
echo -e "defaults.pcm.card 0\ndefaults.pcm.device 0" | sudo tee /etc/asound.conf > /dev/null

# 13. Make .xinitrc owned by the kiosk user and executable
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# 14. Modify the GRUB configuration file
sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' /etc/default/grub

# 15. Update GRUB to apply the changes
update-grub

# 16. Reboot the system
reboot
