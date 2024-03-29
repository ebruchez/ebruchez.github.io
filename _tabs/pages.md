---
layout: page
title: Pages
icon: fas fa-file
order: 3
---

<div id="pages-list" class="pl-xl-2">
<ul class="list-unstyled">
{% for current_page in site.pages %}
{% if current_page.title %}
{% if current_page.url contains "/pages/" %}
    <li>
      <div>
        {% capture this_day %}{{ current_page.date | date: "%d" }}{% endcapture %}
        {% capture this_month %}{{ current_page.date | date: "%b" }}{% endcapture %}
        <span class="date day">{{ this_day }}</span>
        <span class="date month small text-muted">{{ this_month }}</span>
        <a href="{{ current_page.url | relative_url }}">{{ current_page.title }}</a>
      </div>
    </li>
{% endif %}
{% endif %}
{% endfor %}
</ul>
</div>
