#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

install_packages() {
    echo "Starting Fedora environment setup..."
    echo "Installing repository packages..."

    # Updated for Fedora (dnf). Note: 'fd' is 'fd-find' in Fedora.
    # Commented out AUR-specific/missing packages to prevent dnf from failing.
    PACKAGES=(
        flatpak
        lsd
        bat
        wtype
        gnome-keyring
        seahorse
        lazygit
        chezmoi
        starship
        zoxide
        ripgrep
        fd-find
        duf
        fzf
        wget
        zellij
        vlc
        nautilus
        greetd
        cups-pk-helper
        cava
        kf5-kimageformats
        adw-gtk3-theme
        plymouth-theme-spinner
    )

    # dnf install is idempotent by default; it will skip already installed packages.
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

setup_flatpaks() {
    echo "Configuring Flatpak and installing applications..."
    # Ensure flathub remote exists
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Check if Jellyfin is installed before installing
    if ! flatpak list | grep -q "org.jellyfin.JellyfinDesktop"; then
        echo "Installing Jellyfin Desktop..."
        sudo flatpak install -y flathub org.jellyfin.JellyfinDesktop
    else
        echo "Jellyfin Desktop is already installed. Skipping."
    fi

    # Check if Gear Lever is installed before installing
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

        # Writing TOML configuration
        cat <<EOF > "$CHEZMOI_CONF_FILE"
[data]
gitUser = "$GIT_USER"
gitEmail = "$GIT_EMAIL"
EOF
        echo "Created $CHEZMOI_CONF_FILE."
    else
        echo "Chezmoi configuration already exists at $CHEZMOI_CONF_FILE. Skipping input."
    fi

    # Apply the dotfiles if they haven't been cloned yet, otherwise just update/apply
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        echo "Initializing and applying chezmoi dots..."
        chezmoi init --apply https://github.com/VijetHegde604/dots.git
    else
        echo "Chezmoi is already initialized. Applying latest changes..."
        chezmoi apply
    fi
}

install_nix() {
    echo "Checking for Nix..."
    if [ ! -d "/nix" ] && ! command -v nix &> /dev/null; then
        echo "Installing Nix (Daemon mode)..."
        curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
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
    echo "Configuring greetd for niri-session..."

    # Ensure greetd is installed (fallback check just in case)
    if ! command -v greetd &> /dev/null; then
        echo "Installing greetd..."
        sudo dnf install -y greetd
    fi

    local GREETD_CONF="/etc/greetd/config.toml"

    # Idempotency check: only append if [initial_session] isn't already there
    if sudo grep -q "\[initial_session\]" "$GREETD_CONF" 2>/dev/null; then
        echo "greetd [initial_session] is already configured. Skipping."
    else
        echo "Adding [initial_session] to $GREETD_CONF..."

        # Backup the original config just in case
        sudo cp "$GREETD_CONF" "${GREETD_CONF}.bak"

        # Append the configuration using the current $USER
        cat <<EOF | sudo tee -a "$GREETD_CONF" > /dev/null

[initial_session]
command = "niri-session"
user = "$USER"
EOF
    fi

    echo "Enabling greetd service..."
    # Use -f to force enable, which automatically disables conflicting display managers like GDM/SDDM
    sudo systemctl enable -f greetd.service
}

install_zed() {
    echo "Checking for Zed editor..."
    # Zed typically installs to ~/.local/bin/zed, so we check both the path and that specific location
    if ! command -v zed &> /dev/null && [ ! -f "$HOME/.local/bin/zed" ]; then
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
        # Using Tailscale's official installation script which automatically detects Fedora and sets up the repos
        curl -fsSL https://tailscale.com/install.sh | sh

        echo "Enabling and starting Tailscale service..."
        sudo systemctl enable --now tailscaled
    else
        echo "Tailscale is already installed. Skipping."
    fi
}

setup-plymouth() {
    sudo plymouth-set-default-theme spinner
}

main() {
    install_packages
    install_vicinae
    setup_flatpaks
    install_nix
    install_danklinux
    setup_chezmoi
    setup_greetd_niri
    setup_battery_threshold
    install_zed
    install_tailscale
    setup-plymouth

    echo "Setup complete! You may need to restart your terminal or log out and log back in for all changes (like Nix) to take effect."
}

# Execute main function
main
