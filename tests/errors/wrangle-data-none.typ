// A wrangle verb fails by name when its data is `none`.
//
// The message names the verb that the user called, not an internal helper.
//
// expect: select: data must be an array of dicts or a dict of arrays; got none

#import "/lib.typ": select

#select(none, "a")
