#!/bin/bash
# Log file for debugging
LOGFILE="setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Function to handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Prompt for sudo password once
read -rsp "Enter your sudo password: " SUDO_PASSWORD
echo

# Function to run commands with sudo
run_sudo() {
    echo "$SUDO_PASSWORD" | sudo -S "$@" || handle_error "Failed to run: $*"
}

# Update system
update_system() {
    echo "Updating system..."
    run_sudo dnf update -y || handle_error "Failed to update system."
}

# Install essential packages
install_packages() {
    echo "Installing required packages..."
    run_sudo dnf install -y fastfetch git wget curl btop @development-tools libffi-devel ncurses-devel readline-devel sqlite-devel tk-devel gdbm-devel libdb-devel bzip2-devel zlib-devel xz-devel git-credential-libsecret lsd || handle_error "Failed to install packages."
}

# install zoxide
install_zoxide() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || handle_error "Failed to install zoxide."
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
}

# install starship
install_starship() {
    curl -sS https://starship.rs/install.sh | sh || handle_error "Failed to install starship"
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
}

# create startship config
create_starship() {
    cp ./starship.toml ~/.config/starship.toml
}

# install mise
install_mise() {
    curl https://mise.run | sh || handle_error "Failed to install mise."
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
}

# Create a systemd service to set battery charge threshold to 80%
create_battery_service() {
    echo "Checking if battery charge control is supported..."
    if [ ! -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
        echo "Battery charge control is not supported on this system. Skipping service creation."
        return
    fi
    echo "Creating systemd service to set battery charge threshold to 80%..."
    # Create the systemd service file
    cat <<EOF | sudo tee /etc/systemd/system/battery-threshold.service > /dev/null
[Unit]
Description=Set battery charge threshold
After=sysinit.target
After=systemd-modules-load.service
[Service]
Type=oneshot
ExecStart=/bin/bash -c "sleep 1 && echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold"
[Install]
WantedBy=multi-user.target
EOF
    # Enable and start the service
    echo "Enabling and starting battery charge threshold service..."
    run_sudo systemctl enable battery-threshold.service
    run_sudo systemctl start battery-threshold.service
}

# Cleanup temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    run_sudo dnf autoremove -y || handle_error "Failed to clean up."
}

# install zed
install_zed() {
    curl -f https://zed.dev/install.sh | sh
}

# install ghostty
install_ghostty() {
    run_sudo dnf copr enable pgdev/ghostty -y
    run_sudo dnf install -y ghostty
}

# installing tailscale
install_tailscale() {
    run_sudo curl -fsSL https://tailscale.com/install.sh | sh
}

# Main script execution
main() {
    update_system
    install_packages
    install_zoxide
    install_mise
    install_starship
    create_starship
    install_zed
    install_ghostty
    create_battery_service
    install_tailscale
    cleanup
    echo "Setup complete!"
}

# Run the main function
main
