#!/bin/bash
# lib/persistence.sh - Settings Saving and Service Management

# Writes or updates the given setting in /etc/asus-power.conf
save_setting() {
    local key=$1; local val=$2
    [ ! -f "/etc/asus-power.conf" ] && sudo touch "/etc/asus-power.conf"
    
    # Use a lock file to prevent race conditions
    (
        flock -x 200 || exit 1
        if grep -q "^$key=" "/etc/asus-power.conf"; then
            sudo sed -i "s/^$key=.*/$key=$val/" "/etc/asus-power.conf"
        else
            echo "$key=$val" | sudo tee -a "/etc/asus-power.conf" > /dev/null
        fi
    ) 200>"/var/lock/asus-power.lock"
}

# Creates systemd service for automatic application of settings on boot
enable_persistence() {
    local SERVICE_FILE="/etc/systemd/system/asus-pwr-persistence.service"
    if [ ! -f "$SERVICE_FILE" ]; then
        sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Asus Power Master Boot Persistence
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/asus-pwr --apply
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable asus-pwr-persistence.service
        echo "[SUCCESS] Boot persistence enabled."
    fi
}
