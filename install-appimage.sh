#!/bin/bash

# Best Practice: Use set -e to exit immediately if a command exits with a non-zero status.
set -e

# XDG Standards for user-specific installations
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# Ensure directories exist
mkdir -p "$INSTALL_DIR"
mkdir -p "$DESKTOP_DIR"

echo "--- AppImage Installer ---"

# 1. Input Source
read -e -p "Enter path to .AppImage file: " SOURCE_PATH
SOURCE_PATH="${SOURCE_PATH/#\~/$HOME}" # Expand tilde if present

if [[ ! -f "$SOURCE_PATH" ]]; then
  echo "Error: File not found at $SOURCE_PATH"
  exit 1
fi

# 2. Input Custom Name (CLI Alias)
read -p "Enter custom binary name (no spaces, e.g., myapp): " BIN_NAME
TARGET_PATH="$INSTALL_DIR/$BIN_NAME"

if [[ -f "$TARGET_PATH" ]]; then
  read -p "Warning: $TARGET_PATH exists. Overwrite? (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborting."
    exit 0
  fi
fi

# 3. Input Display Name
read -p "Enter Application Display Name (e.g., My App): " DISPLAY_NAME

# 4. Input Icon (Optional)
read -e -p "Enter path to icon file (optional, press Enter to skip): " ICON_PATH
ICON_PATH="${ICON_PATH/#\~/$HOME}"

# --- Execution ---

echo "Installing binary to $TARGET_PATH..."
cp "$SOURCE_PATH" "$TARGET_PATH"
chmod +x "$TARGET_PATH"

echo "Generating .desktop entry..."
DESKTOP_FILE="$DESKTOP_DIR/$BIN_NAME.desktop"

# Create .desktop file
# Note: Exec path uses absolute path to ensure launching works regardless of shell env
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$DISPLAY_NAME
Exec=$TARGET_PATH
Terminal=false
Categories=Utility;
EOF

# Append Icon field if provided
if [[ -n "$ICON_PATH" && -f "$ICON_PATH" ]]; then
  echo "Icon=$ICON_PATH" >> "$DESKTOP_FILE"
fi

# Update desktop database to refresh app launcher immediatey
if command -v update-desktop-database &> /dev/null; then
  update-desktop-database "$DESKTOP_DIR"
fi

echo "Success! installed as '$BIN_NAME'."
echo "Desktop file created at: $DESKTOP_FILE"
