---
layout: post
title: Poor Blog APIs
date: '2005-03-28 14:03:53'
categories:
- Technology
redirect_from:
- "/blog/2005/3/28/poor_blog_apis"
- "/roller/page/ebruchez/poor_blog_apis"
---

When it came to choosing blog software for my personal web site, I first considered writing my own. After all, it can't be difficult, can it? And I have written my own software for my web site including the [photo albums](http://erik.bruchez.name/pictures/ebruchez/), all based on the [Orbeon PresentationServer (OPS)](http://www.orbeon.com/software/) platform. But I let laziness prevail and figured that existing software must be good enough, and I settled for Roller. I preferred a Java-based solution since my OPS-based software already runs on Java and Tomcat.

But finally a few days ago, I [launched a mini-project](http://www.orbeon.com/blog/index.php?p=13) to create a new "Blog" sample application for OPS. So this weekend, I spent a few hours getting started with this. My approach was that the best thing to do first would be to look at blog APIs, such as the Blogger API and the [MetaWeblog API](http://www.xmlrpc.com/metaWeblogApi). The MetaWeblog API extends upon the Blogger API, offering some added functionality, and refining some existing functionality (by replacing calls). A few things struck me:

- **Both those specifications are poorly written.** I have nothing against Dave Winer, mind you. But consider something like this: *"In getPost, the returned value is a struct, as with the Blogger API, but it contains extra elements corresponding to the struct passed to newPost and editPost."* This is it. This is how `getPost` is "specified". There is not even an example showing what the result looks like. No XML Schema or Relax NG schema normalizing what the structure must adhere to. The good news is that you can figure it out, after all, but the bad news is that there is room for misunderstanding. A little more formalism would help.
- **The APIs are extremely basic.** This would not be bad per se, on the contrary. But here simplicity almost equates indigence. There is no access to post comments, for example. There is a call to create a new "media object", but then nothing to list existing objects, retrieve them, or update them. There is no way to manage blogrolls.
- **The APIs are based on XML-RPC.** It would be so much easier to just send and receive structured documents! The calls would be so much shorter and so easier to understand. Well yes, XML-RPC is relatively appropriate for mapping to function or method calls. But that comes at the cost of creating XML documents that are overly complex. I for one much prefer document-based services. See my other [blog entry](http://www.orbeon.com/blog/index.php?p=13) for an example. I am not the only one to have realized that, obviously: see [Why We Need Echo](http://www.sixapart.com/about/news/2003/06/why_we_need_ech.html), [What's Wrong with the MetaWeblog API](http://www.kuro5hin.org/story/2003/6/29/22931/0682), and the [Atom Project](http://www.intertwingly.net/wiki/pie/FrontPage).
- **The APIs don't leverage HTTP.** Authentication is not built into XML-RPC. Simple HTTP authentication would work in theory, but there, the authors of the two APIs in question have resolved to embed username and password information into every request. Therefore, your application has to handle authentication itself, rather than, say, using the existing mechanisms set in place by your web or application server. This is extra burden for the implementor of the APIs.

As of today, I have been mainly been using [w.bloggar](http://www.wbloggar.com/) to edit and post blog entries. It supports the Blogger API and the MetaWeblog API. So for now, in spite of their limitations, I have stuck to implementing those APIs. In fact, in just a few hours, I have implemented a good part of them without great difficulty (thanks OPS - I know, this is so self-serving), but with no way of knowing that I am actually implementing them correctly, other than by observing w.bloggar's behavior.
