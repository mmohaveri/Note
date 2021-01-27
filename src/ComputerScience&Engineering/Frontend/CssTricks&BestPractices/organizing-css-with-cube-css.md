# Organize CSS with cube-css

Notes from [Cube CSS by Andy Bell](https://www.youtube.com/watch?v=IKFq2cSbQ4Q)

The issue with solutions like [Tailwind CSS](https://tailwindcss.com) is that they make your final size so huge because
they're injecting their whole code in the final result.

The cube css methodology is to extent plain old css rather than reinventing.

cube css embraces the power of css, rather than fighting against it as you can see in other css methodologies.
CSS stands for Cascading Style Sheet but many css methodologies, like BEM, try to ignore or prevent the cascading effects
of it.

The core of the Cube CSS is that most of the work is done with global and high level styles. This means before start thinking
about components or blocks your typography, colors, ... are already. The rest of the methodology goes around giving
contextual styles that deviate from the global style. cube css is an progressive advancement style.

## Composition

In design systems you don't just think about things at a micro level, but also at macro level. You have to make high level
organization decisions along with pixel level decisions.

The lego blocks analogy is not a useful one in design systems. It's great at describing component models but they forget
to emphasize the fact that these components are applied in a larger design system to achieve a greater goal.

Composition should:

- Provide high level flexible layouts
- Determine how elements interact with each other
- Create consistent flow and rhythm

It should not:

- Provide visual treatment (color, font, etc.)
- Provide decorative style (shadows, patterns, etc.)
- Force a browser to generate a pixel-perfect layout

the composition is a whole page view.

It's based on [Every Layout](https://every-layout.dev), in short for layout:

- Find the most robust solution by simplifying and distilling the problem.
- Hint the browser, don't micro manage it, browser knows the best

This way you'll have solid resilient layouts capable of progressive enhancement.

In Cube CSS the composition is the skeleton of the layout, you don't apply the layout directly on the components.
Instead we create slots for our components to sit in, regardless of their content.

Compositions mentality also applies to component content too, for example if you have a component that has a header,
a section immediately after, but every other section has a gap, you can do:

```css
.flow + * + {
  margin-top: var(--flow-space, 1em);
}
```

```html
<article class="card">
  <img class="card__image" />
  <div class="[ card__content ] [ flow ]">
    <!-- content -->
  </div>
</article>
```

This way you can specify the gap size for each component, and at the same time provide a fallback value.

## Utility

A utility a rule that one job and one job well. It normally contains a single css rule, but in some cases it can apply
multiple highly correlated rules at the same time, e.g: setting margins

### Design Tokens

> Design Tokens are the visual atoms of the design system. They're named entities that store visual design attributes.
> We use them in place of hard-coded values in order to maintain a scalable and consistent visual system.

Using design tokens let us create a scalable system. In cube css we can take these design token values and apply them
in our code using utility classes, for example:

```json
{
  "colours": {
    "primary": "#ff00ff",
    "secondary": "#ffbf81",
    "base": "#252525"
  }
}
```

```css
.bg-primary: {
  background: #ff00ff;
}

.color-primary: {
  color: #ff00ff;
}

.bg-secondary: {
  background: #ffbf81;
}

.color-secondary {
  color: #ffbf81;
}
```

```html
<article class="bg-primary color-base"></article>
```

Applying design tokens like this allows us to define them once and apply them everywhere. It reduces repetition and
reduces overall bundle size.

### Utility classes should:

- Apply a single CSS property, or a concise group of related properties
- Extend design tokens to maintain a single source of truth
- Abstract repeatability away from the CSS and apply it in the HTML instead

### Utility classes SHOULD NOT:

- Define a large group of unrelated CSS properties (use block in these cases)
- Be used as a specificity hack

## Block

Block is the building block, or component. It can be a card, a button, etc. The definition of block in cube css is
almost identical to blocks in BEM. But cube css blocks are much smaller because most of the work is already done in
upper layers (CSS, Composition, and Utilities).

In cube css content of the block is not restricted, because most of the job is already done in upper layers. You can use
`BEM` style:

```css
.my-block__my-element {
  /* CSS */
}
```

or you can not use it:

```css
.my-block .title {
  /* CSS */
}

.my-block h2 {
  /* CSS */
}
```

A block in cube css is more like a namespace to create some specificity where you need. So you should not get involved
in specificity issues like you would if you nest in BEM.

### Block should:

- Extend the work already done by other layers of the cube css.
- Apply a collection of design tokens within a concise group
  - You can use SASS mixins to apply utility classes into blocks if you needed
- Create a namespace or specificity boost to control a specific context

### Blcoks should not:

- Grow to anything larger than a handful of CSS rules (80-100 lines)
- Solve more than one contextual problem
  - Don't style a card and a button in one block, create two blocks instead

## Exceptions

Little variations mainly to the block, but also can be applied to other things.
For exceptions we use `data-attribute` instead of class modifiers. The reason is that it's easily translated between
javascript, css, and html. It also restrict you to have a single value.

## Grouping

You can group your css classes using brackets:

```html
<article
  class="[ card ] [ section box ] [ bg-base color-primary ]"
  data-state="reversed"
></article>
```

This way you can easily find each element's different selectors.
