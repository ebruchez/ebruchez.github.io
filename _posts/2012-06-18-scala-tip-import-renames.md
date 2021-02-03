---
layout: post
title: 'Scala tip: import renames'
date: '2012-06-18T16:44:00.001-07:00'
author: Erik Bruchez
tags:
- scala
category: Programming
modified_time: '2015-11-12T09:10:25.299-08:00'
blogger_id: tag:blogger.com,1999:blog-2849901641571065621.post-737207396629682363
blogger_orig_url: https://blog.bruchez.name/2012/06/scala-tip-import-renames.html
---

In Java, you often write things like this, which are rather verbose:

```java
URLEncoder.encode(...)
URLDecoder.decode(...)
```

Since Java 1.5 you can use static imports, but then you are stuck with the original function names as is, `encode(...)` and `decode(...)`.

A cool feature of Scala is that imports support renaming, so you can write instead:

```scala
import java.net.URLEncoder.{encode => encodeURL}
import java.net.URLDecoder.{decode => decodeURL}
```

And then you just use the functions under their new name:

```scala
encodeURL(...)
decodeURL(...)
```

This is neat if you have to use these functions many times in a given file.

Another common use of renames is to reduce name clashes. For example, Scala already has a number of things named `Map`. If you are using a Java API expecting a `java.util.Map`, you are likely to get name clashes.

In Java, you would probably resort to full qualification, e.g. `java.util.Map`, and you can do the same in Scala, but that's verbose. With renaming, you can write things like:

```scala
import java.util.{Map => JMap, List => JList}
```

And then use the Java `Map` as `JMap` and the Java `List` as `JList`. Nothing is changed at the VM level: it's the same classes, but you now have a nice, short alias for them in the scope of the imports.
