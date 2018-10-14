## Color Cycling Desktop App running on [Scenic](https://github.com/boydm/scenic/)

## Inspiration

The incredible pixel art of [Mark Ferrari](http://markferrari.com/art/8bit-game-art/)

He's a master of color cycling, a technique used to animate sprites by just chaning   
their palette.

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

## How it works

This is an implementantion of the color cycling technique in Elixir and [Scenic](https://github.com/boydm/scenic/)

Scenic works in retained mode, it doesn't allow you to write pixels on screen directly.

However, among Scenic's primitives there is the `rectangle` that can be filled  
with an image, loaded from disk.

What if we change the pixels of the image in memory and draw it back on screen?  
That's exactly what I did here.

Pngs are loaded into memory, parsed with the [`parse`](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/png.ex#L20) function of the [`PNG`](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/png.ex) module,   
their palette is transformed using the [`Palette`](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/color-cycling/palette.ex) module, the PNG
is re-written as a   
bitstring using the [`write`](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/png.ex#L52) function and then [loaded back into Scenic's cache](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/components/color_cycling.ex#L158).

If the `color blending` checkbox is checked, [the colors between two palette states  
are linearly faded](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/components/color_cycling.ex#L68)   one into the other.

The interval between two states is 6 frames long and gives a much smoother animation,  
especially at lower frame rates (try tho move the slider to 0.25 and activate/deactivate  
the color blending to see the difference)

As soon as this process is completed, the `:fill` attribute for the rectangle containing  
the image is updated and when Scenic refresh the screen, the new image appears.

This process is repeated for each frame.

When another animation is selected, [the images cached in memory for the previous   
one are released](https://gitlab.com/wstucco/scenic-color-cycling/blob/78735a67bf495df49ff8551fa082e7a0519a08b5/lib/components/color_cycling.ex#L83), to avoid trashing memory.

## Preview

![Color Cycling App demo](priv/color-cycling.mp4)
