# Pico Swords

Pico Swords is a 1-2 player game for the Pico 8 where you fight off hoards
of enemies for as long as you can and rack up points!

## Controllers

I think I had to add the following line in my `sdl_controllers.txt` file
and use the "S" mode of my 8BitDo Micro to get it to work:
```
03000000c82d00002090000000000000,8BitDo Micro,a:b1,b:b0,back:b10,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b12,leftshoulder:b6,lefttrigger:b8,leftx:a0,lefty:a1,rightshoulder:b7,righttrigger:b9,rightx:a3,righty:a4,start:b11,x:b4,y:b3,platform:Windows,
```

The reference for that line is the following:

https://github.com/mdqinc/SDL_GameControllerDB/blob/master/gamecontrollerdb.txt
