# Mac-like-automatic-brightness
A simple script to provide a "Mac" like automatic brightness adjustemnt/ animation. 
## Now as a system service 
Run ```setup.sh``` to make it a service and automaticaly set your ```SensorToDisplacScale```

made for the FrameWork laptop

based on 2017 MacBook Pro

read ```Configuration``` for detailed informatoion about what options you have to easily  customize/ adjust the bightness or animation speed

## Requires 
```bc```

For running in as your user you need to be part of the ```vidoe``` group 
```sudo usermod -a -G vido $USER``` if your not apart of the group

If your installing as a system service your user dose not need to be apart of the group

## Non 12th Gen Intel Framework Owners
Your sensor has a diffrent range thant the 12th Gen Intel Framework laptop sensors, please see chart bellow


           Type     |  Sensor Rnge | STDScale
     11th Gen Intel | 0 - 3207633  | 1
     12th Gen Intel | 0 - 3984     | 24
     Dell Insp 7359 | 0 - 15000    | 20 

## Controls
```./AutomaticBrightness.sh | Defualt running mode of script```

```./AutomaticBrightness.sh -i [NUMBER] | Increase the offset your brightness sensors raw reading ```

```./AutomaticBrightness.sh -d [NUMBER] | Decrease the offset your brightness sensors raw reading ```

```/dev/shm/AB.offset | Stores current offset for the sensor```

* Changing the offset of your backlight while the service is running is one way you increase or decease your screen bightness but keep the automatic adjustments when the lighting changes 



## Configuring
```Light Change``` The percent of light change needed to be seen by the sensor for it to change the screen brightness

```SensorDelay``` Time in seconds the script will wait to check the sensor for a luminess change after the animation (LevelSteps * AnimationDelay)

```SensorToDisplayScale``` The ratio from sensor to screen brighness, recommended minimum 24  for 12th gen framework laptops. Increasing the value will give a brighter screen for the amount of light in the room/ enviroment

```LevelSteps```  Sets amount of brightness steps, recomended to match refeshrate

```AnimationDelay```  Speed of the brightness animation(delay between each step), recomended screen refreshrate in seconds (0.16 of 60Hz)

```MinimunBrightness``` The minimum screen brightness, recomended minumim 001 so the backlight dosn't turn off

### Run``` setup.sh -u``` to update the installed script and service

~~ Other things to note but shouldn't have to adjust

```Light```  The file where your lightsensor has its current value

```CurrentBirghtness```  The file where your screen stores its current brightness 

```MaxScreenBrightness``` The highest value your screen supports, check ```/sys/class/backlight/intel_backlight/max_brightness``` on framework laptops
