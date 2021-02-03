---
layout: post
title: 'Scala tip: getOrElseUpdate'
date: '2012-06-30T09:24:00.001-07:00'
author: Erik Bruchez
tags:
- scala
category: Programming
modified_time: '2015-11-12T09:14:39.114-08:00'
blogger_id: tag:blogger.com,1999:blog-2849901641571065621.post-6137668523224516694
blogger_orig_url: https://blog.bruchez.name/2012/06/scala-tip-getorelseupdate.html
---

I found myself recently looking at the following code which I wrote when I was getting started with Scala:

```scala
def getModelState(modelPrefixedId: String) =
  modelStates.get(modelPrefixedId) match {
    case Some(modelState) => modelState
    case None =>
      val modelState = new ModelState(modelPrefixedId)
      modelStates += modelPrefixedId -> modelState
      modelState
  }
```
This is typically logic you would write in Java, and it looks great in some ways: it uses pattern matching, the tuple arrow (`->`), etc. But it turns out that Scala collections already provide the `getOrElseUpdate` method on mutable maps. The 8 lines above translate simply into:

```scala
def getModelState(modelPrefixedId: String) =
  modelStates.getOrElseUpdate(modelPrefixedId, new ModelState(modelPrefixedId))
```

Morality: know your collections!
