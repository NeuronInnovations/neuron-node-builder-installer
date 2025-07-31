#!/usr/bin/env node

/**
 * Cross-platform install script for Neuron SDK components
 * Node.js version combining PowerShell and Bash functionality
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');
const os = require('os');

// Configuration
const CONFIG = {
    REQUIRED_GO_VERSION: '1.23',
    NODE_BUILDER_REPO_URL: 'https://github.com/NeuronInnovations/neuron-node-builder.git',
    SDK_REPO_URL: 'https://github.com/NeuronInnovations/neuron-sdk-websocket-wrapper.git',
    NODE_BUILDER_INSTALL_DIR: 'neuron-node-builder',
    SDK_INSTALL_DIR: 'neuron-sdk-websocket-wrapper'
};

const isWindows = os.platform() === 'win32';
const forceFlag = process.argv.includes('--force') || process.argv.includes('-f');
let installSDK = false;

// Utility functions
function log(message) {
    console.log(message);
}

function error(message) {
    console.error(`Error: ${message}`);
}

function commandExists(command) {
    try {
        execSync(`${isWindows ? 'where' : 'which'} ${command}`, { stdio: 'ignore' });
        return true;
    } catch {
        return false;
    }
}

function askQuestion(question) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer);
        });
    });
}

function removeDirectory(dirPath) {
    if (fs.existsSync(dirPath)) {
        fs.rmSync(dirPath, { recursive: true, force: true });
    }
}

function createDirectory(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}

function executeCommand(command, cwd = process.cwd()) {
    try {
        execSync(command, { cwd, stdio: 'inherit' });
    } catch (error) {
        throw new Error(`Command failed: ${command}`);
    }
}

// Version comparison utility
function compareVersions(version1, version2) {
    const v1parts = version1.split('.').map(Number);
    const v2parts = version2.split('.').map(Number);

    for (let i = 0; i < Math.max(v1parts.length, v2parts.length); i++) {
        const v1part = v1parts[i] || 0;
        const v2part = v2parts[i] || 0;

        if (v1part < v2part) return -1;
        if (v1part > v2part) return 1;
    }
    return 0;
}

// Check functions
async function checkGo() {
    log('Checking Go installation...');

    if (!commandExists('go')) {
        error('Go is not installed!');
        log('Please install Go from: https://golang.org/dl/');
        process.exit(1);
    }

    const goVersionOutput = execSync('go version', { encoding: 'utf8' }).trim();
    const goVersion = goVersionOutput.split(' ')[2].replace('go', '');

    log(`Found Go version: ${goVersion}`);

    if (compareVersions(goVersion, CONFIG.REQUIRED_GO_VERSION) < 0) {
        error(`Go version ${CONFIG.REQUIRED_GO_VERSION} or higher is required!`);
        error(`Current version: ${goVersion}`);
        process.exit(1);
    }

    log('Go version check passed');
}

async function cloneRepositories() {
    const repos = [
        { url: CONFIG.NODE_BUILDER_REPO_URL, dir: CONFIG.NODE_BUILDER_INSTALL_DIR, name: 'neuron-node-builder' }
    ];

    if (installSDK) {
        repos.push({ url: CONFIG.SDK_REPO_URL, dir: CONFIG.SDK_INSTALL_DIR, name: 'neuron-sdk-websocket-wrapper' });
    }

    for (const repo of repos) {
        log(`Cloning ${repo.name} repository...`);

        if (fs.existsSync(repo.dir)) {
            log(`Directory ${repo.dir} already exists!`);
            if (!forceFlag) {
                const response = await askQuestion('Remove it and continue? (y/N): ');
                if (response.toLowerCase() !== 'y') {
                    log('Installation cancelled');
                    process.exit(1);
                }
            }
            removeDirectory(repo.dir);
        }

        executeCommand(`git clone ${repo.url} ${repo.dir}`);
        log(`${repo.name} repository cloned successfully`);
    }
}

async function setupConfig() {
    log('Setting up configuration files...');

    // Create .neuron-node-builder directory in user's home directory
    const neuronUserPath = path.join(os.homedir(), '.neuron-node-builder');
    createDirectory(neuronUserPath);
    log(`User directory ready: ${neuronUserPath}`);

    // Handle .env configuration
    const envExamplePath = path.join(CONFIG.NODE_BUILDER_INSTALL_DIR, '.env.example');
    const envPath = path.join(CONFIG.NODE_BUILDER_INSTALL_DIR, '.env');

    if (fs.existsSync(envExamplePath)) {
        fs.copyFileSync(envExamplePath, envPath);
        log('Copied .env.example to .env');

        let envContent = fs.readFileSync(envPath, 'utf8');

        // Update or add NEURON_SDK_PATH only if installing SDK
        if (installSDK) {
            const sdkExecutableName = isWindows ? 'neuron-sdk-websocket-wrapper.exe' : 'neuron-sdk-websocket-wrapper';
            const sdkExecutablePath = path.resolve(CONFIG.NODE_BUILDER_INSTALL_DIR, 'build', 'bin', sdkExecutableName);

            if (envContent.includes('NEURON_SDK_PATH=')) {
                envContent = envContent.replace(/NEURON_SDK_PATH=.*$/m, `NEURON_SDK_PATH=${sdkExecutablePath}`);
                log('Updated NEURON_SDK_PATH in .env');
            } else {
                envContent += `\nNEURON_SDK_PATH=${sdkExecutablePath}`;
                log('Added NEURON_SDK_PATH to .env');
            }
        }

        // Update or add NEURON_USER_PATH
        if (envContent.includes('NEURON_USER_PATH=')) {
            envContent = envContent.replace(/NEURON_USER_PATH=.*$/m, `NEURON_USER_PATH=${neuronUserPath}`);
            log('Updated NEURON_USER_PATH in .env');
        } else {
            envContent += `\nNEURON_USER_PATH=${neuronUserPath}`;
            log('Added NEURON_USER_PATH to .env');
        }

        fs.writeFileSync(envPath, envContent);
    } else {
        log(`Warning: .env.example not found in ${CONFIG.NODE_BUILDER_INSTALL_DIR}`);
    }

    // Handle flows.json configuration
    const exampleFlowsPath = path.join(CONFIG.NODE_BUILDER_INSTALL_DIR, 'neuron', 'userdir', 'example.flows.json');
    const flowsPath = path.join(CONFIG.NODE_BUILDER_INSTALL_DIR, 'neuron', 'userdir', 'flows.json');

    if (fs.existsSync(exampleFlowsPath)) {
        if (fs.existsSync(flowsPath)) {
            log('flows.json already exists, skipping rename of example.flows.json');
        } else {
            fs.renameSync(exampleFlowsPath, flowsPath);
            log('Renamed example.flows.json to flows.json');
        }
    } else {
        log('Warning: example.flows.json not found in neuron/userdir/');
    }
}

async function installDependencies() {
    const projects = [
        { dir: CONFIG.NODE_BUILDER_INSTALL_DIR, name: 'Node Builder', command: 'npm install' }
    ];

    if (installSDK) {
        projects.push({ dir: CONFIG.SDK_INSTALL_DIR, name: 'SDK', command: 'go mod tidy' });
    }

    for (const project of projects) {
        log(`Installing ${project.name} dependencies...`);
        executeCommand(project.command, project.dir);
        log(`${project.name} dependencies installed successfully`);
    }
}

async function buildProjects() {
    // Build Node Builder project
    log('Building Node Builder project...');
    executeCommand('npm run build', CONFIG.NODE_BUILDER_INSTALL_DIR);
    log('Node Builder project built successfully');

    // Build SDK binary only if installing SDK
    if (installSDK) {
        log('Building SDK binary...');
        const binaryName = isWindows ? 'neuron-sdk-websocket-wrapper.exe' : 'neuron-sdk-websocket-wrapper';
        executeCommand(`go build -o ${binaryName}`, CONFIG.SDK_INSTALL_DIR);
        log('SDK binary built successfully');
    }
}

async function integrateComponents() {
    // Create symlink for SDK binary to Node Builder project only if installing SDK
    if (installSDK) {
        log('Creating link for SDK binary to Node Builder project...');
        const buildBinPath = path.join(CONFIG.NODE_BUILDER_INSTALL_DIR, 'build', 'bin');
        createDirectory(buildBinPath);

        const binaryName = isWindows ? 'neuron-sdk-websocket-wrapper.exe' : 'neuron-sdk-websocket-wrapper';
        const sourcePath = path.resolve(CONFIG.SDK_INSTALL_DIR, binaryName);
        const targetPath = path.join(buildBinPath, binaryName);

        // Remove existing file/link if it exists
        if (fs.existsSync(targetPath)) {
            fs.unlinkSync(targetPath);
        }

        try {
            if (isWindows) {
                // Try creating symlink first, fallback to copy on Windows
                try {
                    fs.symlinkSync(sourcePath, targetPath);
                    log(`SDK binary symlink created: ${targetPath} -> ${sourcePath}`);
                } catch (symlinkError) {
                    // Fallback to copy if symlink fails (no admin privileges)
                    fs.copyFileSync(sourcePath, targetPath);
                    log(`SDK binary copied to ${buildBinPath} (fallback)`);
                }
            } else {
                fs.symlinkSync(sourcePath, targetPath);
                log(`SDK binary symlink created: ${targetPath} -> ${sourcePath}`);
            }
        } catch (error) {
            log(`Warning: Failed to create link for SDK binary: ${error.message}`);
        }
    }
}

async function showConfirmation() {
    if (forceFlag) {
        installSDK = true; // Default to installing SDK when using force flag
        return;
    }

    log('This script will install Neuron Node Builder components:');
    log('- neuron-node-builder (Node.js) [Required]');
    log('');

    const sdkResponse = await askQuestion('Would you like to install/build the neuron-sdk-websocket-wrapper (requires Go)? (y/N): ');
    installSDK = sdkResponse.toLowerCase() === 'y';

    log('');

    if (installSDK) {
        log('Will install:');
        log('- neuron-node-builder (Node.js)');
        log('- neuron-sdk-websocket-wrapper (Go)');
        log('');
        log('Prerequisites will be checked:');
        log('- Go 1.23+');
        log('- git');
    } else {
        log('Will install:');
        log('- neuron-node-builder (Node.js)');
        log('');
        log('Prerequisites will be checked:');
        log('- git');
    }
    log('');

    const response = await askQuestion('Continue with installation? (y/N): ');
    if (response.toLowerCase() !== 'y') {
        log('Installation cancelled');
        process.exit(0);
    }
    log('');
}

// Main installation process
async function main() {
    try {
        await showConfirmation();

        log('Starting Neuron SDK installation...');

        if (installSDK) {
            await checkGo();
        }
        await cloneRepositories();
        await setupConfig();
        await installDependencies();
        await buildProjects();
        await integrateComponents();

        log('Installation completed successfully!');
        log('Repositories installed in:');
        log(`  Node Builder: ${path.resolve(CONFIG.NODE_BUILDER_INSTALL_DIR)}`);
        if (installSDK) {
            log(`  SDK: ${path.resolve(CONFIG.SDK_INSTALL_DIR)}`);
        }
        log('');
        log('To start the application:');
        log(`  from the ${CONFIG.NODE_BUILDER_INSTALL_DIR} directory run:`);
        log('  npm run start');

    } catch (error) {
        error(`Installation failed: ${error.message}`);
        process.exit(1);
    }
}

// Handle command line arguments
if (require.main === module) {
    main();
}

module.exports = { main };