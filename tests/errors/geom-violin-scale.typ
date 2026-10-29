// `geom-violin` reports a bad `scale` under its own name.
//
// `scale: "bogus"` used to fail as `stat-ydensity` at render time.
//
// expect: geom-violin: scale must be one of "area", "count", "width"; got "bogus"

#import "/lib.typ": geom-violin

#geom-violin(scale: "bogus")
