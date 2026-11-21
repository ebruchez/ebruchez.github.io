---
layout: page
lang: fr
title: "Articles en français"
permalink: /fr/
breadcrumb:
  - label: Home
    url: /
---

Cette page regroupe tous les articles publiés en français sur ce blog, qu'il s'agisse de traductions d'articles en anglais ou d'articles écrits directement en français.

<div id="archives" class="pl-xl-2 mt-4">
{% assign current_year = "" %}
{% for post in site.data.french_posts %}
  {% if post.year != current_year %}
    {% unless forloop.first %}</ul>{% endunless %}
    {% assign current_year = post.year %}
    <span class="lead">{{ current_year }}</span>
    <ul class="list-unstyled">
  {% endif %}
    <li>
      <div>
        <span class="date day">{{ post.day }}</span>
        <span class="date month small text-muted">{{ post.month }}</span>
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        {% if post.translation_source %}
          <a href="{{ post.translation_source.url | relative_url }}" class="post-lang-badge" hreflang="en" title="Version anglaise originale">EN</a>
        {% endif %}
      </div>
    </li>
  {% if forloop.last %}</ul>{% endif %}
{% endfor %}
</div>
