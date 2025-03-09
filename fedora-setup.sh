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

# Remove KDE bloatware
remove_bloatware() {
    echo "Removing KDE bloatware..."
    local bloatware=(
        "akregator"
        "dragon"
        "elisa-player"
        "kaddressbook"
        "kamoso"
        "kmail"
        "kmouth"
        "knotes"
        "kolourpaint"
        "konversation"
        "korganizer"
        "kpat"
        "kpublictransport"
        "krdc"
        "krfb"
        "kwrite"
        "neochat"
    )

    for app in "${bloatware[@]}"; do
        echo "Removing $app..."
        run_sudo dnf remove "$app" -y || echo "Warning: Failed to remove $app"
    done
}

# Install essential packages
install_packages() {
    echo "Installing required packages..."
    run_sudo dnf install -y fastfetch git wget curl fish btop || handle_error "Failed to install packages."
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

# Install ble.sh bashline editor
install_ble_sh() {
    echo "Installing ble.sh bashline editor..."
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git || handle_error "Failed to clone ble.sh repository."
    make -C ble.sh install PREFIX=~/.local || handle_error "Failed to build and install ble.sh."
    echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc || handle_error "Failed to add ble.sh to .bashrc."
    source ~/.bashrc
    echo "ble.sh installed successfully."
}

# Install pyenv
install_pyenv() {
    echo "Installing pyenv..."
    curl -fsSL https://pyenv.run | bash || handle_error "Failed to install pyenv."
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
    source ~/.bashrc
    echo "pyenv installed successfully."
}

# Install Jupyter Notebook
install_jupyter() {
    echo "Installing Jupyter Notebook..."
    pyenv install 3.11.8 || handle_error "Failed to install Python 3.11.8."
    pyenv global 3.11.8 || handle_error "Failed to set global python version"
    python -m pip install --upgrade pip || handle_error "Failed to upgrade pip"
    python -m pip install jupyter notebook || handle_error "Failed to install Jupyter Notebook."
    echo "Jupyter Notebook installed successfully."

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
    run_sudo dnf autoremove -y || handle_error "Failed to clean up."
    rm -rf ble.sh || handle_error "Failed to remove ble.sh directory"
}

# Main script execution
main() {
    update_system
    remove_bloatware
    install_packages
    install_nodejs
    install_ble_sh
    install_pyenv
    install_jupyter
    create_battery_service
    cleanup
    echo "Setup complete!"
}

# Run the main function
main
