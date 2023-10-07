# Mac-like-automatic-brightness
A simple script to provide a "Mac" like automatic brightness adjustemnt/ animation

made for the FrameWork laptop

read ```Configuration``` for detailed informatoion about what options you have to easily  customize/ adjust the bightness or animation speed

## Requires 
brightnessctl

## Non 12th Gen Intel Framework Owners
Your sensor has a diffrent range thant the 12th Gen Intel Framework laptop sensors, please see chart bellow


           Type     |  Sensor Rnge | STDScale
     11th Gen Intel | 0 - 3207633  | 1
     12th Gen Intel | 0 - 3984     | 24

## Controls
```./AutomaticBrightness.sh | Defualt running mode of script```

```./AutomaticBrightness.sh -i [NUMBER] | Increase the offset your brightness sensors raw reading ```

```./AutomaticBrightness.sh -d [NUMBER] | Decrease the offset your brightness sensors raw reading ```

```/tmp/AB.offset | Stores current offset for the sensor```

```/tmp/AB.stop  | Stops AutomaticBrightness.sh```

```/tmp/AB.start | Starts stopped AutomaticBrightness.sh``` 

```/tmp/AB.kill  | Kills AutomaticBrightness.sh```

when running you will see a ```AB.running``` file and ```AB.offset`` in ```/tmp```


## Configuring
```Light Change``` The percent of light change needed to be seen by the sensor for it to change the screen brightness

```SensorDelay``` Time in seconds the script will wait to check the sensor for a luminess change after the animation (LevelSteps * AnimationDelay)

```SensorToDisplayScale``` The ratio from sensor to screen brighness, recommended minimum 24  for 12th gen framework laptops. Increasing the value will give a brighter screen for the amount of light in the room/ enviroment

```LevelSteps```  Sets amount of brightness steps, recomended to match refeshrate

```AnimationDelay```  Speed of the brightness animation(delay between each step), recomended screen refreshrate in seconds

```MaxScreenBrightness``` The highest value your screen supports, check ```/sys/class/backlight/intel_backlight/max_brightness``` on framework laptops

```MinimunBrightness``` The minimum screen brightness, recomended minumim 001 so the backlight dosn't turn off

~~ Other things to note

```Light```  The file where your lightsensor has its current value

```CurrentBirghtness```  The file where your screen stores its current brightness 
