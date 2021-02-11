---
layout: post
title: The IBM Memory Typewriter
author: Erik Bruchez
tags:
category: Typewriters
---

## Background

I recently picked up an IBM Memory Typewriter that otherwise would have been scrapped. [^sequence] Many thanks go to the kind soul who tipped the Golfballtypewritershop group and allowed me to pick it up locally!

![The IBM Memory Typewriter](/assets/posts/ibm-memory-typewriter/2x/IMG_8159.jpg){:standalone}

I already own several IBM typewriters in various conditions, and even an IBM Electronic Typewriter 75 (see below), but I was not familiar with the Memory Typewriter. However, it appears to be a very interesting machine, as we will see. First, just look at how it looks like under the hood!

![The IBM Memory Typewriter with covers off](/assets/posts/ibm-memory-typewriter/2x/IMG_8113.jpg){:standalone}

Maybe the most impressive part is the electronic board (called the "planar package" in the IBM service manuals) in the back, with lots of IBM chips. [^schematics]

![The "planar package"](/assets/posts/ibm-memory-typewriter/2x/IMG_8134.jpg){:standalone}

## Condition of the machine

There is no doubt that the machine is in rough condition! Needless to say, it doesn't quite work.

When turning it on, the power supply fan and one light turn on, but the AC motor doesn't. It should turn on immediately after power on, like on a regular Selectric.

There is some damage to the top cover: one part has broken off on the right side, and one is missing on the left side. The left platen knob is also missing. The good news is that these parts are not necessary to the good working of the machine. The bad news is that there is probably bigger fish to fry!

The inside of the machine is filthy. It's typical for the soundproofing foam to disintegrate into a sort of goo in Selectrics, but there is also a lot of dust and debris in there. However, there is no immediately visible damage - but I noticed two screws and a short metal rod lying at the bottom of the machine! That will need investigating.

*UPDATE: I was kindly pointed out that this shaft is the hand-cycle tool extension! So that's a slight relief.*

## Gathering information

### Manuals

The Golfballtypewritershop group was very helpful to get started. Through this group I was able to get a copy of the service and diagnostic manuals for this machine. They contain an incredible amount of very useful information.

So what's special about it? Well, the IBM Memory Typewriter is essentially an [IBM Selectric](https://en.wikipedia.org/wiki/IBM_Selectric_typewriter) typewriter with an important addition: the ability to record text both in *solid-state memory* and on a built-in *magnetic tape*, and to play it back. In short, this was one of the first word-processing machines. This makes it all the more tempting to get this machine to work! Here is an excerpt from the service manual.

![Introduction](/assets/posts/ibm-memory-typewriter/2x/memory-introduction.jpg){:standalone width="60%"}

### IBM's sites

While for many typewriters you can find a wealth of information online these days, it's definitely not the case with the Memory Typewriter. The machine is mentioned in IBM's [The typewriter: an informal history](https://www.ibm.com/ibm/history/exhibits/modelb/modelb_informal.html):

> The typewriter with a memory
>
> In 1974, the introduction of the IBM Memory Typewriter enabled typists to complete their work with a minimum of time and effort. Built into the typewriter is a memory which stores everything typed and allows the operator to recall and revise previously typed material. The memory is activated whenever typists begin keyboarding and because it works in conjunction with the typewriter's special correction system, typists can record all work at "rough draft" speed. The memory is capable of storing up to 50 pages of copy which can be played back in error-free form at 150 words per minute.
>
> The IBM Memory 100 Typewriter, with a 100 page built-in action file, was introduced in 1977

There is also a chronology in IBM's [IBM typewriter milestones](https://www.ibm.com/ibm/history/exhibits/modelb/modelb_milestone.html). Here are some relevant entries:

- 1969: Mag Card Selectric Typewriter announced
- 1973 (April): IBM Mag Card II Typewriter announced ("Its electronic memory holds up to 8,000 characters.")
- 1974: IBM Memory Typewriter rolled out
- 1975 (January): IBM Electronic Selectric Composer launched
- 1977 (March): IBM Memory 100 Typewriter debuts
- 1978: The IBM Electronic Typewriter 50 and 60 ("the first electronic typewriters")

It's unclear, based on this only, which machine first had an "electronic memory". Was it only the Mag Card II in 1973? Or did the 1969 machine already have such a memory?

Checking the "Adjustment Parts Manual", which covers all Mag Card and Memory typewriters, it appears that the Mag Card also had a "planar package". This suggests that there is a line of machines that share a similar electronic system with the planar package in the back. It would make sense, of course, for IBM to not redesign everything from scratch.

![Adjustment Parts Manual](/assets/posts/ibm-memory-typewriter/2x/magcard-apm.jpg){:standalone}

### YouTube

I also found, on YouTube, a [2013 video](https://www.youtube.com/watch?v=H8P1JrivTsE) from Switzerland showing a Memory Typewriter printing its test track, which is recorded on "secret" track 51 of the machine. That machine looks in fantastic condition, and no wonder: the description says it was in use until 2011, and then "fully overhauled" in 2012.

That video also clarifies the following points:

- March 1974 announcement date
- "MOSFET shift register" memory
- tape density of 800 bits per inch
- price of 16,000 Swiss Francs (CHF) in the 1970s

### Pricing of the Memory Typewriter

Based on that YouTube video, let's try to estimate the original price point of this machine.

Using online currency tools, in 1974, 1 USD was about 3 CHF. 1 USD in 1974 is about 5 USD in 2021. So I infer a price of about 5,300 USD in 1974, [^price-confirmation] which would be more than USD 25,000 in year 2021 currency! The machine might well have been more expensive in Switzerland than in the US, but it was certainly a very expensive machine.

This explains why few of these machines are around: they were way more expensive than the regular Selectric, which itself was not a cheap machine.

### Dating of this instance

The model was introduced in March 1974 and was probably produced for a few years. What year exactly is my instance? I haven't located the serial number yet. There is a marking on the power supply cover that says "Aug 2 1974". This would put a lower bound on the date to August 1974. But of course that specific part might have been made then, and the rest of the machine later.

For now I am considering this to be a "1974 IBM Memory Typewriter" and I will revise this if more information is available.

## Layout of the Memory Typewriter

The Memory Typewriter contains the following notable functional blocks:

- power supply
- mechanical keyboard
- printer
- planar package
- tape loop

![Layout of the IBM Memory Typewriter](/assets/posts/ibm-memory-typewriter/2x/memory-74-layout.jpg){:standalone}

The tape loop is built-in. It is a wide (almost 2 inch-wide) tape, which can hold 50 tracks each containing 4000 characters. You select a track with a rotating dial.

![The tape loop](/assets/posts/ibm-memory-typewriter/2x/IMG_8126.jpg){:standalone}

The planar package contains a 4000-character memory.

## Memory Typewriter vs. Electronic Typewriter

In 2020, I bought a 1980 IBM Electronic Typewriter 75 locally, out of curiosity and again to save the machine from possible destruction. That machine doesn't work either.

![IBM Electronic Typewriter 75](/assets/posts/ibm-memory-typewriter/2x/IMG_8244.jpg){:standalone}

But how is the Electronic Typewriter related to the Memory Typewriter? If the 1978 "Electronic Typewriter" is "the first electronic typewriter", how come there is so much "electronics" in the Mag Card Typewriter and Memory Typewriter?

Part of it is marketing and branding. Another aspect is that the Electronic Typewriter appears to have less mechanical parts and more modern electronics, including a processor board. The keyboard too, while still mechanical (but with 6 selection switches), is not quite like the Memory Typewriter's. As a start, you can compare the following layout with the layout of the IBM Memory Typewriter above.

![Layout of the IBM Electronic Typewriter 75](/assets/posts/ibm-memory-typewriter/2x/electronic-75-layout.jpg){:standalone}

## A hybrid machine

The IBM Memory Typewriter is a hybrid machine: it contains a *lot* of mechanical parts, and at the same time has a large electronic part.

For example, the keyboard appears almost unmodified compared with a regular Selectric. It remains truly *mechanical*, with moving keylevers and interposers. It interfaces with the electronics using reed relays. [^mechanical-keyboard]

![The mechanical keyboard](/assets/posts/ibm-memory-typewriter/2x/memory-keyboard.jpg){:standalone}

Conversely, the *printer* part is of course a mechanical unit, but activated from the electronics using solenoids and electromagnets.

One of my initial questions after obtaining the machine was whether there was a way to use the machine in a purely electromechanical mode, like a Selectric, and the answer is no: the machine *requires* the electronics in order to operate. Even if you use the machine in "typewriter mode", the signals go through the electronics. So if the planar package is bust, the machine won't work.

## Operation of the Memory Typewriter

I can't operate the machine right now since it doesn't work, but a few interesting bits come to light from the service manual:

- You can operate the machine in multiple modes:
  - Typewriter mode, where you type and the machine prints immediately.
  - The same, but while also storing characters in memory.
  - Save the memory to one of the 50 tape tracks.
  - Read one of the 50 tape tracks to memory.
- The machine has basic text editing features, including:
  - Backspace both erases the character on paper with the correction tape and removes the previous character from memory.
  - You can delete a word or a line in memory.
  - You can automatically underscore a word.
  - You can automatically center text on a line.
  - A "smart" decimal tabulator backspaces automatically until you press the decimal point.

This is a pretty good list for an early 1970s machine!

## Next steps

I am not a Selectric technician but this machine appears daunting and is probably one step up for most such technicians. Still, it would be incredible to make this machine work. Can that be done? I am tentatively laying out the following initial steps:

- Perform a basic clean-up of the machine.
- Check why the AC motor doesn't run. The service manual provides steps for this.
- See if the electronics appear to do something after that. If not, check the service manual for more steps.
- Consult with a Selectric repair person, especially for the mechanical part.

Does that sound like a plan?

## More

- IBM Memory Typewriter
  - [TWDB entry](https://typewriterdatabase.com/197x-ibm-memory-typewriter.15426.typewriter) [^twdb-first]
  - [Photo album](https://photos.app.goo.gl/JTvsqt6j7iD8pMK9A)
- IBM Electronic Typewriter 75
  - [TWDB entry](https://typewriterdatabase.com/1980-ibm-electronic-typewriter-75.15451.typewriter) [^twdb-first]
  - [Photo album](https://photos.app.goo.gl/hpdgZWUHUK7Tndgn9)

---

[^sequence]: This machine has become number 140 in the collection, by the way!

[^schematics]: It would be interesting to have the schematics for that. Unfortunately, those are not present in the IBM service manuals.

[^electronic-composer]: The "Electronic Selectric Composer" is probably named "electronic" as opposed to the completely electromechanical IBM Selectric Composer from 1966.

[^price-confirmation]: The pricing range is confirmed in a comment to that video saying that a US brochure had it priced at USD 4,900.

[^mechanical-keyboard]: One could argue that these were *true* "mechanical keyboards", unlike today's mechanical keyboards named so just because they have individual switches!

[^twdb-first]: These are the first entries on TWDB for the IBM Memory Typewriter and the IBM Electronic Typewriter 75!

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
