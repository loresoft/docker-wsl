# Docker WSL Uninstall Script
# Run as Administrator

Write-Host "=== Docker WSL Uninstall Script ===" -ForegroundColor Cyan
Write-Host "This script will remove Docker from WSL2 and clean up Windows components" -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "WARNING: This will remove Docker and related components." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel or any other key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Step 1. Remove Docker CLI tools from Windows
Write-Host "`n[1/5] Removing Docker CLI tools from Windows..." -ForegroundColor Green
try {
    Write-Host "Removing Docker CLI..." -ForegroundColor Yellow
    winget uninstall Docker.DockerCLI --silent 2>$null
    Write-Host "Docker CLI removed" -ForegroundColor Green
}
catch {
    Write-Host "Docker CLI not found or already removed" -ForegroundColor Yellow
}

try {
    Write-Host "Removing Docker Compose..." -ForegroundColor Yellow
    winget uninstall Docker.DockerCompose --silent 2>$null
    Write-Host "Docker Compose removed" -ForegroundColor Green
}
catch {
    Write-Host "Docker Compose not found or already removed" -ForegroundColor Yellow
}

try {
    Write-Host "Removing Docker Buildx..." -ForegroundColor Yellow
    winget uninstall Docker.Buildx --silent 2>$null
    Write-Host "Docker Buildx removed" -ForegroundColor Green
}
catch {
    Write-Host "Docker Buildx not found or already removed" -ForegroundColor Yellow
}

# Step 2. Remove DOCKER_HOST environment variable
Write-Host "`n[2/5] Removing DOCKER_HOST environment variable..." -ForegroundColor Green
try {
    [Environment]::SetEnvironmentVariable("DOCKER_HOST", $null, "User")
    Write-Host "DOCKER_HOST environment variable removed" -ForegroundColor Green
}
catch {
    Write-Host "Error removing DOCKER_HOST: $_" -ForegroundColor Red
}

# Step 3. Remove Task Scheduler job
Write-Host "`n[3/5] Removing Task Scheduler job..." -ForegroundColor Green
try {
    $taskName = "WSL-Ubuntu-Startup"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Task Scheduler job removed" -ForegroundColor Green
    }
    else {
        Write-Host "Task Scheduler job not found" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error removing Task Scheduler job: $_" -ForegroundColor Red
}

# Step 4. Optionally remove Ubuntu distribution
Write-Host "`n[4/5] Ubuntu distribution removal (optional)..." -ForegroundColor Green
Write-Host "Do you want to completely remove the Ubuntu distribution?" -ForegroundColor Yellow
Write-Host "WARNING: This will delete all data in the Ubuntu distribution!" -ForegroundColor Red
Write-Host "Press 'Y' to remove Ubuntu, or any other key to skip..." -ForegroundColor Yellow
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.Character -eq 'Y' -or $key.Character -eq 'y') {
    Write-Host "`nRemoving Ubuntu distribution..." -ForegroundColor Yellow
    try {
        wsl --unregister Ubuntu
        Write-Host "Ubuntu distribution removed" -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing Ubuntu: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "`nSkipping Ubuntu removal" -ForegroundColor Yellow
    Write-Host "Note: Docker is still installed in Ubuntu. To remove it manually:" -ForegroundColor Cyan
    Write-Host "  wsl -d Ubuntu sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" -ForegroundColor White
}

# Step 5. Optionally remove .wslconfig file
Write-Host "`n[5/5] .wslconfig file removal (optional)..." -ForegroundColor Green
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if (Test-Path $wslConfigPath) {
    Write-Host "Do you want to remove the .wslconfig file?" -ForegroundColor Yellow
    Write-Host "Location: $wslConfigPath" -ForegroundColor Cyan
    Write-Host "WARNING: This may affect other WSL distributions if you have custom settings!" -ForegroundColor Red
    Write-Host "Press 'Y' to remove .wslconfig, or any other key to skip..." -ForegroundColor Yellow
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    if ($key.Character -eq 'Y' -or $key.Character -eq 'y') {
        Write-Host "`nRemoving .wslconfig file..." -ForegroundColor Yellow
        try {
            Remove-Item $wslConfigPath -Force
            Write-Host ".wslconfig file removed" -ForegroundColor Green
        }
        catch {
            Write-Host "Error removing .wslconfig: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`nSkipping .wslconfig removal" -ForegroundColor Yellow
    }
}
else {
    Write-Host ".wslconfig file not found" -ForegroundColor Yellow
}

# Final message
Write-Host "`n=== Uninstall Complete! ===" -ForegroundColor Cyan
Write-Host "`nDocker WSL components have been removed." -ForegroundColor Green
Write-Host "You may need to restart your terminal for environment variable changes to take effect." -ForegroundColor Yellow
Write-Host ""
