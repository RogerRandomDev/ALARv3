# ALAR V0.0.1_ALPHA

First official release of my sandbox game ALAR.
Produced over multiple iterations as a benchmark for my skill in programming, along with testing new concepts in coding.
Reached a level where I felt like actually making it a full game, so here we are.

# Chunk Saving System

Stores chunks in sets of 64, 8x8 per file.
Each file formats with 128 bytes in front, 2 per chunk, telling the game how big each chunk is on the file.
I rewrote this code roughly 16 times before I finally had a working version.
My understanding of handling raw bytes was poor, so I bet that future me would have an epiphany.
Seeing as you are reading this, it means my bet paid off. Had to sleep on it a few times.
The chunk is 2 bytes per tile, first is 1 to 1 as an int, and second is multiplied by 256 for allowing many more tiles than 256 to be made.
if the second byte is greater than 253, it is  treated as an empty tile.

# Resource Packs

Resource packs allow any png, but it does not scale them with size, so stick to 8x8 when you can.
The player sheet can also be changed out.
to make a texture animated, use godot animatedTextures.




## Author
- [@RogerRandomDev](https://www.github.com/RogerRandomDev)


## Features

- Partial controller support
- Linux/Windows Compatibility


