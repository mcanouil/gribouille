// Unit tests for the error-message builders in src/utils/errors.typ.
// Builders are pure (return strings) so the grammar can be asserted directly;
// the fail-*/check wrappers panic and cannot be tested in Typst.

#import "../../src/utils/errors.typ": (
  cm-text, enum-text, error-text, range-text, type-text, unknown-column-text,
)

// --- error-text: base grammar, period, optional hint ----------------------
#assert.eq(
  error-text("plot", "width must be positive"),
  "plot: width must be positive.",
)
#assert.eq(
  error-text("plot", "width must be positive", hint: "Increase width."),
  "plot: width must be positive. Increase width.",
)

// --- enum-text: quoted, comma-joined valid list ---------------------------
#assert.eq(
  enum-text("compose", "layout", "bad", ("grid", "stack")),
  "compose: layout must be one of \"grid\", \"stack\"; got \"bad\".",
)
#assert.eq(
  enum-text("geom-step", "direction", "xy", ("hv", "vh"), hint: "Pick one."),
  "geom-step: direction must be one of \"hv\", \"vh\"; got \"xy\". Pick one.",
)

// --- type-text: expected noun phrase + repr(value) ------------------------
#assert.eq(
  type-text("utils", "bins", 0, "a positive integer"),
  "utils: bins must be a positive integer; got 0.",
)

// --- range-text: bracket selection per open/closed ------------------------
// Closed interval [0, 1].
#assert.eq(
  range-text("quantile", "q", 2, 0, 1, lo-open: false, hi-open: false),
  "quantile: q must be in [0, 1]; got 2.",
)
// Default open interval (0, 1).
#assert.eq(
  range-text("mean-cl-normal", "conf", 1.5, 0, 1),
  "mean-cl-normal: conf must be in (0, 1); got 1.5.",
)
// Mixed bracket [0, 1) with hint.
#assert.eq(
  range-text("stat", "p", -1, 0, 1, lo-open: false, hint: "Use a probability."),
  "stat: p must be in [0, 1); got -1. Use a probability.",
)

// --- unknown-column-text: aesthetic/facet-role label + available columns ---
#assert.eq(
  unknown-column-text("aes", "colour", "group", ("x", "y")),
  "aes: colour maps to unknown column \"group\"; available columns: \"x\", \"y\".",
)
#assert.eq(
  unknown-column-text("facet-wrap", "variable", "drv", ("displ", "hwy")),
  "facet-wrap: variable maps to unknown column \"drv\"; available columns: \"displ\", \"hwy\".",
)

// --- cm-text: the room a layout failure quotes ----------------------------
// Two digits is the sub-millimetre a reader can act on; a round number keeps
// its short form rather than growing trailing zeros.
#assert.eq(cm-text(1.7345), "1.73")
#assert.eq(cm-text(1.5), "1.5")
#assert.eq(cm-text(0.0), "0")

#"errors builders ok"
