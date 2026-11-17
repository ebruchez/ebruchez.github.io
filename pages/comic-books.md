---
layout: comics
title: Comic Books
dynamic_title: true
breadcrumb:
  - label: Home
    url: /
---

## Background

I grew up reading lots of comic books (AKA "bandes dessinées"). I read lots of [Franco-Belgian comics](https://en.wikipedia.org/wiki/Franco-Belgian_comics) including classics known all around the world, such as Tintin and Asterix, but also Mickey Mouse and Donald Duck which of course originate from the US. I am not a huge fan of the [superhero comics](https://en.wikipedia.org/wiki/Superhero_comics) or [manga](https://en.wikipedia.org/wiki/Manga), but that might still come. I do like some American comic strips, including Peanuts and Calvin and Hobbes.

{% if site.data.comics_latest_featured and site.data.comics_latest_featured.size > 0 %}
<div class="comics-hub-section-header">
  <h2>Latest reads &amp; quick reviews</h2>
  <a href="{{ '/pages/comic-books-2026/' | relative_url }}" class="comics-hub-all-link">
    All 2026 reads ({{ site.data.comics['2026'] | size }}) →
  </a>
</div>

<div class="comics-card-list">
  {% assign hub_cover_idx = 0 %}
  {% for entry in site.data.comics_latest_featured %}
    {% assign hub_prio = 'lazy' %}
    {% if entry.cover_url %}
      {% assign hub_cover_idx = hub_cover_idx | plus: 1 %}
      {% if hub_cover_idx == 1 %}
        {% assign hub_prio = 'high' %}
      {% elsif hub_cover_idx == 2 %}
        {% assign hub_prio = 'normal' %}
      {% endif %}
    {% endif %}
    {% include comics/card.html entry=entry hub_mode=true priority=hub_prio %}
  {% endfor %}
</div>
{% endif %}

## Favorite comic books

### Individual works

<div class="comics-favorites-grid">
  {% for fav in site.data.comics_favorites.individual_works %}
    {% include comics/favorite-card.html entry=fav %}
  {% endfor %}
</div>

### Among the classics

<div class="comics-favorites-grid">
  {% for fav in site.data.comics_favorites.classics %}
    {% include comics/favorite-card.html entry=fav %}
  {% endfor %}
</div>
