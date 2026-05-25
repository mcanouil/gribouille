// compose tag-symbol generation: latin, arabic, roman, and spreadsheet wrap.

#import "../../src/compose.typ": _alpha-symbol, _roman-symbol, _tag-symbol

// Arabic is 1-based.
#assert.eq(_tag-symbol("1", 0), "1")
#assert.eq(_tag-symbol("1", 9), "10")

// Latin upper / lower, with spreadsheet-style wrap past Z.
#assert.eq(_tag-symbol("A", 0), "A")
#assert.eq(_tag-symbol("A", 25), "Z")
#assert.eq(_tag-symbol("A", 26), "AA")
#assert.eq(_tag-symbol("A", 27), "AB")
#assert.eq(_tag-symbol("a", 0), "a")
#assert.eq(_tag-symbol("a", 26), "aa")
#assert.eq(_alpha-symbol(701, true), "ZZ")
#assert.eq(_alpha-symbol(702, true), "AAA")

// Roman is 1-based; lowercase mirrors uppercase.
#assert.eq(_roman-symbol(4), "IV")
#assert.eq(_roman-symbol(2024), "MMXXIV")
#assert.eq(_tag-symbol("I", 0), "I")
#assert.eq(_tag-symbol("I", 8), "IX")
#assert.eq(_tag-symbol("i", 3), "iv")

Compose tag-symbol tests passed.
