# Mac-like-automatic-brightness
A simple script to provide a "Mac" like automatic brightness adjustemnt/ animation

made for the FrameWork laptop

read ```Configuration``` for detailed informatoion about what options you have to easily  customize/ adjust the bightness or animation speed

## Requires 
brightnessctl

## Configuring
```LevelSteps```  Sets amount of brightness steps, recomended to match refeshrate

```AnimationDelay```  Speed of the brightness animation(delay between each step), recomended screen refreshrate in seconds

```MaxScreenBrightness``` The highest value your screen supports, check ```/sys/class/backlight/intel_backlight/max_brightness``` on framework laptops

```SensorDelay``` Time in seconds the script will wait to check the sensor for a luminess change after the animation (LevelSteps * AnimationDelay)

```MinimunBrightness``` The minimum screen brightness, recomended minumim 001 so the backlight dosn't turn off

```SensorToDisplayScale``` The ratio from sensor to screen brighness, recommended minimum 24  for 12th gen framework laptops. Increasing the value will give a brighter screen for the amount of light in the room/ enviroment

~~ Other things to note

```Light```  The file where your lightsensor has its current value

```CurrentBirghtness```  The file where your screen stores its current brightness 
