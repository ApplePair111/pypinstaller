#!/bin/bash

set -e  # Exit on error

PYPINSTALLER_PATH="/usr/bin/pypinstaller"

install_pypinstaller() {
    echo "Installing pypinstaller..."

    # Ensure script is run as root
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)."
        exit 1
    fi

    # Copy the main script to /usr/bin/
    cp ./pypinstaller /usr/bin

    echo "pypinstaller has been installed successfully!"
    echo "Usage: pypinstaller install <pkgname>"
}

remove_pypinstaller() {
    echo "Removing pypinstaller..."

    # Ensure script is run as root
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)."
        exit 1
    fi

    # Remove the command from /usr/bin/
    if [ -f "$PYPINSTALLER_PATH" ]; then
        rm -f "$PYPINSTALLER_PATH"
        echo "pypinstaller has been removed."
    else
        echo "pypinstaller is not installed."
    fi
}

# Handle arguments
if [ "$1" == "install" ]; then
    install_pypinstaller
elif [ "$1" == "remove" ]; then
    remove_pypinstaller
else
    echo "Usage: $0 {install|remove}"
    exit 1
fi
