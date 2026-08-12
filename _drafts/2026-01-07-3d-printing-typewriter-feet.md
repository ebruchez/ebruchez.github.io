---
layout: post
title: 3D Printing Typewriter Feet
author: Erik Bruchez
date: '2026-06-21T14:20:00-07:00'
tags:
category: Typewriters
---

TODO:

- link to models on Printables

![Some of my 3D printed typewriter feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_3860.webp){:standalone}

## Typewriter feet

At the risk of stating the obvious, typewriter feet serve multiple functions:

- They prevent the machine from sliding on smooth surfaces.
- They dampen vibrations when typing, making the typing experience quieter and more comfortable.
- They protect the surface on which the typewriter is placed from scratches and dents.

In order to do this, they need to be fairly soft and grippy, and are typically made of some kind of rubber. But the feet of many typewriters have hardened over time. Sometimes, they just crumble, or they might be entirely missing. You could go as far as saying that typewriter feet are, in the end, consumable items (like platens, or car tires).

## Why 3D print typewriter feet?

Most typewriter companies are long gone, and original replacement feet are no longer available. Modern workarounds include:

- keeping hardened feet and using a typewriter mat
- replacing them with off the shelf parts like rubber furniture feet, bumpers, or tube stoppers
- buying modern replacement feet from typewriter parts sellers

That last option is real, and many typewriter feet are available from various sellers. Personally, over time, I have spent literally hundreds of dollars in typewriter feet. Some are really well-made. They are usually made of some kind of rubber poured in a mold. One issue is that they are pricey (USD 20-40 for a set), and you are limited to the ones on offer. I consider it unreasonably costly to buy custom-molded feet for each of my typewriters, including for parts machines in storage or machines which may or may not ever be restored (see below).

## Material and printer setup

PLA and PETG, the most common materials for 3D printing, are not appropriate for typewriter feet, as they are too hard and not grippy enough. But TPU (thermoplastic polyurethane) is a flexible filament that can be suited for this purpose. Like rubber, it is sold in various hardness levels, measured in Shore A, the most common being Shore 95A.

One challenge is that because it is a soft material, it might not print well on all printers. But in 2025-2026, many printers handle TPU well.

I first tried Shore 95A TPU, but I didn't find it suitable: it is too hard and not grippy enough (although these materials would be fine for display). So I switched to Shore 85A TPU, of the Siraya brand.

![Shore 85A TPU filament](/assets/posts/3d-printing-typewriter-feet/2x/siraya85a.webp){:standalone width="50%"}

PLA can, however, be used to prototype the shape of the feet. Here is an example for the Underwood 5, showing the original foot on the right, and the orange PLA prototype on the left.

![Prototyping typewriter feet in PLA](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1614.webp){:standalone}

For this softer TPU, I couldn't feed the filament through the PTFE tube of my printer, and I fed it directly from the top of the extruder. I had already modded my machine to be able to easily remove its top cover.

[//]: # (![Feeding TPU filament directly into the extruder]&#40;/assets/posts/3d-printing-typewriter-feet/2x/IMG_1439.webp&#41;{:standalone})

I did have a few extruder jams, which probably happened during filament retraction. After playing with the tension of the screws on the extruder, I managed to avoid most jams. The following video shows that setup in more details, including the use of a textured printing sheet/plate.

<script>
  var tag = document.createElement('script');

  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

  var player;
  function onYouTubeIframeAPIReady() {
    var textWidth      = document.getElementById('player').offsetWidth;
    var computedHeight = textWidth * 360 / 640;

    player = new YT.Player('player', {
      height: computedHeight,
      width: textWidth,
      videoId: 'xLLtIfprnDA',
      playerVars: {
        'playsinline': 1
      }
    });
  }
</script>

<div id="player"></div>

TPU 85A allows me to print feet that are softer and grippier, and while maybe not exactly as grippy as new rubber, given the weight of the typewriters I have designed the feet for, it works very well, and certainly beats missing feet or hard or crumbled ones!

TPU needs to be dry to print well, and a filament dryer is a must to obtain the best appearance. I am also feeding it to the printer directly from a dry box.

As far as the softness or bounce of the TPU is concerned, it is excellent and on par with rubber feet. I played with various infill percentages, from 100% down to about 25% depending on the feet.

Color availability is very limited for TPU. I printed the feet in black TPU, which is the most common color. Alternatives include white, clear, and I even saw an orange, but we are far from the wide range of colors available for PLA or PETG. This said, black is perfect for most typewriter feet.

## Design process

The process of creating feet is simple:

- take the original part, or what's left of it
- observe its general shape, reconstituting it mentally if needed, or on paper
- measure diameters and other dimensions with a digital caliper
- design the part in CAD (I used Autodesk Fusion)
- print a test part in PLA
- see how close the part is from the original
- make adjustments, and repeat as needed
- add some chamfers or fillets to improve the look and feel

In general, with 3D printing, large spaces under parts require *supports*. Ideally, one should try to avoid supports, especially with TPU (although some multi-material printers allow making supports in another material like PLA). So I used chamfers and grooved bottoms to avoid overhangs.

##  Feet I designed so far

I started by designing a simple Underwood 5 foot. Once successful, I rapidly designed feet for several other machines, each with different shapes and attachment mechanisms. Here is the list as of August 2026:

| Typewriter                             | Year(s)     | Notes                                                                 |
|----------------------------------------|-------------|-----------------------------------------------------------------------|
| Remington 2                            | 1885        | push-in                                                               |
| Densmore 1b                            | 1894-1896   | push-in                                                               |
| Densmore 4                             | 1899        | push-in; cylindrical and conical versions                             |
| Remington Model 7 with Gorin tabulator | 1907        | push-in; reinforced with rods; tall                                   |
| Smith Premier 5 with Gorin tabulator   | 1907        | push-in; tall                                                         |
| Blickensderfer 5                       | 1909        | push-in; hole for slotted wood screws from the top                    |
| Royal 1/5/6                            | 1906-1913   | screw-in; can be shorter or taller                                    |
| Courier                                | 1917        | push-in                                                               |
| Underwood 5                            | 1920        | metal cup and screw; tall                                             |
| Remington Vertical Adder Model-21      | 1920s       | metal cup and screw                                                   |
| Varityper Folding                      | 1927        | push-in; goes inside and around the metal frame                       |
| Royal KHM                              | 1938        | sandwiched with metal parts; top rubber cushions                      |
| Underwood "S"                          | 1942        | metal cup and screw; felt-like cushions on top of rubber              |
| Underwood "SS"                         | 1948        | metal cup and screw; wide                                             |
| Underwood Rhythm Touch                 | 1949        | metal cup and screw; wide                                             |
| Adler standard                         | 1950s       | square-ish with holes for screws; taped/glued to metal cups           |
| Lexicon 80                             | 1950s       | in metal cups; different shape for front and back                     |
| Hermes Ambassador                      | 1951        | large, rectangular shape; sandwiched with metal parts                 |
| Hermes Media                           | 1958        | small and short; screw and washer; fits in cups at bottom of the case |
| Erika 10                               | 1960        | metal cup and 2 screws; elongated, rounded shape                      |
| Princess 100                           | 1950s-1960s | cylindrical, screwed to the case                                      |
| Facit TP2                              | 1960s       | rectangular with hexagonal hole and metal part                        |

The following section document some specific aspects of the design of some of these feet.

### Remington 2, Densmore 1b, Smith Premier 5

These were the easiest feet to design: simple cylindrical shapes that just press-fit in holes in the typewriter base.

![Smith Premier feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1466.webp){:standalone}

### Remington 7 with Gorin tabulator

These are also very easy to design, but they have a metal rod inside the foot for reinforcement. I preserved this feature, of course.

I made a tapered version as well

![Remington 7 feet with metal rods](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1432.webp){:standalone}

### Densmore 4

I designed two versions of the feet: cylindrical, and then more conical, to look a little more snazzy. I suspect that the original was more cylindrical, like the Remington and Smith Premier feet, but I wanted to try a different shape as well. The feet are held in place with screws.

![Cylindrical Densmore feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1395.webp){:standalone}

![Tapered Densmore feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1465.webp){:standalone}

### Blickensderfer 5 aluminum

I designed two versions of the feet: cylindrical, and then more rounded to match, probably, the originals better. I also added a notch in the left rear foot to clear a screw head on the machine.

![Blickensderfer 5 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1523.webp){:standalone}

### Underwood 5

There are several variants of the Underwood 5 feet. The ones I designed are the tall ones, rather stocky, which fit in a metal cup. They match the originals pretty well - assuming they are originals, but they are rock-hard for sure!

![Underwood 5 feet, tall version](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1250.webp){:standalone}

### Remington Vertical Adder Model-21

These are the interesting, rather large Remington feet of the period. They probably fit other Remingtons in addition to the Vertical Adder.

### Varityper Folding

It's hard to know exactly how the original feet looked like. On top of the case bottom, I had some felt-like cushions. Their tops were cupped a little, but this might have been due to aging. Then on top of that was the rubber foot, which espoused that shape. But if the feet were to be ever used on a table, they would have to have been flat underneath. So I designed the feet with a flat bottom. They feet wrap around the metal legs which are part of the frame. I just had to guess. Existing pictures of the Varityper Folding or Hammond Folding didn't help that much, as they all have very poor quality feet. 

![Varityper Folding feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1713.webp){:standalone}

### Royal KHM

These are interesting because they are made of the foot proper, and a second bumper on top.

![Royal KHM feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1749.webp){:standalone}

### Underwood "S"

I designed these to fit the metal cups and felt inserts. But I made the soft part taller than the originals, although you can't see this at all.

### Underwood "SS" and Rhythm Touch

These feet look almost identical to the "SS"'s. However, the "SS"'s appeared flatter, either originally, or due to flattening. In fact, the rubber part might have been identical. In the end I designed two slightly different feet, with the Rhythm Touch's having straighter walls. However, the Rhythm Touch feet do have, in my case, slightly different hardware, with an extra metal insert and washer, compared with the "SS".

To avoid the use of supports, I designed the bottom of the feet with grooves, as well as a chamfer inside.

![Underwood Rhythm Touch feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1663.webp){:standalone}

![Underwood "SS" feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1717.webp){:standalone}

### Hermes Ambassador

The Ambassador feet are different from most designs, being rectangular and fairly large! But I got to learn how to use the "Loft" feature in Fusion 360! I then reused this knowledge for other feet. I also used rotations, chamfers, fillets, and more.

![Hermes Ambassador feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1369.webp){:standalone}

The Facit TP2 feet are very similar in design, but a small fraction of the size.

![Facit TP2 feet](/assets/posts/3d-printing-typewriter-feet/2x/xxx.webp){:standalone}

### Courier

Here, I designed a built-in notch to clear the typewriter side. This is probably now how the original (flattened) feet were, but I figured I would do this so the feet can be wider.   

![Courier foot with notch](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1867.webp){:standalone}

### Hermes Media, Princess 100

These too are very easy to design. The originals had flattened in various interesting ways!

These are fairly simple feet. They attach to the bottom of the typewriter's travel case with a screw.

### Erika 10

Due to their non-circular, and non-rectangular shape, the Erika 10 feet were more challenging to design. I used a loft, again, but also a scan of the outline of the foot to approximate the shnpe better, with splines. It's not perfect, but pretty close. The original feet are not exactly perfect either!

![Erika 10 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1690.webp){:standalone}

### Adler

The Adler standard feet are the largest I have made so far, and for the foreseeable future. They are xxx wide, and tall as well.

I might improve the design in the future to introduce some kind of profile on the bottom. I worry that the large flat parts might make the feet less grippy.

xxx pic

## Installation and fittings

Underwood 5: in this case, the feet are attached to the typewriter with a screw, and fit in a metal cup.

Some feet are just press-fit, others use screws. The Remington 7 feet are particularly interesting: they include an inch-long metal rod which simply fits in a hole in the foot, presumably enhancing the rigidity and stability of the foot.

A challenge here was removing the old rubber: the metal cups into which the rubber was molded are made of very soft metal. Luckily, I only damaged the inside of the cups a little in the removal process. For some machines, I used a drill to remove the old rubber!

## Benefits and drawbacks

What I find really nice here is the ability to iterate quickly: I can design a part, print it, test it on the machine, and if needed, modify the design and reprint it, all of this in a matter of a few hours, sometimes less. I can also play with small variations: chamfers, cylindrical designs vs. conical, various heights, etc.

It is possible to create feet for machines for which no replacement feet are available.

I wouldn't have bought dozens of sets of feet for machines that I still need to work on, for example, but here I did so, which helps with the handling and storage of those project machines, as they can nicely sit on a shelf without damaging the surface below and without being damaged themselves. And of course, for other machines, it's nice to have feet perform their intended function!

For my Blickensderfer 5, for example, only 2 feet were left, and they were rock-hard and deformed (well, the machine is from 1909, so it's not surprising). I had used Sugru, which is a pretty neat (although expensive) moldable rubber, to recreate the missing feet in the back, but the results were not ideal. Now, with 3D printed TPU feet, the machine is much more stable and the feet look great. When designing the Blickensderfer 5 feet, I noticed that, for one of the feet, a screw on the machine was in the way. I was able to very quickly design a notch in the foot to clear that screw.

On the negative side, the feet are not as grippy as new rubber, although in practice I don't think that's a problem.

The appearance is also different from new rubber: there is a shine, and there are layer lines. I know that those can both some people. In many cases, the feet are not very visible anyway, and they are not exactly the first part one's attention focuses on. So here as well, I don't think it is a big problem.

Recently, someone recommended using a polishing wheel to removes layer lines and gives the parts a more rubbery look. I haven't tried this at the time of writing, but it could be a solution for the perfectionist. Another possibility is to use a resin printer.

## Future work

I intend to design feet for other machines as well. I might also consider printing bail, or other, rollers. I know that it is easy to buy tubing for that purpose, but I am still curious about printing them. I printed some Underwood carriage return lever bumpers as well: this is one of the easiest shape you can imagine printing. Until now, I hadn't realized that those tended to break or be deformed!

![Underwood carriage return lever bumper (cover removed)](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1726.webp){:standalone}

I imagine that it would be possible to use the designs to create molds to pour rubber feet as well, but at this time I don't plan to do this: the 3D printed feet are good enough!

It would be interesting to try even softer TPU as well, but those are harder to find and to print. Some TPU materials have variable hardness depending on print settings. I am not sure whether this can help or not, but it would be interesting to try.

I am really happy with this, but I am sure that there is room for improvement.

---
