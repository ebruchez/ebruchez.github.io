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

## Typewriter pages

- [Typewriter collection: future restorations](/pages/typewriter-collection-future-restorations/)

## Lists of comic books I have read

- [Comic Books](/pages/comic-books/)
    - [2025](/pages/comic-books-2025/)
    - [2024](/pages/comic-books-2024/)
    - [2023](/pages/comic-books-2023/)
    - [2022](/pages/comic-books-2022/)
    - [2021](/pages/comic-books-2021/)
    - [2020](/pages/comic-books-2020/)
    - [2019](/pages/comic-books-2019/)
    - [2018](/pages/comic-books-2018/)
    - [2017](/pages/comic-books-2017/)
    - [2016](/pages/comic-books-2016/)
    - [2015](/pages/comic-books-2015/)

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
