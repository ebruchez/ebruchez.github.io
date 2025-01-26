---
layout: post
title: "Building an Apple-1 Reproduction in 2024/2025 - Part 6: C Programming"
author: Erik Bruchez
date: '2025-01-25T15:00:00-07:00'
tags:
category: Technology
---

This is part  of a series of posts about building an Apple-1 reproduction in 2024. See also:

- [Building an Apple-1 Reproduction in 2024 - Part 1: Components](../apple-1-reproduction-part-1-components/)
- [Building an Apple-1 Reproduction in 2024 - Part 2: Power Supply](../apple-1-reproduction-part-2-power-supply/)
- [Building an Apple-1 Reproduction in 2024 - Part 3: The Retro Chip Tester](../apple-1-reproduction-part-3-retro-chip-tester/)
- [Building an Apple-1 Reproduction in 2024 - Part 4: Assembly](../apple-1-reproduction-part-4-assembly/)
- [Building an Apple-1 Reproduction in 2024 - Part 5: Monitor, Keyboard, Power-Up](../apple-1-reproduction-part-5-monitor-keyboard-power-up/)

![Demo application written in C](/assets/posts/apple1/2x/IMG_1490.jpg){:standalone width="75%"}

## Programming the Apple-1

Back in the days, the obvious choices for programming the Apple-1 were assembly language and BASIC. The former, because it was the most direct way: the Apple-1, thanks to WOZMON, allowed you to enter 6502 instructions in hexadecimal directly into memory, and then to run them. You would probably build your program in assembly on paper (or in your head), then "assemble" by hand into hexadecimal. Over time, you would learn the opcodes by heart. Many programmers got started this way on all sorts of systems.

BASIC was much easier to learn, but you needed to get the Apple-1 ACI (Audio Cassette Interface) to load it into memory. Apple-1 BASIC was written by Woz entirely in assembly, and it was a marvel of compactness and efficiency as it fit in 4K of memory.[^microsoft-basic]

Here is part of the cover of the Apple BASIC manual reproduction, made with love by Armin in Germany: 

![Apple-1 BASIC manual cover (reproduction)](/assets/posts/apple1/2x/IMG_3042.jpg){:standalone}

I never really learned 6502 assembly in its heyday, although I did peruse the great Commodore 64 manual. However, I dabbled with a homemade Z80 computer board, I programmed in RCA 1802 assembly on my own boards, and I eventually got some mastery of 68000 assembly (a beautiful processor instruction set architecture).

In any case, after building my Apple-1 reproduction, I wanted to write some software for it, however simple.

## Why the C language?

 I didn't think that assembly or BASIC were ideal for me. While 6502 assembly is probably the way to go to optimize performance and code size, it is also a very low-level language, and I thought that it would take me too much effort to get really fluent in the 6502 dialect. BASIC is, of course, much higher-level, but it is also very limited, and not challenging enough. 

Instead, I decided to try to write in C. It is a good compromise: it is a higher-level language compared to assembly, with functions, types, structs, enumerations, loops, and flexible ways to deal with memory, but it is also very close to the hardware. Further, I knew C reasonably well at some point in the 1990s so it should come back. But could it work on the Apple-1?

## C and the Apple-1

At the time the Apple-1 came out in 1976, C was already a thing, kind of: the Unix kernel was rewritten in the brand new C language around 1973. But C didn't become really public until 1978, when the first edition of the K&R book was published. So it's not surprising that C wasn't available on the Apple-1. In addition, C required a compiler, which could easily run on a larger system like the PDP-11, but wouldn't have been possible on anything as limited as the Apple-1, certainly not in the default memory configuration and without mass storage.[^small-c] It took the general availability of 16-bit systems to make C a practical language for microcomputers.[^c-compilers-history]

But nowadays, we have *cross-compilers* that can generate 6502 code, so the story is completely different. There are at least two possibilities:

- [cc65](https://cc65.github.io/)
- [LLVM-MOS](https://github.com/llvm-mos/llvm-mos)

I had to choose which one to try first, and I went with cc65, as it seemed simpler and more lightweight, although it might not generate highly optimized code. Also, it has been around for decades now.

## Installation

I first installed `cc65` on my Mac using [Homebrew](https://brew.sh/):

```bash
brew install cc65
```

I couldn't find setup instructions for the Apple-1. Someone mentioned the Apple-1 in a forum around 2013, but that's all I could find. So I read some of tbe documentation, and it turns out that the main thing you need is to create a linker configuration file. I created a file called `apple1.ld65` (this is just my own naming). But what should be in it? A C program consists of:

- code, which can be in read-only memory or read-write memory
- initialized data, which can be read-only or read-write
- uninitialized data

In addition, the C runtime needs:

- some "zero page" configuration
- a place for the CPU stack
- a place for the C stack

On the other hand, my hardware Apple-1 has:

- 8 BK of DRAM at address 0x0000
- an EPROM extension board which can hold up to 4KB of memory (2732 EPROM) at address 0xE000

The linker script configures where everything goes. Here is the configuration I came up with, after a few tries:

```
SYMBOLS {
  __STACKSIZE__: value = $800, type = weak; # 2KB stack
}

MEMORY {
    ZP:    start = $0020, size = $00C0, define = yes; # needs to be at least $1A long (26 bytes) for cc65
    RAM:   start =  $200, size = $1E00, define = yes; # RAM after "6502 stack storage" and fills up to 8KB
    ROM1:  start = $E000, size = $1000, file = "eprom_e000.bin";
}

SEGMENTS {
    ZEROPAGE: load = ZP,   type = zp,  define = yes;
    STARTUP:  load = ROM1, type = ro;
    ONCE:     load = ROM1, type = ro,  optional = yes;
    CODE:     load = ROM1, type = ro;
    RODATA:   load = ROM1, type = ro;
    DATA:     load = ROM1, type = rw,  run = RAM, define = yes;
    BSS:      load = RAM,  type = bss, define = yes;
}

FEATURES {
    STARTADDRESS: default = $E000;
    CONDES: segment = STARTUP, type = constructor, label = __CONSTRUCTOR_TABLE__, count = __CONSTRUCTOR_COUNT__;
    CONDES: segment = STARTUP, type = destructor,  label = __DESTRUCTOR_TABLE__,  count = __DESTRUCTOR_COUNT__;
}
```

The result of a compilation's linker pass will produce a `eprom_e000.bin` file that can be loaded into a 4 KB EPROM  located at address 0xE000.

## C library

You need to create a `crt0.s` file, which is the entry point of the program. [Here is mine](https://github.com/ebruchez/apple1-party/blob/main/crt0.s), copied from existing examples.

You also need to create a library file if you want to use any C library functions that come with `cc65`. Note that `cc65` doesn't come with the entire standard C library, but with a subset of it. I called my library `apple1.lib`. The recommendation from the doc is to copy it from the `supervision.lib` file that comes with `cc65`. Here is how you can do it:

```bash
cp /opt/homebrew/Cellar/cc65/2.19/share/cc65/lib/supervision.lib apple1.lib
ca65 crt0.s
ar65 a apple1.lib crt0.o
```

You then compile, assemble, and link your C program like this:

```bash
cc65 -t none -O main.c
ca65 main.s
ld65 -C apple1.ld65 -m main.map main.o apple1.lib
```

Finally, here is how I write the EPROM, using my very basic USB EPROM programmer:

```bash 
minipro -s -p 2732A@DIP24 -w eprom_e000.bin
```

![EPROM programming and erasing setup](/assets/posts/apple1/2x/IMG_1591.jpg){:standalone}

Note that you don't want to type or rerun individual commands all the time, so I wrote a simple [Makefile](https://github.com/ebruchez/apple1-party/blob/main/Makefile) for this.

## First issue

I was able to pretty quickly compile and run a simple ["HELLORLD" program](https://www.youtube.com/watch?v=gQ6mwbTGXGQ). However, when trying to run a simple `for` loop, it didn't seem to work. How could something that simple fail?

After a lot of debugging, I found that the call to the `incax1` [intrinsic](https://en.wikipedia.org/wiki/Intrinsic_function) was not, in fact, incrementing the `ax` register pair. I used, for debugging, things like this, which call into WOZMON's `FFDC` routine to print an hex value:

```6502
pha
jsr	    $ffdc
pla
```

The reason for this was that the `supervision.lib` I used as the base for my C library was not compiled with plain 6502 instructions. In particular, it used the `INC A` increment instruction, [available with the 65C02](https://en.wikipedia.org/wiki/WDC_65C02#New_and_modified_instructions) which came out in 1983, but not my 1979 6502!

![My Synertek 6502 CPU made in July 1979](/assets/posts/apple1/2x/IMG_3044.jpg){:standalone}

So I had to do thing the hard way and recompile the library for a plain 6502 target:

- I cloned the `cc65` project from GitHub.
- I updated `libsrc/Makefile`:
    - set `--cpu 6502`
    - kept only the `supervision` target
- I built the library:
    - `make lib`
- I used this new `supervision.lib` as base for `apple1.lib`:
    - `ar65 a apple1.lib crt0.o` again

And, success! With this change, I was able to compile a C program with `for` loops on the Apple-1.

## Memory allocator

Since I was using C, I wanted to use `malloc` and `free`. Luckily, these functions are available in the `cc65` library. But things didn't work initially.

I had to debug various constants, and finally found that I had to move my `BSS` after `DATA` for malloc to work.

Here are some values I found:

| Symbol                  | Value   | Notes                                                             |
|-------------------------|---------|-------------------------------------------------------------------|
| `__BSS_RUN__`           | `0x23C` | Starting address of the BSS section.                              |
| `__BSS_SIZE__`          | `0x54`  | Size of the BSS section.                                          |
| First address after BSS | `0x290` | First address after the BSS section (sum of previous two values). |
| `__heapmaxavail()`      | `5484`  | Largest available block in the heap (in bytes).                   |
| `__heapmemavail()`      | `5488`  | Total available heap memory (4 bytes more tha previous value).    |
| First allocation        | `0x29D` | First address allocated by `malloc`.                              |

The memory layout ends up being:

| Function              | Value    | Notes                                                                  |
|-----------------------|----------|------------------------------------------------------------------------|
| BSS start             | `0x23C`  |                                                                        |
| C heap start          | `0x290`  |                                                                        |
| C heap end            | `0x17FF` |                                                                        |
| C stack start/RAM end | `0x1FFF` | `__STACKSIZE__` is `0x800` and stack addresses are in descending order |

In conclusion, my `malloc` setup now appears fine, with various values in the right place, and I can allocate and free memory with some confidence. Note that:

- each allocation takes 4 bytes of overhead
- we have 5488 bytes of heap at beginning

I could easily reduce the size of my C stack down from 2 KB if I need more usable RAM. I might also be able to recover some RAM in the lower space, after The ZP and CPU stack areas.

## Simple program

Because I was going to have guests over, and I was going to annoy them with the Apple-1 anyway, I decided to write a simple program that would allow them to check in. So I wrote a simple "Party checkin system" app which would:

- ask guests for their name and number of guests
- add them to a linked list
- display the list
- display the total number of guests
- allow to remove entries in the list

I wrote simple utility functions in `util.c`:

| Function           | Purpose                                   | Description                                                                  |
|--------------------|-------------------------------------------|------------------------------------------------------------------------------|
| `a1_cputc()`       | Write a character to the screen           | Outputs a single character to the screen at the current cursor position.     |
| `a1_cputs()`       | Write a string to the screen              | Outputs a null-terminated string to the screen starting at the cursor.       |
| `a1_cgetc()`       | Read a character from the keyboard        | Reads a single character input from the user.                                |
| `a1_read_line()`   | Read a line from the keyboard             | Reads a full line of input, storing it in a buffer.                          |
| `print_big()`      | Print a large number on the screen        | Displays a number with large, stylized digits made up of smaller characters. |
| `a1_read_number()` | Read and check a number from the keyboard | Accepts and validates numeric input from the user.                           |

Note that this is all there is to the Apple-1 in terms of I/O, without hardware extensions: you can read and write characters to the screen, and read characters from the keyboard. That's it. There are no graphic capabilities, no sound, no network, no storage, no timers: it's a very simple system!

My `main.c` handles the linked list functions and the main loop.

## Coding tips

My C might be rusty, but here are some things I quickly decided to do:

- use `const` whenever possible
- use type aliases for specific widths, such as `uint8_t`, `uint16_t`, etc.

Here is an example of the style I am using:

```c
uint16_t a1_read_number() {
    uint16_t number = 0;
    uint8_t digits = 0;
    while(1) {
        const char c = a1_cgetc() & 0x7F;
        if (c >= '0' && c <= '9' && digits < 4) {
            a1_cputc(c);
            number = number * 10 + (c - '0');
            digits++;
        } else if (c == CR && digits > 0) {
            break;
        }
    }
    return number;
}
```

## Limitations

It is clear that 4 KB of EPROM is very limiting. Yes, Woz wrote an entire BASIC interpreter in that space, but I am no Woz, and I am not using assembly. A little bit of data, a `cprintf` function, `malloc`, and a small program will quickly fill up that space. In fact, I had to avoid using `printf()`: it is convenient, but it takes significant EPROM space, so I reverted to use lower-level code.

A possible next step will be to make an EPROM board that supports 8 KB or more of memory. This has been done before for the Apple-1, but I am not sure that there is a solution that I truly like (or that is affordable). I might decide to make my own.

If the solution is limited to 8 KB, it is possible to use the `S` and `T` signals on the extension connector. But for more space, one needs to replicate address decoding on the extension card. This is not too hard, but it goes beyond simply connecting one or more EPROMs to the bus.

## Conclusion

I am really happy that I was able to write a small C program for the Apple-1. It uses functions, `malloc`, standard string manipulation functions, creates a linked list, and flawlessly reads from the keyboard and writes to the video terminal.

![Demo application written in C](/assets/posts/apple1/2x/IMG_1490.jpg){:standalone}

You can find the source code for the "Apple-1 Party" app on [GitHub](https://github.com/ebruchez/apple1-party/tree/main).

Part 7 will cover the Audio Cassette Interface (ACI).

---

[^microsoft-basic]: The same could be said of Bill Gates, Paul Allen, and Monte Davidoff's 4K version of Microsoft BASIC for the Altair 8800.

[^small-c]: I learned that [Small-C](https://en.wikipedia.org/wiki/Small-C), a subset of C that could run on 8-bit systems, specifically the 8080 microprocessor, was developed in 1980.

[^c-compilers-history]: I found this interesting [History of C Compilers article](https://thechipletter.substack.com/p/a-history-of-c-compilers-part-1-performance).