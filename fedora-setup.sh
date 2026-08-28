#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

install_packages() {
    echo "Starting Fedora environment setup..."
    echo "Installing repository packages..."

    PACKAGES=(
        flatpak
        lsd
        bat
        wtype
        gnome-keyring
        seahorse
        chezmoi
        zoxide
        ripgrep
        fd-find
        duf
        fzf
        wget
        vlc
        nautilus
        greetd
        cups-pk-helper
        cava
        kf5-kimageformats
        adw-gtk3-theme
        plymouth
        plymouth-theme-spinner
        xdg-user-dirs
        fastfetch
        nix
        google-noto-color-emoji-fonts
        alsa-sof-firmware
        power-profiles-daemon
        kf6-kimageformats
        git-credential-libsecret
        btop
        iwlwifi-mvm-firmware
        pulseaudio-utils
    )

    # dnf install is idempotent; already-installed packages are skipped.
    sudo dnf install -y "${PACKAGES[@]}"
}

install_vicinae() {
    echo "Checking for Vicinae..."

    if ! command -v vicinae &> /dev/null; then
        echo "Installing Vicinae..."
        curl -fsSL https://vicinae.com/install | bash
    else
        echo "Vicinae is already installed. Skipping."
    fi
}

install_lazygit() {
    echo "Installing LazyGit..."

    sudo dnf copr enable atim/lazygit -y
    sudo dnf install lazygit -y
}

setup_flatpaks() {
    echo "Configuring Flatpak and installing applications..."

    # Ensure Flathub remote exists.
    sudo flatpak remote-add --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    if ! flatpak list | grep -q "org.jellyfin.JellyfinDesktop"; then
        echo "Installing Jellyfin Desktop..."
        sudo flatpak install -y flathub org.jellyfin.JellyfinDesktop
    else
        echo "Jellyfin Desktop is already installed. Skipping."
    fi

    if ! flatpak list | grep -q "it.mijorus.gearlever"; then
        echo "Installing Gear Lever..."
        sudo flatpak install -y flathub it.mijorus.gearlever
    else
        echo "Gear Lever is already installed. Skipping."
    fi
}

setup_chezmoi() {
    local CHEZMOI_CONF_DIR="$HOME/.config/chezmoi"
    local CHEZMOI_CONF_FILE="$CHEZMOI_CONF_DIR/chezmoi.toml"

    echo "Setting up Chezmoi..."

    if [ ! -f "$CHEZMOI_CONF_FILE" ]; then
        mkdir -p "$CHEZMOI_CONF_DIR"

        echo "Chezmoi configuration not found. Please enter your Git details."

        read -p "Git Username: " GIT_USER
        read -p "Git Email: " GIT_EMAIL

        cat <<EOF > "$CHEZMOI_CONF_FILE"
[data]
gitUser = "$GIT_USER"
gitEmail = "$GIT_EMAIL"
EOF

        echo "Created $CHEZMOI_CONF_FILE."
    else
        echo "Chezmoi configuration already exists at $CHEZMOI_CONF_FILE. Skipping input."
    fi

    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        echo "Initializing and applying chezmoi dots..."

        chezmoi init --apply \
            https://github.com/VijetHegde604/dots.git
    else
        echo "Chezmoi is already initialized. Applying latest changes..."

        chezmoi apply
    fi
}

install_nix() {
    echo "Checking for Nix..."

    if [ ! -d "/nix" ] && ! command -v nix &> /dev/null; then
        echo "Installing Nix (Daemon mode)..."

        curl --proto '=https' \
            --tlsv1.2 \
            -L https://nixos.org/nix/install \
            | sh -s -- --daemon
    else
        echo "Nix is already installed. Skipping."
    fi
}

install_danklinux() {
    echo "Checking for DankLinux setup..."

    if [ ! -d "$HOME/.danklinux" ] && ! command -v danklinux &> /dev/null; then
        echo "Installing DankLinux..."

        curl -fsSL https://install.danklinux.com | sh
    else
        echo "DankLinux appears to be installed or configured. Skipping."
    fi
}

setup_battery_threshold() {
    echo "Setting up battery charge threshold service..."

    local SERVICE_FILE="/etc/systemd/system/battery-threshold.service"

    cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Set battery charge threshold
After=sysinit.target
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c "sleep 1 && echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold"

[Install]
WantedBy=multi-user.target
EOF

    echo "Enabling and starting battery-threshold.service..."

    sudo systemctl daemon-reload
    sudo systemctl enable --now battery-threshold.service
}

setup_greetd_niri() {
    echo "Configuring greetd for Niri autologin..."

    if ! command -v greetd &> /dev/null; then
        echo "Installing greetd..."
        sudo dnf install -y greetd
    fi

    local GREETD_CONF="/etc/greetd/config.toml"

    # Create a basic configuration if the file does not exist.
    if [ ! -f "$GREETD_CONF" ]; then
        echo "Creating greetd configuration..."

        cat <<EOF | sudo tee "$GREETD_CONF" > /dev/null
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /bin/sh"
user = "greetd"

[initial_session]
command = "/usr/bin/niri-session"
user = "$USER"
EOF

    elif sudo grep -q "^\[initial_session\]" "$GREETD_CONF" 2>/dev/null; then
        echo "greetd [initial_session] already configured. Skipping."
    else
        echo "Adding greetd [initial_session]..."

        sudo cp "$GREETD_CONF" "${GREETD_CONF}.bak"

        cat <<EOF | sudo tee -a "$GREETD_CONF" > /dev/null

[initial_session]
command = "/usr/bin/niri-session"
user = "$USER"
EOF
    fi

    echo "Setting graphical.target as the default target..."

    sudo systemctl set-default graphical.target

    echo "Enabling greetd as the display manager..."

    # Force greetd to own the display-manager.service alias.
    sudo systemctl enable -f greetd.service

    echo "greetd autologin configuration complete."
}

setup_plymouth() {
    echo "Configuring Plymouth..."

    # Ensure Plymouth is installed.
    if ! command -v plymouth-set-default-theme &> /dev/null; then
        echo "Installing Plymouth..."

        sudo dnf install -y \
            plymouth \
            plymouth-theme-spinner
    fi

    echo "Setting Plymouth spinner theme..."

    sudo plymouth-set-default-theme spinner

    echo "Adding Fedora graphical boot arguments..."

    # Ensure Fedora uses the graphical Plymouth boot.
    sudo grubby --update-kernel=ALL --args="rhgb quiet"

    echo "Rebuilding initramfs with dracut..."

    # Fedora uses dracut instead of mkinitcpio.
    sudo dracut --regenerate-all --force

    echo "Plymouth configuration complete."
}

install_zed() {
    echo "Checking for Zed editor..."

    if ! command -v zed &> /dev/null && \
       [ ! -f "$HOME/.local/bin/zed" ]; then

        echo "Installing Zed..."

        curl -f https://zed.dev/install.sh | sh
    else
        echo "Zed is already installed. Skipping."
    fi
}

install_tailscale() {
    echo "Checking for Tailscale..."

    if ! command -v tailscale &> /dev/null; then
        echo "Installing Tailscale..."

        curl -fsSL https://tailscale.com/install.sh | sh

        echo "Enabling and starting Tailscale service..."

        sudo systemctl enable --now tailscaled
    else
        echo "Tailscale is already installed. Skipping."
    fi
}

install_starship() {
    echo "Checking for Starship..."

    if ! command -v starship &> /dev/null; then
        echo "Installing Starship..."

        curl -sS https://starship.rs/install.sh | sh

        echo "Starship installed."
    else
        echo "Starship already installed. Skipping."
    fi
}

main() {
    install_packages
    install_vicinae
    setup_flatpaks
    install_lazygit
    install_danklinux
    setup_chezmoi
    setup_greetd_niri
    setup_battery_threshold
    install_zed
    install_starship
    install_tailscale
    setup_plymouth

    echo
    echo "========================================"
    echo " Fedora setup complete!"
    echo "========================================"
    echo
    echo "Reboot to use the system."
}

main
