# Docker WSL Setup Script (Without Docker Desktop)
# Run as Administrator

Write-Host "=== Docker WSL Setup Script ===" -ForegroundColor Cyan
Write-Host "This script will set up Docker in WSL2 without Docker Desktop" -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# 1. Install WSL
Write-Host "`n[1/9] Installing WSL..." -ForegroundColor Green
try {
    $wslInstalled = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wslInstalled.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Write-Host "WSL feature enabled" -ForegroundColor Green
    } else {
        Write-Host "WSL already installed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error installing WSL: $_" -ForegroundColor Red
}

# Enable Virtual Machine Platform
Write-Host "`n[2/9] Enabling Virtual Machine Platform..." -ForegroundColor Green
try {
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    if ($vmPlatform.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        Write-Host "Virtual Machine Platform enabled" -ForegroundColor Green
    } else {
        Write-Host "Virtual Machine Platform already enabled" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error enabling Virtual Machine Platform: $_" -ForegroundColor Red
}

# 2. Update WSL
Write-Host "`n[3/9] Updating WSL..." -ForegroundColor Green
try {
    wsl --update
    Write-Host "WSL updated successfully" -ForegroundColor Green
} catch {
    Write-Host "Error updating WSL: $_" -ForegroundColor Red
}

# 3. Set WSL 2 as default
Write-Host "`n[4/9] Setting WSL 2 as default version..." -ForegroundColor Green
try {
    wsl --set-default-version 2
    Write-Host "WSL 2 set as default" -ForegroundColor Green
} catch {
    Write-Host "Error setting WSL 2 as default: $_" -ForegroundColor Red
}

# 4. Install Ubuntu from Windows Store
Write-Host "`n[5/9] Installing Ubuntu..." -ForegroundColor Green
Write-Host "Checking if Ubuntu is already installed..." -ForegroundColor Yellow
$ubuntuInstalled = wsl --list --quiet | Select-String -Pattern "Ubuntu"

if (-not $ubuntuInstalled) {
    try {
        Write-Host "Installing Ubuntu from Windows Store..." -ForegroundColor Yellow
        wsl --install -d Ubuntu
        Write-Host "Ubuntu installed successfully" -ForegroundColor Green
        Write-Host "Please complete Ubuntu setup (username/password) in the Ubuntu window that opens" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "Error installing Ubuntu: $_" -ForegroundColor Red
        Write-Host "You may need to install Ubuntu manually from the Microsoft Store" -ForegroundColor Yellow
    }
} else {
    Write-Host "Ubuntu already installed" -ForegroundColor Yellow
}

# Wait for user to complete Ubuntu setup
Write-Host "`nPress any key once Ubuntu setup is complete..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 5. Update and Upgrade Linux Distribution
Write-Host "`n[6/9] Updating and upgrading Ubuntu..." -ForegroundColor Green
$updateScript = @"
sudo apt update && sudo apt upgrade -y
"@
wsl -d Ubuntu -e bash -c $updateScript

# 6. Install Docker in Linux
Write-Host "`n[7/9] Installing Docker in Ubuntu..." -ForegroundColor Green
$dockerInstallScript = @'
# Remove old Docker installations
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

echo 'Docker installed successfully!'
'@

wsl -d Ubuntu -e bash -c $dockerInstallScript

# 7. Configure Docker daemon and start service
Write-Host "`n[8/9] Configuring Docker daemon and starting service..." -ForegroundColor Green
$dockerConfigScript = @'
# Create systemd override directory
sudo mkdir -p /etc/systemd/system/docker.service.d

# Configure Docker to listen on both unix socket and TCP
sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
EOF

# Reload systemd configuration
sudo systemctl daemon-reload

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

echo 'Docker configured and started successfully!'
'@

wsl -d Ubuntu -e bash -c $dockerConfigScript

# 8. Install Docker CLI on Windows and configure
Write-Host "`n[9/9] Installing Docker tools on Windows..." -ForegroundColor Green

try {
    # Install Docker CLI using winget
    Write-Host "Installing Docker CLI via winget..." -ForegroundColor Yellow
    winget install -e --id Docker.DockerCLI --accept-package-agreements --accept-source-agreements
    Write-Host "Docker CLI installed successfully!" -ForegroundColor Green
    
    # Install Docker Compose
    Write-Host "Installing Docker Compose via winget..." -ForegroundColor Yellow
    winget install -e --id Docker.DockerCompose --accept-package-agreements --accept-source-agreements
    Write-Host "Docker Compose installed successfully!" -ForegroundColor Green
    
    # Install Docker Buildx
    Write-Host "Installing Docker Buildx via winget..." -ForegroundColor Yellow
    winget install -e --id Docker.Buildx --accept-package-agreements --accept-source-agreements
    Write-Host "Docker Buildx installed successfully!" -ForegroundColor Green
    # Set DOCKER_HOST environment variable to use localhost (WSL2 forwards to WSL automatically)
    [Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://localhost:2375", "User")
    Write-Host "Set DOCKER_HOST to tcp://localhost:2375" -ForegroundColor Green
    
} catch {
    Write-Host "Error installing Docker tools: $_" -ForegroundColor Red
    Write-Host "You may need to install them manually:" -ForegroundColor Yellow
    Write-Host "  winget install Docker.DockerCLI" -ForegroundColor White
    Write-Host "  winget install Docker.DockerCompose" -ForegroundColor White
    Write-Host "  winget install Docker.Buildx" -ForegroundColor White
}

# Final instructions
Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "`nIMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Restart your computer to ensure all WSL changes take effect" -ForegroundColor White
Write-Host "2. After restart, Docker should start automatically in WSL" -ForegroundColor White
Write-Host "3. Restart PowerShell to load the DOCKER_HOST environment variable" -ForegroundColor White
Write-Host "4. Test Docker from PowerShell with: docker run hello-world" -ForegroundColor White
Write-Host "`nHow it works:" -ForegroundColor Cyan
Write-Host "- Docker Engine runs inside WSL Ubuntu" -ForegroundColor White
Write-Host "- Docker CLI on Windows connects via tcp://localhost:2375" -ForegroundColor White
Write-Host "- You can use 'docker' commands from both PowerShell and Ubuntu" -ForegroundColor White
Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
Write-Host "- If Docker isn't running: wsl -d Ubuntu sudo systemctl start docker" -ForegroundColor White
Write-Host "- Check Docker status: wsl -d Ubuntu sudo systemctl status docker" -ForegroundColor White