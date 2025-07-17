# Cross-platform install script for Neuron SDK components
# PowerShell version for better Windows compatibility

param(
    [switch]$Force
)

# Confirmation prompt for direct execution (skip if Force flag is used)
if (-not $Force) {
    Write-Host "This script will install Neuron Node Builder components:"
    Write-Host "- neuron-node-builder (Node.js)"
    Write-Host "- neuron-registration (Node.js)"
    Write-Host "- neuron-sdk-websocket-wrapper (Go)"
    Write-Host ""
    Write-Host "Prerequisites will be checked:"
    Write-Host "- Node.js 18+"
    Write-Host "- Go 1.23+"
    Write-Host "- npm and git"
    Write-Host ""
    $response = Read-Host "Continue with installation? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Installation cancelled"
        exit 0
    }
    Write-Host ""
}

# Configuration
$REQUIRED_NODE_VERSION = 18
$REQUIRED_GO_VERSION = "1.23"
$NODE_BUILDER_REPO_URL = "https://github.com/NeuronInnovations/neuron-node-builder.git"
$REGISTRATION_REPO_URL = "https://github.com/NeuronInnovations/neuron-registration.git"
$SDK_REPO_URL = "https://github.com/NeuronInnovations/neuron-sdk-websocket-wrapper.git"
$NODE_BUILDER_INSTALL_DIR = "neuron-node-builder"
$REGISTRATION_INSTALL_DIR = "neuron-registration"
$SDK_INSTALL_DIR = "neuron-sdk-websocket-wrapper"

# Check if command exists
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check Node.js installation and version
function Test-NodeJS {
    Write-Host "Checking Node.js installation..."
    
    if (-not (Test-Command "node")) {
        Write-Error "Node.js is not installed!"
        Write-Host "Please install Node.js from: https://nodejs.org/"
        exit 1
    }
    
    $nodeVersion = node --version
    $versionNumber = $nodeVersion -replace "v", ""
    $majorVersion = [int]($versionNumber -split "\.")[0]
    
    Write-Host "Found Node.js version: $versionNumber"
    
    if ($majorVersion -lt $REQUIRED_NODE_VERSION) {
        Write-Error "Node.js version $REQUIRED_NODE_VERSION or higher is required!"
        Write-Error "Current version: $versionNumber"
        exit 1
    }
    
    Write-Host "Node.js version check passed"
}

# Check npm installation
function Test-NPM {
    Write-Host "Checking npm installation..."
    
    if (-not (Test-Command "npm")) {
        Write-Error "npm is not installed!"
        Write-Host "npm usually comes with Node.js. Please reinstall Node.js."
        exit 1
    }
    
    Write-Host "npm check passed"
}

# Check Go installation and version
function Test-Go {
    Write-Host "Checking Go installation..."
    
    if (-not (Test-Command "go")) {
        Write-Error "Go is not installed!"
        Write-Host "Please install Go from: https://golang.org/dl/"
        exit 1
    }
    
    $goVersionOutput = go version
    $goVersion = ($goVersionOutput -split " ")[2] -replace "go", ""
    
    Write-Host "Found Go version: $goVersion"
    
    # Simple version comparison
    $currentVersion = [Version]$goVersion
    $requiredVersion = [Version]$REQUIRED_GO_VERSION
    
    if ($currentVersion -lt $requiredVersion) {
        Write-Error "Go version $REQUIRED_GO_VERSION or higher is required!"
        Write-Error "Current version: $goVersion"
        exit 1
    }
    
    Write-Host "Go version check passed"
}

# Clone repositories
function Install-Repositories {
    # Clone Node Builder repository
    Write-Host "Cloning neuron-node-builder repository..."
    
    if (Test-Path $NODE_BUILDER_INSTALL_DIR) {
        Write-Host "Directory $NODE_BUILDER_INSTALL_DIR already exists!"
        if (-not $Force) {
            $response = Read-Host "Remove it and continue? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Host "Installation cancelled"
                exit 1
            }
        }
        Remove-Item -Recurse -Force $NODE_BUILDER_INSTALL_DIR
    }
    
    git clone $NODE_BUILDER_REPO_URL $NODE_BUILDER_INSTALL_DIR
    Write-Host "neuron-node-builder repository cloned successfully"
    
    # Clone Registration repository
    Write-Host "Cloning neuron-registration repository..."
    
    if (Test-Path $REGISTRATION_INSTALL_DIR) {
        Write-Host "Directory $REGISTRATION_INSTALL_DIR already exists!"
        if (-not $Force) {
            $response = Read-Host "Remove it and continue? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Host "Installation cancelled"
                exit 1
            }
        }
        Remove-Item -Recurse -Force $REGISTRATION_INSTALL_DIR
    }
    
    git clone $REGISTRATION_REPO_URL $REGISTRATION_INSTALL_DIR
    Write-Host "neuron-registration repository cloned successfully"
    
    # Clone SDK repository
    Write-Host "Cloning neuron-sdk-websocket-wrapper repository..."
    
    if (Test-Path $SDK_INSTALL_DIR) {
        Write-Host "Directory $SDK_INSTALL_DIR already exists!"
        if (-not $Force) {
            $response = Read-Host "Remove it and continue? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Host "Installation cancelled"
                exit 1
            }
        }
        Remove-Item -Recurse -Force $SDK_INSTALL_DIR
    }
    
    git clone $SDK_REPO_URL $SDK_INSTALL_DIR
    Write-Host "neuron-sdk-websocket-wrapper repository cloned successfully"
}

# Setup configuration files
function Set-Config {
    Write-Host "Setting up configuration files..."
    
    # Copy .env.example to .env for neuron-node-builder
    $envExamplePath = "$NODE_BUILDER_INSTALL_DIR\.env.example"
    $envPath = "$NODE_BUILDER_INSTALL_DIR\.env"
    
    if (Test-Path $envExamplePath) {
        Copy-Item $envExamplePath $envPath
        Write-Host "Copied .env.example to .env"
        
        # Update NEURON_SDK_PATH in .env file
        $sdkExecutablePath = "$(Get-Location)\$NODE_BUILDER_INSTALL_DIR\build\bin\neuron-sdk-websocket-wrapper.exe"
        $envContent = Get-Content $envPath
        $neuronSdkPathFound = $false
        
        # Check if NEURON_SDK_PATH exists and update it
        for ($i = 0; $i -lt $envContent.Length; $i++) {
            if ($envContent[$i] -match "^NEURON_SDK_PATH=") {
                $envContent[$i] = "NEURON_SDK_PATH=$sdkExecutablePath"
                $neuronSdkPathFound = $true
                break
            }
        }
        
        if ($neuronSdkPathFound) {
            $envContent | Set-Content $envPath
            Write-Host "Updated NEURON_SDK_PATH in .env"
        } else {
            # Add NEURON_SDK_PATH if it doesn't exist
            Add-Content $envPath "NEURON_SDK_PATH=$sdkExecutablePath"
            Write-Host "Added NEURON_SDK_PATH to .env"
        }
    }
    else {
        Write-Host "Warning: .env.example not found in $NODE_BUILDER_INSTALL_DIR"
    }
}

# Install dependencies
function Install-Dependencies {
    # Install Node Builder dependencies
    Write-Host "Installing Node Builder dependencies..."
    Push-Location $NODE_BUILDER_INSTALL_DIR
    npm install
    Pop-Location
    Write-Host "Node Builder dependencies installed successfully"
    
    # Install Registration dependencies
    Write-Host "Installing Registration dependencies..."
    Push-Location $REGISTRATION_INSTALL_DIR
    npm install
    Pop-Location
    Write-Host "Registration dependencies installed successfully"
    
    # Install SDK dependencies
    Write-Host "Installing SDK dependencies..."
    Push-Location $SDK_INSTALL_DIR
    go mod tidy
    Pop-Location
    Write-Host "SDK dependencies installed successfully"
}

# Build projects
function Build-Projects {
    # Build Node Builder project
    Write-Host "Building Node Builder project..."
    Push-Location $NODE_BUILDER_INSTALL_DIR
    npm run build
    Pop-Location
    Write-Host "Node Builder project built successfully"
    
    # Build Registration project
    Write-Host "Building Registration project..."
    Push-Location $REGISTRATION_INSTALL_DIR
    npm run build
    Pop-Location
    Write-Host "Registration project built successfully"
    
    # Build SDK binary
    Write-Host "Building SDK binary..."
    Push-Location $SDK_INSTALL_DIR
    go build -o neuron-sdk-websocket-wrapper.exe
    Pop-Location
    Write-Host "SDK binary built successfully"
}

# Integrate components
function Integrate-Components {
    # Copy SDK binary to Node Builder project
    Write-Host "Copying SDK binary to Node Builder project..."
    $buildBinPath = "$NODE_BUILDER_INSTALL_DIR\build\bin"
    New-Item -ItemType Directory -Path $buildBinPath -Force | Out-Null
    Copy-Item "$SDK_INSTALL_DIR\neuron-sdk-websocket-wrapper.exe" $buildBinPath
    Write-Host "SDK binary copied to $NODE_BUILDER_INSTALL_DIR\build\bin\"
    
    # Create symlink from Node Builder to Registration
    Write-Host "Creating symlink for Registration..."
    $nodesDir = "$NODE_BUILDER_INSTALL_DIR\neuron\nodes"
    New-Item -ItemType Directory -Path $nodesDir -Force | Out-Null
    
    $sourcePath = "$(Get-Location)\$REGISTRATION_INSTALL_DIR"
    $targetPath = "$nodesDir\neuron-registration"
    
    # Remove existing symlink/directory if it exists
    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Force -Recurse
    }
    
    # Create symlink (requires admin privileges on older Windows versions)
    try {
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
        Write-Host "Symlink created: $targetPath -> $sourcePath"
    }
    catch {
        Write-Host "Admin privileges required for symlink. Creating junction instead..."
        $junctionResult = cmd /c "mklink /J `"$targetPath`" `"$sourcePath`" 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Junction created: $targetPath -> $sourcePath"
        } else {
            Write-Host "Error creating junction: $junctionResult"
            Write-Host "Warning: Link creation failed. Registration may not work properly."
        }
    }
}

# Main installation process
function Main {
    Write-Host "Starting Neuron SDK installation..."
    
    Test-NodeJS
    Test-NPM
    Test-Go
    Install-Repositories
    Set-Config
    Install-Dependencies
    Build-Projects
    Integrate-Components
    
    Write-Host "Installation completed successfully!"
    Write-Host "Repositories installed in:"
    Write-Host "  Node Builder: $(Get-Location)\$NODE_BUILDER_INSTALL_DIR"
    Write-Host "  Registration: $(Get-Location)\$REGISTRATION_INSTALL_DIR"
    Write-Host "  SDK: $(Get-Location)\$SDK_INSTALL_DIR"
    Write-Host ""
    Write-Host "To start the application:"
    Write-Host "  from the $NODE_BUILDER_INSTALL_DIR directory run:"
    Write-Host "  npm run start"
}

# Run main function
Main