#!/bin/bash
# Migration script from user services to system services
# Requires sudo privileges

echo "="*50
echo "MIGRATING TO SYSTEM SERVICES"
echo "="*50
echo "This script should be run manually when you have sudo access"
echo ""

# 1. Create system users
echo "Creating system users..."
sudo useradd -r -s /bin/false goose || true
sudo useradd -r -s /bin/false llama || true
sudo useradd -r -s /bin/false bifrost || true

# 2. Copy binaries to /usr/local/bin
echo "Copying binaries to /usr/local/bin..."
sudo cp /home/sheldon/.local/bin/goose /usr/local/bin/goose || true
sudo cp /home/sheldon/.local/bin/llama /usr/local/bin/llama || true

# Note: bifrost is in /home/sheldon/.cache/bifrost/v2.3.2/bin/bifrost-http-0
# Need to copy that specific binary
sudo cp /home/sheldon/.cache/bifrost/v2.3.2/bin/bifrost-http-0 /usr/local/bin/bifrost || true

# 3. Create service files in /etc/systemd/system
echo "Creating service files in /etc/systemd/system..."

# Goose service
sudo cp ~/.config/systemd/user/goose.service /etc/systemd/system/goose.service || true

# Llama service  
sudo cp ~/.config/systemd/user/llama.service /etc/systemd/system/llama.service || true

# Bifrost service
sudo cp ~/.config/systemd/user/bifrost.service /etc/systemd/system/bifrost.service || true

# 4. Adjust service files for system paths
echo "Adjusting service file paths..."
sudo sed -i "s|/home/sheldon/.local/bin|/usr/local/bin|g" /etc/systemd/system/goose.service || true
sudo sed -i "s|/home/sheldon/.local/bin|/usr/local/bin|g" /etc/systemd/system/llama.service || true

# For bifrost, might need to adjust paths differently

# 5. Enable and start system services
echo "Enabling and starting system services..."
sudo systemctl --system daemon-reload
sudo systemctl enable goose.service
sudo systemctl enable llama.service
sudo systemctl enable bifrost.service

echo "Migration complete! Please check services with:"
echo "  sudo systemctl status goose.service llama.service bifrost.service"
echo "  curl http://localhost:8080/health (for bifrost)"