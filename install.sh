#!/bin/bash

# Cross-platform install script for neuron-node-builder

set -e  # Exit on any error

# Confirmation prompt for direct execution
echo "This script will install Neuron Node Builder components:"
echo "- neuron-node-builder (Node.js)"
echo "- neuron-js-registration-sdk (Node.js)"
echo "- neuron-sdk-websocket-wrapper (Go)"
echo
echo "Prerequisites will be checked:"
echo "- Node.js 18+"
echo "- Go 1.23+"
echo "- npm and git"
echo
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi
echo

# Configuration
REQUIRED_NODE_VERSION="18"
REQUIRED_GO_VERSION="1.23"
NODE_BUILDER_REPO_URL="https://github.com/NeuronInnovations/neuron-node-builder.git"
REGISTRATION_REPO_URL="https://github.com/NeuronInnovations/neuron-js-registration-sdk.git"
SDK_REPO_URL="https://github.com/NeuronInnovations/neuron-sdk-websocket-wrapper.git"
NODE_BUILDER_INSTALL_DIR="neuron-node-builder"
REGISTRATION_INSTALL_DIR="neuron-js-registration-sdk"
SDK_INSTALL_DIR="neuron-sdk-websocket-wrapper"

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

# Check Go installation and version
check_go() {
    echo "Checking Go installation..."
    
    if ! command_exists go; then
        echo "Error: Go is not installed!"
        echo "Please install Go from: https://golang.org/dl/"
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR_MINOR=$(echo $GO_VERSION | cut -d. -f1,2)
    REQUIRED_MAJOR_MINOR=$(echo $REQUIRED_GO_VERSION | cut -d. -f1,2)
    
    echo "Found Go version: $GO_VERSION"
    
    # Simple version comparison for Go
    if [ "$(printf '%s\n' "$REQUIRED_MAJOR_MINOR" "$GO_MAJOR_MINOR" | sort -V | head -n1)" != "$REQUIRED_MAJOR_MINOR" ]; then
        echo "Error: Go version $REQUIRED_GO_VERSION or higher is required!"
        echo "Current version: $GO_VERSION"
        exit 1
    fi
    
    echo "Go version check passed"
}

# Clone repositories
clone_repositories() {
    # Clone Node Builder repository
    echo "Cloning neuron-node-builder repository..."
    
    if [ -d "$NODE_BUILDER_INSTALL_DIR" ]; then
        echo "Directory $NODE_BUILDER_INSTALL_DIR already exists!"
        read -p "Remove it and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$NODE_BUILDER_INSTALL_DIR"
        else
            echo "Installation cancelled"
            exit 1
        fi
    fi
    
    git clone "$NODE_BUILDER_REPO_URL" "$NODE_BUILDER_INSTALL_DIR"
    echo "Node Builder repository cloned successfully"
    
    # Clone Registration repository
    echo "Cloning neuron-js-registration-sdk repository..."
    
    if [ -d "$REGISTRATION_INSTALL_DIR" ]; then
        echo "Directory $REGISTRATION_INSTALL_DIR already exists!"
        read -p "Remove it and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$REGISTRATION_INSTALL_DIR"
        else
            echo "Installation cancelled"
            exit 1
        fi
    fi
    
    git clone "$REGISTRATION_REPO_URL" "$REGISTRATION_INSTALL_DIR"
    echo "Registration SDK repository cloned successfully"

    # Clone SDK repository
    echo "Cloning neuron-sdk-websocket-wrapper repository..."
    
    if [ -d "$SDK_INSTALL_DIR" ]; then
        echo "Directory $SDK_INSTALL_DIR already exists!"
        read -p "Remove it and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$SDK_INSTALL_DIR"
        else
            echo "Installation cancelled"
            exit 1
        fi
    fi
    
    git clone "$SDK_REPO_URL" "$SDK_INSTALL_DIR"
    echo "SDK repository cloned successfully"
}

# Setup configuration files
setup_config() {
    echo "Setting up configuration files..."
    
    # Create .neuron-node-builder directory in user's home directory
    NEURON_USER_PATH="$HOME/.neuron-node-builder"
    if [ ! -d "$NEURON_USER_PATH" ]; then
        mkdir -p "$NEURON_USER_PATH"
        echo "Created user directory: $NEURON_USER_PATH"
    else
        echo "User directory already exists: $NEURON_USER_PATH"
    fi
    
    # Copy .env.example to .env for neuron-node-builder
    if [ -f "$NODE_BUILDER_INSTALL_DIR/.env.example" ]; then
        cp "$NODE_BUILDER_INSTALL_DIR/.env.example" "$NODE_BUILDER_INSTALL_DIR/.env"
        echo "Copied .env.example to .env"
        
        # Update NEURON_SDK_PATH in .env file
        SDK_EXECUTABLE_PATH="$(pwd)/$NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper"
        if grep -q "NEURON_SDK_PATH=" "$NODE_BUILDER_INSTALL_DIR/.env"; then
            # Update existing NEURON_SDK_PATH
            sed -i.bak "s|NEURON_SDK_PATH=.*|NEURON_SDK_PATH=$SDK_EXECUTABLE_PATH|" "$NODE_BUILDER_INSTALL_DIR/.env" && rm "$NODE_BUILDER_INSTALL_DIR/.env.bak"
            echo "Updated NEURON_SDK_PATH in .env"
        else
            # Add NEURON_SDK_PATH if it doesn't exist
            echo "NEURON_SDK_PATH=$SDK_EXECUTABLE_PATH" >> "$NODE_BUILDER_INSTALL_DIR/.env"
            echo "Added NEURON_SDK_PATH to .env"
        fi
        
        # Update or add NEURON_USER_PATH in .env file
        if grep -q "NEURON_USER_PATH=" "$NODE_BUILDER_INSTALL_DIR/.env"; then
            # Update existing NEURON_USER_PATH
            sed -i.bak "s|NEURON_USER_PATH=.*|NEURON_USER_PATH=$NEURON_USER_PATH|" "$NODE_BUILDER_INSTALL_DIR/.env" && rm "$NODE_BUILDER_INSTALL_DIR/.env.bak"
            echo "Updated NEURON_USER_PATH in .env"
        else
            # Add NEURON_USER_PATH if it doesn't exist
            echo "NEURON_USER_PATH=$NEURON_USER_PATH" >> "$NODE_BUILDER_INSTALL_DIR/.env"
            echo "Added NEURON_USER_PATH to .env"
        fi
    else
        echo "Warning: .env.example not found in $NODE_BUILDER_INSTALL_DIR"
    fi
    
    # Rename example.flows.json to flows.json if it exists
    EXAMPLE_FLOWS_PATH="$NODE_BUILDER_INSTALL_DIR/neuron/userdir/example.flows.json"
    FLOWS_PATH="$NODE_BUILDER_INSTALL_DIR/neuron/userdir/flows.json"
    
    if [ -f "$EXAMPLE_FLOWS_PATH" ]; then
        if [ -f "$FLOWS_PATH" ]; then
            echo "flows.json already exists, skipping rename of example.flows.json"
        else
            mv "$EXAMPLE_FLOWS_PATH" "$FLOWS_PATH"
            echo "Renamed example.flows.json to flows.json"
        fi
    else
        echo "Warning: example.flows.json not found in neuron/userdir/"
    fi
}

# Install dependencies
install_dependencies() {
    # Install Node Builder dependencies
    echo "Installing Node Builder dependencies..."
    cd "$NODE_BUILDER_INSTALL_DIR"
    npm install
    cd ..
    echo "Node Builder dependencies installed successfully"
    
    # Install Registration dependencies
    echo "Installing Registration dependencies..."
    cd "$REGISTRATION_INSTALL_DIR"
    npm install
    cd ..
    echo "Registration dependencies installed successfully"
    
    # Install SDK dependencies
    echo "Installing SDK dependencies..."
    cd "$SDK_INSTALL_DIR"
    go mod tidy
    cd ..
    echo "SDK dependencies installed successfully"
}

# Build projects
build_projects() {
    # Build Node Builder project
    echo "Building Node Builder project..."
    cd "$NODE_BUILDER_INSTALL_DIR"
    npm run build
    cd ..
    echo "Node Builder project built successfully"
    
    # Build Registration project
    echo "Building Registration project..."
    cd "$REGISTRATION_INSTALL_DIR"
    npm run build
    cd ..
    echo "Registration project built successfully"
    
    # Build SDK binary
    echo "Building SDK binary..."
    cd "$SDK_INSTALL_DIR"
    go build -o neuron-sdk-websocket-wrapper
    cd ..
    echo "SDK binary built successfully"
}

# Integrate components
integrate_components() {
    # Create symlink for SDK binary to Node Builder project
    echo "Creating symlink for SDK binary to Node Builder project..."
    mkdir -p "$NODE_BUILDER_INSTALL_DIR/build/bin"
    
    # Remove existing file/symlink if it exists
    if [ -f "$NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper" ] || [ -L "$NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper" ]; then
        rm "$NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper"
    fi
    
    # Create symlink for the binary
    ln -s "$(pwd)/$SDK_INSTALL_DIR/neuron-sdk-websocket-wrapper" "$NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper"
    echo "SDK binary symlink created: $NODE_BUILDER_INSTALL_DIR/build/bin/neuron-sdk-websocket-wrapper -> $SDK_INSTALL_DIR/neuron-sdk-websocket-wrapper"
    
    # Create symlink from Node Builder to Registration
    echo "Creating symlink for Registration..."
    mkdir -p "$NODE_BUILDER_INSTALL_DIR/neuron/nodes"
    ln -sf "$(pwd)/$REGISTRATION_INSTALL_DIR" "$NODE_BUILDER_INSTALL_DIR/neuron/nodes/neuron-js-registration-sdk"
    echo "Symlink created: $NODE_BUILDER_INSTALL_DIR/neuron/nodes/neuron-js-registration-sdk -> $REGISTRATION_INSTALL_DIR"
}

# Main installation process
main() {
    echo "Starting Neuron SDK installation..."
    
    check_nodejs
    check_npm
    check_go
    clone_repositories
    setup_config
    install_dependencies
    build_projects
    integrate_components
    
    echo "Installation completed successfully!"
    echo "Repositories installed in:"
    echo "  Node Builder: $(pwd)/$NODE_BUILDER_INSTALL_DIR"
    echo "  Registration: $(pwd)/$REGISTRATION_INSTALL_DIR"
    echo "  SDK: $(pwd)/$SDK_INSTALL_DIR"
    echo
    echo "To start the application:"
    echo "  from the  $NODE_BUILDER_INSTALL_DIR directory run:"
    echo "  npm run start"
}

main "$@"