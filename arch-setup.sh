#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# --------------------------------------------------
# Helpers
# --------------------------------------------------
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

fail() {
    echo "[ERROR] $1"
    exit 1
}

require_sudo() {
    sudo -v
}

# --------------------------------------------------
# Core system setup
# --------------------------------------------------
update_system() {
    log "Updating system"
    sudo pacman -Syu --noconfirm
}

install_base_packages() {
    log "Installing base packages"

    sudo pacman -S --noconfirm --needed \
        base-devel \
        git \
        curl \
        wget \
        flatpak \
        bluez \
        bluez-utils \
        reflector \
        pacman-contrib \
        btop \
        noto-fonts \
        noto-fonts-emoji \
	noto-fonts-cjk \
        zed \
        fastfetch \
        qt6-imageformats \
        lsd
}

enable_services() {
    log "Enabling system services"

    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now paccache.timer
    sudo systemctl enable reflector.timer
}

configure_reflector() {
    log "Configuring reflector (India mirrors)"

    sudo reflector \
        --country India \
        --sort rate \
        --latest 6 \
        --save /etc/pacman.d/mirrorlist
}

# --------------------------------------------------
# AUR
# --------------------------------------------------
install_paru() {
    if command -v paru &>/dev/null; then
        log "paru already installed"
        return
    fi

    log "Installing paru"

    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
}

install_aur_packages() {
    log "Installing AUR packages"

    paru -S --noconfirm \
        visual-studio-code-bin \
        snapper \
	snapper-support
}

# --------------------------------------------------
# Dev tools
# --------------------------------------------------
install_mise() {
    curl https://mise.run | sh || fail "Failed to install mise."
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
}

install_zoxide() {
    if command -v zoxide &>/dev/null; then
        log "zoxide already installed"
        return
    fi

    log "Installing zoxide"
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

# --------------------------------------------------
# Shell
# --------------------------------------------------
install_starship() {
    curl -sS https://starship.rs/install.sh | sh || fail "Failed to install starship"
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
}

set_starship_config() {
    cp ~/linux-setup-scripts/starship.toml ~/.config/starship.toml
}

configure_bash() {
    cp ./bashrc ~/.bashrc
}

# --------------------------------------------------
# Laptop specific
# --------------------------------------------------
configure_battery_limit() {
    local threshold="/sys/class/power_supply/BAT0/charge_control_end_threshold"

    if [ ! -f "$threshold" ]; then
        warn "Battery charge limit not supported"
        return
    fi

    log "Setting battery charge limit to 80%"

    sudo tee /etc/systemd/system/battery-threshold.service >/dev/null <<EOF
[Unit]
Description=Set battery charge threshold
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo 80 > $threshold"

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable --now battery-threshold.service
}

# --------------------------------------------------
# Custom Scripts
# --------------------------------------------------
install_custom_scripts() {
    log "Installing custom webapp creator (mkapp)"

    # Ensure the local bin directory exists
    mkdir -p "$HOME/.local/bin"

    # Copy the file and rename it to 'mkapp'
    # Assuming the script is in your current directory
    if [ -f "./create-webapp.sh" ]; then
        cp "./create-webapp.sh" "$HOME/.local/bin/mkapp"
        chmod +x "$HOME/.local/bin/mkapp"
        log "mkapp installed to ~/.local/bin"
    else
        warn "create-webapp.sh not found in current directory, skipping."
    fi
}

# --------------------------------------------------
# Cleanup
# --------------------------------------------------
cleanup() {
    log "Cleaning up build directories"
    rm -rf /tmp/paru
}

# --------------------------------------------------
# Main
# --------------------------------------------------
main() {
#    require_sudo
#    update_system
#    install_base_packages
#    configure_reflector
#    enable_services

#    install_paru
#    install_aur_packages

    install_mise

    install_starship
    set_starship_config
    configure_bash
    install_custom_scripts

    configure_battery_limit
    cleanup

    log "Setup complete. Reboot recommended."
}

main
