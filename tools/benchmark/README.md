# Benchmark harness

Measures how compile cost and output size grow as charts go from light to heavy.
Each case in `cases/` is compiled across a range of element counts, render
variants, and output formats, recording compile time, output size, and
(optionally) peak memory.

This is a local, manually run tool.
It is not wired into CI, and its results under `build/benchmark/` are git-ignored.

## Usage

```bash
lua tools/benchmark/run.lua [options]
```

| Option              | Default                       | Description                                              |
| ------------------- | ----------------------------- | -------------------------------------------------------- |
| `--cases <list>`    | every `cases/*.typ`           | Comma-separated case names.                              |
| `--variants <list>` | each case's own set           | Comma-separated render variants applied to every case.   |
| `--sizes <list>`    | `10,100,1000,5000,10000`      | Comma-separated element counts.                          |
| `--formats <list>`  | `png,svg,pdf`                 | Comma-separated subset of `png`, `svg`, `pdf`.           |
| `--reps <n>`        | `3`                           | Timed compiles per cell; the median is reported.         |
| `--timeout <secs>`  | `120`                         | Per-compile budget; over it the cell is a timeout (`0` disables). |
| `--warmup`          | off                           | One untimed compile per cell first (cold-cache discard). |
| `--ppi <n>`         | `144`                         | PNG raster density (matches the snapshot harness).       |
| `--mem`             | off                           | Also capture peak resident memory (best-effort).         |
| `--root <dir>`      | repo root                     | Repository root passed to `typst compile`.               |
| `--out <path>`      | `build/benchmark/results.csv` | CSV output path.                                         |

The sweep runs serially so parallel compiles never contend for CPU and skew the
timings.
Compiled artefacts are kept under `build/benchmark/<format>/` for inspection.

Examples:

```bash
# Quick comparison of one case across formats.
lua tools/benchmark/run.lua --cases point --sizes 100,1000 --formats png,svg,pdf

# Compare render settings of geom-point at a fixed count.
lua tools/benchmark/run.lua --cases point --variants base,large,star,alpha --sizes 1000

# Full default sweep with memory capture.
lua tools/benchmark/run.lua --mem
```

## Cases

| Case           | Geom                         | Scaling                                              |
| -------------- | ---------------------------- | ---------------------------------------------------- |
| `point`        | `geom-point`                 | Linear: one marker per row.                          |
| `line`         | `geom-line`                  | Linear: one vertex per row, single path.             |
| `col`          | `geom-col`                   | Linear: one bar per row.                             |
| `tile`         | `geom-tile`                  | Linear: one rectangle per row.                       |
| `polygon`      | `geom-polygon`               | Flat in marks: many vertices on twelve rings.        |
| `bin2d`        | `geom-bin-2d`                | Sublinear: rows aggregated into a fixed grid.        |
| `boxplot`      | `geom-boxplot`               | Sublinear: rows reduced to a per-group summary.      |
| `facet-smooth` | `facet-wrap` + `geom-smooth` | Per-panel stat re-training on a per-row point layer. |

Each case reads its element count from `sys.inputs` (`--input n=<count>`) and
generates deterministic synthetic data, so a given size renders the same chart
every run.

## Variants

A variant fixes the element count and changes render settings, isolating the
cost of those settings.
Cases read the active variant from `sys.inputs` (`--input variant=<name>`).
Without `--variants`, each case sweeps only the variants it implements; cases
that ignore the setting run `base` alone, so the matrix never compiles
duplicate outputs.
Passing `--variants` overrides this and applies the listed variants to every
selected case.

`point` implements these variants:

| Variant | Settings                  | Probes                              |
| ------- | ------------------------- | ----------------------------------- |
| `base`  | small filled circle       | Reference.                          |
| `large` | larger filled circle      | More raster and vector coverage.    |
| `star`  | star glyph                | Heavier per-marker path.            |
| `alpha` | translucent small circle  | Blending pressure.                  |

## Output

The CSV schema is:

```text
case,variant,n,format,status,time_s,bytes,rss_kb,reps
point,base,1000,png,ok,2.2900,34396,,3
point,base,100000,png,timeout,90.0000,,,3
point,star,1000,svg,ok,4.3500,782938,,3
```

`status` is `ok`, `timeout`, or `error`.
`time_s` is the median wall time in seconds (the budget for a timeout), `bytes`
is the output file size, and `rss_kb` is peak resident memory in KB (blank
unless `--mem` is set; blank for any non-`ok` row).
A summary table is also printed to stdout, grouped by case and variant, with a
`within budget` line naming the largest size that compiled under the timeout.
Timeouts are recorded data, not failures, so the run exits non-zero only on a
genuine compile `error`.

## Documentation dataset

The performance page at `docs/guides/benchmarks.qmd` reads a committed dataset
that the figures `docs/guides/_benchmarks-time.typ` and `_benchmarks-size.typ`
plot with Gribouille itself.
Refresh it by writing the harness output to that path:

```bash
lua tools/benchmark/run.lua \
  --variants base \
  --sizes 100,1000,10000,100000 \
  --formats png,svg,pdf --reps 1 --timeout 90 \
  --out docs/benchmarks/results.csv
```

The timings are machine-specific, so the page presents them as illustrative.

The harness writes CRLF line endings on some platforms.
The committed dataset uses LF, so convert the file after a refresh if your run adds carriage returns.
