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

# Step 1. Install WSL
Write-Host "`n[1/8] Installing WSL..." -ForegroundColor Green
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

# Step 2. Enable Virtual Machine Platform
Write-Host "`n[2/8] Enabling Virtual Machine Platform..." -ForegroundColor Green
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

# Step 3. Update WSL
Write-Host "`n[3/8] Updating WSL..." -ForegroundColor Green
try {
    wsl --update
    Write-Host "WSL updated successfully" -ForegroundColor Green
} catch {
    Write-Host "Error updating WSL: $_" -ForegroundColor Red
}

# Step 4. Set WSL 2 as default and configure networking
Write-Host "`n[4/8] Setting WSL 2 as default version and configuring networking..." -ForegroundColor Green
try {
    wsl --set-default-version 2
    Write-Host "WSL 2 set as default" -ForegroundColor Green
    
    # Configure .wslconfig for mirrored networking
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    $wslConfigContent = @"
[wsl2]
networkingMode=mirrored

"@
    
    # Create or update .wslconfig
    Set-Content -Path $wslConfigPath -Value $wslConfigContent -Force
    Write-Host "WSL networking mode set to mirrored" -ForegroundColor Green
    Write-Host "Configuration saved to $wslConfigPath" -ForegroundColor Yellow
} catch {
    Write-Host "Error configuring WSL: $_" -ForegroundColor Red
}

# Step 5. Install Ubuntu from Windows Store
Write-Host "`n[5/8] Installing Ubuntu..." -ForegroundColor Green
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

# Step 6. Update Ubuntu, Install and Configure Docker
Write-Host "`n[6/8] Updating Ubuntu, installing and configuring Docker..." -ForegroundColor Green
$dockerSetupScript = @'
# Update and upgrade Ubuntu
echo "Updating and upgrading Ubuntu..."
sudo apt update && sudo apt upgrade -y

# Remove old Docker installations
echo "Removing old Docker installations..."
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "Setting up Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Create systemd override directory
echo "Configuring Docker daemon..."
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

echo 'Docker installed and configured successfully!'
'@

wsl -d Ubuntu -e bash -c $dockerSetupScript

# Step 7. Install Docker CLI on Windows and configure
Write-Host "`n[7/8] Installing Docker tools on Windows..." -ForegroundColor Green

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
    
    # Get WSL Ubuntu IP address for DOCKER_HOST
    Write-Host "Detecting WSL Ubuntu IP address..." -ForegroundColor Yellow
    $wslIp = wsl -d Ubuntu hostname -I | ForEach-Object { $_.Trim().Split()[0] }
    
    if ([string]::IsNullOrWhiteSpace($wslIp)) {
        # Fallback to 127.0.0.1 if we can't get WSL IP
        Write-Host "Could not detect WSL IP, using 127.0.0.1..." -ForegroundColor Yellow
        $dockerHost = "tcp://127.0.0.1:2375"
    } else {
        Write-Host "WSL Ubuntu IP detected: $wslIp" -ForegroundColor Green
        $dockerHost = "tcp://${wslIp}:2375"
    }
    
    # Set DOCKER_HOST environment variable
    [Environment]::SetEnvironmentVariable("DOCKER_HOST", $dockerHost, "User")
    Write-Host "Set DOCKER_HOST to $dockerHost" -ForegroundColor Green
    
} catch {
    Write-Host "Error installing Docker tools: $_" -ForegroundColor Red
    Write-Host "You may need to install them manually:" -ForegroundColor Yellow
    Write-Host "  winget install Docker.DockerCLI" -ForegroundColor White
    Write-Host "  winget install Docker.DockerCompose" -ForegroundColor White
    Write-Host "  winget install Docker.Buildx" -ForegroundColor White
}

# Step 8. Creating Task Scheduler job to keep Ubuntu running
Write-Host "`n[8/8] Creating Task Scheduler job to start Ubuntu at user logon..." -ForegroundColor Green
try {
$taskName = "WSL-Ubuntu-Startup"

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Task already exists. Removing old task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the action (with working directory set to user profile)
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\wsl.exe" -Argument "-d Ubuntu -e bash -c `"sleep infinity`"" -WorkingDirectory $env:USERPROFILE

# Create the trigger (at user logon)
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Create the principal (run as current user with limited privileges)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

# Create settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
    -DontStopOnIdleEnd


# Register the task
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Starts WSL Ubuntu distribution at user logon to keep Docker running"
    
    Write-Host "Task Scheduler job created successfully!" -ForegroundColor Green
    Write-Host "Ubuntu will now start automatically when you log on" -ForegroundColor Green
} catch {
    Write-Host "Error creating Task Scheduler job: $_" -ForegroundColor Red
    Write-Host "You may need to create it manually in Task Scheduler" -ForegroundColor Yellow
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
Write-Host "- Docker CLI on Windows connects via the WSL IP address on port 2375" -ForegroundColor White
Write-Host "- You can use 'docker' commands from both PowerShell and Ubuntu" -ForegroundColor White
Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
Write-Host "- If Docker isn't running: wsl -d Ubuntu sudo systemctl start docker" -ForegroundColor White
Write-Host "- Check Docker status: wsl -d Ubuntu sudo systemctl status docker" -ForegroundColor White