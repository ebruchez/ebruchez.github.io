---
layout: page
title: Pages
icon: fas fa-file
order: 3
---

## Bucket lists

bucket list
: list of things that one has not done before but wants to do before dying

I maintain the following "bucket lists" of things to acquire:

- [Typewriters](/pages/typewriter-bucket-list/)
- [Computers](/pages/computer-bucket-list/)

## Collections

### Typewriters

- [Typewriter Collection: Completed Restorations](/pages/typewriter-collection-completed-restorations/)
- [Typewriter Collection: Future Restorations](/pages/typewriter-collection-future-restorations/)
- [Typewriter Collection: Hermes Typewriters](/pages/typewriter-collection-hermes/)
- [Typewriter Collection: IBM Typewriters](/pages/typewriter-collection-ibm/)
- [Typewriter Collection: Varityper](/pages/typewriter-collection-varityper/)
- [Typewriter Collection: Accounting Machines](/pages/typewriter-collection-accounting/)

### Computers

- [Computer Collection: Vintage Computers](/pages/computer-collection/)

## Other websites

- [Mascagni.org](https://mascagni.org/) — My website dedicated to Italian composer Pietro Mascagni (1863–1945)

## Other

- [Predictions](/pages/predictions/)

[//]: # (<div id="pages-list" class="pl-xl-2">)

[//]: # ()
[//]: # (<ul class="list-unstyled">)

[//]: # ()
[//]: # ({% for current_page in site.pages %})

[//]: # ()
[//]: # ({% if current_page.title %})

[//]: # ()
[//]: # ({% if current_page.url contains "/pages/" %})

[//]: # ()
[//]: # (    <li>)

[//]: # ()
[//]: # (      <div>)

[//]: # ()
[//]: # (        {% capture this_day %}{{ current_page.date | date: "%d" }}{% endcapture %})

[//]: # ()
[//]: # (        {% capture this_month %}{{ current_page.date | date: "%b" }}{% endcapture %})

[//]: # ()
[//]: # (        <span class="date day">{{ this_day }}</span>)

[//]: # ()
[//]: # (        <span class="date month small text-muted">{{ this_month }}</span>)

[//]: # ()
[//]: # (        <a href="{{ current_page.url | relative_url }}">{{ current_page.title }}</a>)

[//]: # ()
[//]: # (      </div>)

[//]: # ()
[//]: # (    </li>)

[//]: # ()
[//]: # ({% endif %})

[//]: # ()
[//]: # ({% endif %})

[//]: # ()
[//]: # ({% endfor %})

[//]: # ()
[//]: # (</ul>)

[//]: # ()
[//]: # (</div>)
