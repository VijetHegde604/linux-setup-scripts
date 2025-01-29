#!/bin/bash

# Script configuration
set -euo pipefail  # Exit on error, undefined vars, and pipe failures
LOGFILE="${HOME}/setup_$(date +%Y%m%d_%H%M%S).log"
PACKAGES=(
    fastfetch
    git
    wget
    curl
    flatpak
    fish
    sof-firmware
    bluez-utils
    power-profiles-daemon
    less
    okular
    spectacle
    docker
    docker-compose
    linux-headers
    base-devel
)

# Configure logging
exec 1> >(tee -a "${LOGFILE}")
exec 2> >(tee -a "${LOGFILE}" >&2)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    exit 1
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should NOT be run as root"
    fi
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error "Required command '$1' not found"
}

# Ensure sudo access
setup_sudo() {
    log "Requesting sudo access..."
    sudo -v || error "Failed to obtain sudo privileges"
    
    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# System update function
update_system() {
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm || error "System update failed"
}

# Package installation function
install_packages() {
    log "Installing required packages..."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" || error "Package installation failed"
}

# Install yay AUR helper
install_yay() {
    if command -v yay >/dev/null 2>&1; then
        log "yay is already installed"
        return
    }

    log "Installing yay AUR helper..."
    local temp_dir
    temp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "${temp_dir}/yay" || error "Failed to clone yay"
    (cd "${temp_dir}/yay" && makepkg -si --noconfirm) || error "Failed to install yay"
    rm -rf "${temp_dir}"
}

# Install Node.js using nvm
install_nodejs() {
    log "Installing Node.js via nvm..."
    
    # Install nvm if not present
    if [[ ! -d "${HOME}/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || error "Failed to install nvm"
    fi

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Node.js LTS
    nvm install --lts || error "Failed to install Node.js LTS"
    nvm use --lts || error "Failed to use Node.js LTS"

    # Install global npm packages
    npm install -g npm@latest yarn pnpm || warn "Failed to install global npm packages"
}

# Install Rust using rustup
install_rust() {
    log "Installing Rust..."
    if command -v rustc >/dev/null 2>&1; then
        log "Rust is already installed"
        rustup update
        return
    fi

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || error "Failed to install Rust"
    source "$HOME/.cargo/env"
}

# Setup Docker
setup_docker() {
    log "Setting up Docker..."
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo usermod -aG docker "$USER" || warn "Failed to add user to docker group"
}

# Configure battery threshold
setup_battery() {
    local threshold=80
    local bat_path="/sys/class/power_supply/BAT0/charge_control_end_threshold"

    if [[ ! -f "${bat_path}" ]]; then
        warn "Battery charge control is not supported on this system"
        return
    }

    log "Setting up battery charge threshold to ${threshold}%..."

    # Create systemd service
    sudo tee /etc/systemd/system/battery-threshold.service > /dev/null << EOF
[Unit]
Description=Set battery charge threshold
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/bash -c 'echo ${threshold} > ${bat_path}'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable battery-threshold.service
    sudo systemctl start battery-threshold.service
}

# Configure system
configure_system() {
    log "Configuring system..."

    # Enable SSD trim
    if [[ -n $(lsblk -d -o name,rota | grep "0$") ]]; then
        sudo systemctl enable fstrim.timer
        sudo systemctl start fstrim.timer
    fi

    # Enable timesyncd
    sudo systemctl enable systemd-timesyncd.service
    sudo systemctl start systemd-timesyncd.service

    # Enable bluetooth
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service

    # Enable power profiles daemon
    sudo systemctl enable power-profiles-daemon.service
    sudo systemctl start power-profiles-daemon.service
}

# Cleanup function
cleanup() {
    log "Cleaning package cache..."
    sudo pacman -Scc --noconfirm
    
    log "Cleaning home directory..."
    rm -rf ~/.cache/yay/*
}

# Main function
main() {
    log "Starting system setup..."
    
    # Preliminary checks
    check_root
    check_command git
    
    # Setup
    setup_sudo
    update_system
    install_packages
    install_yay
    install_nodejs
    install_rust
    setup_docker
    setup_battery
    configure_system
    cleanup
    
    log "Setup complete! Please restart your system to apply all changes."
    log "Setup log has been saved to: ${LOGFILE}"
}

# Run main function
main
