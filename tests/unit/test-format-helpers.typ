// Unit tests for the format-* formatter helpers.

#import "../../src/utils/format.typ": (
  format-comma, format-currency, format-log, format-lower, format-number,
  format-percent, format-scientific, format-title, format-upper, format-wrap,
)
#import "../../src/utils/typst-markup.typ": is-typst-markup

// format-number: thousands separator, decimal handling.
#let n = format-number()
#assert.eq(n(1234.56), "1,234.56")
#assert.eq(n(1000000), "1,000,000")
#assert.eq(n(0), "0")
#assert.eq(n(-1234), "-1,234")
#assert.eq(n(none), none)

// Custom marks (e.g., French).
#let n-fr = format-number(big-mark: " ", decimal-mark: ",")
#assert.eq(n-fr(1234.5), "1 234,5")

// Fixed digits.
#let n-2 = format-number(digits: 2)
#assert.eq(n-2(1.0), "1.00")
#assert.eq(n-2(1.235), "1.24")

// format-comma is a thin shorthand.
#let c = format-comma()
#assert.eq(c(1234), "1,234")

// format-percent.
#let p = format-percent()
#assert.eq(p(0.25), "25%")
#assert.eq(p(1), "100%")
#let p-d = format-percent(digits: 1)
#assert.eq(p-d(0.123), "12.3%")

// format-currency.
#let cur = format-currency()
#assert.eq(cur(12.5), "$12.50")
#assert.eq(cur(1234), "$1,234.00")
#let euro = format-currency(symbol: "€", big-mark: ".", decimal-mark: ",")
#assert.eq(euro(1234.5), "€1.234,50")

// format-scientific returns a typst()-tagged value for out-of-range
// magnitudes; in-range values format as plain numbers.
#let sci = format-scientific()
#assert.eq(is-typst-markup(sci(1.23e-5)), true)
#assert.eq(is-typst-markup(sci(1234567.89)), true)
// In-range still wraps with typst() (consistent type) but the math is plain.
#assert.eq(is-typst-markup(sci(12.34)), true)
#assert.eq(sci(0).source, "$0$")

// format-log writes an exact power as a superscript, and keeps a mantissa for
// the 1/2/5 breaks an automatic log axis produces.
#let lg = format-log()
#assert.eq(lg(1000).source, "$10^(3)$")
#assert.eq(lg(1).source, "$10^(0)$")
// `str` of a negative integer uses the minus sign, not the hyphen, which is
// what the math mode wants anyway.
#assert.eq(lg(0.001).source, "$10^(" + str(-3) + ")$")
#assert.eq(lg(1000000).source, "$10^(6)$")
#assert.eq(lg(2).source, "$2$")
#assert.eq(lg(5).source, "$5$")
#assert.eq(lg(20).source, "$2 times 10^(1)$")
#assert.eq(lg(50).source, "$5 times 10^(1)$")
// A string break parses like every other formatter takes one.
#assert.eq(lg("1000").source, "$10^(3)$")
// A break at or below zero belongs to a linear axis; label it plainly.
#assert.eq(lg(0), "0")
#assert.eq(lg(-5), "-5")
#assert.eq(lg(none), none)

// Another base labels its own powers.
#let lg2 = format-log(base: 2)
#assert.eq(lg2(8).source, "$2^(3)$")
#assert.eq(lg2(1).source, "$2^(0)$")
#assert.eq(lg2(3).source, "$1.5 times 2^(1)$")

// Case helpers.
#let title = format-title()
#assert.eq(title("hello world"), "Hello World")
#assert.eq(title("aLpHa"), "Alpha")
#assert.eq(title(""), "")
#assert.eq(title(none), none)

#let upper = format-upper()
#assert.eq(upper("hello"), "HELLO")
#assert.eq(upper("MiXeD"), "MIXED")

#let lower = format-lower()
#assert.eq(lower("HELLO"), "hello")
#assert.eq(lower("MiXeD"), "mixed")

// format-wrap inserts newlines at word boundaries.
#let wrap = format-wrap(width: 10)
#assert.eq(wrap("short"), "short")
#assert.eq(wrap("hello world foo"), "hello\nworld foo")

format helper tests passed.
