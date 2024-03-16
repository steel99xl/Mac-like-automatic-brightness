#!/bin/bash
#
case $1 in
        -u) echo "Updading Mac-like-automatic-brightness..."
          echo "Stopping AB service..."
          sudo systemctl kill AB
          echo "Updating AutomaticBrightness.sh..."
          echo "Cloning AutomaticBrighness.sh..."
          sudo cp AutomaticBrightness.sh /usr/local/bin/AutomaticBrightness.sh
          echo "Updating AB.service for systemD..."
          echo "Cloning AB.service for systemD..."
          sudo cp AB.service /etc/systemd/system/AB.service
          echo "Restarting AB service..."
          systemctl daemon-reload
          sudo systemctl start AB
          exit;;
esac

echo "Setting up AutomaticBrightness.sh as a service..."

echo "Calibrating Light Sensor Scale..."

LSensorPath=$(find -L /sys/bus/iio/devices -maxdepth 2  -name "in_illuminance_raw" 2>/dev/null | grep "in_illuminance_raw")

MaxScreenBrightness=$(find -L /sys/class/backlight -maxdepth 2 -name "max_brightness" 2>/dev/null | grep "max_brightness" | xargs cat)

echo "Put your sensor in a bright light (outside works best)"
read -p "Press Enter to continue..."

Smax=$(cat $LSensorPath)

Scale=$(echo "scale=2; $MaxScreenBrightness / $Smax" | bc)

Final="SensorToDisplayScale=$Scale"

awk -v new_phrase="$Final" '/SensorToDisplayScale=/{ print new_phrase; next } 1' AutomaticBrightness.sh  > temp && mv temp AutomaticBrightness.sh

TempSteps=($MaxScreenBrightness / 60)
if [[ TempSteps -lt 17 ]]
then
    Steps=$($MaxScreenBrightness / 16)
    NewStep="LevelSteps=$Steps"

    awk -v new_phrase="$NewStep" '/LevelSteps=/{ print new_phrase; next } 1' AutomaticBrightness.sh  > temp && mv temp AutomaticBrightness.sh
fi

echo "Cloning AutomaticBrighness.sh..."
sudo cp AutomaticBrightness.sh /usr/local/bin/AutomaticBrightness.sh

echo "Cloning AB.service for systemD..."
sudo cp AB.service /etc/systemd/system/AB.service


echo "Startin Service..."
sudo systemctl enable AB
sudo systemctl start AB



