---
layout: post
title: Map.map vs. Map.mapValues
date: '2013-02-03T17:29:00.001-08:00'
author: Erik Bruchez
tags:
- scala
category: Programming
modified_time: '2015-11-12T09:43:38.716-08:00'
blogger_id: tag:blogger.com,1999:blog-2849901641571065621.post-3317894540003411035
blogger_orig_url: https://blog.bruchez.name/2013/02/mapmap-vs-mapmapvalues.html
redirect_from:
  - /2013/02/mapmap-vs-mapmapvalues.html
---

I just hit a bug caused by a misunderstanding of how `Map.mapValues` works. Consider:

```scala
val original = Map("a" → 1, "b" → 2)
val modified = original map { case (k, v) ⇒ k → (v + 1) }
```

The result is an immutable map[^1] which is a transformation of the original map (all values are incremented by one). Once the `map` method terminates, the new map is actually holding those new values.

Now `Map` also has a `mapValues` method, which seems like an attractive shortcut for the rather verbose transformation above. So you write:

```scala
val original = Map("a" → 1, "b" → 2)
val modified = original mapValues (_ + 1)
```

More concise, right? But there is a catch: `map` and `mapValues` are different in a not-so-subtle way. `mapValues`, unlike `map`, returns a *view* on the original map. This view holds references to both the original map and to the transformation function (here `(_ + 1)`). Every time the returned map (view) is queried, the original map is first queried and the tranformation function is called on the result. You can see this in the source code of the Scala standard library:

```scala
override def mapValues[C](f: B => C): Map[A, C] = new DefaultMap[A, C] {
  ...
  def get(key: A) = self.get(key).map(f)
}
```

If the transformation function is referentially transparent, like `(_ + 1)`, all is well (besides performance considerations). But if not, you might be in for fun bugs depending on when the resulting map is queried. In my case, the transformation function depended on a context which, at a later point, was made invalid. When the resulting map was queried, the function-that-really-shouldn't-run-now was running in that invalidated context and causing trouble.

There is nothing inherently wrong with providing a view on the original map, but I would say the naming of `mapValues` violates the principle of least surprise: everybody knows the `map` method, and might reasonably assume that `mapValues` would behave in a similar way (and it doesn't).

Morality: when using `mapValues`, make sure the implications of using a view are acceptable, including making sure that your transformation function can safely run at the time the resulting map is queried. If not, prefer the good old `map` method. Oh, and also try to keep mutations local (but it's often not easy).

[^1]: Scala has `Map` and `map`: `Map` denotes one of the traits for "a map from keys of type A to values of type B" (AKA a hash map),  `map` is a method on collections, including `Map`, which "builds a new collection by applying a function to all elements of this map". When I (and Scaladoc) use "map" as a noun, it means "it's an instance of `Map`".
