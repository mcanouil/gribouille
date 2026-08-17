// Seam sealing applies only where marks share an edge, so a geom that leaves
// whitespace on purpose keeps it.

#import "../../src/utils/stroke.typ": seal-seam, seam-seal-thickness
#import "../../src/position/apply.typ": layer-marks-abut
#import "../../src/geom/tile.typ": _axis-pitch

#let blue = rgb("#336699")

// --- seal-seam ---------------------------------------------------------------

// Abutting marks are sealed with their own fill.
#let sealed = seal-seam(none, blue)
#assert.eq(sealed.paint, blue)
#assert.eq(sealed.thickness, seam-seal-thickness)

// Marks that cannot touch keep their bare fill, so the shape paints at
// exactly the size it was given.
#assert.eq(seal-seam(none, blue, abutting: false), none)

// An explicit stroke is the caller's choice and survives either way.
#let pinned = (paint: red, thickness: 2pt)
#assert.eq(seal-seam(pinned, blue), pinned)
#assert.eq(seal-seam(pinned, blue, abutting: false), pinned)

// A translucent fill is still never sealed: the overlap would darken its rim.
#assert.eq(seal-seam(none, blue.transparentize(50%)), none)

// --- layer-marks-abut --------------------------------------------------------

#assert(layer-marks-abut((position: "stack")))
#assert(layer-marks-abut((position: "fill")))
#assert(not layer-marks-abut((position: "identity")))
#assert(not layer-marks-abut((position: "dodge")))
#assert(not layer-marks-abut((:)))
#assert(layer-marks-abut((position: (name: "stack", params: (:)))))

// --- tile pitch --------------------------------------------------------------

#let discrete = (type: "discrete", domain: ("a", "b", "c"))
#let continuous = (type: "continuous", domain: (0, 10))

// A discrete axis measures a tile as a fraction of its slot, so the pitch is
// one slot.
#assert.eq(_axis-pitch(discrete, ("a", "b", "c")), 1)

// A continuous axis measures a tile in data units, so the pitch is the
// smallest gap between distinct centres. Zero is not folded in: the grid
// starts where the data starts.
#assert.eq(_axis-pitch(continuous, (2, 4, 6)), 2.0)
#assert.eq(_axis-pitch(continuous, (2, 4, 5, 9)), 1.0)

// One distinct centre has no neighbour to abut, on either axis type.
#assert.eq(_axis-pitch(discrete, ("a", "a")), none)
#assert.eq(_axis-pitch(continuous, (3, 3)), none)
#assert.eq(_axis-pitch(continuous, ()), none)

// Blank centres are dropped before the count.
#assert.eq(_axis-pitch(continuous, (5, none)), none)

seam-sealing tests passed.
