# Docker WSL Setup Script

Automated PowerShell script to set up Docker in WSL2 without Docker Desktop.

## Overview

This script provides a complete automated installation of Docker running natively in WSL2 (Ubuntu), allowing you to use Docker from both Windows PowerShell and the Linux environment without requiring Docker Desktop.

## Features

- Installs and configures WSL2 with mirrored networking mode
- Installs Ubuntu distribution
- Installs Docker Engine in Ubuntu
- Configures Docker daemon with systemd
- Installs Docker CLI tools on Windows
- Automatically detects WSL IP and configures DOCKER_HOST
- Sets up Task Scheduler to auto-start Ubuntu at user logon
- Enables Docker commands from both Windows and WSL

## Prerequisites

- Windows 10 version 2004 or higher (Build 19041 and higher) or Windows 11
- Administrator privileges
- Internet connection

## Installation

### Quick Start

1. **Open PowerShell as Administrator**
   - Right-click PowerShell and select "Run as Administrator"

2. **Run the script**

   ```powershell
   .\docker-wsl.ps1
   ```

3. **Follow the prompts**
   - The script will pause for you to complete Ubuntu setup (username/password)
   - After creating your Ubuntu username and password, type `exit` to return to PowerShell
   - Press any key to continue the installation

4. **Restart your computer**
   - Required for all WSL changes to take effect

5. **Test Docker**

   ```powershell
   docker run hello-world
   ```

## What the Script Does

The installation process includes 8 steps:

1. **Install WSL** - Enables Windows Subsystem for Linux
2. **Enable Virtual Machine Platform** - Required for WSL2
3. **Update WSL** - Gets the latest WSL version
4. **Set WSL 2 as default and configure networking** - Ensures new distributions use WSL2 and sets up mirrored networking mode
5. **Install Ubuntu** - Installs Ubuntu distribution from Windows Store
6. **Update Ubuntu and Install Docker** - Updates Ubuntu packages and installs Docker Engine, CLI, containerd, and Docker Compose plugin
7. **Install Windows Docker tools** - Installs Docker CLI, Compose, and Buildx on Windows, and configures DOCKER_HOST with `tcp://127.0.0.1:2375`
8. **Create Task Scheduler job** - Sets up automatic Ubuntu startup at user logon to ensure the WSL distribution stays running (required for Docker to remain accessible from Windows)

## How It Works

- **WSL networking** is configured in mirrored mode for better network compatibility
- **Docker Engine** runs inside WSL Ubuntu as a systemd service
- **Docker CLI** on Windows connects to the WSL Docker daemon via localhost (127.0.0.1:2375) in mirrored networking mode
- **Task Scheduler** automatically starts Ubuntu at user logon and keeps it running in the background
  - WSL distributions automatically shut down when idle to save resources
  - The scheduled task runs a background process (`sleep infinity`) to prevent Ubuntu from stopping
  - This ensures Docker remains accessible from Windows PowerShell at all times
  - Without this task, you would need to manually start WSL before using Docker commands
- You can use `docker` commands from both PowerShell and Ubuntu terminal
- The `DOCKER_HOST` environment variable is automatically set to `tcp://127.0.0.1:2375` for mirrored networking mode

## Usage

After installation, you can use Docker commands from any PowerShell or terminal window:

```powershell
# Pull and run containers
docker pull nginx
docker run -d -p 8080:80 nginx

# Use Docker Compose
docker compose up -d

# Check Docker status
docker ps
docker images
```

From within Ubuntu WSL:
```bash
# Same Docker commands work
docker ps
sudo systemctl status docker
```

## Managing Docker with Portainer

For a web-based Docker management interface, we recommend using [Portainer](https://www.portainer.io/). Portainer provides an intuitive UI to manage containers, images, volumes, networks, and more.

### Installing Portainer

```powershell
# Create a volume for Portainer data
docker volume create portainer_data

# Run Portainer container
docker run -d `
  --name portainer `
  -p 9000:9000 `
  -p 9443:9443 `
  --restart always `
  -v /var/run/docker.sock:/var/run/docker.sock `
  -v portainer_data:/data `
  portainer/portainer-ce:latest
```

### Accessing Portainer

1. Open your browser and navigate to: `http://localhost:9000` or `https://localhost:9443`
2. Create your admin account on first launch
3. Select "Docker" as the environment to manage
4. Start managing your Docker environment through the web interface

### Portainer Features

- Visual container management (start, stop, restart, remove)
- Image management and registry connections
- Volume and network management
- Docker Compose stack deployment
- Container logs and stats viewing
- Terminal access to containers

## Troubleshooting

### Ensure Ubuntu distribution is running

```powershell
# Check if Ubuntu is running
wsl -l -v

# Check if the scheduled task is running
Get-ScheduledTask -TaskName "WSL-Ubuntu-Startup" | Get-ScheduledTaskInfo

# If the task is not running, start it
Start-ScheduledTask -TaskName "WSL-Ubuntu-Startup"

# Alternative: If Ubuntu is not running (State: Stopped), 
# you can start it manually instead of using the scheduled task
wsl -d Ubuntu
```

### Docker daemon not running

```powershell
wsl -d Ubuntu sudo systemctl start docker
```

### Check Docker status

```powershell
wsl -d Ubuntu sudo systemctl status docker
```

### Restart Docker service

```powershell
wsl -d Ubuntu sudo systemctl restart docker
```

### Verify DOCKER_HOST is set

```powershell
echo $env:DOCKER_HOST
# Should output: tcp://127.0.0.1:2375
```

### DOCKER_HOST connection issues

If Docker commands fail to connect, try these alternatives:

**For mirrored networking mode (default in this script):**

```powershell
# Try IPv4 localhost
[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://127.0.0.1:2375", "User")

# Try IPv6 localhost
[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://[::1]:2375", "User")
```

**For NAT networking mode (if you changed from mirrored):**

```powershell
# Get the WSL IP address and set DOCKER_HOST
$wslIp = wsl -d Ubuntu hostname -I | ForEach-Object { $_.Trim().Split()[0] }
[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://${wslIp}:2375", "User")
```

After changing DOCKER_HOST, restart your PowerShell session for the changes to take effect.

**Test without changing environment variable:**

You can test different host addresses without modifying DOCKER_HOST using the `-H` option:

```powershell
# Test with IPv4 localhost
docker -H tcp://127.0.0.1:2375 ps

# Test with IPv6 localhost
docker -H tcp://[::1]:2375 ps

# Test with WSL IP (for NAT mode)
$wslIp = wsl -d Ubuntu hostname -I | ForEach-Object { $_.Trim().Split()[0] }
docker -H tcp://${wslIp}:2375 ps
```

### Test Docker API connection

```powershell
# Test if Docker API is responding (mirrored networking uses localhost)
curl http://localhost:2375/version
```

### Restart WSL

```powershell
wsl --shutdown
wsl
```

## Security Considerations

⚠️ **Important**: This script configures Docker to listen on `tcp://0.0.0.0:2375` without TLS encryption. This is suitable for local development but exposes Docker to your local network.

For production use, consider:

- Using Unix socket only
- Enabling TLS authentication
- Restricting network access with firewall rules

## Uninstallation

To remove Docker:

```powershell
# Remove Docker CLI tools from Windows (run in PowerShell as Administrator)
winget uninstall Docker.DockerCLI
winget uninstall Docker.DockerCompose
winget uninstall Docker.Buildx

# Remove DOCKER_HOST environment variable
[Environment]::SetEnvironmentVariable("DOCKER_HOST", $null, "User")

# Remove Task Scheduler job
Unregister-ScheduledTask -TaskName "WSL-Ubuntu-Startup" -Confirm:$false

# Optionally remove Ubuntu distribution
wsl --unregister Ubuntu

# Optionally remove .wslconfig file
Remove-Item "$env:USERPROFILE\.wslconfig" -Force
```

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
