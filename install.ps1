# Neuron Node Builder Installer
# PowerShell version for Windows

param(
    [switch]$Force
)

# Configuration
$REQUIRED_NODE_VERSION = 18
$INSTALL_JS_URL = "https://raw.githubusercontent.com/NeuronInnovations/neuron-node-builder-installer/refs/heads/main/install.js"
$INSTALL_JS_FILE = "install.js"

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

# Download install.js
function Get-InstallScript {
    Write-Host "Downloading install script..."
    
    try {
        Invoke-WebRequest -Uri $INSTALL_JS_URL -OutFile $INSTALL_JS_FILE
        Write-Host "Install script downloaded successfully"
    }
    catch {
        Write-Error "Failed to download install script from $INSTALL_JS_URL"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Run install.js
function Start-Installation {
    Write-Host "Running installation script..."
    
    try {
        if ($Force) {
            node $INSTALL_JS_FILE --force
        } else {
            node $INSTALL_JS_FILE
        }
    }
    catch {
        Write-Error "Installation script failed"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Ask if user wants to start the application
function Ask-StartApplication {
    if ($Force) {
        return $true
    }
    
    Write-Host ""
    $response = Read-Host "Would you like to start the Neuron Node Builder now? (y/N)"
    return ($response -eq "y" -or $response -eq "Y")
}

# Start the application
function Start-Application {
    Write-Host "Starting Neuron Node Builder..."
    
    if (Test-Path "neuron-node-builder") {
        Push-Location "neuron-node-builder"
        try {
            npm run start
        }
        catch {
            Write-Error "Failed to start application"
            Write-Error $_.Exception.Message
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Error "neuron-node-builder directory not found. Installation may have failed."
        exit 1
    }
}

# Main installation process
function Main {
    Write-Host "Neuron Node Builder Installer"
    Write-Host "=============================="
    Write-Host ""
    
    Test-NodeJS
    Test-NPM
    Get-InstallScript
    Start-Installation
    
    # Clean up downloaded script
    if (Test-Path $INSTALL_JS_FILE) {
        Remove-Item $INSTALL_JS_FILE -Force
    }
    
    # Ask if user wants to start the application
    if (Ask-StartApplication) {
        Start-Application
    } else {
        Write-Host ""
        Write-Host "To start, cd into the 'neuron-node-builder' directory and run 'npm run start'"
    }
}

# Run main function
Main