#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end

local DIR = script_dir()
local ROOT = DIR .. "/../.."

package.path = DIR .. "/?.lua;" .. ROOT .. "/tools/typstdoc/?.lua;" .. package.path

local util = require("util")
local extract = require("extract")
local common = require("common")

local USAGE = [[
Usage: tools/snapshot/run.lua [--check | --update] [options]

Modes:
  --check         Compile and diff against tests/visual/golden/ (default).
  --update        Compile and overwrite goldens in tests/visual/golden/.
                  CI only: run the `Refresh visual snapshots` workflow.

Options:
  --root <dir>    Repository root (default: two levels above this script).
  --ppi <n>       Raster density (default: 144).
  --tolerance <n> Max AE pixel count per diff (default: 0).
  --fuzz <pct>    ImageMagick `-fuzz` value (default: 2%).
  --only <key>    Only run sources whose key contains this substring.
  --jobs <n>      Parallel typst compiles (default: $JOBS or processor count).
  --help          Show this help and exit.
]]

local shell_quote = common.shell_quote
local function abs(path) return common.abs(ROOT, path) end

local function processor_count()
  local code, out = util.popen_capture("getconf _NPROCESSORS_ONLN 2>/dev/null")
  if code == 0 then return tonumber(out:match("%d+")) end
  return nil
end

local function parse_args(argv)
  local opts = {
    update = false,
    root = ROOT,
    ppi = 144,
    tolerance = 0,
    -- 2% absorbs sub-pixel anti-aliasing that differs between CPU
    -- architectures (arm64 vs x86_64 floating-point rounding) while still
    -- failing on structural changes; `tolerance` stays 0 (no stray pixels).
    fuzz = "2%",
    only = nil,
    jobs = math.max(1, tonumber(os.getenv("JOBS")) or processor_count() or 1),
  }
  local i = 1
  local function take_value(flag)
    i = i + 1
    if i > #argv then
      io.stderr:write("snapshot: " .. flag .. " requires a value\n")
      os.exit(2)
    end
    return argv[i]
  end
  while i <= #argv do
    local a = argv[i]
    if a == "--check" then opts.update = false
    elseif a == "--update" then opts.update = true
    elseif a == "--root" then opts.root = take_value(a)
    elseif a == "--ppi" then opts.ppi = tonumber(take_value(a)) or opts.ppi
    elseif a == "--tolerance" then opts.tolerance = tonumber(take_value(a)) or opts.tolerance
    elseif a == "--fuzz" then opts.fuzz = take_value(a)
    elseif a == "--only" then opts.only = take_value(a)
    elseif a == "--jobs" then opts.jobs = math.max(1, tonumber(take_value(a)) or opts.jobs)
    elseif a == "--help" or a == "-h" then io.write(USAGE); os.exit(0)
    else io.stderr:write("snapshot: unknown arg: " .. a .. "\n"); io.write(USAGE); os.exit(2)
    end
    i = i + 1
  end
  return opts
end

-- Keep up to `jobs` typst processes in flight as a sliding window: reap the
-- oldest handle to free a slot before spawning the next source, instead of
-- draining a whole batch behind its slowest compile. Returns an array aligned
-- with `sources`, where each entry is `{ code, log, png }`.
local function compile_pool(sources, opts)
  local results = {}
  local pending = {}
  local function reap_oldest()
    local b = table.remove(pending, 1)
    local out = b.handle:read("*a")
    local _, _, code = b.handle:close()
    results[b.idx] = { code = code or 0, log = out, png = b.png }
  end
  for i, s in ipairs(sources) do
    if #pending >= opts.jobs then reap_oldest() end
    local png = string.format("%s/png/%s.png", opts.build_root, s.key)
    local cmd = string.format(
      "typst compile %s --root %s --ignore-system-fonts --ppi %d %s 2>&1",
      shell_quote(s.src_typ), shell_quote(opts.root), opts.ppi, shell_quote(png)
    )
    local handle = io.popen(cmd, "r")
    if not handle then
      error(string.format("snapshot: failed to spawn typst for %s (io.popen returned nil)", s.src_typ))
    end
    pending[#pending + 1] = { idx = i, handle = handle, png = png }
  end
  while #pending > 0 do reap_oldest() end
  return results
end

-- ImageMagick `compare -metric AE` writes "<ae>" or "<ae> (<normalised>)" on
-- stderr. Uses the v6/v7-compatible `compare` entry point rather than
-- `magick compare`. Exit codes: 0 == identical, 1 == differs but ran
-- cleanly, >=2 == error. Returns `code, ae, log`; on error `ae` is nil so
-- callers don't confuse a crashed compare with a clean 0-pixel match.
local function diff_images(golden, current, diff_png, fuzz)
  local cmd = string.format(
    "compare -metric AE -fuzz %s %s %s %s 2>&1",
    fuzz, shell_quote(golden), shell_quote(current), shell_quote(diff_png)
  )
  local code, out = util.popen_capture(cmd)
  local ae
  if code <= 1 then ae = tonumber(out:match("^%s*(%d+)")) end
  return code, ae, out
end

-- Goldens are minted by CI and nowhere else. A local `--update` bakes the
-- contributor's own toolchain into the repository: a Typst release older or
-- newer than the pinned `compiler` renders the same source differently, so the
-- goldens pass on the machine that wrote them and fail for everyone else.
-- `--check` stays available locally; only the write path is gated.
local function assert_ci_update()
  if os.getenv("GITHUB_ACTIONS") == "true" then return end
  io.stderr:write(
    "snapshot: --update writes goldens and only runs in CI.\n"
      .. "  Dispatch the `Refresh visual snapshots` workflow on your branch:\n"
      .. "    gh workflow run snapshot-refresh.yml --ref <branch> -f direct=true\n"
      .. "  Use --check locally to see which snapshots your change moves.\n"
  )
  os.exit(2)
end

-- The pinned compiler is what CI installs and what minted every golden, so a
-- local `--check` on a different release reports diffs that say nothing about
-- the change under test. Warn rather than fail: the mismatch matters for
-- reading the result, not for running it.
local function warn_compiler_mismatch(root)
  local pinned = util.read_file(root .. "/typst.toml")
  if not pinned then return end
  pinned = pinned:match('compiler%s*=%s*"([^"]+)"')
  if not pinned then return end
  local code, out = util.popen_capture("typst --version 2>/dev/null")
  if code ~= 0 then return end
  local local_version = out:match("typst%s+([%d%.]+)")
  if not local_version or local_version == pinned then return end
  io.stderr:write(string.format(
    "snapshot: warning: typst %s is installed, typst.toml pins %s.\n"
      .. "  Goldens were minted on %s; diffs below may be version artefacts.\n",
    local_version, pinned, pinned
  ))
end

local function main()
  local opts = parse_args(arg or {})
  opts.root = abs(opts.root)
  if opts.update then assert_ci_update() end
  warn_compiler_mismatch(opts.root)
  local build_root = opts.root .. "/build/snapshot"
  local golden_root = opts.root .. "/tests/visual/golden"

  util.remove_dir(build_root)
  for _, sub in ipairs({ "src", "png/examples", "png/docstrings", "diff/examples", "diff/docstrings" }) do
    util.make_dir(build_root .. "/" .. sub)
  end

  local sources = extract.collect({
    root = opts.root,
    build_root = build_root,
    golden_root = golden_root,
    only = opts.only,
  })

  if #sources == 0 then
    io.stderr:write("snapshot: no sources matched\n")
    os.exit(1)
  end

  if opts.update then
    util.make_dir(golden_root .. "/examples")
    util.make_dir(golden_root .. "/docstrings")
  end

  opts.build_root = build_root
  local compile_fail, diff_fail, missing, ok = {}, {}, {}, 0
  local compiled = compile_pool(sources, opts)

  for i, s in ipairs(sources) do
    local r = compiled[i]
    if r.code ~= 0 then
      compile_fail[#compile_fail + 1] = s.key
      io.write(string.format("COMPILE-FAIL %s\n%s\n", s.key, r.log))
    elseif opts.update then
      util.copy_file(r.png, s.golden)
      ok = ok + 1
      io.write(string.format("update       %s\n", s.key))
    elseif not util.file_exists(s.golden) then
      missing[#missing + 1] = s.key
      io.write(string.format("MISSING      %s (no golden at %s)\n", s.key, s.golden))
    else
      local diff_png = string.format("%s/diff/%s.png", build_root, s.key)
      local code, ae, log = diff_images(s.golden, r.png, diff_png, opts.fuzz)
      if ae == nil then
        diff_fail[#diff_fail + 1] = string.format("%s (compare exit=%d)", s.key, code)
        io.write(string.format("COMPARE-ERR  %s exit=%d\n%s\n", s.key, code, log))
      elseif ae > opts.tolerance then
        diff_fail[#diff_fail + 1] = string.format("%s (AE=%d)", s.key, ae)
        io.write(string.format("DIFF         %s  AE=%d\n", s.key, ae))
      else
        ok = ok + 1
        io.write(string.format("ok           %s\n", s.key))
      end
    end
  end

  local total = #sources
  io.write(string.format("\nsnapshots: %d/%d ok\n", ok, total))
  if #compile_fail > 0 then
    io.write(string.format("compile failures: %d\n", #compile_fail))
  end
  if #missing > 0 then
    io.write(string.format("missing goldens:  %d\n", #missing))
  end
  if #diff_fail > 0 then
    io.write(string.format("diff failures:    %d\n", #diff_fail))
    for _, line in ipairs(diff_fail) do io.write("  " .. line .. "\n") end
  end

  local check_fail = not opts.update and (#missing + #diff_fail) > 0
  if #compile_fail > 0 or check_fail then os.exit(1) end
end

main()
