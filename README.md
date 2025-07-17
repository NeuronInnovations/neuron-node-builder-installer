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
iwr -useb https://raw.githubusercontent.com/your-org/your-repo/main/install.ps1 | iex
```

**Note**: If you get an execution policy error, use one of these alternatives:
```powershell
# Option 1: Bypass execution policy for this session
powershell -ExecutionPolicy Bypass -File install.ps1

# Option 2: Run directly with bypass
powershell -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/your-org/your-repo/main/install.ps1 | iex"
```

### Linux & macOS
```bash
curl -fsSL https://raw.githubusercontent.com/your-org/your-repo/main/install.sh | bash
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

1. Checks Node.js version (requires 18+)
2. Verifies npm is installed
3. Checks Go version (requires 1.23+)
4. Clones three repositories:
   - neuron-node-builder (Node.js)
   - neuron-sdk-websocket-wrapper (Go)
   - neuron-registration (Node.js)
5. Installs dependencies for all projects
6. Builds the Go binary
7. Copies the binary to `neuron-node-builder/build/bin/`
8. Creates a symlink from `neuron-node-builder/neuron/nodes/neuron-registration` to the `neuron-registration` directory

## Troubleshooting

- **Node.js not found**: Install from [nodejs.org](https://nodejs.org/)
- **Go not found**: Install from [golang.org/dl](https://golang.org/dl/)
- **Permission denied**: On Linux/Mac, make sure the script is executable with `chmod +x install.sh`
- **Git not found**: The script will fail with a clear error if git isn't installed