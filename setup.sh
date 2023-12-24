#!/bin/bash
echo "Setting up AutomaticBrightness.sh as a service..."

echo "Cloning AutomaticBrighness.sh..."
sudo cp AutomaticBrightness.sh /usr/local/bin/

echo "Cloning AB.service for systemD"
sudo cp AB.service /etc/systemd/system/

echo "Startin Service..."
sudo systemctl enable AB
sudo systemctl start AB



