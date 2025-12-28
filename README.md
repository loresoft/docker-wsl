# Docker WSL Setup Script

Automated PowerShell script to set up Docker in WSL2 without Docker Desktop.

## Overview

This script provides a complete automated installation of Docker running natively in WSL2 (Ubuntu), allowing you to use Docker from both Windows PowerShell and the Linux environment without requiring Docker Desktop.

## Features

- Installs and configures WSL2
- Installs Ubuntu distribution
- Installs Docker Engine in Ubuntu
- Configures Docker daemon with systemd
- Installs Docker CLI tools on Windows
- Sets up automatic Docker daemon startup
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
   - Press any key to continue after Ubuntu setup is complete

4. **Restart your computer**
   - Required for all WSL changes to take effect

5. **Test Docker**

   ```powershell
   docker run hello-world
   ```

## What the Script Does

The installation process includes 9 steps:

1. **Install WSL** - Enables Windows Subsystem for Linux
2. **Enable Virtual Machine Platform** - Required for WSL2
3. **Update WSL** - Gets the latest WSL version
4. **Set WSL 2 as default** - Ensures new distributions use WSL2
5. **Install Ubuntu** - Installs Ubuntu distribution from Windows Store
6. **Update Ubuntu** - Updates and upgrades Ubuntu packages
7. **Install Docker** - Installs Docker Engine, CLI, containerd, and Docker Compose plugin
8. **Configure Docker daemon** - Sets up systemd service and TCP socket
9. **Install Windows Docker tools** - Installs Docker CLI, Compose, and Buildx on Windows

## How It Works

- **Docker Engine** runs inside WSL Ubuntu as a systemd service
- **Docker CLI** on Windows connects to the WSL Docker daemon via `tcp://localhost:2375`
- You can use `docker` commands from both PowerShell and Ubuntu terminal
- The `DOCKER_HOST` environment variable is automatically configured

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

## Troubleshooting

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
# Should output: tcp://localhost:2375
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
# From WSL Ubuntu
wsl -d Ubuntu
sudo apt remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo rm -rf /var/lib/docker

# Optionally remove Ubuntu distribution
wsl --unregister Ubuntu
```

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
