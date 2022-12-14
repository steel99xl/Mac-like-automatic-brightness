#!/bin/bash

LevelSteps=60
AnimationDelay=0.016
MaxScreenBrightness=96000
SensorDelay=1

MinimumBrightness=001

SensorToDisplayScale=24

while true; do
Light=$(cat /sys/bus/iio/devices/iio\:device0/in_illuminance_raw)

CurrentBrightness=$(cat /sys/class/backlight/intel_backlight/brightness)


Light=$(( $Light + $MinimumBrightness ))


TempLight=$(($Light * $SensorToDisplayScale))

if [[ $TempLight -gt $MaxScreenBrightness ]]
then
	NewLight=$MaxScreenBrightness
else
	NewLight=$TempLight
fi

DiffCount=$(( ($NewLight - $CurrentBrightness)/$LevelSteps ))

for i in $(eval echo {1..$LevelSteps} )
do

	NewLight=$(( $DiffCount ))

	if [[ $NewLight -lt 0 ]]
	then
	NewLight=$( echo "$NewLight" | awk -F "-" {'print$2'})
	NewLight=$(echo $NewLight-)
	else
	NewLight=$(echo +$NewLight)
	fi

	brightnessctl -q s $NewLight
	sleep $AnimationDelay

done

sleep $SensorDelay

done
