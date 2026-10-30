// A join with `by: ()` fails, since an empty key list matches nothing.
//
// expect: left-join: by must name at least one key column

#import "/lib.typ": left-join

#left-join(((k: 1, a: 1),), ((k: 1, b: 2),), by: ())
