---
layout: post
title: The MacBook Air M1
date: '2021-05-17T22:43:00.000-07:00'
author: Erik Bruchez
tags:
category: Technology
modified_time: '2021-05-18T12:09:00.000-07:00'
---

## Introduction

I've had a 10-core iMac Pro for over 3 years now. It's a superb machine with a beautiful 27" 5K display. Its thermal design is excellent and even when the fans run, they tend to be pretty silent, unlike the Intel-based MacBook Pro. The machine has been very reliable. (Also, Apple has announced that they are discontinuing it.)

For travel this summer I will need a laptop. One of my kids has been using my "older" MacBook Pro with butterfly keyboard during the pandemic's distance learning. That machine has been pretty good as well, except for the terrible keyboard, which luckily I have only rarely had to use.

So I ordered a MacBook Air M1 with 16 GB of RAM and 512 GB of storage. I would never have bought a MacBook Air in the past for tasks that include software development, due to the abysmal performance compared to other Apple machines. But the [M1-powered](https://en.wikipedia.org/wiki/Apple_M1) machines are different.

![Rendering of the Apple M1](/assets/posts/macbook-air-m1/apple-m1-render.jpg){:standalone width="50%"}

## A first benchmark

As a quick benchmark, I ran a [Scala](https://www.scala-lang.org/) compilation and packaging task from my work project. What I am testing here is the `package` command running from scratch (after deleting all `target` directories), without any artifact downloads. This is very CPU-intensive task (Scala compilation tends to be on the expensive side), but also happens to touch lots of files. Here is the result (lower is better):

|2017 iMac Pro Xeon W|2020 MacBook Air M1|
|---:|---:|
|111 s|92 s|

In short the MacBook Air M1 is roughly 20% faster at this task.

## Apples to Apples

Intuitively, this result is not surprising given what we have known about the M1 Macs over the last few months, and the fact that I am comparing to a 3-year-old machine. [^xeon] On the other hand, the iMac Pro has 10 cores [^parallelism] and 32 GB of RAM, and the performance of Intel CPUs has barely budged in 3 years, so I could have been surprised either way.

But it is pretty impressive when you think that the MacBook Air does this *without a fan* and within a 10 W CPU thermal envelope. To be fair, I am not sure what the exact numbers are for the MacBook Air, in particular the split between the CPU (or SoC) and the rest of the computer. Apple [does say](https://www.apple.com/az/mac/m1/):

> 10 watts (the thermal envelope of a MacBook Air)

So I am taking this as an upper bound for the SoC. For comparison, here are some power consumption numbers from other Macs, provided by Apple:

|Model|Idle|Max|
|---|---:|---:|
|[2017 iMac Pro Xeon W](https://support.apple.com/en-us/HT208378)|64 W|370 W|
|[2018 Mac Mini i7](https://support.apple.com/en-us/HT201897)|19.9 W|122 W|
|[2020 Mac Mini M1](https://support.apple.com/en-us/HT201897)|6.8 W|39 W|

The difference in power usage is staggering. An M1-powered MacBook Air will barely warm up even during a serious compilation.

The MacBook Air is also a relatively low-end machine for Apple, price-wise: the iMac Pro was a $5,000 machine, while the MacBook Air is a $1,450 machine in my configuration. There are differences, of course: larger monitor, SSD, and RAM count for something. Even if I bump the SSD to 1 TB to match the iMac Pro, the MacBook Air would be $1,650 (there is no 32 GB RAM option for the MacBook Air yet).

## Software installation

I transferred my main installation from my iMac Pro (which I still use, of course), including apps. However, out of the box, [Rosetta](https://en.wikipedia.org/wiki/Rosetta_(software)#Rosetta_2) was not installed and I was not even prompted. In any case, I had to reinstall some apps I use often, including Google Chrome, IntelliJ, and a few others. I want these apps to be native anyway.

[Homebrew](https://brew.sh/) didn't work at all, and it seemed like a fresh install was recommended in any case. So I uninstalled and reinstalled it completely.

I used [SDKMAN!](https://sdkman.io/) to install the Java JDK as well as [`sbt`](https://www.scala-sbt.org/). I first installed Java from [Azul](https://www.azul.com/downloads/), but I failed to install `sbt` with Homebrew. It turns out that `sbt` includes native code as well for OS integration! [^SDKMAN]

I struggled a little to update my local Jekyll installation (which powers this blog), but switching to `rbenv` and telling it to use Ruby 3.0.0 appears to have been enough to solve the issue.

At this time, I am running software such as 1Password 6, the Plex player, Google Backup and Sync, Evernote, and Marked 2, via Rosetta.

I have also started using Docker, which now supports the `arm64` CPU architecture of the M1 macs, as well as emulation of the Intel CPU architecture. However, Docker does not recommend emulation and says that there are limitations. I have managed to run MySQL using the `mysql/mysql-server` package natively with the `arm64` architecture.

## Conclusion

My rough initial benchmark, and the fact that I have been able to install all the software that I need so far including native versions of key applications, confirms that the M1 should rock for my software development use cases.

I now own a much cheaper, quieter, cooler, and less power-hungry computer, which happens to be also significantly faster than my iMac Pro. All it needs is a little more RAM (although I have not yet had an issue with the 16 GB capacity) and a larger monitor to truly surpass it.

I am looking forward to seeing how it behaves over the next few months, and I can't wait for the "Pro" versions of the CPU to come out soon in new higher-end iMacs and laptops. Then my iMac Pro will be ready to move on - although there is no real hurry as it still performs very well, if about 20% slower (and significantly hotter) during compilations.

---

[^xeon]: In addition Xeon processors, even when fresh out of the fab, are always slower in single-thread performance compared to their non-Xeon Intel counterparts. This was the case with the Xeon W in the iMac Pro.

[^parallelism]: The Scala build does have some level of parallelism due to using multiple modules (subprojects) and tasks (compilation, packaging, assets processing, and [Scala.js](https://www.scala-js.org/) compilation and optimization).

[^SDKMAN]: SDKMAN! looked like a joke at first, but it appears to be widely used and even recommended as a way to install not only Java but `sbt` by the `sbt` project itself.
