# Install Script

Cross-platform installation script for Neuron SDK components.

## Prerequisites

- Node.js 18 or higher
- npm (comes with Node.js)
- Go 1.23 or higher
- git

## Quick Install (One-liner)

### Windows
```powershell
iwr -useb https://raw.githubusercontent.com/NeuronInnovations/neuron-node-builder-installer/main/install.ps1 | iex
```

**Note**: If you get an execution policy error, use one of these alternatives:
```powershell
# Option 1: Bypass execution policy for this session
powershell -ExecutionPolicy Bypass -File install.ps1

# Option 2: Run directly with bypass
powershell -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/NeuronInnovations/neuron-node-builder-installer/main/install.ps1 | iex"
```

### Linux & macOS
```bash
curl -fsSL https://raw.githubusercontent.com/NeuronInnovations/neuron-node-builder-installer/main/install.sh -o install.sh ; chmod +x install.sh ; ./install.sh
```

## Manual Install

### Windows (Recommended)

```powershell
.\install.ps1
```

Or with force flag to skip prompts:
```powershell
.\install.ps1 -Force
```

### Linux & macOS

```bash
chmod +x install.sh
./install.sh
```

### Windows (Alternative - requires Git Bash or WSL)

```bash
chmod +x install.sh
./install.sh
```

## What it does

This installer sets up a portable Neuron Node-RED environment by building its components from source on your machine. It performs the following steps:

1.  **Checks Prerequisites:** Verifies that Node.js (v18+), npm, Go (v1.23+), and Git are installed on your system.
2.  **Clones Repositories:** Downloads the source code for `neuron-node-builder` (a Node.js project) and optionally `neuron-sdk-websocket-wrapper` (a Go project) from their respective GitHub repositories.
3.  **Installs Dependencies:** Installs the necessary project dependencies using `npm install` for Node.js projects and `go mod tidy` for Go projects.
4.  **Builds Projects:** Compiles the `neuron-node-builder` using `npm run build` and, if selected, builds the Go SDK into an executable using `go build`.
5.  **Integrates Components:** Configures the environment by setting up `.env` and `flows.json` files. If the Go SDK was built, it copies or symlinks its executable into the `neuron-node-builder/build/bin` directory, making it accessible to the Node-RED environment.

The "one-click install" refers to the ease of running this installation script, and "portable" describes the resulting self-contained Node-RED environment.

## Script Overview

This installer utilizes three main scripts, each with a distinct role:

*   **`install.js` (Node.js script):** This is the core logic of the installer. Written in JavaScript, it performs the main installation steps: checking Go version, cloning repositories, setting up configuration, installing dependencies, building projects, and integrating components. It's designed to be cross-platform.
*   **`install.sh` (Bash script):** This is a shell wrapper specifically for macOS and Linux environments. Its primary role is to prepare the environment (e.g., checking Node.js/npm, downloading `install.js` if needed) and then execute `install.js`. It also handles starting the installed application.
*   **`install.ps1` (PowerShell script):** This is a shell wrapper specifically for Windows environments. Similar to `install.sh`, it prepares the Windows environment, executes `install.js`, and handles post-installation application launch, but uses PowerShell commands.

In essence, `install.js` contains the detailed installation instructions, while `install.sh` and `install.ps1` are platform-specific launchers that ensure `install.js` runs correctly on their respective operating systems.

## Installer vs. Official Releases

This installer is designed to set up a Neuron Node-RED environment by building its components directly from source on your local machine. This approach is particularly useful for:

*   **Developers:** Who wish to contribute to the Neuron Node Builder or Neuron SDK, allowing for local development, customization, and debugging.
*   **Specific Build Requirements:** Users who need to compile with particular flags, versions of dependencies, or in environments with restricted internet access.
*   **Transparency:** Users who prefer to build software from source for verification and control.

For official, pre-built, signed, and notarized releases of the Neuron Node Builder, please refer to the [Neuron Node Builder GitHub Releases page](https://github.com/NeuronInnovations/neuron-node-builder/releases). These official releases are generated via a comprehensive GitHub Actions workflow that handles packaging, code signing, and notarization for various platforms.

## Notes on Auto-Updates

The `releases.json` file in this repository is consumed by the `neuron/services/NeuronUpdateService.js` component within the `neuron-node-builder` repository. This service uses the information in `releases.json` to determine when to trigger auto-updates for the Neuron Node-RED environment. For the auto-update mechanism to function correctly, `releases.json` must contain valid release information, including download URLs for different platforms and architectures.

## Troubleshooting

- **Node.js not found**: Install from [nodejs.org](https://nodejs.org/)
- **Go not found**: Install from [golang.org/dl](https://golang.org/dl/)
- **Permission denied**: On Linux/Mac, make sure the script is executable with `chmod +x install.sh`
- **Git not found**: The script will fail with a clear error if git isn't installed
