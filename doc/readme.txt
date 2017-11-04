Available online at: http://papilio.cc/index.php?n=Playground.BombJack

3/May/2012

!Bomb Jack implementation in FPGA
Author: Alex

<Link To Project Here>

!!Background

This project started late 2011 as a way for me to further hone my VHDL skills. I didn't want to re-do Pac Man or Frogger, I wanted to implement a game that hadn't been done before in an FPGA. Looking around the net, I found a treasure trove of old arcade schematics and after sifting though them, Bomb Jack (BJ from now on) caught my eye. The main reasons why I settled on BJ were that no one had implemeted it before in an FPGA, the schematics were of great quality and it used standard hardware of that era, such as discrete TTL logic, Z80 CPU and AY-3-8192 sound generators. I knew these cores were already available and I could stand on the shoulders of giants and not have to re-implement the CPU and audio chips, instead focus on translating the schematic to VHDL.

!!Roadblocks

In my eagerness to begin, I threw caution to the wind and didn't go through a resource planning stage, I simply went page by page in the schematic and translated all the chips to VHDL code, connecting everything together. This was a fairly tedious process for the most part, but also challenging, in trying to figure out the proper VHDL constructs and solve various implementation issues. This can be seen in the project source code, where each page of the schematic is implemeted in it's own corresponding VHDL file. I've also kept the chip notation inside the VHDL code as per schematic, namely a number letter pair identifying the board row/column where the chip is located. In the case where a specific gate within a chip needs to be identified, an optional number follows specifying the pin where the output connects. For example, 1T8 refers to chip located at coordinates 1,T on the board. It is a LS08 quad AND gate as seen in the schematic. Furthermore 1T8 refers to one of the four gates in the chip, the gate with output exiting at pin 8 of the chip.


Once the translation from schematic to VHDL was complete, I came across what seemed like an insurmountable problem. The game uses a total of 16 ROM chips adding up to 112Kb of memory but my FPGA, a S3E500 only has internal space for 40Kb. This issue would have come up earlier had I bothered to go through a planning stage. In hindsight, it was probably serendipitous, as if I had figured this out early, I might not have started the project at all. Now that I had spent all this time and effort, I was invested. Even so, I had to put this project on ice for the rest of 2011 until through sheer luck, Jack Gasset donated a beta Papilio Plus board. The P+ uses a LX9 FPGA but the board also has a 512Kb of static RAM chip. This was perfect for this project and early this year I picked up the project again and attempted to progress it.

!!More Roadblocks

The next problem I encountered was the fact that the video circuit uses a total of 10 ROM chips. Even if you consider that some ROM chips share a data bus, that still leaves one ROM chip with a 8 bit data width and three ROMs with a 24 bit width. That's without even counting the main CPU program ROMs and the audio CPU program ROM. The problem is that all these ROMs are constantly accessed simultaneously and in different clock domains, for example the CPU ROMs are accessed synchronous to the CPU clock which is 4Mhz but the video ROMs are synchronous with the 6Mhz video clock and the audio CPU ROMs runs at 3Mhz, which at least is in sync with the 6MHz clock.

But I only have one single SRAM chip to store them all in. How can I fake having a bunch of separate ROM chips by only using a single SRAM chip? After a fair amount to simulation and examining the circuit diagram, it turns out the answer is time division multiplexing. By running the SRAM on a 48Mhz clock, it turns out is possible to fake the appearance of multiple ROM chips by storing them in different areas of the SRAM and quickly reading each ROM address and presenting the data to the target just in time.

By also taking advantage of the FPGA's built in BRAM blocks, it was possible to store the main and audio CPU ROMs inside the FPGA (total of 48Kb = 24 BRAMs) and only have to retrieve the video ROMs from external SRAM, which are inside the same clock domain.

!!Final stumble

So now we have a bunch of ROMs that need to be available inside the SRAM chip at power on, but the SRAM is a volatile storage medium. This is where the SRAM bootstrap comes in. The bootstrap project ([[Playground.Bootstrap]]) which I published on the Papilio Code Playground back in February is a direct result of this BJ project. You can read the details at the link above but briefly, on power on or reset, the boostrap takes over the SRAM chip buses and copies the contents of the serial FLASH chip in to the SRAM, then releases the SRAM buses to the user and signals it is done. The user portion, in this case the actual BJ circuit, uses that signal as its reset, so when the boostrap is done, the BJ circuit comes out of reset state and is free to run and access the SRAM.

!!Debugging
By far the lengthiest part of this project was debugging the game so it runs correctly (or at all). After writing some test jigs and testing the easy schematic pages, such as the input switches on page 2 and the video and timing signal generator on page 3, I started the debug process from the video output and moved backwards.

This meant starting with page 8, the color palette circuit. This was fairly simple to debug but it needed something to initialise the palette RAM and drive it. I decided to build a simple state machine test jig that would replace the CPU and simply initialize the palette RAM by writing the values to address space based at 0x9c00 then drive one of the priority encoder inputs such as for example BC/BV. The priority encoders 5F,H,J,K on page 8 are arranged such that when supplied with simultaneous video signals on inputs BC/BV, SC/SV and OC/OV they prioritise these signals such that BC/BV has the lowest priority (this is the background picture), SC/SV has the next highest priority (this is the character generator) so it always appears "on top" of the background and OC/OV has the highest priority (these are the sprites) so they would be displayed "on top" of both characters and background.

The next step was to drive the palette circuitry and by examining the schematic I decided the easiest and best part to get going next was the background generator on page 7. This generates the in game backgrounds and it doesn't even depend much on the CPU driving it, the CPU simply writes a value to address 0x9e00 to select a background and then leaves it alone while the circuit continuously generates the background and shifts it out to the video output. The test jig I'd built earlier fit the bill perfectly adding this new schematic page to it and before long I could see my first real game pictures. I could cycle through all the game background pictures, though the colors were off as it seems each background uses a different palette. Nevertheless this was a great step forward as it was the first real video from this whole project that looked like part of the original game.

The next part to get going would logically be the character generator on page 6, as it is not much different from the background generator circuit on page 7 except for the index ROM 4P is now replaced with a SRAM chip 6LM. This means that it would now be more difficult to drive this with my test jig, so I'd actually have to implement the main CPU. I quickly decided to move all the main CPU ROMs to external SRAM since that didn't require any multiplexing and shift as many video ROMs to internal BRAMs which are truly independent and can easily emulate multiple independent ROMs. After testing in the simulator that the main CPU executes instructions from its program ROMs I tried running the whole game on the FPGA. This didn't initially just work but after some more simulator action and tweaking of the timing of some signals and fixing up some minor bugs, the video screen showed the game booting up through its power on self test routine, with all ROMs passing the test and most of the RAMs too, then the initial high score table would be displayed. As I let the game run through it's demo mode, I couldn't of course see any sprites as they hadn't been tested and were also comented out, but I could see the background and the in game graphics that consisted of characters only, such as the platforms and bombs and their colors matched what I expected to see from MAME.

One thing that puzzled me for a while was that the Bomb Jack logo on the startup screen would be missing its top part completely. It was not until much later when I implemented the sprites, that the mystery was solved, that missing top part of the logo is built with sprites not characters!

The final part of the circuitry was pages 4 and 5 and proved to be the most complex to debug. This is the sprites generator (page 4) and sprite positioning (page 5). The problem I had was that simulating this was hard, in that simply running the game in the simulator was not an option because the sprites don't appear on screen until about a minute after power on. It takes several hours to simulate one single second of circuit action. This is where I had to break out IDA and dig through the disassembly of the game ROMs, then find suitable patch locations to force the game to skip portions I wasn't interested and just jump to where I needed it to. At this point there wasn't enough memory space inside the FPGA to keep all the video ROMs, so since the background generator had already been tested I commented out its ROMs and brought in the character generator and sprite generator ROMs. I'm not exagerating when I say this portion of the debug took a couple of months on an off working into the evening simulating and examining the traces. Initially I got page 4 working which finally displayed some sprites to the screen but they only moved left-right as page 5 had not been implemented. There was also something that bothered me immensely, while sprites appeared to work, the death sequence animation of Bomb Jack showed corrupt  graphics across the entire row that Bomb Jack occupied. I put this aside for now and continued with page 5.

The sprite positioning on page 5 was a bit of a head scratcher, as soon as I brought it in, the sprites would disappear completely. Much time spent in the simulator showed this to be a timing issue. The RAMs on page 5 have the 6Mhz clock connected to their R/W line, this means the RAMs are read when the clock is high and written to, when the clock is low. Essentially they are accessed twice inside a single 6Mhz clock cycle. Once that was apparent, I brought in a 12Mhz clock line to the chip in order to get it working double time however that didn't prove to be as simple as I thought. More simulator action showed very subtle timing issue with the clocks, in that the 6 and 12 Mhz clocks cannot have coincident edges, so I inverted the 12Mhz clock in order to shift its edge to the middle of each 6Mhz clock half cycle. Presto! The sprites finally appeared in all their glory. Yet the death animation corruption issue remained...

Back to the simulator. I must as as aside, say that the simulator is absolutely invaluable. Without simulation, it would have been very very hard, if not impossible to track down some of the bugs or other subtle issues encountered here. At this point I patched some test code into the VGA scan doubler so that it writes its input signals to a .ppm file. What is special about this is that a ppm file (portable pixmap format) is actually an uncompressed image file (similar to a bitmap) but entirely in text format. As I run the simulator, a sequence or ppm files would be output each corresponding to a video frame, which I could then view with a graphics program. This allowed me to see at exactly which frame the faulty sprites appeared. The cause of all this grief turned out to be very simple, I had incorrectly inverted the signal coming out of gate 7C6 on page 4. This was a very simple mistake that proved very costly in terms of time to track down.

As troubleshooting the video section took such a long time, in order to not lose my mind working on the same problem over and over without making much progress, I decide to take a "break" and work on the audio section. This is a fairly simple setup, a CPU with ROM and RAM driving three identical programmable sound generators (PSGs). These are AY-3-8192 types but there is a proven YM2149 core written by MikeJ of fpgaarcade.com, YM2149 being identical to the AY-3-8192 chip apart from one pin that lets you run the YM at double clock (by causing the chip to halve the clock internally).

Again since the audio circuitry on page 9 and 10 is quite self sufficient, it just needs a value written to its input latch to select which sound to play, I decided to write a test jig for it, but one that could be run on the FPGA, not just the simulator, and by using buttons select what value to write to the audio board while displaying relevant info on the VGA screen using another one of my projects, the [[Playground.VGA7SEG]]

The main problem initialy encountered here was that some of the signals are not labeled on the schematic, such as the clock to the PSGs, the mystery signal feeding the flip-flop which goes to the CPU NMI input, some signals were mismatched in their labeling, such as the /SIORQ from the CPU that really does go to IORQ at chip 5D. However when all those were sorted by referencing the source code for MAME for clues, the audio board finally played sound effects and music. One small issue that arose during testing was that the background music seemed to be missing one of the audio channels. Simulation showed that the audio CPU was explicitly writing the register of the PSG to actively mute that channel. This was very strange until after more debugging and talking to MikeJ the solution presented itself. I was missing the chip select to the RAM. By having the RAM permanently enabled, some writes from the CPU that should not have gone to the RAM at all, were in fact writing memory corrupting it, causing the CPU to the write incorrect data to the PSGs.

Up to this point, the CPU ROMs were running out of external SRAM and the video ROMs from internal FPGA BRAMs, and there wasn't even enough room for those inside the FPGA, so I'd had to comment out some ROMs such as the background generator ROMs. It was finally the time to shift everything around. I moved the audio and main CPU ROMs to internal BRAMs and all the video ROMs to external SRAM, but I was still one BRAM short fitting everyting in the FPGA. I eventually changed the color palete design on page 8 so instead of using BRAMs, it uses vector arrays, which at syntesis are mapped to lookup tables and not BRAMs.

There was yet more simulator required to figure out the exact times to read the external SRAM and present the data to the appropriate places inside the FPGA in order to mimic having a bunch of separate ROMs and fixed some more minor bugs, such as having some of the sprites colors wrong when running from external SRAM because I'd incorreclty swapped around some of the ROM chip address mapping, but it eventually all finally fell into place and I had the whole game running as it should.

!!Building the project

The project is organised into a number of folders relative to the main project folder, all the source code lives in /source, the BJ original ROMs are expected to be in /roms/bombjack and some handy scripts live in /scripts while relevant documentation can be found in /doc. Finally the Xilinx build occurs in the /build directory which can become cluttered with temp files after each build. Feel free to delete all files in there but make sure you keep the .xise project files.

The basic steps to build this project are:
 1) copy the binary ROM files to /roms/bombjack
 2) run /scripts/build_roms_bombjack.bat to translate the binary ROMs to VHDL code
 3) run /build/bombjack.xise to start the Xilings ISE environment and generate the fpga bit file.
 4) run /scripts/build_fpga_image.bat to concatenate the ROMs to the FPGA bit file
 5) finally burn the resulting /scripts/fpga.bin file to FLASH using the command "papilio-prog.exe -b bscan_spi_lx9.bit -f fpga.bit"

It is important to burn the fpga.bit to FLASH rather than just soft upload it to the FPGA because the game ROMs must be present inside the FLASH so that the bootstrapper can then copy them to SRAM at power on.

!!Limitations
This project as it stands now, uses all 32 BRAM blocks of the LX9 FPGA, so it would not be easy to port it to another FPGA with fewer BRAMs unless either or both the main and audio CPU ROMS could be run from external SRAM. The largest ROMs, are the main CPU ROMs, totalling 40Kb or 20 BRAMs, and they are the most difficult to run from SRAM due to the main CPU running at 4Mhz which does not sync up with the video ROMs being accessed on a 6Mhz clock.

As such, this project runs specifically on the Papilio Plus platform with the MegaWing add on. The button labeled RESET on the MegaWing is not used as reset but as a shift to expand the functionality of the remaining four buttons.

The control buttons are as follows:

 Buttons             Function
 RESET+LEFT          Player 1 coin insert
 RESET+RIGHT         Player 2 coin insert
 RESET+UP            Start one player game
 RESET+DOWN          Start two player game

 UP+DOWN+LEFT+RIGHT  Hardware reset

 UP                  In game up + jump button (these would be separate on the original game)
 DOWN                In game down button
 LEFT                In game left button
 RIGHT               In game right button
