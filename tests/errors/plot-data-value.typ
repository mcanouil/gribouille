// `plot` names itself when its data is neither rows nor columns.
//
// expect: plot: data must be an array of dicts or a dict of arrays; got 5

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(data: 5, layers: (geom-point(),))
