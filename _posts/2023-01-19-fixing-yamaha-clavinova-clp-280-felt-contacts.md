---
layout: post
title: Yamaha Clavinova CLP-280 felt and rubber contacts replacement
author: Erik Bruchez
date: '2023-01-19T20:52:00-07:00'
tags:
category: Technology
---

## The symptoms

Recently, I started feeling that the touch of our 15-year-old Yamaha Clavinova CLP-280 in the mid-range was different: the responsiveness of the keys was not good anymore, and different from the lower and higher ranges. In addition, a couple of keys occasionally made a clacking sound.

![The Yamaha Clavinova CLP-280](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0273.jpg){:standalone}

Given what I know about the CLP-280, I figured that there might be two different things at play:

1. The rubber membranes ("rubber contacts") that I had observed in my [first repair](2021-11-07-fixing-yamaha-clavinova-clp-280.md) might have some wear.
2. The felt that dampens the keys might have lost shape as well, explaining the clacking sound.

## The parts

I was eager enough to try to fix the problem that I ordered a set of replacement membranes and replacement felt. I found the replacement parts on eBay as those are no longer sold by Yamaha. However, those are OEM parts. These parts appear to be generally for the GH3 ("Grade Hammer 3") Yamaha keyboards, and are not specific to the CLP-280.

I got a full set of membranes, as there are three different lengths:

- 1 × 5-key membrane to the left side of the keyboard (VCZ74400/VCZ7440)
- 6 × 12-key membranes in the middle (VCZ74300/VCZ7430)
- 1 × 11-key membrane to the right side of the keyboard (VCZ74500/VCZ7450)

![5-key membrane](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0251.jpg){:standalone}

![12-key membranes](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0259.jpg){:standalone}

![11-key membrane](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0254.jpg){:standalone}

The felt is called "stopper" or "upstop felt" (V8468201).

![Label of the felt package](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0271.jpg){:standalone}

## The repair

Like last time, I started by opening the top of the piano by removing the 3 screws in the back and removing the top cover. I could see the problem immediately: the felt had detached in the middle portion of the keyboard! Well, in retrospect, I should have checked done that step first!

![Inside of the piano](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0218.jpg){:standalone}

The next step was to remove the keyboard from the piano, as I did last year. This is neither hard nor risky, although it is a little time-consuming.

![The piano without its keyboard](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0234.jpg){:standalone}

In this picture you can see where the felt detached from the rest of the keyboard.

![Wavy felt](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0243.jpg){:standalone}

The first task was to remove the old felt entirely. I didn't think it was reasonable to try to glue it back, as one layer clearly had outlasted its life. The film with the glue was a little hard to remove from the plastic of the keyboard in places, but I used:

- a plastic razor blade scraper to remove the parts that stuck
- a hair dryer to soften the glue in the rest of the felt

![Plastic scraper](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0245.jpg){:standalone}

This went very smoothly.

I then proceeded to remove the 3 PCBs (printed circuit boards) that are attached to the keyboard. I had to remove the screws that hold each PCB in place. The PCBs then easily come off the keyboard, and the rubber membranes will either stay stuck to them, or stay on the rest of the keyboard. I carefully took them out, blew compressed air on them to clean them, and numbered them before storing them away in the original plastic bag containing the replacement membranes, as I thought that the old ones might actually be quite ok, especially the ones that had less use (not in the middle of the keyboard).

Putting them back is a little tricky, as you want them to fit perfectly in the slots in the keyboard before placing the PCBs on top of them and screwing them back, perfectly aligned. For this, I used the same method I did last time: I put the keyboard quasi vertically on its side, which let me position the membranes in place so they don't fall, and then putting the PCBs back.

![Membranes installation](/assets/posts/fixing-yamaha-clavinova-clp-280-felt-contacts/2x/IMG_0262.jpg){:standalone}

I installed the felt without an problem. The glue was quite strong, to the point that if touches the plastic it might be almost impossible to get it out without damage. So proceed carefully!

This done, I put the keyboard back in the piano, and then tested the keyboard. To my relief, the responsiveness of the keys was back to normal, and the clacking sound was gone (as I expected). I only had to put back the top of the piano.

## The result

The keyboard now sounds like new. I am very happy with the result, and even though I might not actually have had to replace the membranes, that should extend the life of the keyboard no matter what. You can hear the result here.

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
      videoId: 'gEMCxHElgrU',
      playerVars: {
        'playsinline': 1
      }
    });
  }
</script>

<div id="player"></div>

## More

Read about my two previous repairs:

- [Fixing a Yamaha Clavinova CLP-280](2021-11-07-fixing-yamaha-clavinova-clp-280.md)
- [Fixing a Yamaha Clavinova CLP-280 pedal](2022-11-15-fixing-yamaha-clavinova-clp-280-pedal.md)
