// Unit tests for parse-temporal: ISO-8601 strings to numeric epoch.

#import "../../src/utils/types.typ": parse-temporal

// Numeric pass-through: 2024-01-01 sits 8766 days after 2000-01-01.
#assert.eq(parse-temporal(8766, "date"), 8766.0)
#assert.eq(parse-temporal(0, "date"), 0.0)
#assert.eq(parse-temporal(3.5, "datetime"), 3.5)

// Compute the expected day-count for 2024-01-15 via the helper itself,
// then assert it is an integer-valued float greater than 8766 (2024-01-01).
#let d-2024-01-15 = parse-temporal("2024-01-15", "date")
#assert(type(d-2024-01-15) == float)
#assert.eq(d-2024-01-15, calc.round(d-2024-01-15))
#assert.eq(d-2024-01-15, 8780.0)

// Datetime: 2024-01-15T08:30:00 = days * 86400 + 8.5 hours.
// 8.5 hours = 30600 seconds, so the result mod 86400 must equal 30600.
#let dt = parse-temporal("2024-01-15T08:30:00", "datetime")
#assert(type(dt) == float)
#assert.eq(calc.rem(dt, 86400), 30600.0)
#assert.eq(dt, 8780.0 * 86400 + 30600)

// Space separator is also accepted for datetimes.
#let dt-space = parse-temporal("2024-01-15 08:30:00", "datetime")
#assert.eq(dt-space, dt)

// Datetime without seconds.
#let dt-no-sec = parse-temporal("2024-01-15T08:30", "datetime")
#assert.eq(dt-no-sec, dt)

// Time: 12:00 = 43200 seconds since midnight.
#assert.eq(parse-temporal("12:00", "time"), 43200.0)
#assert.eq(parse-temporal("12:00:00", "time"), 43200.0)
#assert.eq(parse-temporal("00:00:00", "time"), 0.0)
#assert.eq(parse-temporal("23:59:59", "time"), 86399.0)

// Unparseable / empty / none values return none.
#assert.eq(parse-temporal("not-a-date", "date"), none)
#assert.eq(parse-temporal("", "date"), none)
#assert.eq(parse-temporal(none, "date"), none)
#assert.eq(parse-temporal("2024-01-15", "time"), none)
#assert.eq(parse-temporal("12:00", "date"), none)

// An impossible date or clock time is an unusable cell, not a Typst error.
#assert.eq(parse-temporal("2020-02-30", "date"), none)
#assert.eq(parse-temporal("2021-02-29", "date"), none)
#assert.eq(parse-temporal("1900-02-29", "date"), none)
#assert.eq(parse-temporal("2020-13-01", "date"), none)
#assert.eq(parse-temporal("2020-04-31", "date"), none)
#assert.eq(parse-temporal("2020-00-10", "date"), none)
#assert.eq(parse-temporal("2020-01-00", "date"), none)
#assert.eq(parse-temporal("2020-02-30T10:00", "datetime"), none)
#assert.eq(parse-temporal("2020-01-01T25:00", "datetime"), none)
#assert.eq(parse-temporal("2020-01-01T10:60", "datetime"), none)
#assert.eq(parse-temporal("2020-01-01T10:00:60", "datetime"), none)
#assert(parse-temporal("2020-02-29", "date") != none)
#assert(parse-temporal("2000-02-29", "date") != none)
#assert(parse-temporal("2020-12-31T23:59:59", "datetime") != none)

parse-temporal tests passed.
