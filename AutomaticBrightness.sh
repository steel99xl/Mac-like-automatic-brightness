#!/bin/bash

#How much light change must be seen by the sensor before it will act
LightChange=10

#How often it check the sensor
SensorDelay=1

# Scale sensor to display brightness range
# NOW WITH FLOAT SUPPORT
SensorToDisplayScale=24.09

# 12 steps is the most similar on a Macbook 2017 running Arch compared to MacOS
LevelSteps=12
# Plays the 12 step effectively at 30 FPS 32ms
AnimationDelay=0.032


# Read the variable names
MinimumBrightness=001

# Keyboard Stuff
EnableKBControl=true

# Max Brightness
KBMaxBrightness=80

# Screen brightness in % to turnoff backlight
KBScreenCutoff=50


# 2 : Default | 1 : Add Offset | 0 : Subtract Offset, Recommended not to change
op=2


# Only look for flags -i or -d with an additional value
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

# Verify offset file exists and if so read it
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

# relatively change number in Offset file and write it
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


# Built int keyboard backlight support
# These are hard coded for now
MaxKBBrightness=$(cat  /sys/class/leds/chromeos::kbd_backlight/max_brightness)
KBLightPath=/sys/class/leds/chromeos::kbd_backlight/brightness


#Set the current light value so we have something to compare to
OldSensorLight=$(cat $LSensorPath)

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
    
    MaxOld=$((OldSensorLight + OldSensorLight/LightChange))
    MinOld=$((OldSensorLight - OldSensorLight/LightChange))


    if [[ $Light -gt $MaxOld ]] || [[ $Light -lt $MinOld ]]
    then

      # Store new light as old light for next comparison
      OldSensorLight=$Light

      CurrentBrightness=$(cat $BLightPath)

      # Add MinimumBrightness here to not effect comparison but the outcome
      Light=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; $Light +  (  ($MaxScreenBrightness  * ( $MinimumBrightness / 100 )) / $SensorToDisplayScale )  " | bc ))
      
      # Generate a TempBackLight value for the screen to be set to
      # Float math thanks Matthias_Wachter 
      TempBackLight=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; $Light * $SensorToDisplayScale" | bc))

      # Check that we dont ask the screen to go brighter than it can
      if [[ $TempBackLight -gt $MaxScreenBrightness ]]
      then
          NewBackLight=$MaxScreenBrightness
          KBLightNew=0
      else
          NewBackLight=$TempBackLight
          # Calculate Keyboard Backlight value for screen brightness
          KBLightNew=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; ( 1 - ( $NewBackLight / $MaxScreenBrightness ) ) * $KBMaxBrightness  " | bc ))
      fi

    

        # Get new screen brightness as a % and then set the keyboard using its limits
      ScreenPrecentage=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; ( $NewBackLight / $MaxScreenBrightness  ) * 100  " | bc ))


          
      # How different should each step be
      DiffCount=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; ( $NewBackLight - $CurrentBrightness ) / $LevelSteps" | bc ))
       
      # Calculate Keyboard step
      CurrentKBBrightness=$(cat $KBLightPath)
      KBDiffCount=$(LC_NUMERIC=C printf "%.0f" $(echo "scale=2; ( $KBLightNew - $CurrentKBBrightness ) / $LevelSteps" | bc ))

      # Step once per Screen Hz to make animation
		  for i in $(eval echo {1..$LevelSteps} )
		  do

            # Set new relative light value
			  NewBackLight=$(( $DiffCount ))


                # Get current screen brightness
              CurrentBrightness=$(cat $BLightPath)

              FakeBackLight=$(( $NewBackLight + $CurrentBrightness))

              if [[ $FakeBackLight -gt $MaxScreenBrightness ]]
              then
                  NewBackLight=$MaxScreenBrightness
                  echo "ERROR : ATTEMPTED TO MAKE SCREEN TO BRIGHT!!"
              else
                  echo $FakeBackLight > $BLightPath
              fi

            
              # KEYBOARD LOGIC
              if [[ $EnableKBControl ]]
              then
                  KBLightNew=$(( $KBDiffCount ))

                  CurrentKBBrightness=$(cat $KBLightPath)
                  FakeKBLight=$(( $KBLightNew + $CurrentKBBrightness))

                  if [[ $KBScreenCutoff -gt ScreenPrecentage ]]
                  then 
                      # Limit Keyboard Brightness
                      if [[ $FakeKBLight -gt $KBMaxBrightness ]]
                      then
                          FakeKBLight=$KBMaxBrightness
                      fi

                  else
                      FakeKBLight=0
                  fi


                  echo $FakeKBLight > $KBLightPath

              fi


            
              #time for animation
			  sleep $AnimationDelay

		  done

      
    fi
   
		sleep $SensorDelay
done



