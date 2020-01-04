# Bilinear-Interpolation

The Bilinear Interpolation is a simple program written in MIPS assembly language using MARS Simulator. Program allows user to specify width and height of a drawn rectangle as well as four colors of every vertices in order : upper left, upper right, lower left, lower right. Output rectangle is saved in heap address range and can be displayed using build-in MARS Bitmap Display set with a width parameter to 1024.

## Inputs of a program 

| Parameter | Description |
| ------------- | ------------- |
| _width_ | The width of a drawn rectangle. Value range between <0; 1024>. |
| _height_ | The height of a drawn rectangle. Value range arbitrary but depending from a MARS Bitmap Display configurations. |
| _color_ | Color of a upper left vertex. RGB value specified as a decimal value. |
| _color_ | Color of a upper right vertex. RGB value specified as a decimal value. |
| _color_ | Color of a lower left vertex. RGB value specified as a decimal value. |
| _color_ | Color of a lower right vertex. RGB value specified as a decimal value. |

__Beware that program assumes the correctness of input therefore unknown behaviour may appear if wrong input is specified!__

## Program output

Below you can see example of output for :

| Input | Value |
| ------------- | ------------- |
| _width_ | 800 |
| _height_ | 500 |
| _color_ | 255 (Blue) |
| _color_ | 65280 (Grenn) |
| _color_ | 16711680 (Red) |
| _color_ | 16711935 (Magenda) |

Output : 

 ![alt text](https://db3pap002files.storage.live.com/y4mL0jyDWpNCbdegNT36I87Yo5-6zohtihgEl8hPkcw8rlT2xZmNMKSPwEI1MbRuX_zvd-IGMncUVj9bXUE9fm08QUL2owfivABDH9o8kwjPdD25ynd4ysqlUItsCfJU8QQ-MwU9JopAf1XAaiu6p8EYZMovyaYSJ2PJb6A7GC5xh7Yu9QbwufaX6z_Ul6WR5ff0boYzFT4KDbSZdS1tOXlXQ/Bez%C2%A0tytu%C5%82u.bmp?psid=1&width=1168&height=515)
 
 ### Implementation detailed
 
 * Fixed point arithmetic 16.16 was used.
 * Desctiption of an algorithm can be found on _Wikipedia_ website ( https://en.wikipedia.org/wiki/Bilinear_interpolation )
