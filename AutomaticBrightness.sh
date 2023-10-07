#!/bin/bash

#How much light change must be seen by the sensor befor it will act
LightChange=5

#How often it check the sensor
SensorDelay=1

# Scale sesor to displas brightness range
SensorToDisplayScale=24

#This should match your refesh rate other wise it will either change the back light more times than needed or too few for a smooth animation
LevelSteps=60
# The is should match the LevelSteps but in the acual time each event should take to see
AnimationDelay=0.016


# Read the variable names
MaxScreenBrightness=96000

MinimumBrightness=001


touch '/tmp/AB.running'

OldLight=$(cat /sys/bus/iio/devices/iio\:device0/in_illuminance_raw)

until [ -f /tmp/AB.kill ]
do
	if [[ -f /tmp/AB.stop ]]
	then
		rm '/tmp/AB.stop'
		rm '/tmp/AB.running'

		until [[ -f /tmp/AB.start ]]
		do
			sleep 10
		done
		rm '/tmp/AB.start'
		touch '/tmp/AB.running'
	else
		Light=$(cat /sys/bus/iio/devices/iio\:device0/in_illuminance_raw)

    MaxOld=$((OldLight + OldLight/LightChange))
    MinOld=$((OldLight - OldLight/LightChange))


    if [[ $Light -gt $MaxOld ]] || [[ $Light -lt $MinOld ]]
    then


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

      OldLight=$Light
    fi
   
		sleep $SensorDelay
  fi

done


rm '/tmp/AB.running'
rm '/tmp/AB.kill'



