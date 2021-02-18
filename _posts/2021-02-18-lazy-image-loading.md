---
layout: post
title: Turning off lazy image loading
author: Erik Bruchez
date: '2021-02-18T13:15:00.000-08:00'
tags:
category: Technology
---

When switching to my new blog setup, which is based on [Jekyll](https://jekyllrb.com/) and the [Chirpy theme](https://github.com/cotes2020/jekyll-theme-chirpy), I wondered why things jittered around when paging down a long post with images. Similarly, using the "End" key to reach the end of the page and then going back up was weird. Finally, printing a blog post or saving it as a PDF was not showing all the images!

I discovered that there has been a fad about lazy image loading in web development in recent years. JavaScript libraries such as Lozad.js help you do that, and this Jekyll theme includes that library by default. The theme first replaces `<img>` tags to have blank placeholder images, and then as images show in the viewport when the user scrolls, the JavaScript actually loads images.

Why go through all of this? Apparently to save bandwidth on page load, as well as some other unverified benefits. Yes, it's "smart", but not all the way through because it comes at the cost of damaging the user experience in many ways. I don't think it's worth the price and therefore I disabled the built-in lazy image loading.

One way to improve on this would be to have not only blank placeholder images but to have placeholders with the correct width and height. This would avoid the jittering but still it wouldn't fix the printing/save to PDF problem. Maybe there is another solution to that specific problem, such as the native [`loading="lazy"`](https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading#images_and_iframes) (which at this time is [not supported by Safari](https://caniuse.com/loading-lazy-attr)), but which would allow the browser to load all relevant lazy images before printing.

Some sites do this better than others. For example [iFixit](https://www.ifixit.com/), which makes heavy use of images in their repair guides, uses lazy image loading. However all images have the same predefined size and no jittering happens when scrolling. But if you try to print a guide or export it as PDF, guess what: most of the images won't appear unless you have patiently scrolled down the page first.

At this point I can only see this as another mostly misguided fad in development. There might be valid use cases for high traffic sites, but I suspect that this benefits mostly sites which throw a lot of unwanted stuff at the user anyway. For a personal blog post, there is really no reason to enable this and damage the user experience.
