// `count` names itself and its positional column in an unknown-column message.
//
// expect: count: column maps to unknown column "b"

#import "/lib.typ": count

#count(((a: 1),), "b")
