#!/bin/bash

# Git Time Controller Installer
# Install script for global system installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="git-date-modifier"
HOOK_SCRIPT="git-hook.sh"
SETUP_SCRIPT="setup-hooks.sh"

echo -e "${GREEN}Git Date Modifier Installer${NC}"
echo "================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Please run as root (sudo)$NC"
    exit 1
fi

# Check dependencies
echo "Checking dependencies..."
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed${NC}"
    exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Install main script
echo "Installing main script..."
cp "src/$SCRIPT_NAME.sh" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Install hook script
echo "Installing hook scripts..."
cp "src/$HOOK_SCRIPT" "$INSTALL_DIR/"
cp "src/$SETUP_SCRIPT" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$HOOK_SCRIPT"
chmod +x "$INSTALL_DIR/$SETUP_SCRIPT"

# Create symbolic link for easier access
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/gdm"

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  git-date-modifier --date \"2024-01-15 14:30:00\""
echo "  gdm --date \"2 days ago\""
echo ""
echo "To setup hooks in a repository:"
echo "  cd /path/to/your/repo"
echo "  setup-hooks.sh"