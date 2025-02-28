#!/bin/bash

# 1. Comment out lines in /etc/apt/sources.list that include "cdrom:"
sed -i '/cdrom:/s/^[^#]/#/' /etc/apt/sources.list

# 2. Update the system
apt update -y

# 3. Install necessary packages
apt install -y xorg xinit chromium alsa-utils

# 4. Create the directory for the systemd service override
mkdir -p /etc/systemd/system/getty@tty1.service.d/

# 5. Create the override.conf file
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I \$TERM
EOL

# 6. Add "startx" to the end of /home/kiosk/.bashrc if it isn't already
grep -qxF "startx" /home/kiosk/.bashrc || echo "startx" >> /home/kiosk/.bashrc

# 7. Create the .xinitrc file for the kiosk user
cat > /home/kiosk/.xinitrc <<EOL
#!/bin/bash

sleep 3

xrandr --output Virtual-1 --mode 1920x1080

sleep 2

amixer -c 0 sset Master 100%

SCREEN_RESOLUTION=\$(xrandr | grep '*' | awk '{print \$1}')

WIDTH=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 1)
HEIGHT=\$(echo \$SCREEN_RESOLUTION | cut -d 'x' -f 2)

chromium --no-sandbox --kiosk --window-position=0,0 --window-size=\$WIDTH,\$HEIGHT "https://example.com"
EOL

# 8. Make .xinitrc owned by the kiosk user and executable
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# 9. Modify the GRUB configuration file
sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' /etc/default/grub

# 10. Update GRUB to apply the changes
update-grub

# 11. Reboot the system
reboot
