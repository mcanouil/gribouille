// guide-custom() builds a free-form guide spec consumed by the legend dispatch.

#import "../../src/guide/custom.typ": guide-custom
#import "../../src/guide/legend.typ": guide-legend
#import "../../src/guides.typ": guides
#import "../../src/render/legend.typ": guides-for
#import "../../src/theme/minimal.typ": theme-minimal

#let g = guide-custom([Hello])
#assert.eq(g.kind, "guide")
#assert.eq(g.name, "custom")
#assert.eq(g.width, auto)
#assert.eq(g.height, auto)
#assert.eq(g.title, none)
// The side is left unresolved so the guide can inherit one, exactly as
// `guide-legend` does. It settles to `"right"` when nothing sets a side.
#assert.eq(g.placement.side, auto)
#assert.eq(g.placement.direction, auto)
#assert.eq(g.placement.order, none)
#assert.eq(g.placement.byrow, false)

#let sized = guide-custom(
  [Notes here],
  width: 4cm,
  height: 2cm,
  title: "Notes",
)
#assert.eq(sized.width, 4cm)
#assert.eq(sized.height, 2cm)
#assert.eq(sized.title, "Notes")

#let positioned = guide-custom(
  [Block],
  position: "bottom",
  order: 1,
)
#assert.eq(positioned.placement.side, "bottom")
#assert.eq(positioned.placement.direction, "horizontal")
#assert.eq(positioned.placement.order, 1)

#let hidden = guide-custom([], position: "none")
#assert.eq(hidden.placement.side, "none")

#let bound = guides(custom: guide-custom([x], width: 3cm))
#assert.eq(bound.custom.kind, "guide")
#assert.eq(bound.custom.name, "custom")
#assert.eq(bound.custom.width, 3cm)

// Placement inheritance, which is what makes a custom block work on any side.
// A custom guide resolves through the same layering as every other guide, so a
// `guides(default: ...)` side and a `theme(legend-position:)` side both reach
// it, and its own `position` still wins over both.
#let _side-of(spec, theme: none) = {
  let found = guides-for(spec, (:), theme: theme)
  found.first().placement
}
#let _spec(..bindings) = (
  mapping: (:),
  layers: (),
  guides: guides(..bindings),
)

// Nothing set: the natural default still puts it on the right.
#assert.eq(_side-of(_spec(note: guide-custom([x]))).side, "right")

// A `default:` side reaches it, and the direction follows the side.
#let inherited = _side-of(_spec(
  default: guide-legend(position: "bottom"),
  note: guide-custom([x]),
))
#assert.eq(inherited.side, "bottom")
#assert.eq(inherited.direction, "horizontal")

// A theme side reaches it too.
#assert.eq(
  _side-of(
    _spec(note: guide-custom([x])),
    theme: theme-minimal(
      legend-position: "left",
    ),
  ).side,
  "left",
)

// Its own side beats both.
#assert.eq(
  _side-of(
    _spec(default: guide-legend(position: "bottom"), note: guide-custom(
      [x],
      position: "top",
    )),
    theme: theme-minimal(legend-position: "left"),
  ).side,
  "top",
)

// Suppression still drops it entirely.
#assert.eq(
  guides-for(_spec(note: guide-custom([x], position: "none")), (:)).len(),
  0,
)

// Inheriting a side means inheriting suppression too: a theme that hides its
// legends now hides a custom block with them, where the block used to stay
// visible because it never read the theme at all.
#assert.eq(
  guides-for(
    _spec(note: guide-custom([x])),
    (:),
    theme: theme-minimal(legend-position: "none"),
  ).len(),
  0,
)
#assert.eq(
  guides-for(
    _spec(default: guide-legend(position: "none"), note: guide-custom([x])),
    (:),
  ).len(),
  0,
)

// The block is a stack of primitives now, so the room it reserves is what the
// stack measured. `_guide-width` still carries its own formula for the width,
// so the two are pinned against each other here: the stack's length is the
// wider of the title and the block, and its depth is the title band, the block,
// and the trailing slack.
#context {
  let found = guides-for(
    _spec(note: guide-custom([x], width: 3cm, height: 2cm, title: "Notes")),
    (:),
  )
  let custom = found.first()
  assert.eq(custom.custom.layout.along, calc.max(custom.width, 3.0))
  assert.eq(
    calc.round(custom.height, digits: 9),
    calc.round(custom.title-h + 2.0 + 0.2, digits: 9),
  )
  assert.eq(custom.height, custom.custom.layout.across)

  // A block with no title loses the title band but keeps the slack.
  let bare = guides-for(
    _spec(note: guide-custom([x], width: 3cm, height: 2cm)),
    (:),
  ).first()
  assert.eq(calc.round(bare.height, digits: 9), 2.2)
}

// An `order` set on a `default:` entry reaches the guides that inherit from it,
// rather than being dropped by the placement a bare `position` builds.
#assert.eq(
  _side-of(_spec(
    default: guide-legend(position: "bottom", order: 2),
    note: guide-custom([x]),
  )).order,
  2,
)
// The guide's own order still wins.
#assert.eq(
  _side-of(_spec(
    default: guide-legend(position: "bottom", order: 2),
    note: guide-custom([x], order: 5),
  )).order,
  5,
)

Guide-custom tests passed.
