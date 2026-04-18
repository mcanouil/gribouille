// labs() builds a labs record and injects axis titles into trained scale specs.

#import "../../src/labs.typ": labs, xlab, ylab, ggtitle

#let l = labs(title: "T", subtitle: "S", caption: "C", x: "X-axis", y: "Y-axis", colour: "Colour")
#assert.eq(l.kind, "labs")
#assert.eq(l.title, "T")
#assert.eq(l.subtitle, "S")
#assert.eq(l.caption, "C")
#assert.eq(l.axes.x, "X-axis")
#assert.eq(l.axes.y, "Y-axis")
#assert.eq(l.axes.colour, "Colour")

#let lx = xlab("X")
#assert.eq(lx.axes.x, "X")

#let ly = ylab("Y")
#assert.eq(ly.axes.y, "Y")

#let lt = ggtitle("Main")
#assert.eq(lt.title, "Main")

Labs tests passed.
