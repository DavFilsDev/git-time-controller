#!/bin/bash

# Git Date Modifier Uninstaller

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="git-date-modifier"

echo -e "${YELLOW}Git Date Modifier Uninstaller${NC}"
echo "=================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Please run as root (sudo)$NC"
    exit 1
fi

echo "Removing installed files..."

# Remove main script
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm "$INSTALL_DIR/$SCRIPT_NAME"
    echo "Removed: $INSTALL_DIR/$SCRIPT_NAME"
fi

# Remove symbolic link
if [ -L "$INSTALL_DIR/gdm" ]; then
    rm "$INSTALL_DIR/gdm"
    echo "Removed symbolic link: $INSTALL_DIR/gdm"
fi

# Remove hook scripts
if [ -f "$INSTALL_DIR/git-hook.sh" ]; then
    rm "$INSTALL_DIR/git-hook.sh"
    echo "Removed: $INSTALL_DIR/git-hook.sh"
fi

if [ -f "$INSTALL_DIR/setup-hooks.sh" ]; then
    rm "$INSTALL_DIR/setup-hooks.sh"
    echo "Removed: $INSTALL_DIR/setup-hooks.sh"
fi

echo -e "${GREEN}Uninstallation complete!${NC}"