#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end

local DIR = script_dir()
local ROOT = DIR .. "/../.."

package.path = ROOT .. "/tools/typstdoc/?.lua;" .. package.path

local util = require("util")

-- Collapse the `tools/benchmark/../..` suffix into a clean absolute root so
-- logged paths read naturally.
do
  local handle = io.popen(string.format("cd '%s' && pwd", ROOT))
  if handle then
    local resolved = handle:read("*l")
    handle:close()
    if resolved and resolved ~= "" then ROOT = resolved end
  end
end

local USAGE = [[
Usage: tools/benchmark/run.lua [options]

Sweeps each case in tools/benchmark/cases/ across a range of row counts and
output formats, compiling serially and recording compile time, output size, and
(optionally) peak resident memory.

Options:
  --cases    <list>  Comma-separated case names (default: every cases/*.typ).
  --variants <list>  Comma-separated render variants applied to every case
                     (default: each case's own variant set, see CASE_VARIANTS).
  --sizes    <list>  Comma-separated row counts (default: 10,100,1000,5000,10000).
  --formats  <list>  Comma-separated of png,svg,pdf (default: png,svg,pdf).
  --reps    <n>      Timed compiles per cell; median reported (default: 3).
  --timeout <secs>   Per-compile budget; over it the cell is recorded as a
                     timeout rather than hung (default: 120, 0 disables).
  --warmup           Run one untimed compile per cell first (cold-cache discard).
  --ppi     <n>      PNG raster density (default: 144).
  --mem              Also capture peak resident memory (best-effort).
  --root    <dir>    Repository root (default: two levels above this script).
  --out     <path>   CSV output path (default: build/benchmark/results.csv).
  --help             Show this help and exit.
]]

-- Render variants each case is swept across when `--variants` is not given.
-- A case interprets the `variant` input itself (`sys.inputs.variant`); cases
-- absent here run only `base`. Listing variants per case keeps the matrix from
-- compiling identical outputs for cases that ignore the setting.
local CASE_VARIANTS = {
  point = { "base", "large", "star", "alpha" },
}
local DEFAULT_VARIANTS = { "base" }

-- Single-quote a string for safe interpolation into a shell command.
local function shell_quote(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- Resolve a path against `root` unless it is already absolute.
local function abs(path)
  if path:sub(1, 1) == "/" then return path end
  return ROOT .. "/" .. path
end

-- Byte count of a file, or nil when it cannot be opened.
local function file_size(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local size = f:seek("end")
  f:close()
  return size
end

local function split_list(value)
  local out = {}
  for item in value:gmatch("[^,]+") do
    local trimmed = item:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" then out[#out + 1] = trimmed end
  end
  return out
end

local function parse_args(argv)
  local opts = {
    cases = nil,
    variants = nil,
    sizes = { 10, 100, 1000, 5000, 10000 },
    formats = { "png", "svg", "pdf" },
    reps = 3,
    timeout = 120,
    warmup = false,
    ppi = 144,
    mem = false,
    root = ROOT,
    out = "build/benchmark/results.csv",
  }
  local i = 1
  local function take_value(flag)
    i = i + 1
    if i > #argv then
      io.stderr:write("benchmark: " .. flag .. " requires a value\n")
      os.exit(2)
    end
    return argv[i]
  end
  while i <= #argv do
    local a = argv[i]
    if a == "--cases" then opts.cases = split_list(take_value(a))
    elseif a == "--variants" then opts.variants = split_list(take_value(a))
    elseif a == "--sizes" then
      opts.sizes = {}
      for _, s in ipairs(split_list(take_value(a))) do opts.sizes[#opts.sizes + 1] = tonumber(s) end
    elseif a == "--formats" then opts.formats = split_list(take_value(a))
    elseif a == "--reps" then opts.reps = math.max(1, tonumber(take_value(a)) or opts.reps)
    elseif a == "--timeout" then opts.timeout = math.max(0, tonumber(take_value(a)) or opts.timeout)
    elseif a == "--warmup" then opts.warmup = true
    elseif a == "--ppi" then opts.ppi = tonumber(take_value(a)) or opts.ppi
    elseif a == "--mem" then opts.mem = true
    elseif a == "--root" then opts.root = take_value(a)
    elseif a == "--out" then opts.out = take_value(a)
    elseif a == "--help" or a == "-h" then io.write(USAGE); os.exit(0)
    else io.stderr:write("benchmark: unknown arg: " .. a .. "\n"); io.write(USAGE); os.exit(2)
    end
    i = i + 1
  end
  for _, f in ipairs(opts.formats) do
    if f ~= "png" and f ~= "svg" and f ~= "pdf" then
      io.stderr:write("benchmark: unsupported format: " .. f .. "\n")
      os.exit(2)
    end
  end
  return opts
end

-- List case names (without extension) discovered under cases/.
local function discover_cases(cases_dir)
  local names = {}
  local handle = io.popen(string.format("ls %s/*.typ 2>/dev/null", shell_quote(cases_dir)))
  if not handle then return names end
  for line in handle:lines() do
    local name = line:match("([^/]+)%.typ$")
    if name then names[#names + 1] = name end
  end
  handle:close()
  table.sort(names)
  return names
end

-- "Darwin" => BSD `time -l` reports bytes; otherwise assume GNU `time -v` in KB.
local function detect_os()
  local code, out = util.popen_capture("uname")
  if code == 0 and out:match("Darwin") then return "darwin" end
  return "linux"
end

local function median(values)
  if #values == 0 then return nil end
  local sorted = {}
  for _, v in ipairs(values) do sorted[#sorted + 1] = v end
  table.sort(sorted)
  local mid = math.floor((#sorted + 1) / 2)
  if #sorted % 2 == 1 then return sorted[mid] end
  return (sorted[mid] + sorted[mid + 1]) / 2
end

-- Build the `typst compile` command for one cell. PNG carries `--ppi`; the
-- vector formats ignore it.
local function compile_cmd(case_typ, fmt, n, variant, out_path, opts)
  local ppi = fmt == "png" and string.format(" --ppi %d", opts.ppi) or ""
  return string.format(
    "typst compile %s --root %s --input n=%d --input variant=%s --ignore-system-fonts%s %s",
    shell_quote(case_typ), shell_quote(opts.root), n, shell_quote(variant), ppi, shell_quote(out_path)
  )
end

-- Wrap a command so it is killed after `secs` (0 disables). perl ships on both
-- macOS and Linux. It forks the compiler and, on the alarm, kills the child and
-- exits 142 itself, so the parent shell never prints an "Alarm clock" notice and
-- a timeout is distinguishable by exit code.
local TIMEOUT_PERL =
  [[perl -e 'my $s=shift; my $p=fork; unless($p){exec @ARGV; exit 127} ]]
  .. [[$SIG{ALRM}=sub{kill "KILL",$p; exit 142}; alarm $s; waitpid($p,0); exit($?>>8)']]
local function with_timeout(cmd, secs)
  if secs <= 0 then return cmd end
  return string.format("%s %d %s", TIMEOUT_PERL, secs, cmd)
end

-- Last `real <seconds>` value `/usr/bin/time -p` prints (BSD and GNU alike).
local function parse_real(out)
  local last
  for value in out:gmatch("real%s+([%d%.]+)") do last = value end
  return last and tonumber(last) or nil
end

-- Compile under the time and timeout wrappers, repeating up to `reps` times.
-- Returns `status, time, log` where status is "ok", "timeout", or "error". A
-- non-ok first attempt short-circuits the remaining reps; on timeout the budget
-- is reported as the time.
local function time_compile(cmd, reps, timeout)
  local wrapped = string.format("/usr/bin/time -p %s 2>&1", with_timeout(cmd, timeout))
  local samples = {}
  for _ = 1, reps do
    local code, out = util.popen_capture(wrapped)
    if code ~= 0 then
      local real = parse_real(out)
      if code == 142 or (timeout > 0 and real and real >= timeout * 0.9) then
        return "timeout", timeout, out
      end
      return "error", real, out
    end
    local real = parse_real(out)
    if not real then return "error", nil, out end
    samples[#samples + 1] = real
  end
  return "ok", median(samples), nil
end

-- Peak resident memory in KB via the platform `time` variant, under the same
-- timeout budget. Best-effort: any miss returns nil rather than failing.
local function measure_rss(cmd, os_kind, timeout)
  local guarded = with_timeout(cmd, timeout)
  if os_kind == "darwin" then
    local _, out = util.popen_capture(string.format("/usr/bin/time -l %s 2>&1", guarded))
    local bytes = out:match("(%d+)%s+maximum resident set size")
    if bytes then return math.floor(tonumber(bytes) / 1024 + 0.5) end
  else
    local _, out = util.popen_capture(string.format("/usr/bin/time -v %s 2>&1", guarded))
    local kb = out:match("[Mm]aximum resident set size %(kbytes%):%s*(%d+)")
    if kb then return tonumber(kb) end
  end
  return nil
end

local function fmt_kb(bytes)
  if not bytes then return "-" end
  return string.format("%d", math.floor(bytes / 1024 + 0.5))
end

local function print_summary(rows, opts)
  -- One block per case/variant, keyed by "n/format" within the block.
  local groups = {}
  local order = {}
  for _, r in ipairs(rows) do
    local label = r.case .. " / " .. r.variant
    if not groups[label] then groups[label] = {}; order[#order + 1] = label end
    groups[label][r.n .. "/" .. r.format] = r
  end

  io.write("\nbenchmark summary (time = seconds, size = KB)\n")
  for _, label in ipairs(order) do
    io.write("\n" .. label .. "\n")
    local header = string.format("  %-8s", "n")
    for _, f in ipairs(opts.formats) do
      header = header .. string.format("  %7s %7s", f .. "_t", f .. "_kb")
    end
    io.write(header .. "\n")
    for _, n in ipairs(opts.sizes) do
      local line = string.format("  %-8d", n)
      for _, f in ipairs(opts.formats) do
        local r = groups[label][n .. "/" .. f]
        if r and r.status == "ok" then
          line = line .. string.format("  %7.2f %7s", r.time, fmt_kb(r.bytes))
        elseif r and r.status == "timeout" then
          line = line .. string.format("  %7s %7s", "TMO", "-")
        else
          line = line .. string.format("  %7s %7s", "ERR", "-")
        end
      end
      io.write(line .. "\n")
    end
    -- Suitability ceiling: largest n that stayed within budget per format.
    local ceiling = "  within budget:"
    for _, f in ipairs(opts.formats) do
      local best
      for _, n in ipairs(opts.sizes) do
        local r = groups[label][n .. "/" .. f]
        if r and r.status == "ok" then best = n end
      end
      ceiling = ceiling .. string.format("  %s<=%s", f, best and tostring(best) or "none")
    end
    io.write(ceiling .. "\n")
  end
end

-- Variants to sweep for a case: an explicit `--variants` applies to every case,
-- otherwise fall back to the case's own set (or just `base`).
local function variants_for(case, opts)
  if opts.variants then return opts.variants end
  return CASE_VARIANTS[case] or DEFAULT_VARIANTS
end

local function main()
  local opts = parse_args(arg or {})
  opts.root = abs(opts.root)
  local cases_dir = DIR .. "/cases"
  local out_csv = abs(opts.out)
  local build_root = opts.root .. "/build/benchmark"

  local case_names = opts.cases or discover_cases(cases_dir)
  if #case_names == 0 then
    io.stderr:write("benchmark: no cases found in " .. cases_dir .. "\n")
    os.exit(1)
  end

  util.remove_dir(build_root)
  for _, f in ipairs(opts.formats) do util.make_dir(build_root .. "/" .. f) end

  local os_kind = opts.mem and detect_os() or nil
  local rows = {}
  local failures = {}
  local total = 0
  for _, case in ipairs(case_names) do
    total = total + #variants_for(case, opts) * #opts.sizes * #opts.formats
  end
  local done = 0

  for _, case in ipairs(case_names) do
    local case_typ = cases_dir .. "/" .. case .. ".typ"
    if not util.file_exists(case_typ) then
      io.stderr:write("benchmark: no such case: " .. case_typ .. "\n")
      os.exit(1)
    end
    for _, variant in ipairs(variants_for(case, opts)) do
      for _, n in ipairs(opts.sizes) do
        for _, fmt in ipairs(opts.formats) do
          done = done + 1
          local out_path = string.format("%s/%s/%s-%s-%d.%s", build_root, fmt, case, variant, n, fmt)
          local cmd = compile_cmd(case_typ, fmt, n, variant, out_path, opts)
          io.write(string.format("[%d/%d] %s/%s n=%d %s ... ", done, total, case, variant, n, fmt))
          io.flush()

          if opts.warmup then util.popen_capture(with_timeout(cmd, opts.timeout) .. " 2>&1") end

          local status, time, log = time_compile(cmd, opts.reps, opts.timeout)
          local row = { case = case, variant = variant, n = n, format = fmt, status = status, time = time }
          if status == "ok" then
            row.bytes = file_size(out_path)
            if opts.mem then row.rss = measure_rss(cmd, os_kind, opts.timeout) end
            io.write(string.format("%.2fs  %s KB\n", time, fmt_kb(row.bytes)))
          elseif status == "timeout" then
            io.write(string.format("TIMEOUT (>%ds)\n", opts.timeout))
          else
            failures[#failures + 1] = string.format("%s/%s n=%d %s", case, variant, n, fmt)
            io.write("ERROR\n" .. (log or "") .. "\n")
          end
          rows[#rows + 1] = row
        end
      end
    end
  end

  local csv = { "case,variant,n,format,status,time_s,bytes,rss_kb,reps" }
  for _, r in ipairs(rows) do
    csv[#csv + 1] = string.format(
      "%s,%s,%d,%s,%s,%s,%s,%s,%d",
      r.case, r.variant, r.n, r.format, r.status,
      r.time and string.format("%.4f", r.time) or "",
      r.bytes or "",
      r.rss or "",
      opts.reps
    )
  end
  util.write_file(out_csv, table.concat(csv, "\n") .. "\n")

  print_summary(rows, opts)
  io.write(string.format("\nwrote %s (%d rows)\n", out_csv, #rows))
  if #failures > 0 then
    io.write(string.format("compile failures: %d\n", #failures))
    for _, f in ipairs(failures) do io.write("  " .. f .. "\n") end
    os.exit(1)
  end
end

main()
