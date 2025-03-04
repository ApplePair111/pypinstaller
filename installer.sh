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
    cd /usr/bin
    cat <<EOF pypinstaller
    #!/bin/bash

    set -e  # Exit on error
    
    if [ "$#" -lt 2 ]; then
        echo "Usage: pypinstaller [-dev] {install|remove} <pkgname>"
        exit 1
        fi
    
    # Check if -dev flag is used
    DEBUG=false
    if [ "$1" == "-dev" ]; then
        DEBUG=true
        shift  # Remove -dev from arguments
    fi
    
    ACTION="$1"
    PKG_NAME="$2"
    
    # Get Python binary and version
    PYTHON_BIN=$(which python3)
    PYTHON_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    
    # Find site-packages directory
    SITE_PACKAGES=$(dirname "$PYTHON_BIN")/../lib/python$PYTHON_VERSION/site-packages
    PKG_PATH="$SITE_PACKAGES/$PKG_NAME"
    
    # Debug logging function
    log() {
        if [ "$DEBUG" == true ]; then
            echo "[DEBUG] $1"
        fi
    }
    
    install_package() {
        log "Fetching package info from PyPI for $PKG_NAME..."
    
        # Get package download URL from PyPI
        PACKAGE_URL=$(curl -s "https://pypi.org/pypi/$PKG_NAME/json" | grep -o '"https://files.pythonhosted.org[^"]*' | head -n 1)
    
        if [ -z "$PACKAGE_URL" ]; then
            echo "Error: Package not found on PyPI."
            exit 1
        fi
    
        log "Package URL: $PACKAGE_URL"
    
        # Display loading animation (background process)
        loading() {
            local chars="/-\|"
            while true; do
                for (( i=0; i<${#chars}; i++ )); do
                    printf "\rInstalling %s... [%c]" "$PKG_NAME" "${chars:$i:1}"
                    sleep 0.1
                done
            done
        }
    
        loading &  # Start animation
        LOADING_PID=$!
    
        # Download and extract the package
        TMP_DIR="/tmp/$PKG_NAME"
        mkdir -p "$TMP_DIR"
        log "Downloading package to $TMP_DIR/package.tar.gz..."
        curl -sL "$PACKAGE_URL" -o "$TMP_DIR/package.tar.gz"
    
        log "Extracting package..."
        tar -xzf "$TMP_DIR/package.tar.gz" -C "$TMP_DIR"
    
        # Find the extracted directory
        EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    
        if [ -z "$EXTRACTED_DIR" ]; then
            echo "Error: Extraction failed."
            kill "$LOADING_PID" >/dev/null 2>&1  # Stop loading animation
            exit 1
        fi
    
        log "Extracted directory: $EXTRACTED_DIR"
    
        # Move package to site-packages
        log "Moving package to $SITE_PACKAGES..."
        mv "$EXTRACTED_DIR" "$SITE_PACKAGES"
    
        # Kill loading animation **only if it's still running**
        if ps -p "$LOADING_PID" > /dev/null; then
            kill "$LOADING_PID" >/dev/null 2>&1
        fi
    
        printf "\rInstallation complete!           \n"
    }
    
    remove_package() {
        if [ -d "$PKG_PATH" ]; then
            echo "Removing $PKG_NAME..."
            log "Deleting directory: $PKG_PATH"
            rm -rf "$PKG_PATH"
            echo "$PKG_NAME has been removed."
        else
            echo "Error: Package $PKG_NAME not found in site-packages."
        fi
    }
    
    # Execute action
    case "$ACTION" in
        install)
            install_package
            ;;
        remove)
            remove_package
            ;;
        *)
            echo "Usage: pypinstaller [-dev] {install|remove} <pkgname>"
            exit 1
            ;;
    esac
    EOF


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
