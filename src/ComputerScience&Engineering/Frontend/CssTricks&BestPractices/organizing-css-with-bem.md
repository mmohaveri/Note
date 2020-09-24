# Organizing CSS with BEM

Notes from [Organizing CSS with OOCSS, SMACSS, and BEM - Matt Stauffer](https://www.youtube.com/watch?v=IKFq2cSbQ4Q)

The goal is to organize our css codes in a better more manageable codes.

We want to apply OOP principals into our CSS codebase:

On of the OOP's most important principals is _decoupling_. It means writing our codes in a way that one piece is less
tied to other pieces.

For example, if I want to reuse functionality `x` in an other project and I am forced to include functionality `y`, and
`z` in the other project it means that my initial code is not decoupled enough.

But what _decoupled enough_ means? Here we can take a hint from other important OOP principals, namely _Single Responsibility
Principle_ and _Separation of Concerns_.

_Single Responsibility Principle_ means each part of your code is responsible for one thing and one thing only. If you
try to describe that part of code, you should be able to say "This part does this thing". As soon as you start to use
",", "and", "or", "also", "unless", and things like these in your description it means you've broken the _SRP_.

_Separation of Concerns_ means different concerns belong to different parts of the code. A good way to measure _SC_ is
to count _reason of change_. As uncle bob says, each part of your code should have one and only one reason for change.

Finally _encapsulation_ means that your code pieces should be encapsulated in a way that allows to change inner-mechanism
of your code, without changing its API or behavior.

What we want to do is to identify objects in our code. In a way that each object is small, neat, have very few ties to
other pieces of the code, and only does one thing and does that one thing well.

Let's apply these ideas to CSS:

## OOCSS (Object Oriented CSS)

As described [here](http://www.stubbornella.org/content/2010/06/25/the-media-object-saves-hundreds-of-lines-of-code/)
by Nicole Sullivan, OOCSS says identify patterns and `objects`, or `modules`, in your code.

![Nicole Sullivan's Media Object](http://www.stubbornella.org/content/wp-content/uploads/2010/06/Facebook-ImageBlock-216x1024.png)

As you can see, in this page there is a repeating pattern in this page: two columns, left column is an image, right
column contains content. Let's extract this pattern and call it `media object`, but how?

```css
.media {
  margin: 10px;
}
.media,
.bd {
  overflow: hidden;
  _overflow: visible;
  zoom: 1;
}
.media .img {
  float: left;
  margin-right: 10px;
}
.media .img img {
  display: block;
}
.media .imgExt {
  float: right;
  margin-left: 10px;
}
```

You can reuse this module as many times as you want. You can even add modifiers that change the behavior of your module;
For example imagine you want to have a RTL media object, just add a modifier that changes the `float` property of your
modules children.

## SMACSS (Scalable Modular Architecture for CSS)

SMACSS says each CSS code base consists of five primary grouping:

- **Base**: applies to HTML (no class/ID selectors)
  - h1, h2, p, etc.
- **Layout**: Big page sections, mile high view of your pages, headers, sidebars, footers, etc.
  - .headers, .sidebar, .footer, etc.
- **Modules**: encapsulated modules, re-usable
- **State**: overrides defaults, take an existing module and change part of it behavior
  - .is-open, .is-checked
- **Theme**: contains theme information, optional

## BEM (Block-Element-Modifier)

BEM is way to think about naming your classes:

- `.{Block}__{Element}`
- `.{Block}__{Element}--{Modifier}`
- `.{Block}--{Modifier}`

`block` is like your module name.
`element` is one of `block`'s children
`modifier` is the the thing that modifies behavior of the element

We ary trying to flatten our selectors, using `.media__img` instead of `.media .img`.
Grandchildren are a bad idea, you can put blocks inside blocks, but grandchilding them, using two sets of double
underscores is a really bad idea. You'll end up in a wired problems and performance issues.

If you absolutely have to do a prohibited thing, put it in a new file called shame :))

### Why having flat selectors matters?

CSS uses a set of rules to decide which css rules should overwrite other rules. It calls them `selector specificity` and
rules with higher specificity overwrite the lower ones.

If two set of rules have same specificity, the one that comes last wins the match :)

In short `specificity` means how specific your selector is? so `.media .img` is more specific than `.img`.

Having nested selectors will cause specificity issues. For example in the following code:

```css
.body h1 {
  color: red;
}

.alternate {
  color: green;
}
```

```html
<div class="body">
  <h1 class="alternate">Awesome</h1>
</div>
```

One might think the result will be a green text, but because `.body h1` is more specific than `.alternate` it will
overwrite it and the text becomes red!

A rule that you should keep in mind is any selector containing an ID will overwrite any selector not containing an ID.
So **DO NOT** use IDs in your CSS files.

This is why nested selectors are a bad idea, and you should avoid using them as much as possible.

### What about Utility classes?

Utility classes are classes that do only one job. The problem with utility classes is that they hard defined your style
in your presentation layer, it's almost as bad as defining your style inline style. If you want to change their style
you'll have to change all the places that they've occurred in your HTML code, which is a boring task with high risk of
error. Your tieing your visual representation to your HTML code, and that's defeating the purpose of the CSS.

There is two ways to go around this problem.

The first method is you can use sass `@extend` directive to reduce your dependency on the utility class:

```css
.primary-rail {
  @extend .pull-left, .col-md-6, .small;
}
```

This way if you decide to change your column width from 6 to 3 you only have to change one place.

You can also use sass `mixin` but, because mixins get replicated when they're used, in large projects it will increase
your code size a lot. But `extend` will do optimizations and tries to prevent duplicate codes.

The second method is you can build with utility classes, and then extract components from them as necessary.

## How to get started?

- Flatten your selectors
- Organize your code, preferably use the five primary grouping mentioned above.
  - Keep in mind that using sass and less you can split your codes into as many files as you want and as long as you
    group them together in one file it will not impose any performance problems!
- Make your classes do one thing and one thing well, separation of concerns, single responsibility principle, etc.
- Decouple for reusability
- use a pre-processor
