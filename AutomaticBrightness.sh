#!/bin/bash

#How much light change must be seen by the sensor befor it will act
LightChange=10

#How often it check the sensor
SensorDelay=1

# Scale sesor to displas brightness range
# NOW WITH FLOAT SUPPORT
SensorToDisplayScale=24.09

#This should match your refesh rate other wise it will either change the back light more times than needed or too few for a smooth animation
LevelSteps=60
# The is should match the LevelSteps but in the acual time each event should take to see
AnimationDelay=0.016


# Read the variable names
MinimumBrightness=001



# 2 : Default | 1 : Add Offset | 0 : Subtract Offset, Recomended not to change
op=2


# Only look for flags -i or -d with an aditional value
# AutomaticBrightness.sh -i 100
while getopts i:d: flag
do
    case "${flag}" in
        i) op=1
           num=${OPTARG};;
        d) op=0 
           num=${OPTARG};;
    esac
done

# Verigy offset file exsits and if so read it
if [[ -f /dev/shm/AB.offset ]]
then
  OffSet=$(cat /dev/shm/AB.offset)
else
  OffSet=0
  $(echo $OffSet > /dev/shm/AB.offset)
  $(chmod 666 /dev/shm/AB.offset)
fi

#if no offset or its less than 0 make 0
OffSet=$((OffSet < 0 ? 0 : OffSet))

# relativly change number in Offset file and write it
if [[ $op -lt 2 ]]
then
  if [[ $op -eq 1 ]]
  then
    OffSet=$((OffSet + num))
  else 
    OffSet=$((OffSet - num))
  fi

  # verify offset is not less than 0
  OffSet=$((OffSet < 0 ? 0 : OffSet))

  $(echo $OffSet > /dev/shm/AB.offset)
  
  exit

fi

# This was moved down here to not affect performance of setting AB.offset
priority=19 # Priority level , 0 = regular app , 19 = very much background app

# Set the priority of the current script, Thank you  Theluga.
renice "$priority" "$$"

sleep 5

# Get screen max brightness value
MaxScreenBrightness=$(find -L /sys/class/backlight -maxdepth 2 -name "max_brightness" 2>/dev/null | grep "max_brightness" | xargs cat)

# Set path to current screen brightness value
BLightPath=$(find -L /sys/class/backlight -maxdepth 2 -name "brightness" 2>/dev/null | grep "brightness")

# Set path to current luminance sensor
LSensorPath=$(find -L /sys/bus/iio/devices -maxdepth 2  -name "in_illuminance_raw" 2>/dev/null | grep "in_illuminance_raw")


#Set the current light value so we have something to compare to
OldLight=$(cat $LSensorPath)

while true
do
    if [[ -f /dev/shm/AB.offset ]]
    then
      OffSet=$(cat /dev/shm/AB.offset)
    else
      OffSet=0
      $(echo $OffSet > /dev/shm/AB.offset)
      $(chmod 666 /dev/shm/AB.offset)
    fi

		Light=$(cat $LSensorPath)
    ## apply offset to current light value
    Light=$((Light + OffSet))

    # Set allowed range for light 
    
    MaxOld=$((OldLight + OldLight/LightChange))
    MinOld=$((OldLight - OldLight/LightChange))


    if [[ $Light -gt $MaxOld ]] || [[ $Light -lt $MinOld ]]
    then


		  CurrentBrightness=$(cat $BLightPath)

      # Add MinimumBrighness here to not effect comparison but the outcome
		  Light=$(( $Light + $MinimumBrightness ))
      
      # Gernate a TempLight value for the screen to be set to
      # Float math thanks Matthias_Wachter 
      TempLight=$(echo "scale=2; $Light * $SensorToDisplayScale" | bc)
      # REmoves float for latter checks
      TempLight=$(LANG=C printf "%.0f" $TempLight)


      # Check we dont ask the screen to go brighter than it can
		  if [[ $TempLight -gt $MaxScreenBrightness ]]
		  then
			  NewLight=$MaxScreenBrightness
		  else
			  NewLight=$TempLight
		  fi

      # How diffrent should each stop be
		  DiffCount=$(( ( $NewLight - $CurrentBrightness ) / $LevelSteps ))

      # Step once per Screen Hz to make animation
		  for i in $(eval echo {1..$LevelSteps} )
		  do

        # Set new relative light value
			  NewLight=$(( $DiffCount ))


        # Format values apropriatly for brightnessctl
			  if [[ $NewLight -lt 0 ]]
			  then
			  NewLight=$( echo "$NewLight" | awk -F "-" {'print$2'})
			  NewLight=$(echo $NewLight-)
			  else
			  NewLight=$(echo +$NewLight)
			  fi
        
        # Adjust brightness relativly
			  brightnessctl -q s $NewLight
        # Sleep for the screen Hz time so he effect is visible
			  sleep $AnimationDelay

		  done
      
      # Store new light as old light for next comparison
      OldLight=$Light
    fi
   
		sleep $SensorDelay
done



