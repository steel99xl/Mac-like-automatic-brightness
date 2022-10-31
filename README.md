# Mac-like-automatic-brightness
A simple script to provide a "Mac" like automatic brightness adjustemnt/ animation

made for the FrameWork laptop

## Requires 
brightnessctl

## Configuring
```LevelSteps```  Sets amount of brightness stesp, recomended to match refeshrate

```AnimationDelay```  Speed of the brightness animation, recomended screen refreshrate in seconds

```MaxScreenBrightness``` The highest value your screen supports, check your /sys/class/backlight/{GPU_MAIN_SCREEN}/brightness

```SensorDelay``` Time in seconds the script will wait to check the sensor for a luminess change

```MinimunBrightness``` The minimum screen brightness, recomended minumim 001 so the backlight dosn't turn off

```SensorToDisplayScale``` The ratio from sensor to screen brighness, recommended minimum 24 for 12th gen framework laptops. The script will limit the max values to MaxScreenBrighness
