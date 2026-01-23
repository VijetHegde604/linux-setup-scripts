#!/bin/bash

# Requirements: curl, ImageMagick (for icon processing)
# Usage: ./create-webapp.sh

echo "--- Web App Creator ---"

CHOSEN_BROWSER="brave"

# 1. Collect User Input
read -p "Enter App Name (e.g., ChatGPT): " APP_NAME
read -p "Enter URL (e.g., https://chatgpt.com): " APP_URL
read -p "Enter Icon URL (Optional, press enter for default, prefer png!): " ICON_URL

# Create a sanitized slug for filenames and window classes
APP_SLUG=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
ICON_PATH="$HOME/.local/share/icons/$APP_SLUG.png"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_SLUG.desktop"

# 2. Handle Icon
mkdir -p "$HOME/.local/share/icons"

if [ -z "$ICON_URL" ]; then
  # Default to a generic web icon if none provided
  echo "No icon provided, using default."
  ICON_VALUE="web-browser"
else
  echo "Downloading icon..."
  curl -L -s "$ICON_URL" -o "$ICON_PATH"
  ICON_VALUE="$ICON_PATH"
fi

# 3. Create the .desktop file
cat <<EOF >"$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Web Application launched via $CHOSEN_BROWSER
Exec=$CHOSEN_BROWSER --app=$APP_URL --class=webapp-$APP_SLUG
Icon=$ICON_VALUE
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=webapp-$APP_SLUG
EOF

chmod +x "$DESKTOP_FILE"

echo "----------------------------------------"
echo "SUCCESS: $APP_NAME has been created!"
echo "Desktop File: $DESKTOP_FILE"
echo "----------------------------------------"
