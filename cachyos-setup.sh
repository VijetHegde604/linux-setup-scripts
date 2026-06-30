#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "Starting CachyOS environment setup..."

# 1. Install packages from CachyOS/Arch repos
# Using --needed ensures pacman only installs packages that are missing (idempotent)
PACKAGES=(
    flatpak
    lsd
    bat
    helium-browser-bin
    wtype
    gnome-keyring
    seahorse
    zed
    lazygit
    chezmoi
    starship
    zoxide
    ripgrep
    fd
    duf
    fzf
    wget
    ouch
    zellij
    vlc
    adw-gtk-theme
    nautilus
    greetd
)

echo "Installing repository packages..."
# Using paru if available (standard on CachyOS for AUR/Repo), fallback to pacman
if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm "${PACKAGES[@]}"
else
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
fi

# 2. Install Vicinae
echo "Checking for Vicinae..."
if ! command -v vicinae &> /dev/null; then
    echo "Installing Vicinae..."
    curl -fsSL https://vicinae.com/install | bash
else
    echo "Vicinae is already installed. Skipping."
fi

# 3. Configure Flatpak and Install Jellyfin
echo "Configuring Flatpak and installing Jellyfin..."
# Ensure flathub remote exists
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Check if Jellyfin is installed before installing
if ! flatpak list | grep -q "org.jellyfin.JellyfinDesktop"; then
    sudo flatpak install -y flathub org.jellyfin.JellyfinDesktop
else
    echo "Jellyfin Desktop is already installed. Skipping."
fi

# 4. Configure and Initialize Chezmoi
CHEZMOI_CONF_DIR="$HOME/.config/chezmoi"
CHEZMOI_CONF_FILE="$CHEZMOI_CONF_DIR/chezmoi.toml"

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

# 5. Install Nix Package Manager
echo "Checking for Nix..."
if [ ! -d "/nix" ] && ! command -v nix &> /dev/null; then
    echo "Installing Nix (Daemon mode)..."
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
else
    echo "Nix is already installed. Skipping."
fi

# 6. Install DankLinux
echo "Checking for DankLinux setup..."
# Assuming a generic check for a danklinux directory; adjust if it installs a specific binary
if [ ! -d "$HOME/.danklinux" ] && ! command -v danklinux &> /dev/null; then
    echo "Installing DankLinux..."
    curl -fsSL https://install.danklinux.com | sh
else
    echo "DankLinux appears to be installed or configured. Skipping."
    # If the DankLinux installer is naturally idempotent on its own, you can remove
    # the if-statement and just run: curl -fsSL https://install.danklinux.com | sh
fi

# 7. Configure Battery Charge Threshold
echo "Setting up battery charge threshold service..."
SERVICE_FILE="/etc/systemd/system/battery-threshold.service"

cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Set battery charge threshold
After=sysinit.target
After=systemd-modules-load.service

[Service]
Type=oneshot
# Systemd services run as root, so sudo is not needed here
ExecStart=/bin/bash -c "sleep 1 && echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold"

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting battery-threshold.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now battery-threshold.service

# 8. Install and Configure Greetd for Niri
echo "Configuring greetd for niri-session..."

# Ensure greetd is installed
if ! command -v greetd &> /dev/null; then
    echo "Installing greetd..."
    if command -v paru &> /dev/null; then
        paru -S --needed --noconfirm greetd
    else
        sudo pacman -S --needed --noconfirm greetd
    fi
fi

GREETD_CONF="/etc/greetd/config.toml"

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
# Use -f to force enable, which automatically disables conflicting display managers like SDDM
sudo systemctl enable -f greetd.service

echo "Setup complete! You may need to restart your terminal or log out and log back in for all changes (like Nix) to take effect."
