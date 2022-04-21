---
layout: post
title: Restoring an IBM Memory Typewriter - Part 2
author: Erik Bruchez
date: '2021-10-03T09:45:00.000-07:00'
category: Typewriters
---

## Introduction

I previously [wrote about my IBM Memory Typewriter](../ibm-memory-typewriter/) and the [first installment about its cleaning and restoration](../restoring-ibm-memory-typewriter-1/). In this post, I describe the continuation of the cleaning of the machine. This is still a work in progress as of October 2021.

## The ribbon mechanism

The ribbon mechanism was very dirty and at first I couldn't remove the ribbon cartridge.

![Filth](/assets/posts/ibm-memory-typewriter/2x/IMG_8378.jpg){:standalone}

Luckily the service manual has detailed instruction about the ribbon mechansim and how things fit together.

![Ribbon mechanism removal instructions](/assets/posts/ibm-memory-typewriter/2x/ribbon-mechanism-removal.jpg){:standalone}

Still, I had to pull out the cartridge in an unorthodox way! It turned out that the swing arm on the ribbon mechanism was the part causing problems. It was completely stuck. I decided to take everything apart for in-depth cleaning.

![Cleaning the ribbon mechanism](/assets/posts/ibm-memory-typewriter/2x/IMG_8382.jpg){:standalone}

The parts came out really clean.

![The ribbon mechanism after cleaning](/assets/posts/ibm-memory-typewriter/2x/IMG_8416.jpg){:standalone}

Unlike the regular Selectric, this ribbon mechanism also has a a reed switch and magnet to detect the end of the ribbon! Here is what the manual says:

>  The end of ribbon feature stops playout prior to the end of the ribbon. When the machine stops, the operator has the option of changing the ribbon at that time or resuming playout one line at a time until the copy is complete or the end of the ribbon is reached. When the end of ribbon mechanism is active, the machine will stop each time a carrier return is read.
>
> The end of ribbon mechanism incorporates a sensor which senses the amount of ribbon remaining on the supply spool inside the ribbon cartridge. Tue sensor operates through a slot in the bottom of the ribbon cartridge and is held down (inactive) by the unused ribbon on the supply spool. When the diameter of the ribbon on the supply spool falls below a certain point, the sensor will snap up into its active position. In this position, the lower extension of the sensor, which has a magnet attached to it, will rotate against a reed switch circuit board, causing the switch to close. With the switch closed, the machine will operate in the LINE mode and will stop whenever a carrier return code is read from the card.

At first I thought that this was over-engineered, but in fact this makes sense for a machine that is able to print an entire page out of memory.

![The "ribbon end" reed switch and magnet](/assets/posts/ibm-memory-typewriter/2x/IMG_8417.jpg){:standalone}

The type element had a broken tab, which is 100% certain to happen on elements with the metal hinge. I got it out following instructions [in this video](https://www.youtube.com/watch?v=-FiFpZFgcV4).

![Bookface Acad 72 10 CPI type element](/assets/posts/ibm-memory-typewriter/2x/IMG_8419.jpg){:standalone}

I found the broken tab inside the carrier! Not that it helps, because you can't really glue it back.

## More covers

Below the ribbon mechanism, things were pretty scary.

![Gunk](/assets/posts/ibm-memory-typewriter/2x/IMG_8413.jpg){:standalone}

There is a plastic accordion “print shaft cover” which I detached.

![Accordion](/assets/posts/ibm-memory-typewriter/2x/IMG_8428.jpg){:standalone}

This part required cleaning. But I don't know how good it's going to look in the end. I might have to consider replacing it.

![Cleaning the accordion](/assets/posts/ibm-memory-typewriter/2x/IMG_8773.jpg){:standalone}

Underneath, there are actual print shaft covers. Those are metal, unlike the plastic ones of some Selectrics! I removed those easily and cleaned them.

![Print shaft covers](/assets/posts/ibm-memory-typewriter/2x/IMG_8438.jpg){:standalone}

The paper pan and feed rollers also got the same treatment.

![Paper pan and rollers](/assets/posts/ibm-memory-typewriter/2x/IMG_8441.jpg){:standalone}

I removed two more covers, including one for the fuses.

![More covers](/assets/posts/ibm-memory-typewriter/2x/IMG_8444.jpg){:standalone}

## Cleaning the mechanical parts

I wondered whether I should disassemble more of the machine to clean it. I was advised to clean things in place. I put rags to absorb liquids just in case, as I really don't want liquids to reach the planar, and I used mineral spirits and a toothbrush to loosen grime and grease. I used compressed air to get the stuff out. It's a slow and tiresome process, which I did with a headlight to see what I was doing. Here is an example of what I have to deal with.

![Gunk](/assets/posts/ibm-memory-typewriter/2x/IMG_8426.jpg){:standalone}

Halfway through the process, I tried the machine again. Things on the carrier appear to move much better.

## Cable bundles

I note some markings on cloth labels attached to cable bundles. First label:

```
WHITEAKER CABLE CORP.
ASSY. NO.   1466720
E.C. NO.     582452
DATE:          1974
```

Second label:

The 582785 number could also be 582765.

```
WHITAKER CABLE CORP.
ASSY. NO.   1466002
E.C. NO.     582785
DATE:    7-11-1974
```

Third label:

```
WHITEAKER CABLE CORP.
ASSY. NO.    1466002
E.C. NO.      582699
DATE:           1974
```

For one thing, this confirms the 1974 date!

![Markings](/assets/posts/ibm-memory-typewriter/2x/IMG_9148.jpg){:standalone}

## The planar and its support

I decided that I should remove and clean the planar even as I wasn't done cleaning the rest of the machine.

- This provides better access for cleaning the machine.
- I wanted to make sure I didn't damage it, for example by spraying solvents on it by accident.
- I wanted to clean it.

Removing it is very easy. It was designed to be removed and swapped if anything goes wrong with it. Remove the connectors, a couple of screws, and that's it!

![The planar removed](/assets/posts/ibm-memory-typewriter/2x/IMG_9157.jpg){:standalone}

This clearly provides better access to the motor and other mechanical parts.

![The AC motor after removing the planar](/assets/posts/ibm-memory-typewriter/2x/IMG_9150.jpg){:standalone}

Now the planar is a thing of beauty. It is full of custom, unfortunately undocumented IBM chips. The planar would deserve its own post, but I'll mention here that we identified the memory chips. It is pretty clear that these chips are shift-registers, and that each of those probably holds 4,000 (or maybe 4,096) bits of data. 7 chips provide 4,000 (or maybe 4,096) 7-bit characters or codes, which is the advertised memory capacity of the machine.

![The 7 memory chips](/assets/posts/ibm-memory-typewriter/2x/IMG_9237.jpg){:standalone}

The memory chips are all labeled as follows:

```
2707872
IBM 98C
X25329201
1 I94
```

Note that the IBM Electronic Composer, a machine in the same lineage is the IBM Memory Typewriter, and which boasts 8000 characters of memory, happens to have 14 such chips.

The planar is attached to a polycarbonate (maybe?) back. It had some soundproofing or insulation, which was all crumbling. I removed what I could, but it left a hard residue.

![The planar backing and its ugly glue residue](/assets/posts/ibm-memory-typewriter/2x/IMG_9159.jpg){:standalone}

I removed the metal and plastic hardware.

![Parts from the top of the frame](/assets/posts/ibm-memory-typewriter/2x/IMG_9165.jpg){:standalone}

Removing this residue was not easy. I didn't want to damage the plastic. I tried various cleaners and solvents, including Simple Green and Goo Gone, which did nothing. In the end, I found that Hoppe's #9 was slowly softening the residue. I could apply it, and, using a plastic blade, scrape it a little.

![Scraping](/assets/posts/ibm-memory-typewriter/2x/IMG_9257.jpg){:standalone}

It took many passes over the course of one week to finally get all of it out. If you look closely and with the right light you will still see some scratches, but overall it's a beautiful part!

![The result](/assets/posts/ibm-memory-typewriter/2x/IMG_9404.jpg){:standalone}

The planar is attached its backing with brackets.

![Bracket](/assets/posts/ibm-memory-typewriter/2x/IMG_9479.jpg){:standalone}

Note the air guide, which connects to the fan in the power supply, and which ensures that air reaches the planar.

![Air guide](/assets/posts/ibm-memory-typewriter/2x/IMG_9917.jpg){:standalone}

The result is pretty neat.

![The assembly all clean](/assets/posts/ibm-memory-typewriter/2x/IMG_9906.jpg){:standalone}

In the following picture you can see the memory chips at the top.

![View including the shift-register chips](/assets/posts/ibm-memory-typewriter/2x/IMG_9910.jpg){:standalone}

The planar bears several numbers:

- "E 4290 006" on one end of the planar
- "075507" on the other end of the planar
- "018524" on the air guide (sticker)
- "1466300 D" and "1466405" on the support (stickers)

I don't know what they mean. Could some of the stickers be IBM service stickers?

## The transmit block

This is the part that "reads" the keyboard.

![The transmit block](/assets/posts/ibm-memory-typewriter/2x/IMG_8308.jpg){:standalone}

once you remove the PCB, you can see that it consists of seven magnets and seven reed switches. The magnets are activated mechanically.

![The magnets](/assets/posts/ibm-memory-typewriter/2x/IMG_0135.jpg){:standalone}

The board with the reed switches was very dirty, no doubt in part due to my own cleaning of other parts of the machine.

![Dirty reed board](/assets/posts/ibm-memory-typewriter/2x/IMG_0133.jpg){:standalone}

I cleaned it a little, but some black residues remain.

![Cleaner reed board](/assets/posts/ibm-memory-typewriter/2x/IMG_0136.jpg){:standalone}

## Conclusion so far

Here is a picture of the bottom of the machine as of September 2021, with the planar and power supply off.

![The machine's bottom](/assets/posts/ibm-memory-typewriter/2x/IMG_4522.jpg){:standalone}

I made a lot of progress, but I am not done yet. Here are tentative next steps:

- finish cleaning the mechanical parts
- apply grease appropriately
- reassemble and reinstall the ribbon mechanism
- reinstall the planar
- check the power supply

I mention the power supply because I took it out to take pictures, and I am now worried that if something went wrong with it, it could fry the planar. I am wondering what kind of crowbar system I could put in place to protect the planar in case something goes wrong.

Hopefully, with the ribbon mechanism and the rest of the machine cleaned, I will be able to test actually printing on paper!

## More

- Blog post: [The IBM Memory Typewriter](../ibm-memory-typewriter/)
- Blog post: [Restoring an IBM Memory Typewriter - Part 1](../restoring-ibm-memory-typewriter-1/)
- Photo album: [Pictures before restoration](https://photos.app.goo.gl/JTvsqt6j7iD8pMK9A)
- Photo album: [All pictures of the restoration](https://photos.app.goo.gl/2ACu1dM3E7ZsgWwn9)
