// A missing cell (`none` or `""`) on a discrete scale keys as the reserved NA
// level. The lookups answer its index when the domain holds `NA-KEY`, and
// `none` when it does not, instead of failing inside `str(none)`.

#import "../../src/scale/train.typ": level-position, map-discrete
#import "../../src/utils/level-resolve.typ": discrete-index
#import "../../src/utils/types.typ": NA-KEY, is-missing

#assert(is-missing(none))
#assert(is-missing(""))
#assert(not is-missing("f"))
#assert(not is-missing(0))
#assert.eq(NA-KEY, "\u{0}")

#let plain = (type: "discrete", domain: ("f", "m"))
#let with-na = (type: "discrete", domain: ("f", "m", NA-KEY))

#assert.eq(discrete-index(plain, none), none)
#assert.eq(discrete-index(plain, ""), none)
#assert.eq(discrete-index(with-na, none), 2)
#assert.eq(discrete-index(with-na, ""), 2)
#assert.eq(discrete-index(with-na, "m"), 1)

#assert.eq(map-discrete(none, plain.domain, (0, 3)), none)
#assert.eq(map-discrete("", plain.domain, (0, 3)), none)
#assert.eq(map-discrete(none, with-na.domain, (0, 3)), 2.5)
#assert.eq(map-discrete("f", with-na.domain, (0, 3)), 0.5)

#assert.eq(level-position(plain, none), none)
#assert.eq(level-position(with-na, none), 3)
#assert.eq(level-position(with-na, ""), 3)
#assert.eq(level-position(with-na, "f"), 1)
