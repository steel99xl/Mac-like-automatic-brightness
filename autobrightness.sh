#!/bin/bash
# Slight Alteration of AutomaticBrighness.sh (could be a dell specific fork)

#variables to run

#decrease cpu usage
Priority=19 # CPU limit, adjust as needed

# How much light change must be seen by the sensor before it will act
LightChange=10

# How often it checks the sensor
SensorDelay=1

# Scale sensor to display brightness range
SensorToDisplayScale=20

# This should match your refresh rate otherwise it will either change the backlight more times than needed or too few for a smooth animation
LevelSteps=60

# The is should match the LevelSteps but in the actual time each event should take to see
AnimationDelay=0.016

# Read the variable names
MaxScreenBrightness=937
MinimumBrightness=1

#minimum illuminance to get minimum brightness

MinimimumIlluminance=0

# 2 : Default | 1 : Add Offset | 0 : Subtract Offset, Recommended not to change
op=2

#place where you get the brightness of the monitor being controled and the sensor of brightness
MonitorBrightness=/sys/class/backlight/intel_backlight/brightness

#my sensor keep changing places, this way it will always be found with * if you have lots of sensors

AnbientSensorIlluminance=/sys/bus/iio/devices/iio:*/in_illuminance_raw 


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
    RealLight=$(cat $AnbientSensorIlluminance)
    Light=$((Light + OffSet))
    RealLight=$((RealLight + OffSet))

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
        LimitMaxIlluminanceReached=1
      elif [[ $RealLight -le $MinimimumIlluminance ]]; then
        NewLight=$MinimumBrightness
        LimitMinIlluminanceReached=1
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
        
        if [[ $i -eq $LevelSteps ]]; then
          brightnessctl -q s $NewLight
          
          if [[ $LimitMaxIlluminanceReached -eq 1 ]]; then
            NewLight=$MaxScreenBrightness
            LimitMaxIlluminanceReached=0
          fi
          
          if [[ $LimitMinIlluminanceReached -eq 1 ]]; then
            NewLight=$MinimumBrightness
            LimitMinIlluminanceReached=0
          fi
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
