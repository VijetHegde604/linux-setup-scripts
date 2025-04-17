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
        "libreoffice-*"
        "kmahjongg"
        "kmines"
        "skanpage"
        "pinyin"
    )

    for app in "${bloatware[@]}"; do
        echo "Removing $app..."
        run_sudo dnf remove "$app" -y || echo "Warning: Failed to remove $app"
    done
}

# Install essential packages
install_packages() {
    echo "Installing required packages..."
    run_sudo dnf install -y fastfetch git wget curl zsh btop @development-tools libffi-devel ncurses-devel readline-devel sqlite-devel tk-devel gdbm-devel libdb-devel bzip2-devel zlib-devel xz-devel || handle_error "Failed to install packages."
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

# install zoxide
install_zoxide() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || handle_error "Failed to install zoxide."
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
}

# creating zshrc
create_zshrc() {
    cp ./zshrc ~/.zshrc
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

# install zed
install_zed() {
    curl -f https://zed.dev/install.sh | sh
}

# installing vscode
install_vscode() {
    run_sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

    run_sudo dnf check-update
    run_sudo dnf install -y code || handle_error "vscode installation failed"
}

# installing gcm
install_gcm() {
    curl -LO "https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.tar.gz"

    run_sudo tar -xvf ./gcm-linux_amd64.2.6.1.tar.gz -C /usr/local/bin
    git-credential-manager configure

    git config --global credential.credentialStore cache
}

# Main script execution
main() {
    update_system
    remove_bloatware
    install_packages
    install_nodejs
    install_pyenv
    create_zshrc
    install_zoxide
    install_zed
    install_vscode
    install_gcm
    create_battery_service
    cleanup
    echo "Setup complete!"
}

# Run the main function
main
