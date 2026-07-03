#!/usr/bin/env bash
set -euo pipefail

echo "--- Web App Creator ---"

# -------------------------------
# Detect default browser command
# -------------------------------
get_default_browser() {
  local desktop desktop_file exec

  desktop="$(xdg-mime query default x-scheme-handler/http 2>/dev/null || true)"

  if [ -z "$desktop" ]; then
    desktop="$(xdg-settings get default-web-browser 2>/dev/null || true)"
  fi

  [ -n "$desktop" ] || {
    echo "Error: Could not detect default browser (.desktop)"
    exit 1
  }

  desktop_file="$(find \
    ~/.local/share/applications \
    /usr/share/applications \
    /run/current-system/sw/share/applications \
    -name "$desktop" 2>/dev/null | head -n1)"

  [ -f "$desktop_file" ] || {
    echo "Error: Could not find .desktop file for $desktop"
    exit 1
  }

  exec="$(grep -E '^Exec=' "$desktop_file" | head -n1 | cut -d= -f2)"

  # Remove placeholders (%U, %u, etc.)
  exec="${exec//%u/}"
  exec="${exec//%U/}"
  exec="${exec//%f/}"
  exec="${exec//%F/}"

  # Extract only the binary (remove extra flags)
  exec="$(echo "$exec" | awk '{print $1}')"

  echo "$exec"
}

CHOSEN_BROWSER="$(get_default_browser)"
echo "Using browser: $CHOSEN_BROWSER"

# -------------------------------
# Collect User Input
# -------------------------------
read -rp "Enter App Name (e.g., ChatGPT): " APP_NAME
read -rp "Enter URL (e.g., https://chatgpt.com): " APP_URL
read -rp "Enter Icon URL (Optional, press enter to auto-fetch from dashboard-icons): " ICON_URL

# Validate input
[ -n "$APP_NAME" ] || { echo "App name required"; exit 1; }
[ -n "$APP_URL" ] || { echo "URL required"; exit 1; }

# -------------------------------
# Prepare paths
# -------------------------------
APP_SLUG="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"

ICON_DIR="$HOME/.local/share/icons"
APP_DIR="$HOME/.local/share/applications"

ICON_PATH="$ICON_DIR/$APP_SLUG.png"
DESKTOP_FILE="$APP_DIR/$APP_SLUG.desktop"

mkdir -p "$ICON_DIR" "$APP_DIR"

# -------------------------------
# Handle Icon
# -------------------------------
if [ -z "$ICON_URL" ]; then
  echo "No icon URL provided. Attempting auto-fetch from dashboard-icons..."

  # Construct URL for walkxcode/dashboard-icons using the app slug
  DASHBOARD_ICON_URL="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/${APP_SLUG}.png"

  if curl -L --fail --silent "$DASHBOARD_ICON_URL" -o "$ICON_PATH"; then
    echo "Successfully fetched icon for '$APP_SLUG' from dashboard-icons."
    ICON_VALUE="$ICON_PATH"
  else
    echo "Warning: Icon not found in dashboard-icons for '$APP_SLUG'. Using default."
    ICON_VALUE="web-browser"
    rm -f "$ICON_PATH" # Clean up any empty files left by curl
  fi
else
  echo "Downloading user-provided icon..."
  if curl -L --fail --silent --show-error "$ICON_URL" -o "$ICON_PATH"; then
    ICON_VALUE="$ICON_PATH"
  else
    echo "Warning: Failed to download provided icon, using default."
    ICON_VALUE="web-browser"
    rm -f "$ICON_PATH"
  fi
fi

# -------------------------------
# Determine browser flags
# -------------------------------
# Assume Chromium-based (Helium, Brave, Chrome, etc.)
APP_FLAG="--app=$APP_URL"

# -------------------------------
# Create .desktop file
# -------------------------------
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Web App ($APP_URL)
Exec=$CHOSEN_BROWSER $APP_FLAG --class=webapp-$APP_SLUG
Icon=$ICON_VALUE
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=webapp-$APP_SLUG
EOF

chmod +x "$DESKTOP_FILE"

# -------------------------------
# Update desktop database (optional)
# -------------------------------
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

# -------------------------------
# Done
# -------------------------------
echo "----------------------------------------"
echo "SUCCESS: $APP_NAME created!"
echo "Browser : $CHOSEN_BROWSER"
echo "File    : $DESKTOP_FILE"
if [[ "$ICON_VALUE" != "web-browser" ]]; then
  echo "Icon    : $ICON_VALUE"
fi
echo "----------------------------------------"
