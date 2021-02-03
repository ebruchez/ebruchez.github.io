---
layout: post
title: Implicit conversion to the Unit type in Scala
date: '2012-10-05T10:02:00.000-07:00'
author: Erik Bruchez
tags:
- scala
category: Programming
modified_time: '2015-11-14T11:34:05.808-08:00'
blogger_id: tag:blogger.com,1999:blog-2849901641571065621.post-2619114618400983867
blogger_orig_url: https://blog.bruchez.name/2012/10/implicit-conversion-to-unit-type-in.html
redirect_from:
  - /2012/10/implicit-conversion-to-unit-type-in.html
---

In Scala, you have a few ways to express that a function returns the `Unit` type.[^1] A common way is to use the
function syntax and specify a result type of `Unit`:

```scala
def foo: Unit = ...
```

Like for any result type, the type annotation is not necessary if the function body already returns the expected type,
as in:

```scala
def newline = println()
```

or:[^2]

```scala
trait Foo {
  def log = ()
}
```

The type annotation is useful not only for documentation purposes, but also in case the last expression of the
function body happens to return a result of a type which is not `Unit`:

```scala
def focus(): Boolean = ...    // function with side effect but which also returns a value
def justFocus: Unit = focus() // function with side effect returning Unit
```

Now you might wonder, as [@avernet](https://twitter.com/avernet) and I did yesterday, how this last bit can work!
How does the compiler, with an expected type of `Unit` on one hand, and an actual expression type of `Boolean` on the other hand,
reconcile the two?

This is not done via subtyping, because `Unit` is not a supertype of `Boolean`: instead `Unit` is a subtype of `AnyVal`
and at the same level as `Boolean` in the [Scala type hierarchy](http://www.scala-lang.org/node/128).

The answer is that there is an *implicit conversion* taking place.[^3] The [Scala language
specification](http://www.scala-lang.org/docu/files/ScalaReference.pdf) specifies this conversion in section 6.26.1:

> *Value Discarding*. If *e* has some value type and the expected type is `Unit`, *e* is converted to the expected type
> by embedding it in the term `{ e; () }`.

In case you are wondering, here *value type* does *not* mean a subtype of `AnyVal`. This can be a bit misleading,
especially with the introduction in Scala 2.10 of *value classes*, which *do* derive from `AnyVal`. Instead, a value
type is just a type which can have concrete values, as explained in chapter 3 of the spec:

> A subset of first-order types called *value types* represents sets of (first-class) values. […] Non-value types
> capture properties of identifiers that are not values (§3.3). For example, a type constructor (§3.3.3) does not
> directly specify a type of values."

In short the spec mandates that any value returned by an expression is implicitly converted to
`Unit` by the compiler when the expected type is `Unit`. This applies in particular to functions, where the
expression is the function body and the expected type is determined with the `Unit` type annotation.

So now we all know how it works!

[^1]: `Unit` is similar to the `void` of C or Java, but a bit fancier. For example you can have variables of type `Unit`,
and pass a value of type `Unit` around)

[^2]: Note the syntax for the `Unit` value: `()`.

[^3]: This doesn't mean that the implicit conversion is actually defined in the `Predef` object with the `implicit`
keyword. It could possibly be implemented that way, but as of Scala 2.10 this is not the case. So it's probably done by
compiler magic.
