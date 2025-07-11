#!/bin/bash
LOGFILE="setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Colors
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
purple=$(tput setaf 5)

info()    { echo "${cyan}ℹ️ $1${normal}"; }
success() { echo "${green}✅ $1${normal}"; }
warn()    { echo "${yellow}⚠️ $1${normal}"; }
error()   { echo "${red}❌ $1${normal}"; }
section() { echo "${purple}\n====== 🚀 $1 ======${normal}"; }

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

handle_error() {
    error "$1"
    exit 1
}

# Prompt for sudo password once
read -rsp "Enter your sudo password: " SUDO_PASSWORD
echo

run_sudo() {
    echo "$SUDO_PASSWORD" | sudo -S "$@" || handle_error "Failed: $*"
}

section "Updating system"
run_sudo pacman -Syu --noconfirm & spinner
success "System updated!"

section "Installing essential packages"
run_sudo pacman -S --noconfirm \
    base-devel git wget curl flatpak sof-firmware less \
    bluez bluez-utils inotify-tools fastfetch \
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-indic-otf \
    okular spectacle btop qt6-imageformats zsh timeshift \
    reflector pacman-contrib & spinner
success "Installed essential packages"

section "Configuring reflector with India mirrors"
run_sudo reflector --country India --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --number 6 & spinner
run_sudo systemctl enable --now reflector.timer
success "Reflector set up & enabled"

section "Enabling paccache.timer"
run_sudo systemctl enable --now paccache.timer
success "paccache.timer enabled"

section "Enabling Bluetooth"
run_sudo systemctl enable --now bluetooth
success "Bluetooth service running"

section "Installing paru (AUR helper)"
cd /tmp || handle_error "cd /tmp failed"
git clone https://aur.archlinux.org/paru.git & spinner
cd paru || handle_error "cd paru failed"
makepkg -si --noconfirm & spinner
cd ~
success "paru installed"

section "Installing AUR packages"
paru -S --noconfirm ghostty visual-studio-code-bin timeshift-autosnap auto-cpufreq & spinner
success "AUR packages installed"

section "Enabling auto-cpufreq"
run_sudo systemctl enable --now auto-cpufreq
success "auto-cpufreq running"

section "Installing Node via nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash & spinner
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22 & spinner
success "Node.js installed via nvm"

section "Installing pyenv"
curl -fsSL https://pyenv.run | bash & spinner
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
source ~/.bashrc
success "pyenv installed"

section "Installing zoxide"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh & spinner
success "zoxide installed"

section "Installing Zed editor"
curl -f https://zed.dev/install.sh | sh & spinner
success "Zed installed"

section "Changing default shell to zsh"
run_sudo chsh -s "$(which zsh)" "$USER"
success "Default shell set to zsh"

section "Configuring zsh"
cd ~/linux-setup-scripts
if [ -f "./zshrc" ]; then
    cp ./zshrc ~/.zshrc
    success "zsh configuration applied"
else
    warn "No zshrc found in linux-setup-scripts, skipping"
fi

section "Setting battery threshold"
if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
    cat <<EOF | sudo tee /etc/systemd/system/battery-threshold.service > /dev/null
[Unit]
Description=Set battery charge threshold
After=sysinit.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c "sleep 1 && echo 80 | tee /sys/class/power_supply/BAT0/charge_control_end_threshold"
[Install]
WantedBy=multi-user.target
EOF
    run_sudo systemctl enable --now battery-threshold.service
    success "Battery charge threshold service enabled"
else
    warn "Battery charge control not supported on this laptop"
fi

section "Installing Tailscale"
run_sudo curl -fsSL https://tailscale.com/install.sh | sh & spinner
success "Tailscale installed"

section "Cleaning up"
rm -rf /tmp/paru
success "Cleaned up build files"

echo -e "${green}🎉 All done! Reboot recommended.${normal}"
