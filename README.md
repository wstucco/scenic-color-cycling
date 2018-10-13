## Color Cycling Desktop App running on [Scenic](https://github.com/boydm/scenic/)

## Inspiration

The incredible pixel art of [Mark Ferrari](http://markferrari.com/art/8bit-game-art/)

He's a master of color cycling, a technique used to animate sprites by just chaning their palette

I still remember the first time I saw it at work, I couldn't believe it.

The GUI was heavily influenced by [HTML5 Color Cycling Art Gallery](http://www.effectgames.com/demos/canvascycle/)  
if you still don't think that color cycling is awesome, take a look at [this other demo](http://www.effectgames.com/demos/worlds/),
where different times of the day are recreated by shifting colors in the palette

The code to implement the cyclcing is a porting from [jtsiomb/colcycle](https://github.com/jtsiomb/colcycle)

I've only ported the `NORMAL` and `REVERSE` mode, the only two used here

I've converted the [original LBM files](https://github.com/jtsiomb/colcycle/wiki#lbm-images) to PNG with [XNviewMP](https://www.xnview.com/en/xnviewmp/)

## Prerequisites

Follow the instruction and install [the `scenic_driver_glfw`](https://github.com/boydm/scenic_new#install-prerequisites)

## Clone and run

`git clone https://gitlab.com/wstucco/scenic-color-cycling.git`  
`cd scenic-color-ciclyng`  
`mix deps.get`  
  
`mix scenic.run`

documentation will follow soon  
Enoy the beast!

![Shadow of the Beast](priv/static/screenshot.png "Shadow of the Beast")
