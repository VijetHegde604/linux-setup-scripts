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
    run_sudo pacman -Syu --noconfirm
}

# Install essential packages
install_packages() {
    echo "Installing required packages..."
    run_sudo pacman -S --noconfirm fastfetch git wget curl flatpak fish sof-firmware bluez-utils power-profiles-daemon less okular spectacle
}

# Install yay (AUR helper)
install_yay() {
    echo "Installing yay (AUR helper)..."
    run_sudo pacman -S --noconfirm base-devel git
    cd /tmp || handle_error "Failed to change to /tmp directory."
    git clone https://aur.archlinux.org/yay.git || handle_error "Failed to clone yay repository."
    cd yay || handle_error "Failed to change to yay directory."
    makepkg -si --noconfirm || handle_error "Failed to build and install yay."
    cd ~ || handle_error "Failed to return to home directory."
}

# Install Node.js using nvm
install_nodejs() {
    echo "Installing Node.js via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || handle_error "Failed to install nvm."

    # Source nvm script to make it available immediately
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || handle_error "Failed to source nvm."

    # Install Node.js version 22 using nvm
    nvm install 22 || handle_error "Failed to install Node.js v22."

    # Verify Node.js installation
    echo "Node.js version:"
    node -v || handle_error "Node.js is not installed."
    echo "NVM current version:"
    nvm current || handle_error "NVM is not working."
    echo "NPM version:"
    npm -v || handle_error "NPM is not installed."
}

# Install Rust using rustup
install_rust() {
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || handle_error "Failed to install Rust."

    # Source rustup to make Rust available immediately
    export PATH="$HOME/.cargo/bin:$PATH"

    # Verify Rust installation
    echo "Rust version:"
    rustc --version || handle_error "Rust is not installed."
    echo "Cargo version:"
    cargo --version || handle_error "Cargo is not installed."
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
    cat <<EOF | run_sudo tee /etc/systemd/system/battery-threshold.service > /dev/null
[Unit]
Description=Set battery charge threshold
After=sysinit.target
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c "sleep 5 && echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold"

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
    rm -rf /tmp/yay || handle_error "Failed to clean up /tmp/yay."
}

# Main script execution
main() {
    update_system
    install_packages
    install_yay
    install_nodejs
    install_rust
    create_battery_service
    cleanup
    echo "Setup complete!"
}

# Run the main function
main
