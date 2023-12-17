#!/bin/bash

#variables to run

#decrease cpu usage
Priority=19 # CPU limit, adjust as needed

# How much light change must be seen by the sensor before it will act
LightChange=10

# How often it checks the sensor
SensorDelay=1

# Scale sensor to display brightness range
SensorToDisplayScale=24

# This should match your refresh rate otherwise it will either change the backlight more times than needed or too few for a smooth animation
LevelSteps=60

# The is should match the LevelSteps but in the actual time each event should take to see
AnimationDelay=0.016

# Read the variable names
MaxScreenBrightness=937
MinimumBrightness=1

# 2 : Default | 1 : Add Offset | 0 : Subtract Offset, Recommended not to change
op=2

#place where you get the brightness of the monitor being controled and the sensor of brightness
MonitorBrightness=/sys/class/backlight/intel_backlight/brightness

AnbientSensorIlluminance=/sys/bus/iio/devices/iio:device5/in_illuminance_raw

#Normal Mode, if the file offset is set to 1. Darker Mode if set to 0
# the offset file in /tmp/AB.offset will start with 0 so darker mode is default
# setting to 1 will enable normal mode. (darker mode ignores brightness set if iluminance is 0 and will set display to actual_brightness=1

# Function to smoothly decrease brightness
#darker mode
smoothly_decrease_brightness() {
  current_brightness=$(cat $MonitorBrightness)
  target_brightness=1   # can be set to 0 or more when illuminance is 0.

  steps=60  # You can adjust the number of steps for smoother transition
  animation_delay=0.016

  diff_count=$((($target_brightness - $current_brightness) / $steps))

  for ((i = 1; i <= $steps; i++)); do
    new_brightness=$((current_brightness + i * diff_count))
    brightnessctl -q s $new_brightness
    sleep $animation_delay
  done

  # Set the final brightness value
  brightnessctl -q s $target_brightness
}

while getopts i:d: flag; do
  case "${flag}" in
    i) op=1
       num=${OPTARG};;
    d) op=0 
       num=${OPTARG};;
  esac
done

if [[ -f /tmp/AB.offset ]]; then
  OffSet=$(cat /tmp/AB.offset)
else
  OffSet=0
  echo $OffSet > /tmp/AB.offset
  chmod 666 /tmp/AB.offset
fi

OffSet=$((OffSet < 0 ? 0 : OffSet))

if [[ $op -lt 2 ]]; then
  if [[ $op -eq 1 ]]; then
    OffSet=$((OffSet + num))
  else 
    OffSet=$((OffSet - num))
  fi

  OffSet=$((OffSet < 0 ? 0 : OffSet))
  echo $OffSet > /tmp/AB.offset
  chmod 666 /tmp/AB.offset
  exit
fi


# Set the priority of the current script and says it is running
renice "$Priority" "$$"
touch '/tmp/AB.running'


OldLight=$(cat $AnbientSensorIlluminance)

until [ -f /tmp/AB.kill ]; do
  if [[ -f /tmp/AB.stop ]]; then
    rm '/tmp/AB.stop'
    rm '/tmp/AB.running'

    until [[ -f /tmp/AB.start ]]; do
      sleep 10
    done

    rm '/tmp/AB.start'
    touch '/tmp/AB.running'
  else
    if [[ -f /tmp/AB.offset ]]; then
      OffSet=$(cat /tmp/AB.offset)
    else
      OffSet=0
      echo $OffSet > /tmp/AB.offset
      chmod 666 /tmp/AB.offset
    fi

    Light=$(cat $AnbientSensorIlluminance)
    Light=$((Light + OffSet))

    if [[ $Light -lt $LightChange ]]; then
      MaxOld=$((OldLight + LightChange))
      MinOld=$((OldLight - LightChange))
    else
      MaxOld=$((OldLight + OldLight/LightChange))
      MinOld=$((OldLight - OldLight/LightChange))
    fi

    if [[ $Light -gt $MaxOld ]] || [[ $Light -lt $MinOld ]]; then
      CurrentBrightness=$(cat $MonitorBrightness)
      Light=$(( $Light + $MinimumBrightness ))
      TempLight=$(($Light * $SensorToDisplayScale))

      if [[ $TempLight -gt $MaxScreenBrightness ]]; then
        NewLight=$MaxScreenBrightness
      else
        NewLight=$TempLight
      fi

      DiffCount=$(( ($NewLight - $CurrentBrightness)/$LevelSteps ))

      for i in $(eval echo {1..$LevelSteps}); do
        NewLight=$(( $DiffCount ))

        if [[ $NewLight -lt 0 ]]; then
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

#darker mode activated
    if [[ $Light -lt 1 ]]; then
      smoothly_decrease_brightness
    fi

    sleep $SensorDelay
  fi
done

rm '/tmp/AB.running'
rm '/tmp/AB.kill'
