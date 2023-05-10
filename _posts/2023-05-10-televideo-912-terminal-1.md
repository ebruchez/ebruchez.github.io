---
layout: post
title: The TeleVideo TVI-912 terminal - Part 1
author: Erik Bruchez
date: '2023-05-10T11:21:00-07:00'
tags:
category: Technology
---

## Introduction

I recently won a computer terminal at a local auction. I bid on it because I had been hoping to find a vintage computer terminal for a while, so I could connect it to my [Altair-Duino](https://adwaterandstir.com/product/altair-8800-emulator-kit/) or [PiDP-11](https://obsolescence.wixsite.com/obsolescence/pidp-11) kits. This one looked cool, I thought I would not win the auction, and then I did![^compupro]

[//]: # (![The terminal as I got it]&#40;/assets/posts/televideo-912/2x/IMG_2764.jpg&#41;)
![The terminal as I got it](/assets/posts/televideo-912/2x/IMG_3026.jpg){:standalone}

Esthetically, I find the terminal good-looking with its curved body. It's very different from the iconic DEC VT100, which is of the same era, but there is nothing wrong with liking different styles.[^vt100]

This instance bears the marking "TeleVideo TVI-912", which is of course the brand and model number. I didn't know anything about TeleVideo terminals before this acquisition, but that changed quickly!

## Background

### TeleVideo the company

Wikipedia has a [page about TeleVideo](https://en.wikipedia.org/wiki/TeleVideo). The company was based in San Jose, California[^addresses], and made terminals until about 2011 when it definitely folded. It seems that the company was founded in 1975, although [this reference](https://web.archive.org/web/20090517093721/http://www.usu.edu/alumni/newsletter/2004/feb04.html#spot) mentions that "TeleVideo Systems, Inc. was born in March of 1979". [This other reference](http://edgar.secdatabase.com/1670/110465906016916/filing-main.htm) mentions 1975, while the [official web site](http://televideo.com/), which is only a leftover page, mentions "35 years in business" as of 2011, which points to a date closer to 1975 than 1979. It might be that the company started in 1975, but was renamed or reincorporated in the following years.

### Dating of the 912 model

The TeleVideo TVI-912 was one of the first models made by the company. It came out in 1978 or 1979:

- [This terminals wiki page](http://terminals-wiki.org/wiki/index.php/TeleVideo_912) mentions 1978 and supports this by referencing a Computerworld article announcing the device from September 4, 1978, which I cropped below:

    ![1978 Computerworld article](/assets/posts/televideo-912/2x/1978-09-04-computerworld.jpg){:standalone width="40%"}
- [This vt100.net page](https://vt100.net/televideo/) mentions 1979.
- [This page](https://www.cs.grinnell.edu/old/drupal6/TeleVideo%20TVI-912%20ASCII%20terminal.html) also mentions 1979:

    > The TVI-912, introduced in 1979, the same year TeleVideo was founded, was one of TeleVideo's earliest terminals, preceded only by the TVI-910. It supports a 96-character ASCII upper and lower case alphabet, displays 24 80-character lines on screen, and weighs in at 30 lbs. It supports 9 data rates on RS232 serial interfaces, ranging from 75 to 9600 baud (bits/second) with half-duplex and full-duplex conversation and block transfer modes.
- The manuals I found (see below) bear a copyright of 1979 at the earliest.
- The control board of my instance (see further below) shows a date of 1979 (2-79) as revision date.
- The control board also shows a copyright of 1978 for the ROMs.

Based on the article referenced above it is certain that the device was announced in late 1978, but it might not have been really on the market until 1979.

## Documentation

There is a lot of documentation about this terminal online. The following sections list what I found.

### TeleVideo Operators Reference Handbook (1979)

This is for the following models:

- TVI-912B and TVI-920B
- TVI-912C and TVI-920C

This manual has 36 pages including covers, and a copyright date of 1979. You can find it on Archive.org.

There are a couple of versions, if not more, of this manual.

![Operators Reference Handbook](/assets/posts/televideo-912/2x/televideo-operators-reference-handbook-1.jpg){:standalone width="50%"}

### Operating instructions (1979)

This is for the following models:

- Model 912
- Model 920

This has exactly the same table of contents as the previous manual, and is also dated 1979, but it has only 19 pages. I haven't compared the content with the other manual in detail.

![Operating Instructions](/assets/posts/televideo-912/2x/televideo-operating-instructions-912-920.jpg){:standalone width="50%"}

### TeleVideo Terminal Maintenance Training Manual (March 1983)

This manual has 558 pages! To be fair, 98 of those pages are manufacturer spec sheets for components. This appears to cover all the terminal models up to the March 1983 date of publication: 910, 912, 920, 925, 950, and 970. It includes full schematics of the terminals!

![TeleVideo Terminal Maintenance Training Manual](/assets/posts/televideo-912/2x/televideo-terminal-maintenance-training-manual.jpg){:standalone width="50%"}

Here is one of the pages of the schematics for the 912, showing the microcontroller:

![First page of the schematics](/assets/posts/televideo-912/2x/schematics-1.jpg){:standalone}

### "The Value Leaders" marketing brochure

This is an 8-page marketing brochure, where we learn about some features of the terminals up to model 950, including some that requires digging intom including:

- "true block mode"
- "typewriter tabbing"

Now this makes me want to find a 925 or 950 terminal! Look at these beauties!

![The Value Leaders](/assets/posts/televideo-912/2x/televideo-value-leaders-cover.jpg){:standalone width="50%"}

![Model 912/920 in the brochure](/assets/posts/televideo-912/2x/televideo-value-leaders-912-920.jpg){:standalone width="50%"}

### "Compare Smarts. Compare Prices." marketing brochure

This is a 6-page marketing brochure specifically about the 912 and 920 models. It is dated 1980. It has a lot of information about the terminals, including a comparison between the 912 and the 920 (variants B and C).

![Compare Smarts. Compare Prices.](/assets/posts/televideo-912/2x/televideo-compare-smarts-912-920.jpg){:standalone width="50%"}

### Other resources

There is a [video series on YouTube](https://www.youtube.com/playlist?list=PLAvOjNk-JGgU5tOh2xcoECoh6kCwpRUSN), mostly about cleaning a working TeleVideo 912.

## Turning it on

I took the risk of turning on the terminal. The good news is that it beeped right away! The bad news is that the screen only showed some indication of life over a vertical area in the middle of the screen. This told me that:

- maybe the control board was working, at least to some degree
- but the electronics controlling the CRT might have issues

Later, I also tried `CTRL-G`, which is the code for the "BEL" character, which is supposed to beep, but nothing happened. However, I think I might need to configure the RS-232 interface to loop back for that to have any chance to work.

Can the terminal be fixed? That's what I hope to figure out eventually.

## Opening it up

I opened the terminal: two screws in the front unlock the top of the terminal, which then swivels on its hinges in the back.

The CRT remains in the top case, with the terminal's power supply on the left, and the video control board on the right. The CRT is braced by a rusty spring:

![The CRT spring](/assets/posts/televideo-912/2x/IMG_2770.jpg){:standalone width="60%"}

I took a look at the control board. It is a beautiful large board, but it looked very dirty, with signs of corrosion.

![The dirty main control board](/assets/posts/televideo-912/2x/IMG_2775.jpg){:standalone}

Here is a close-up of the main video chip, before any cleaning:

![The main video chip](/assets/posts/televideo-912/2x/IMG_2776.jpg){:standalone}

I blew some air inside the case and on the board. I also did a first pass at cleaning the board with isopropyl alcohol. There was no change in behavior after that, unsurprisingly. But I took more detailed pictures of the terminal. Here is the terminal's two parts:

![The open terminal](/assets/posts/televideo-912/2x/IMG_3057.jpg){:standalone}

Here is the back of the terminal. The RS-232 port is visible, as well as configuration DIP switches, a contrast button, the power button, and a fuse. I believe that there should be a cover over the connector area, and if so it is missing. Instances of the terminal could have a printer port as well, but this one doesn't have it. Some of the labels had fallen off, but they were stored in a small ziploc bag attached to the terminal.

![The back of the terminal](/assets/posts/televideo-912/2x/IMG_3035.jpg){:standalone}

The keyboard of this 912 terminal has 84 keys in the "teletype" layout. Documentation shows that there were two main layout options:

- "teletype" layout, for models "B" (912B)
- "typewriter" layout, for models "C" (912C)

![The "teletype" layout](/assets/posts/televideo-912/2x/912-teletype-keyboard.jpg){:standalone}

![The "typewriter" layout](/assets/posts/televideo-912/2x/912-typewriter-keyboard.jpg){:standalone}

These options might not have been available from the start. Indeed, my terminal doesn't show a "B" or "C" suffix.

Model 920 was identical to the 912 except that it had, in addition, function keys, edit keys, and transmission keys. It, too, came in a "B" or "C" version matching the "teletype" or "typewriter" layouts.

![The "teletype" keyboard of my 912](/assets/posts/televideo-912/2x/IMG_3043.jpg){:standalone}

The board looks nicer after a basic cleaning.

![The board after cleaning](/assets/posts/televideo-912/2x/IMG_3045.jpg){:standalone}

I recognized the video output and power supply input on the board. I disconnected both, and measured the voltage on the input connector, with values close to:

- -12 V
- +5 V
- +12 V

This means the power supply is in decent shape. Here is a picture of it, attached to the upper part of the case:

![The power supply](/assets/posts/televideo-912/2x/IMG_3052.jpg){:standalone}

The other side of the upper case consists of the video control board:

![The video control board](/assets/posts/televideo-912/2x/IMG_3053.jpg){:standalone}

I note that the terminal's serial number appears in multiple places, and it is consistent: 79061208. Can we infer from that series of digits a production date of June 1979? It would make sense!

The serial appears:

- on the back of the device
- on the CRT
- on the power supply
- on the video control board

## The main control board

After cleaning the board an the main ICs, I looked up the references of the main chips, and found the following (also confirmed by the schematics):

| Chip            | Description                          |
|-----------------|--------------------------------------|
| Intel 8035      | 8-bit MCU (microcontroller unit)     |
| SMC CRT5027     | CRT Video Timer and Controller VTAC  |
| SMC COM2502     | UART                                 |
| 2 x Intel 2111A | 256 x 4 SRAM                         |
| A3              | 2KB ROM (probably the character ROM) |
| A49             | 4 KB ROM                             |
| A50             | ROM                                  |

So the terminal has 256 bytes of SRAM, with 64 bytes of internal RAM as well in the 8035, for a total of 320 bytes of RAM. That's not much to work with!

The rest of the chips consists mainly of 7400-series TTL chips.

I annotated the picture of the board with what I found.

![The main board, with annotations](/assets/posts/televideo-912/2x/board-chips.jpg){:standalone}

The CRT chip, in particular, is quite beautiful, although it too shows signs of corrosion. On a couple of pictures I found online of the 912/920 board, the chip is a regular black plastic package. Here we have what is probably a ceramic package, with golden pins and a golden cover (but then how is it that it appears corroded?). This might be an earlier version of the chip.

![The CRT chip](/assets/posts/televideo-912/2x/IMG_3054.jpg){:standalone}

It's interesting that the terminal uses a fairly simple microcontroller. I thought it might have used a Z80 or similar microprocessor, but apparently a much simpler MCU was enough to drive the system.

![The Intel 8035 MCU](/assets/posts/televideo-912/2x/IMG_3048.jpg){:standalone}

Reading up on the [Intel MCS-48 family of microcontrollers](https://en.wikipedia.org/wiki/Intel_MCS-48), it turns out that these were often used in keyboards, including the original IBM PC keyboard (which, of course, came out after this terminal, in 1981). A Philips derivative was used in Philips's first CD player, the CD-100. In short, this was a very popular microcontroller family.

The 8035 is a ROM-less version of the microcontroller: there is no mask ROM or EPROM on the chip, and the ROM has to be external, as is clearly the case with the TeleVideo 912. An Intel manual is available (396 pages), dated July 1978:

![The Intel MCS-48 manual](/assets/posts/televideo-912/2x/intel-mcs-48-users-manual.jpg){:standalone width="60%"}

Here is a picture of the main ROMs and the UART:

![The ROMs and UART](/assets/posts/televideo-912/2x/IMG_3055.jpg){:standalone}

I found that there are dumps of ROMs online, although I don't know if they match my terminal exactly. It could be interesting to read and reverse-engineer the code! The third ROM (actually the first one, called A3) is a character ROM, I think - that is, a ROM containing the bitmaps (7x10, from the marketing brochures) of the characters that can be displayed on the screen.

## Next steps

The goal is to figure out what's wrong with the terminal. I think the next step consists in hooking up an oscilloscope and figure out what kind of signals we are getting at various points on the board, in particular the video output. This should allow us to determine, first, whether the issue is with the CRT board or the control board (it could be both!). I wouldn't be surprised if the terminal has multiple issues given the corrosion that is visible.

A quick scan of the service manual shows some troubleshooting procedures, and indicates that a particular transistor is responsible for the horizontal scan. That will be a place to probe.

## See also

- Photo album: [Televideo TVI-912 terminal (1979) - Part 1](https://photos.app.goo.gl/yuPhPkv7v9hbr3v8A)
- Photo album: [Televideo TVI-912 terminal (1979) - Part 2](https://photos.app.goo.gl/uKXsfHny6XiJ9Fu3A)

---

[^compupro]: To be fair, I was the only bider on this item. and it turned out that, with that terminal, came a CompuPro System 8/16, and that was a great surprise. But that's story for later.

[^vt100]: I'd love to find a VT100 for a reasonable price, although I am not particularly hopeful.

[^addresses]: Although addresses in Sunnyvale and Santa Clara also appear in the documentation, indicating that the firm moved during its lifetime.
