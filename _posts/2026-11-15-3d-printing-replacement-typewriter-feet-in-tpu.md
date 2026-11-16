---
layout: post
title: "3D Printing Replacement Typewriter Feet in TPU"
author: Erik Bruchez
date: '2026-11-15T18:30:00-08:00'
tags:
- typewriters
- 3d-printing
- restoration
category: Typewriters
---

![Some of my 3D-printed typewriter feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_3860.webp){:standalone}

## Why 3D print typewriter feet?

Typewriter feet do more work than they usually get credit for:

- They keep the machine from sliding across smooth desks when typing or returning the carriage.
- They dampen vibrations and noise, making typing quieter and more comfortable.
- They protect both the desk surface underneath and the typewriter itself from scratches and dents.

To do all three jobs, feet need to be relatively soft and grippy, which is why they were traditionally made of rubber. Over the decades, however, rubber ages poorly: on most vintage machines, the original feet have turned rock-hard, flattened, crumbled away, or gone missing altogether. You could reasonably view typewriter feet as consumable parts - much like platens, or car tires.

Most typewriter manufacturers are long gone, and original replacement parts haven't been made in decades. Until recently, the usual workarounds were:

- keeping the hardened feet and placing the typewriter on a mat;
- substituting generic hardware-store parts such as rubber furniture feet, bumpers, or lab stoppers;
- sculpting replacements out of moldable rubber like Sugru; or
- buying modern replacement feet from specialty typewriter-parts sellers.

That last option is very real, and some of the custom-poured rubber feet sold today are wonderfully made. Over the years, I have personally spent hundreds of dollars on them. The catch is twofold: at USD 20–40 per set, they get expensive fast, and you are limited to the relatively common models on offer. Across a large collection - including rare 19th- and early-20th-century machines for which no aftermarket feet exist, as well as unrestored project or parts machines sitting in storage - buying poured rubber sets for everything simply isn't practical.

Once I got a 3D printer, designing and printing my own replacement feet turned out to be a game changer. Starting with a single test for a 1920 Underwood 5, I quickly ended up designing feet for over twenty machines spanning eight decades of typewriter history.

## Choosing the right material: Shore 85A TPU

PLA and PETG, the workhorse filaments of hobbyist 3D printing, are poorly suited for actual typewriter feet: they are far too hard and slippery. **TPU** (*thermoplastic polyurethane*), on the other hand, is a flexible elastomer filament sold in varying hardness grades on the Shore A scale.

The most widely available flexible filament is **Shore 95A TPU**. I tried it first, and while it works fine for static display, I found it too stiff and not grippy enough for real use. Switching to a softer **Shore 85A TPU** - specifically Siraya Tech Flex 85A - made all the difference.

![Siraya Tech Flex Shore 85A TPU filament](/assets/posts/3d-printing-typewriter-feet/2x/siraya85a.webp){:standalone width="50%"}

In terms of bounce and cushioning, Shore 85A TPU is excellent and feels very close to rubber. You can also tune the effective firmness of a foot by varying the slicer infill - I have used anywhere from 100% solid down to about 25% depending on the thickness and geometry of the foot. While TPU is still slightly less tacky than fresh natural rubber, the weight of a typewriter makes up for it in practice, and it is worlds better than missing, petrified, or crumbled feet.

Color choices are much narrower in soft TPU than in PLA or PETG: black is by far the most common, alongside white, clear, and the occasional bright color like orange. Fortunately, black is perfect for almost any typewriter.

## Printer setup for soft TPU

Soft TPU has a reputation for being finicky, though modern printers handle it much better than older machines did. Still, Shore 85A is floppy enough that I couldn't push it reliably through my printer's PTFE guide tube. Instead, I feed the filament straight into the top of the extruder - a setup made easy by an earlier modification allowing me to lift off my printer's top cover.

[//]: # (![Feeding TPU filament directly into the extruder](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1439.webp){:standalone})

Initially, I ran into a few extruder jams, likely triggered during filament retractions. Tweaking the tension screws on the extruder idler largely eliminated those jams. Equally important, TPU is hygroscopic and *must* be dry to print cleanly: a filament dryer is essential, and I feed the spool directly out of a dry box onto a textured build sheet so it doesn't absorb moisture mid-print. The short video below shows that setup in action:

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

## From petrified rubber to CAD

Before a new foot goes on, the remnants of the old one have to come off. When the original rubber was molded into a metal cup, removing it can be surprisingly tricky: the cups are often stamped out of very soft steel or brass that bends easily if you pry too hard. On a couple of machines, the aged rubber was so hard that I actually used a drill to bore it out, escaping with only minor scratches inside the cups.

Once the mounting hardware is clean, the design loop itself is fast and satisfying:

1. **Inspect what remains** of the original foot, mentally (or on paper) reconstructing its un-flattened profile.
2. **Measure key dimensions** - cup inner diameters, stem holes, screw clearances, and frame offsets - with digital calipers.
3. **Model the part in CAD** (I use Autodesk Fusion).
4. **Print a quick test piece in PLA** to verify the fit against the hardware and frame, adjusting dimensions as needed.
5. **Refine and print in Shore 85A TPU**, adding fillets and chamfers for appearance and printability.

Here is that PLA prototyping step for my very first design, the 1920 Underwood 5, showing the rock-hard original foot on the right and the orange PLA test print on the left (both viewed from underneath):

![Prototyping Underwood 5 typewriter feet in orange PLA](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1614.webp){:standalone}

One important 3D-printing constraint is avoiding **supports**. Overhanging cavities normally require sacrificial support material, which is messy to remove cleanly from flexible TPU (unless you have a multi-material setup printing PLA supports). By using angled internal chamfers and concentric bottom grooves instead of flat unsupported overhangs, **none of the feet I have designed so far require supports**.

## Designing across eight decades of typewriters

What surprised me most after doing the Underwood 5 was just how differently typewriter makers approached mounting four pieces of rubber to a frame between the 1880s and the 1960s. Grouping my designs by attachment style and geometry gives a nice tour of both typewriter engineering and CAD techniques.

### 1. Press-fit stems, reinforcing rods, and clearance notches (1885–1917)

The earliest feet in my collection were also the simplest to model: stepped cylindrical plugs that press-fit directly into round holes in the cast-iron base, as on the **Remington 2** (1885), **Densmore 1b** (1894–1896), and **Smith Premier 5** (1907).

<!-- Optional extra photos in assets/posts/3d-printing-typewriter-feet/2x/ if you want them here:
     IMG_1463.webp = Remington 2, IMG_1470.webp = Densmore 1b -->

![Smith Premier 5 press-fit feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1466.webp){:standalone}

Because CAD makes experimentation nearly free, I tried two variations for my 1899 **Densmore 4** (whose feet are secured with screws): a straightforward cylindrical profile - likely closer to what left the factory - and a tapered conical version just to look a little more snazzy.

![Cylindrical Densmore 4 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1395.webp){:standalone}

![Tapered Densmore 4 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1465.webp){:standalone}

The tall push-in feet on my 1907 **Remington 7 with Gorin tabulator** look similar from the outside, but hide a neat structural detail: an inch-long steel rod slips into the center of the foot to stiffen and stabilize it. Preserving that internal bore in the printed TPU version (alongside a tapered variant) was trivial.

![Remington 7 feet with internal metal reinforcing rods](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1432.webp){:standalone}

Custom CAD also shines when a machine needs an asymmetric tweak. My 1909 aluminum **Blickensderfer 5** arrived with only two deformed, fossilized feet remaining; years ago I had sculpted makeshift rear feet out of Sugru, with mediocre results. While modeling proper rounded TPU replacements (with top holes for slotted wood screws), I noticed a screw head on the underside of the frame encroaching on the left rear foot - and added a clean clearance notch in minutes:

![Blickensderfer 5 feet, including the notched rear foot](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1523.webp){:standalone}

I took a similar approach on my 1917 **Courier** - essentially an Austrian-built **Oliver 3** (so the part may fit an Oliver 3 as well). Here the feet press directly into the frame without hardware, and adding a stepped side notch let me make the base slightly oversized, reaching just beyond the cast-iron body for a wider, more stable footprint:

![Courier foot with side clearance notch](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1867.webp){:standalone}

### 2. Metal cups, screw studs, and multi-part cushions (1906–1949)

By the 1910s and 1920s, many standard office machines seated their rubber feet inside stamped metal cups held to the frame with screws. That includes the screw-in feet on the **Royal "flatbed" Models 1, 5, and 6** (which can be printed shorter or taller depending on preference), the tall stocky cup-mounted feet of my 1920 **Underwood 5**, and the wide cup-mounted feet of the 1920s **Remington Vertical Adder Model 21** (which likely fit contemporaneous Remington standards as well).

<!-- Optional extra photo in assets/: IMG_1702.webp = Remington Model 21 -->

![Royal 1/5/6 screw-in feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1822.webp){:standalone}

![Underwood 5 tall feet (original left, 3D-printed TPU right)](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1250.webp){:standalone}

By the late 1930s and 1940s, vibration isolation became more sophisticated. The 1938 **Royal KHM** sandwiches the mounting hardware between the main square-ish foot below and a separate rubber rebound cushion on top:

![Royal KHM feet and top cushions](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1749.webp){:standalone}

Postwar Underwoods evolved along similar lines. On my 1942 **Underwood "S"**, the rubber sits beneath felt-like cushions inside metal cups; I made the hidden soft TPU section slightly taller than the flattened originals without changing the external look. The 1948 **Underwood "SS"** and 1949 **Rhythm Touch** use wider saucer-like feet that may originally have shared the same molded rubber part, though on my machines the Rhythm Touch hardware includes an extra metal insert and washer. I modeled slightly straighter walls for the Rhythm Touch and gave both designs grooved undersides and internal chamfers so they print cleanly without supports.

![Underwood "S" TPU inserts behind two original metal cups with screw studs](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1500.webp){:standalone}

![Underwood Rhythm Touch feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1663.webp){:standalone}

![Underwood "SS" feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1717.webp){:standalone}

### 3. Travel cases and reconstructing lost shapes (1927–1960s)

Portable typewriters often attach compact circular feet directly to the bottom of their carrying case or baseboard with a screw and washer. Both the 1958 **Hermes Media** and the **Princess 100** had originals squashed in creative ways, making them quick, rewarding replacements to print:

![Hermes Media feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1671.webp){:standalone}

![Princess 100 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_2071.webp){:standalone}

Not every portable leaves clear clues behind, though. Reconstructing the feet on my 1927 **Varityper Folding** (closely related to the Hammond Folding) required some guesswork. Inside the case bottom were aged, slightly cupped felt pads, and the surviving rubber remnants had deformed into that cup - yet if the machine was ever meant to sit directly on a table outside its case, the bottom of the feet had to be flat. Online photos of surviving Varityper and Hammond Folding machines weren't much help either, as nearly all of them have badly deteriorated feet. I settled on a flat-bottomed design that wraps neatly around and inside the metal frame legs:

![Varityper Folding feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1713.webp){:standalone}

### 4. Beyond round feet: lofts, splines, and oversized blocks (1950s–1960s)

Mid-century European machines pushed me past simple revolved cylinders in Fusion. The 1951 **Hermes Ambassador** uses long, substantial rectangular feet sandwiched between stamped metal brackets. Modeling them was my excuse to learn Fusion's **Loft** feature, combined with chamfers and fillets - and seeing the crumbling grey original next to the fresh black TPU part speaks for itself:

![Hermes Ambassador foot alongside its metal bracket and crumbling original](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1369.webp){:standalone}

The 1960s **Facit TP2** uses a very similar rectangular, metal-plate-retained concept at a fraction of the Ambassador's size:

<!-- Note: IMG_2059.webp shows the 4 Facit TP2 feet textured-bottom-up; swap with your top-recess photo from Printables if you prefer showing the inner cavity! -->

![Facit TP2 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_2059.webp){:standalone}

More challenging still was the 1960 **Erika 10**, whose elongated, boat-like feet are neither circular nor rectangular. Here I combined a loft with a flatbed scan of the original foot's outline, tracing splines over the scan to approximate the curve. It isn't mathematically exact - then again, neither were the factory originals!

![Erika 10 feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1690.webp){:standalone}

Finally, two 1950s office standards in my collection seat distinct front and rear shapes inside metal cups. The **Olivetti Lexicon 80** pairs round conical front feet with elongated, two-screw rear feet whose deep inner pockets accept a metal retaining bar:

![Olivetti Lexicon 80 front and rear feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_4771.webp){:standalone}

And at the largest end of the scale, my **Adler Standard** pads are over two inches across - the widest feet I have printed so far. Here the front feet include a larger central hole to clear a mounting nut in addition to the mounting screws, while the rear feet feature an opening at the back. On future revisions I might add a tread profile underneath so that broad flat contact area stays as grippy as possible:

![Adler Standard front and rear feet](/assets/posts/3d-printing-typewriter-feet/2x/IMG_4742.webp){:standalone}

## Complete catalog on Printables

All of the models below are available on [my Printables profile](https://www.printables.com/@ebruchez_3481058/models) under a Creative Commons Attribution-ShareAlike (CC BY-SA 4.0) license. Because `.stl` meshes alone are tedious to modify when another machine needs a slightly taller foot or a wider screw hole, **every download includes the original Autodesk Fusion (`.f3d`) and `.step` CAD source files** alongside `.stl` and `.3mf` print files.

| Typewriter                             | Link                                                                                                      | Year(s)     | Attachment & Notes                                                    |
|----------------------------------------|-----------------------------------------------------------------------------------------------------------|-------------|-----------------------------------------------------------------------|
| Remington 2                            | [Printables](https://www.printables.com/model/1548387-remington-2-typewriter-rubber-foot)                 | 1885        | Push-in                                                               |
| Densmore 1b                            | [Printables](https://www.printables.com/model/1546628-densmore-1b-typewriter-rubber-foot)                 | 1894–1896   | Push-in                                                               |
| Densmore 4                             | [Printables](https://www.printables.com/model/1541028-densmore-4-typewriter-rubber-foot)                  | 1899        | Screw-mounted; cylindrical and conical versions                       |
| Royal "flatbed" 1 / 5 / 6              | [Printables](https://www.printables.com/model/1565685-royal-flatbed-156-typewriter-rubber-foot)           | 1906–1913   | Screw-in; shorter or taller variants                                  |
| Remington Model 7 with Gorin tabulator | [Printables](https://www.printables.com/model/1544036-remington-7-typewriter-rubber-foot)                 | 1907        | Push-in; tall, reinforced with internal steel rod                     |
| Smith Premier 5 with Gorin tabulator   | [Printables](https://www.printables.com/model/1540555-smith-premier-typewriter-rubber-foot)               | 1907        | Push-in; tall                                                         |
| Blickensderfer 5                       | [Printables](https://www.printables.com/model/1545715-blickensderfer-5-typewriter-rubber-foot)            | 1909        | Push-in with top wood-screw hole and rear clearance notch             |
| Courier                                | [Printables](https://www.printables.com/model/1916844-courier-typewriter-rubber-foot)                     | 1917        | Push-in with side clearance notch (Austrian Oliver 3)                 |
| Underwood 5                            | [Printables](https://www.printables.com/model/1540512-1920-underwood-5-typewriter-rubber-foot)            | 1920        | Metal cup and screw; tall variant                                     |
| Remington Vertical Adder Model 21      | [Printables](https://www.printables.com/model/1545724-remington-model-21-typewriter-rubber-foot)          | 1920s       | Metal cup and screw                                                   |
| Varityper / Hammond Folding            | [Printables](https://www.printables.com/model/1562187-varityper-folding-or-hammond-folding-typewriter-fo) | 1927        | Push-in; wraps inside and around the metal frame legs                 |
| Royal KHM                              | [Printables](https://www.printables.com/model/1562252-royal-khm-typewriter-foot)                          | 1938        | Sandwiched with metal hardware + top rubber cushions                  |
| Underwood "S"                          | [Printables](https://www.printables.com/model/1549982-underwood-s-typewriter-rubber-foot)                 | 1942        | Metal cup and screw; fits beneath felt-like top cushions              |
| Underwood "SS"                         | [Printables](https://www.printables.com/model/1552390-underwood-ss-typewriter-foot)                       | 1948        | Metal cup and screw; wide, grooved support-free base                  |
| Underwood Rhythm Touch                 | [Printables](https://www.printables.com/model/1562199-underwood-rhythm-touch-typewriter-foot)             | 1949        | Metal cup, insert, washer, and screw; wide                            |
| Adler Standard                         | [Printables](https://www.printables.com/model/1916810-adler-standard-typewriter-rubber-feet)              | 1950s       | Wide square-ish blocks in metal cups; distinct front and rear shapes  |
| Olivetti Lexicon 80                    | [Printables](https://www.printables.com/model/1916835-lexicon-80-typewriter-rubber-feet)                  | 1950s       | Seated in metal cups; round front feet and oblong 2-screw rear feet   |
| Hermes Ambassador (early)              | [Printables](https://www.printables.com/model/1540422-early-hermes-ambassador-typewriter-rubber-foot)     | 1951        | Large rectangular bar sandwiched between metal brackets               |
| Hermes Media                           | [Printables](https://www.printables.com/model/1554200-hermes-media-typewriter-foot)                       | 1958        | Compact; screw and washer into bottom case cups                       |
| Princess 100                           | [Printables](https://www.printables.com/model/1709663-princess-typewriter-rubber-foot)                    | 1950s–1960s | Cylindrical; screwed to travel case                                   |
| Erika 10                               | [Printables](https://www.printables.com/model/1562194-erika-10-typewriter-foot)                           | 1960        | Metal cup and 2 screws; spline-lofted oblong shape                    |
| Facit TP2                              | [Printables](https://www.printables.com/model/1709671-facit-typewriter-rubber-foot)                       | 1960s       | Compact rectangular block with recessed metal retaining plate & screw |

## Trade-offs and beyond feet

What I love most about this workflow is the speed of iteration: going from a crumbled remnant and a pair of calipers to a fitted TPU foot installed on a machine takes at most a few hours, often much less. Even better, because filament costs pennies per foot, I have been able to outfit unrestored project machines before putting them back on storage shelves - protecting both the shelves and the typewriters until their turn on the workbench comes.

There are, of course, a couple of honest trade-offs compared with poured rubber:

- **Grip:** Shore 85A TPU is slightly less tacky than fresh rubber, though under the weight of a typewriter I haven't found sliding to be an issue in practice.
- **Cosmetics:** Printed TPU has a slight sheen and visible layer lines. Underneath a typewriter frame, feet rarely draw the eye, so this doesn't bother me at all. For perfectionists, someone recently suggested lightly buffing TPU on a polishing wheel to knock down layer lines and leave a matte, rubbery finish; flexible SLA resins - or using 3D-printed positives to cast silicone molds for poured rubber - are also possibilities, though for my needs direct TPU prints are already more than good enough.

Once your printer is dialed in for Shore 85A TPU, other degraded rubber parts start jumping out at you too. For instance, I hadn't realized how often carriage return lever bumpers split or flatten until I inspected my 1942 Underwood "S" and 1948 Underwood "SS" - each uses two tiny ring bumpers that take minutes to model and print ([also on Printables](https://www.printables.com/model/1562263-underwood-typewriter-carriage-return-lever-bumper)):

![Underwood carriage return lever bumper installed (cover removed)](/assets/posts/3d-printing-typewriter-feet/2x/IMG_1726.webp){:standalone}

Next on my curiosity list are paper bail and feed rollers (even though rubber tubing is an easy alternative), more foot designs as new machines cross the bench, and experimenting with even softer or variable-hardness foaming TPUs.
