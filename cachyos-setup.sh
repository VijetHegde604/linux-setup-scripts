#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Colors for UI
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

print_header() { echo -e "${CYAN}==> $1${RESET}"; }
print_ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
print_err() { echo -e "${RED}[ERR]${RESET} $1"; }

# Check dependencies
if ! command -v curl &> /dev/null; then
    print_err "curl is required but not installed. Please install it."
    exit 1
fi

# The browser to use (must support Chromium's --app flag)
CHOSEN_BROWSER="brave-browser"

# Fallback check if brave-browser isn't the exact command name
if ! command -v "$CHOSEN_BROWSER" &> /dev/null; then
    if command -v brave &> /dev/null; then CHOSEN_BROWSER="brave";
    elif command -v google-chrome &> /dev/null; then CHOSEN_BROWSER="google-chrome";
    elif command -v chromium &> /dev/null; then CHOSEN_BROWSER="chromium";
    else
        print_warn "Brave not found. The generated file may need manual tweaking for your specific browser."
    fi
fi

clear
print_header "Web App Creator (PWA)"

# 1. Collect User Input
read -p "Enter App Name (e.g., Jellyfin): " APP_NAME
if [[ -z "${APP_NAME// /}" ]]; then
    print_err "App Name cannot be empty."
    exit 1
fi

read -p "Enter URL (e.g., 192.168.1.100:8096): " APP_URL
if [[ -z "${APP_URL// /}" ]]; then
    print_err "URL cannot be empty."
    exit 1
fi

# Auto-fix URL if http(s):// is missing
if [[ ! "$APP_URL" =~ ^https?:// ]]; then
    APP_URL="http://$APP_URL" # Defaulting to http for local IPs, change to https if needed
fi

read -p "Enter custom Icon URL (Leave blank to auto-fetch from Dashboard Icons): " ICON_URL

# 2. Setup Paths & Slugs
# Create sanitized slug (lowercase, replace non-alphanumeric with dashes, trim edges)
APP_SLUG=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')

ICON_DIR="$HOME/.local/share/icons"
APP_DIR="$HOME/.local/share/applications"
ICON_PATH="$ICON_DIR/$APP_SLUG.png"
DESKTOP_FILE="$APP_DIR/$APP_SLUG.desktop"

mkdir -p "$ICON_DIR"
mkdir -p "$APP_DIR"

# 3. Handle Icon Download
if [[ -z "${ICON_URL// /}" ]]; then
    print_ok "No icon provided. Attempting to fetch from Dashboard Icons..."

    # Try fetching from walkxcode/dashboard-icons via jsDelivr CDN
    # -s: silent, -f: fail on HTTP errors (like 404), -L: follow redirects
    DASHBOARD_ICON_URL="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/${APP_SLUG}.png"

    if curl -sfL "$DASHBOARD_ICON_URL" -o "$ICON_PATH"; then
        ICON_VALUE="$ICON_PATH"
        print_ok "Dashboard icon fetched successfully!"
    else
        print_warn "Icon not found in Dashboard Icons. Falling back to website favicon..."

        # Extract domain from URL for the favicon API
        DOMAIN=$(echo "$APP_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        AUTO_ICON_URL="https://s2.googleusercontent.com/s2/favicons?domain=${DOMAIN}&sz=128"

        if curl -sL "$AUTO_ICON_URL" -o "$ICON_PATH"; then
            ICON_VALUE="$ICON_PATH"
            print_ok "Website favicon fetched successfully."
        else
            print_warn "Failed to fetch any icon. Using default web browser icon."
            ICON_VALUE="web-browser"
        fi
    fi
else
    print_ok "Downloading custom icon..."
    if curl -sL "$ICON_URL" -o "$ICON_PATH"; then
        ICON_VALUE="$ICON_PATH"
    else
        print_warn "Failed to download custom icon. Using default."
        ICON_VALUE="web-browser"
    fi
fi

# 4. Create the .desktop file
print_ok "Creating desktop entry..."
cat <<EOF >"$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Web Application launched via $CHOSEN_BROWSER
Exec=$CHOSEN_BROWSER --app="$APP_URL" --class=webapp-$APP_SLUG
Icon=$ICON_VALUE
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=webapp-$APP_SLUG
EOF

chmod +x "$DESKTOP_FILE"

# 5. Refresh Desktop Database (so it appears in launchers immediately)
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$APP_DIR" &> /dev/null || true
fi

echo
print_header "SUCCESS: $APP_NAME has been created!"
echo "Launcher: $DESKTOP_FILE"
echo "Icon:     $ICON_VALUE"
echo
