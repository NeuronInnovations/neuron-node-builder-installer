#!/bin/bash

# Neuron Node Builder Installer
# Bash version for Unix-like systems

set -e  # Exit on any error

# Configuration
REQUIRED_NODE_VERSION="18"
INSTALL_JS_URL="https://raw.githubusercontent.com/NeuronInnovations/neuron-node-builder-installer/refs/heads/main/install.js"
INSTALL_JS_FILE="install.js"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js installation and version
check_nodejs() {
    echo "Checking Node.js installation..."
    
    if ! command_exists node; then
        echo "Error: Node.js is not installed!"
        echo "Please install Node.js from: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | sed 's/v//')
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
    
    echo "Found Node.js version: $NODE_VERSION"
    
    if [ "$MAJOR_VERSION" -lt "$REQUIRED_NODE_VERSION" ]; then
        echo "Error: Node.js version $REQUIRED_NODE_VERSION or higher is required!"
        echo "Current version: $NODE_VERSION"
        exit 1
    fi
    
    echo "Node.js version check passed"
}

# Check npm installation
check_npm() {
    echo "Checking npm installation..."
    
    if ! command_exists npm; then
        echo "Error: npm is not installed!"
        echo "npm usually comes with Node.js. Please reinstall Node.js."
        exit 1
    fi
    
    echo "npm check passed"
}

# Download install.js
download_install_script() {
    echo "Downloading install script..."
    
    if command_exists curl; then
        curl -fsSL "$INSTALL_JS_URL" -o "$INSTALL_JS_FILE"
    elif command_exists wget; then
        wget -q "$INSTALL_JS_URL" -O "$INSTALL_JS_FILE"
    else
        echo "Error: Neither curl nor wget is available for downloading the install script"
        echo "Please install curl or wget and try again"
        exit 1
    fi
    
    echo "Install script downloaded successfully"
}

# Run install.js
run_installation() {
    echo "Running installation script..."
    
    # Check if force flag was passed to this script
    if [[ "$*" == *"--force"* ]] || [[ "$*" == *"-f"* ]]; then
        node "$INSTALL_JS_FILE" --force
    else
        node "$INSTALL_JS_FILE"
    fi
}

# Ask if user wants to start the application
ask_start_application() {
    # Check if force flag was passed
    if [[ "$*" == *"--force"* ]] || [[ "$*" == *"-f"* ]]; then
        return 0  # true
    fi
    
    echo
    read -p "Would you like to start the Neuron Node Builder now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

# Start the application
start_application() {
    echo "Starting Neuron Node Builder..."
    
    if [ -d "neuron-node-builder" ]; then
        cd "neuron-node-builder"
        npm run start
    else
        echo "Error: neuron-node-builder directory not found. Installation may have failed."
        exit 1
    fi
}

# Main installation process
main() {
    echo "Neuron Node Builder Installer"
    echo "=============================="
    echo
    
    check_nodejs
    check_npm
    download_install_script
    run_installation "$@"
    
    # Clean up downloaded script
    if [ -f "$INSTALL_JS_FILE" ]; then
        rm "$INSTALL_JS_FILE"
    fi
    
    # Ask if user wants to start the application
    if ask_start_application "$@"; then
        start_application
    else
        echo
        echo "To start, cd into the 'neuron-node-builder' directory and run 'npm run start'"
    fi
}

main "$@"