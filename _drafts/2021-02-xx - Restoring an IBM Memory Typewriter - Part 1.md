---
layout: post
title: Restoring an IBM Memory Typewriter - Part 1
author: Erik Bruchez
tags:
category: Typewriters
---

## Introduction

I previously [wrote about my IBM Memory Typewriter](../ibm-memory-typewriter/). In this post, I describe my initial troubleshooting of the machine.

## The cover

The machine has a "top" and "center" cover, per the manual, which I'll just call the cover. This has to be removed to access the inside of the machine, of course. The cover was not fully closed when I got the machine. I don't know if it's missing screws or latches. But in any case the machine was filthy! Disgusting, in fact!

![Not really pretty inside](/assets/posts/ibm-memory-typewriter/2x/IMG_8288.jpg){:standalone}

## The tilt support

Unlike the regular Selectric, you don't take the machine fully out of the case to service it. Instead, the machine has what I called a kickstand, and which the service manual calls "tilt support", which allows lifting the main body of the machine so you can access underneath. This doesn't include the power supply and the tape loop.

I wasn't sure how hard I should push up the body of the machine, or where to hold it while doing so. The machine weighs 57.8 lbs (26.2 kg) and the main body is a good part of that weight. I pushed slightly, then figured I needed to unscrew a metal part underneath (called the "retainer" in the manual) before putting the stand up and then screw again to secure the kickstand - so you don't get your head or fingers crushed if it fails!

![The "kickstand"](/assets/posts/ibm-memory-typewriter/2x/IMG_8292.jpg){:standalone}

The process was harder than it should have been, because hinge was missing 2 screws on the left. The 2 screws were at the bottom of the machine. I put a temporary fix in place so that the body would rest on the hinge.

## Initial cleaning

I scraped, brushed and vacuumed the disintegrated foam. I also moved the power supply for easier cleaning. It is held in place with a single screw. Then I also used an air compressor to blow out dust and dust.

![Cleaning in progress](/assets/posts/ibm-memory-typewriter/2x/IMG_8293.jpg){:standalone}

The machine is in much better shape now!

![Much cleaner underneath](/assets/posts/ibm-memory-typewriter/2x/IMG_8315.jpg){:standalone}

## The power supply

Before anything else, I wanted to test the power supply.

![AC and DC connectors and fuses](/assets/posts/ibm-memory-typewriter/2x/IMG_8298.jpg){:standalone}

Thanks to the service manual, all the expected voltages are known.

![DC connector voltages](/assets/posts/ibm-memory-typewriter/2x/dc-power-connector.jpg){:standalone}

I disconnected the AC and DC connectors, then opened it to clean inside and blow air. It was a little dirty but otherwise good.

![]()

All the voltages checked!

I also checked the AC connector on the AC motor, and it was good.

## The AC motor

The first obvious issue with the machine was that the AC motor didn't run. I tried again, and confirmed that it was stuck. Looking closely, I could tell that the motor was trying to rotate, but just couldn't. So I had to try to figure out where things were stuck.

I acquired a hand cycle tool from Clark Hinson via eBay. These are newly-made versions of a standard IBM tool, which allows you to "cycle" the machine without the motor. This allows you to control and visually inspect everthing that's happening when the machine goes through a keyboard cycle.

![]()

You can't turn too hard or the tool will break. So I had to be careful. Rotating by hand didn't work at first. I applied mineral spirits on some parts that looked like they could be stuck. Still no progress. I also tried to help by trying to move other parts while using the hand cycle tool. Then I decided to power the machine on to get some help from the motor, while I used the hand cycle tool. And it worked! Things started to run reasonably smoothly!

## Debugging the cycle clutch

As things started turning, I pressed a key. And to my delight, I saw the selection magnets, under the keyboard, activate!

This meant that:

1. The key selection was captured by the reed relays.
2. The signals were sent to the planar.
3. The planar was sending back signals to the magnets.

While this might not be very complex logic, it means the planar is working to some degree, which is fantastic news!

![The selection magnets](/assets/posts/ibm-memory-typewriter/2x/IMG_8371.jpg){:standalone}

However, after that, nothing would happen. The magnets would remain selected and that was it.

What is supposed to happen is that the cycle clutch magnet is supposed to activate, which is supposed to get the machine to "cycle": that's the mechanical process whereby the cycle shaft turns and cause the type element to position itself to the right character, etc.

![The clutch magnet](/assets/posts/ibm-memory-typewriter/2x/IMG_8370.jpg){:standalone}


xxx

![The LED resistor](/assets/posts/ibm-memory-typewriter/2x/IMG_8351.jpg){:standalone}

The machine records and replays!

## More degunking

The ribbon mechanism was very dirty and stuck.

![Filth](/assets/posts/ibm-memory-typewriter/2x/IMG_8378.jpg){:standalone}

In fact, I couldn't take the cartridge (xxx?) out. Luckily the service manual has detailed instruction on how to remove that part. I still had to pull the cartridge out in an unorthodox way.

![Ribbon mechanism removal instructions](/assets/posts/ibm-memory-typewriter/2x/ribbon-mechanism-removal.jpg){:standalone}

It turned out that the swing arm on the ribbon mechanism was stuck. xxx

![The ribbon mechanism after cleaning](/assets/posts/ibm-memory-typewriter/2x/IMG_8416.jpg){:standalone}



xxx reed ,etc.

![The "ribbon end" reed switch and magnet](/assets/posts/ibm-memory-typewriter/2x/IMG_8417.jpg){:standalone}

The type element had a broken tab, but I got it out following instructions [in this video](https://www.youtube.com/watch?v=-FiFpZFgcV4).

![Bookface Acad 72 10 CPI type element](/assets/posts/ibm-memory-typewriter/2x/IMG_8419.jpg){:standalone}

xxxx

## More covers

There is a plastic accordion “print shaft cover” which I detached. That will have to be cleaned.

![Accordion](/assets/posts/ibm-memory-typewriter/2x/IMG_8428.jpg){:standalone}

Underneath, there are actual print shaft covers. Those are metal, unlike the plastic ones of some Selectrics! I removed those easily and cleaned them.

![Print shaft covers](/assets/posts/ibm-memory-typewriter/2x/IMG_8438.jpg){:standalone}

The paper pan and feed rollers also got the same treatment.

![Paper pan and rollers](/assets/posts/ibm-memory-typewriter/2x/IMG_8441.jpg){:standalone}

Two more covers, including for the fuses.

![More covers](/assets/posts/ibm-memory-typewriter/2x/IMG_8444.jpg){:standalone}

---

"noble cause"

Ken Shirriff

http://www.righto.com/2014/12/inside-intel-1405-die-photos-of-shift.html

US4084258A
https://patents.google.com/patent/US4084258A/en



---

## More stuff I learned

I reach out to find some information about the IBM chips.

It looks like so far, those chips are not documented, unfortunately.

But we strongly suspect that the system is based on so-called shift-register memory! Some of those chips must be that kind of memory.

Ken Shirriff pointed out that [US patent 4084258A](https://patents.google.com/patent/US4084258A/en) describes what is probably the system in use in the IBM Memory Typewriter!

In short, "regular" memory was expensive, and for a while shift-register memory was much more cost-effective. The patent describes how to make changes to memory content xxxx. IBM's older systems were based on magnetic tape, which was slow and prone to fragmentation, based on this patent.

"IBM Magnetic Tape Selectric Typewriter is announced. The MT/ST"

xxx don't know about Mag Card systems.


"The Magnetic Tape Selectric Typewriter is called the MT/ST.
If you will look at the picture of the machine, you will see that the IBM Magnetic Tape Selectric Typewriter consists of two parts: a "Sele,-;tric" Typewriter in a desk unit, and a tape control unit." → has big unit

xxx details about the patent & what it could tell us about the Mem/T

Circular buffer (shift-reg). Codes stored, incl. chars, and special chars.

However, the patent mentions "normal" vs. "revision". But the actual mchine doesn't have this exposed.

Still the basic architecture of the memory is pretty clear.

Electronic Composer (not to be confused with the older, electromechanical one) has 14 chips, Mem has 7. 8,000 vs. 4,000 chars of shift-reg mem! We have identified that part :)

So we can infer 7 bits per character! Each module would have about 4,000 bits on the Mem. 14 chips yield double that on the Composer.

xxx

from  F. T. May
IBM Word Processing Development
IBM I. RES.DEVELOP. VOL. 25 NO.5 SEPTEMBER 1981

"In March 1974, the IBM Memory Typewriter was an- nounced. It was packaged in one set of covers that fit on a desktop, and could be classified as the first IBM “elec- tronic typewriter.” The functions were essentially the same as the Mag Card 11, but it had a 4-Kbyte electronic buffer anda tape loop under the covers capable of storing fifty 4-Kbyte “pages” on fifty tracks. The tape was 1.5 inches wide, ran at 12.5 ips, and was recorded at a density of 800 bits per inch (bpi). This product was a very good entry-level product for users with applications that did notrequire extensive magnetic card storage. The tape loop storage was doubled to 100 pages in 1977.
"

---

The first desk-top typewriter with an electronic memory, the Office Products Division’s new IBM Memory Typewriter looks to be a winner. Announced by the division March 1, the machine has been selling at a brisk clip
(and that in spite of the fact that top OPD sales reps were attending
the Hundred Percent Club in Miami for a week).
According to one enthusiastic Midwest OPD branch manager: “It’s an
unbelievable machine. And one of the best things about itisthat you can pick itup, carry itinto the customer’s office, and demonstrate it on the spot.”

A story on how the machine was developed will appear in a forthcoming issue of Think.

think-magazine-1974-04.pdf

---

xxx answers to questions in first blog post!

"MagCard II family of products" April 1973

"In the Mag Card II family, information was input from the keyboard, a magnetic medium, or a communications line to an electronic buffer. The new technology for the buffer was a MOSFET dynamic shift register that operated by continually shifting information in a loop at a rate of 156 x 10^3 bytes/s and was accessed by appropriate electronic timing at specified ports. With this buffer the machine organization allowed for extensive revision capabilities without the physical constraints of the magnetic recording media and transports. The size of the buffer varied in the product family from 4 to 8 Kbytes (where K = 1024), which provided space for editing and merging a page or more of information at a time."

F. T. May
IBM Word Processing Development
IBM J. RES. DEVELOP. VOL. 25 NO.5 SEPTEMBER 1981

"The Mag Card I1 was only the second IBM product an- nounced with MOSFET electronics, and product devel- opment required continual interaction with IBM com- ponents development for this technology and for the de- sign and testing systems. The planar packaging concept was continued with the new, higher-density technology, and the added electronic logic capacity supported many advances in the word processing functions of this new machine."

---

ads., markleting:

- OPD
- plus: all-in-one, compact
- previously, MagCard had large separate unit on the side!

---

MOS memory capability built into IBM typewriter
Electronic Design Vol. 22 No. 7, April 1, 1974
p. 25

https://archive.org/details/bitsavers_ElectronicignV22N0719740401_67626564/page/24/mode/2up?q=IBM

"The semiconductor, ran- dom-access memory is organized into a 4-k-by-7-bi•t array. Seven memory modules, each containing two 2-k chips, are used."

---

"The right margin is set electronically which means you can draft a line of eight or nine inches but can set the margin for the finished material at any length, the machine will select the words to finish each line."

IBM MEMORY TYPEWRITER
By Clement F. Bailey, NLG
Numismatic Literary Guild Newsletter
July-August 1979
Vol. 12 No. 4

---


<!--
Interesting stuff from John J. G. Savard:

- http://www.quadibloc.com/comp/pro04.htm
- http://www.quadibloc.com/comp/propint.htm
- http://www.quadibloc.com/comp/pro0402.htm
- http://www.quadibloc.com/comp/pro040301.htm
- http://www.quadibloc.com/comp/pro0403.htm
- http://www.quadibloc.com/comp/pro01.htm
- http://www.quadibloc.com/comp/pro040307.htm
- http://www.quadibloc.com/comp/pro0401.htm
- maybe more?
-->
