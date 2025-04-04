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
    run_sudo pacman -S --noconfirm fastfetch git wget curl flatpak sof-firmware bluez-utils tuned tuned-ppd less noto-fonts okular spectacle btop qt6-imageformats zsh
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

# Install AUR packages using yay
install_aur_packages() {
    echo "Installing Ghostty and Visual Studio Code from AUR..."
    yay -S --noconfirm ghostty visual-studio-code-bin || handle_error "Failed to install AUR packages."
    echo "AUR packages installed successfully."
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

# Install zoxide
install_zoxide() {
    echo "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || handle_error "Failed to install zoxide."
    echo "zoxide installed successfully."
}

# Install Zed editor
install_zed() {
    echo "Installing Zed editor..."
    curl -f https://zed.dev/install.sh | sh || handle_error "Failed to install Zed editor."
    echo "Zed editor installed successfully."
}

# Configure zsh
configure_zsh() {
    echo "Configuring zsh..."
    if [ -f "./zshrc" ]; then
        cp ./zshrc ~/.zshrc || handle_error "Failed to copy zshrc to home directory."
        echo "zsh configuration copied successfully."
    else
        echo "Warning: zshrc file not found in current directory. Skipping zsh configuration."
    fi
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

# Install Jupyter Notebook
install_jupyter() {
    echo "Installing Jupyter Notebook..."
    run_sudo pacman -S --noconfirm jupyter-notebook
    echo "Jupyter Notebook installed successfully."
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
    install_aur_packages
    install_nodejs
    install_pyenv
    install_zoxide
    install_zed
    install_jupyter
    configure_zsh
    create_battery_service
    cleanup
    echo "Setup complete!"
}

# Run the main function
main