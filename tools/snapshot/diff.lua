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
local common = require("common")

local GOLDEN_REL = "tests/visual/golden"

local USAGE = [[
Usage: tools/snapshot/diff.lua [options]

Visualise how the committed golden snapshots changed between two git refs, then
serve a single-snapshot review tool: one diff at a time (no page scroll), a
Side/Onion/Diff/Flicker view switch, a keyboard stepper that walks only the
diffs, and a `validate` button that stages each golden with `git add`.

Builds composites, then runs a localhost-only server in the foreground until
Ctrl-C (opens a browser unless --no-open).

Options:
  --base <ref>    Base commit or branch (default: HEAD~1). For a branch like
                  `main`, the effective base is the merge-base with head, so the
                  report shows only the snapshots this branch/PR changed.
  --head <ref>    Head commit. Omitted compares the base against the on-disk
                  goldens (working tree), so uncommitted `--update` results show.
                  Validate is enabled only in this working-tree mode.
  --exact         Skip merge-base resolution; diff <base>..<head> literally.
  --only <substr> Restrict to golden keys containing this substring.
  --fuzz <pct>    ImageMagick `-fuzz` for the overlay (default: 2%).
  --out <dir>     Report directory (default: build/snapshot/diff-report).
  --port <n>      Server port (default: 0, OS picks a free port).
  --no-open       Build and serve without opening a browser.
  --help          Show this help and exit.
]]

local shell_quote = common.shell_quote
local function abs(path) return common.abs(ROOT, path) end

local function die(msg)
  io.stderr:write("snapshot-diff: " .. msg .. "\n")
  os.exit(1)
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_args(argv)
  local opts = {
    base = "HEAD~1",
    head = nil,
    exact = false,
    only = nil,
    fuzz = "2%",
    out = "build/snapshot/diff-report",
    port = 0,
    no_open = false,
  }
  local i = 1
  local function take_value(flag)
    i = i + 1
    if i > #argv then die(flag .. " requires a value") end
    return argv[i]
  end
  while i <= #argv do
    local a = argv[i]
    if a == "--base" then opts.base = take_value(a)
    elseif a == "--head" then opts.head = take_value(a)
    elseif a == "--exact" then opts.exact = true
    elseif a == "--only" then opts.only = take_value(a)
    elseif a == "--fuzz" then opts.fuzz = take_value(a)
    elseif a == "--out" then opts.out = take_value(a)
    elseif a == "--port" then opts.port = tonumber(take_value(a)) or 0
    elseif a == "--no-open" then opts.no_open = true
    elseif a == "--help" or a == "-h" then io.write(USAGE); os.exit(0)
    else die("unknown arg: " .. a) end
    i = i + 1
  end
  return opts
end

-- All git calls run from ROOT; dynamic values are shell-quoted by the caller.
local function git(args)
  return util.popen_capture(string.format("git -C %s %s 2>&1", shell_quote(ROOT), args))
end

local function resolve_commit(ref)
  local code, out = git(string.format("rev-parse --verify %s^{commit}", shell_quote(ref)))
  if code ~= 0 then return nil end
  return trim(out)
end

local function subject(rev)
  local code, out = git("show -s --format=" .. shell_quote("%h %s") .. " " .. shell_quote(rev))
  if code ~= 0 then return rev end
  return trim(out)
end

-- `identify` is part of the ImageMagick suite the harness already requires.
local function dimensions(png)
  local _, out = util.popen_capture(
    string.format("identify -format '%%wx%%h' %s 2>/dev/null", shell_quote(png)))
  local w, h = out:match("(%d+)x(%d+)")
  return tonumber(w), tonumber(h)
end

-- Pad to a common canvas so `compare` does not abort on a size mismatch
-- (the margin-reclaim refresh changes canvas height). NorthWest gravity keeps
-- the plot pinned top-left so the growth shows as extra blank space.
local function pad_to(src, dst, w, h)
  util.run(string.format(
    "convert %s -background white -gravity NorthWest -extent %dx%d %s 2>/dev/null",
    shell_quote(src), w, h, shell_quote(dst)))
end

-- Same `compare -metric AE -fuzz` contract as run.lua:diff_images, so the
-- overlay matches what CI gates on. Returns the AE pixel count (nil on error).
local function overlay(base_png, head_png, diff_png, fuzz)
  local cmd = string.format(
    "compare -metric AE -fuzz %s %s %s %s 2>&1",
    fuzz, shell_quote(base_png), shell_quote(head_png), shell_quote(diff_png))
  local code, out = util.popen_capture(cmd)
  if code > 1 then return nil end
  return tonumber(out:match("^%s*(%d+)"))
end

local function side_by_side(base_png, head_png, out_png)
  util.run(string.format("convert %s %s +append %s 2>/dev/null",
    shell_quote(base_png), shell_quote(head_png), shell_quote(out_png)))
end

local function git_show_to(rev, path, dst)
  local ok = os.execute(string.format("git -C %s show %s > %s 2>/dev/null",
    shell_quote(ROOT), shell_quote(rev .. ":" .. path), shell_quote(dst)))
  -- `os.execute` returns true/nil on Lua 5.2+ and an exit-status number on
  -- 5.1; normalise so callers get a real boolean. The shell redirect creates
  -- `dst` even when `git show` fails, so drop the empty file on failure.
  ok = ok == true or ok == 0
  if not ok then os.remove(dst) end
  return ok
end

-- Returns an array of { status = "A"|"M"|"D", path = <repo-relative> }.
local function changed_goldens(base_rev, head_ref)
  local entries, seen = {}, {}
  local args
  if head_ref then
    args = string.format("diff --name-status %s %s -- %s",
      shell_quote(base_rev), shell_quote(head_ref), shell_quote(GOLDEN_REL))
  else
    args = string.format("diff --name-status %s -- %s",
      shell_quote(base_rev), shell_quote(GOLDEN_REL))
  end
  local _, out = git(args)
  for line in out:gmatch("[^\n]+") do
    local status, path = line:match("^(%a)%S*\t(.+)$")
    if status and path then
      entries[#entries + 1] = { status = status, path = path }
      seen[path] = true
    end
  end
  -- Working-tree mode: untracked goldens are not in `diff`; surface them as adds.
  if not head_ref then
    local _, others = git(string.format(
      "ls-files --others --exclude-standard -- %s", shell_quote(GOLDEN_REL)))
    for path in others:gmatch("[^\n]+") do
      if not seen[path] then entries[#entries + 1] = { status = "A", path = path } end
    end
  end
  return entries
end

local function key_of(path)
  return (path:gsub("^" .. GOLDEN_REL:gsub("([%-%.])", "%%%1") .. "/", ""):gsub("%.png$", ""))
end

local function html_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local STYLE = [[
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; overflow: hidden; }
body { font: 14px/1.5 system-ui, sans-serif; display: grid; grid-template-rows: auto 1fr; }
.bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
  padding: 8px 14px; border-bottom: 1px solid #8884; background: Canvas; }
.bar button { font: inherit; padding: 4px 10px; cursor: pointer; }
.bar .pos { font-variant-numeric: tabular-nums; font-weight: 600; min-width: 5.5em; text-align: center; }
.bar .key { font-weight: 600; }
.bar .meta { color: #888; font-variant-numeric: tabular-nums; }
.bar .summary, .bar .hint { color: #888; }
.bar .hint { margin-left: auto; }
.badge { font-size: 11px; text-transform: uppercase; letter-spacing: .04em;
  padding: 2px 7px; border-radius: 99px; color: #fff; }
.badge.m { background: #d97706; } .badge.a { background: #16a34a; } .badge.d { background: #dc2626; }
.seg { display: inline-flex; border: 1px solid #8886; border-radius: 6px; overflow: hidden; }
.seg button { border: 0; border-radius: 0; background: transparent; padding: 4px 10px; }
.seg button.on { background: #3b82f6; color: #fff; }
.seg button:disabled { opacity: .35; cursor: not-allowed; }
#opa { width: 200px; }
#validate.staged { background: #16a34a; color: #fff; border-color: #16a34a; }
.stage-wrap { display: inline-flex; gap: 8px; align-items: center; }
.staged-count { color: #888; font-variant-numeric: tabular-nums; }
.viewer { min-height: 0; overflow: hidden; display: grid; place-items: center; padding: 12px; }
.card { display: none; width: 100%; height: 100%; place-items: center; }
.card.active { display: grid; }
.v { display: none; }
.viewer img, .stack { max-width: 100%; max-height: 100%; object-fit: contain;
  background: repeating-conic-gradient(#0001 0 25%, transparent 0 50%) 0 0 / 16px 16px; }
.stack { position: relative; display: inline-block; }
.stack img { display: block; max-width: 100%; max-height: 100%; }
.stack .oh { position: absolute; inset: 0; }
]]

local SCRIPT = [[
const cards = Array.from(document.querySelectorAll('.card'));
const M = cards.length;
const el = id => document.getElementById(id);
const posEl = el('pos'), keyEl = el('key'), badgeEl = el('badge'), metaEl = el('meta'),
      opa = el('opa'), valBtn = el('validate'), stagedCountEl = el('stagedcount'),
      stageWrap = el('stagewrap');
const VIEW = { side: '.v-side', diff: '.v-diff', onion: '.v-stack', flicker: '.v-stack' };
const staged = new Set();
let idx = 0, mode = 'diff', flick = null;

function active() { return cards[idx]; }
function stopFlicker() { if (flick) { clearInterval(flick); flick = null; } }

function applyView() {
  stopFlicker();
  const c = active();
  c.querySelectorAll('.v').forEach(v => { v.style.display = 'none'; });
  const both = c.dataset.both === '1';
  let eff = mode;
  if (!both && eff !== 'side') eff = 'side';
  const sel = c.querySelector(VIEW[eff]) || c.querySelector('.v-side');
  if (sel) sel.style.display = sel.classList.contains('v-stack') ? 'inline-block' : 'block';
  document.querySelectorAll('#seg button').forEach(b => {
    b.classList.toggle('on', b.dataset.mode === mode);
    b.disabled = b.dataset.mode !== 'side' && !both;
  });
  opa.hidden = eff !== 'onion';
  const oh = c.querySelector('.oh');
  if (oh && eff === 'onion') oh.style.opacity = opa.value / 100;
  if (oh && eff === 'flicker') {
    let on = true;
    flick = setInterval(() => { oh.style.opacity = on ? 1 : 0; on = !on; }, 500);
  }
}

function refreshStage() {
  if (!window.CFG.stageable) return;
  const isStaged = staged.has(active().dataset.path);
  valBtn.textContent = isStaged ? 'staged ✓' : 'validate';
  valBtn.classList.toggle('staged', isStaged);
  stagedCountEl.textContent = 'staged ' + staged.size + ' / ' + M;
}

function show(i) {
  if (!M) return;
  idx = (i + M) % M;
  cards.forEach((c, n) => c.classList.toggle('active', n === idx));
  const c = active();
  posEl.textContent = (idx + 1) + ' / ' + M;
  keyEl.textContent = c.dataset.key;
  badgeEl.textContent = c.dataset.label;
  badgeEl.className = 'badge ' + c.dataset.badge;
  metaEl.textContent = c.dataset.meta || '';
  applyView();
  refreshStage();
}

function setMode(m) { mode = m; applyView(); }

document.querySelectorAll('#seg button').forEach(b =>
  b.addEventListener('click', () => { if (!b.disabled) setMode(b.dataset.mode); }));
el('next').addEventListener('click', () => show(idx + 1));
el('prev').addEventListener('click', () => show(idx - 1));
opa.addEventListener('input', () => {
  const oh = active().querySelector('.oh');
  if (oh) oh.style.opacity = opa.value / 100;
});

async function toggleStage() {
  if (!window.CFG.stageable) return;
  const path = active().dataset.path;
  const isStaged = staged.has(path);
  try {
    const r = await fetch(isStaged ? '/api/unstage' : '/api/stage', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ path })
    });
    if (!r.ok) {
      const e = await r.json().catch(() => ({}));
      alert('stage failed: ' + (e.error || r.status));
      return;
    }
    if (isStaged) staged.delete(path); else staged.add(path);
    refreshStage();
  } catch (err) { alert('stage failed: ' + err); }
}
valBtn.addEventListener('click', toggleStage);

document.addEventListener('keydown', e => {
  if (e.target.matches('input, textarea')) return;
  switch (e.key) {
    case 'j': case 'ArrowRight': show(idx + 1); e.preventDefault(); break;
    case 'k': case 'ArrowLeft': show(idx - 1); e.preventDefault(); break;
    case 'd': setMode('diff'); break;
    case 'o': setMode('onion'); break;
    case 's': setMode('side'); break;
    case 'f': setMode('flicker'); break;
    case 'v': toggleStage(); break;
  }
});

async function init() {
  if (window.CFG.stageable) {
    try {
      const r = await fetch('/api/status');
      if (r.ok) { const j = await r.json(); (j.staged || []).forEach(p => staged.add(p)); }
    } catch (e) { /* server-less view; leave validate disabled */ }
  } else {
    stageWrap.style.display = 'none';
  }
  show(0);
}
init();
]]

-- Localhost-only review server: serves the report and runs `git add`/`reset`
-- on validate. Stdlib only (http.server + subprocess); git is invoked with an
-- argument list (never a shell) and every path is re-validated against the
-- golden directory before it reaches git. Written into the report dir at run
-- time and launched in the foreground.
local SERVER_PY = [[
import sys, os, json, re, subprocess, http.server, socketserver, webbrowser

ROOT = os.path.abspath(sys.argv[1])
OUT = os.path.abspath(sys.argv[2])
PORT = int(sys.argv[3])
OPEN = sys.argv[4] == '1'
SAFE = re.compile(r'^tests/visual/golden/[A-Za-z0-9._/-]+\.png$')

def safe(p):
    return bool(SAFE.match(p)) and '..' not in p.split('/')

def git(args):
    return subprocess.run(['git', '-C', ROOT] + args, capture_output=True, text=True)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=OUT, **k)

    def log_message(self, *a):
        pass

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == '/api/status':
            r = git(['diff', '--cached', '--name-only', '--', 'tests/visual/golden'])
            return self._json(200, {'staged': [l for l in r.stdout.splitlines() if l]})
        return super().do_GET()

    def do_POST(self):
        if self.path not in ('/api/stage', '/api/unstage'):
            return self._json(404, {'error': 'not found'})
        n = int(self.headers.get('Content-Length', '0'))
        try:
            body = json.loads(self.rfile.read(n) or b'{}')
        except Exception:
            return self._json(400, {'error': 'bad json'})
        path = body.get('path', '')
        if not safe(path):
            return self._json(400, {'error': 'invalid path: ' + path})
        if self.path == '/api/stage':
            r = git(['add', '--', path])
        else:
            r = git(['reset', '-q', 'HEAD', '--', path])
        if r.returncode != 0:
            return self._json(500, {'error': r.stderr.strip()})
        return self._json(200, {'ok': True, 'path': path})

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

with Server(('127.0.0.1', PORT), Handler) as httpd:
    url = 'http://127.0.0.1:%d/' % httpd.server_address[1]
    print('serving %s  (Ctrl-C to stop)' % url, flush=True)
    if OPEN:
        webbrowser.open(url)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nstopped', flush=True)
]]

local function render_card(e)
  local badge = ({ M = "m", A = "a", D = "d" })[e.status]
  local label = ({ M = "modified", A = "added", D = "removed" })[e.status]
  local both = (e.base_over and e.head_over) and "1" or "0"
  local parts = {
    string.format(
      '    <section class="card" data-path="%s" data-both="%s" data-key="%s"' ..
      ' data-badge="%s" data-label="%s" data-meta="%s">\n',
      html_escape(e.path), both, html_escape(e.key), badge, label,
      html_escape(e.meta or "")),
  }
  local side = e.side_rel or e.single_rel
  if side then
    parts[#parts + 1] = string.format(
      '      <img class="v v-side" src="%s" loading="lazy">\n', side)
  end
  if e.diff_rel then
    parts[#parts + 1] = string.format(
      '      <img class="v v-diff" src="%s" loading="lazy">\n', e.diff_rel)
  end
  if e.base_over and e.head_over then
    parts[#parts + 1] = table.concat({
      '      <div class="v v-stack stack">\n',
      string.format('        <img class="ob" src="%s" loading="lazy">\n', e.base_over),
      string.format('        <img class="oh" src="%s" loading="lazy">\n', e.head_over),
      '      </div>\n',
    })
  end
  parts[#parts + 1] = '    </section>\n'
  return table.concat(parts)
end

local function render_report(summary, cards_html, stageable)
  return table.concat({
    "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n',
    "<title>Snapshot diff</title>\n<style>\n", STYLE, "</style>\n</head>\n<body>\n",
    '<div class="bar">\n',
    '  <button id="prev">&larr; prev</button>\n',
    '  <span class="pos" id="pos">0 / 0</span>\n',
    '  <button id="next">next &rarr;</button>\n',
    '  <span class="key" id="key"></span>\n',
    '  <span class="badge" id="badge"></span>\n',
    '  <span class="meta" id="meta"></span>\n',
    '  <span class="seg" id="seg">',
    '<button data-mode="side">Side</button>',
    '<button data-mode="onion">Onion</button>',
    '<button data-mode="diff">Diff</button>',
    '<button data-mode="flicker">Flicker</button></span>\n',
    '  <input id="opa" type="range" min="0" max="100" value="50" hidden>\n',
    '  <span class="stage-wrap" id="stagewrap"><button id="validate">validate</button>',
    '<span class="staged-count" id="stagedcount"></span></span>\n',
    string.format('  <span class="summary">%s</span>\n', html_escape(summary)),
    '  <span class="hint">j/k step &middot; d/o/s/f mode &middot; v validate</span>\n',
    '</div>\n<div class="viewer" id="viewer">\n', cards_html, '</div>\n',
    string.format('<script>window.CFG={stageable:%s};</script>\n',
      stageable and "true" or "false"),
    "<script>\n", SCRIPT, "</script>\n</body>\n</html>\n",
  })
end

local function main()
  local opts = parse_args(arg or {})
  local out_dir = abs(opts.out)

  local base_commit = resolve_commit(opts.base)
  if not base_commit then die("base ref does not resolve: " .. opts.base) end

  local head_commit = opts.head and resolve_commit(opts.head) or "HEAD"
  if opts.head and not head_commit then die("head ref does not resolve: " .. opts.head) end

  local base_rev = base_commit
  if not opts.exact then
    local code, mb = git(string.format("merge-base %s %s",
      shell_quote(base_commit), shell_quote(head_commit)))
    if code == 0 and trim(mb) ~= "" then base_rev = trim(mb) end
  end

  local entries = changed_goldens(base_rev, opts.head)
  if opts.only then
    local filtered = {}
    for _, e in ipairs(entries) do
      if key_of(e.path):find(opts.only, 1, true) then filtered[#filtered + 1] = e end
    end
    entries = filtered
  end

  local base_label = subject(base_rev)
  local head_label = opts.head and subject(head_commit) or "working tree"

  if #entries == 0 then
    io.write(string.format("no snapshot changes between %s..%s\n", base_label, head_label))
    os.exit(0)
  end

  util.remove_dir(out_dir)
  util.make_dir(out_dir)

  local counts = { M = 0, A = 0, D = 0 }
  for _, e in ipairs(entries) do
    counts[e.status] = (counts[e.status] or 0) + 1
    e.key = key_of(e.path)
    local safe = e.key:gsub("/", "__")
    local img_dir = out_dir .. "/img/" .. safe
    util.make_dir(img_dir)

    if e.status ~= "A" then
      local base_png = img_dir .. "/base.png"
      if git_show_to(base_rev, e.path, base_png) and util.file_exists(base_png) then
        e.base_abs, e.base_rel = base_png, "img/" .. safe .. "/base.png"
      end
    end

    if e.status ~= "D" then
      local head_png = img_dir .. "/head.png"
      local ok
      if opts.head then
        ok = git_show_to(opts.head, e.path, head_png)
      else
        ok = util.copy_file(abs(e.path), head_png)
      end
      if ok and util.file_exists(head_png) then
        e.head_abs, e.head_rel = head_png, "img/" .. safe .. "/head.png"
      end
    end

    e.ae = -1
    if e.base_abs and e.head_abs then
      local bw, bh = dimensions(e.base_abs)
      local hw, hh = dimensions(e.head_abs)
      local base_cmp, head_cmp = e.base_abs, e.head_abs
      local size_note
      if bw and hw and (bw ~= hw or bh ~= hh) then
        local cw, ch = math.max(bw, hw), math.max(bh, hh)
        local bp, hp = img_dir .. "/base.pad.png", img_dir .. "/head.pad.png"
        pad_to(e.base_abs, bp, cw, ch)
        pad_to(e.head_abs, hp, cw, ch)
        base_cmp, head_cmp = bp, hp
        size_note = string.format("%dx%d -> %dx%d", bw, bh, hw, hh)
      end
      local diff_png = img_dir .. "/diff.png"
      local ae = overlay(base_cmp, head_cmp, diff_png, opts.fuzz)
      if ae and util.file_exists(diff_png) then
        e.ae, e.diff_rel = ae, "img/" .. safe .. "/diff.png"
      end
      local side_png = img_dir .. "/side.png"
      side_by_side(base_cmp, head_cmp, side_png)
      if util.file_exists(side_png) then e.side_rel = "img/" .. safe .. "/side.png" end

      e.base_over = e.base_rel
      e.head_over = e.head_rel
      if base_cmp ~= e.base_abs then
        e.base_over = "img/" .. safe .. "/base.pad.png"
        e.head_over = "img/" .. safe .. "/head.pad.png"
      end

      local meta = {}
      if e.ae >= 0 then
        local w, h = dimensions(base_cmp)
        local pct = (w and h and w * h > 0) and (e.ae / (w * h) * 100) or 0
        meta[#meta + 1] = string.format("AE=%d  %.3f%%", e.ae, pct)
      end
      if size_note then meta[#meta + 1] = "size " .. size_note end
      e.meta = table.concat(meta, "  \194\183  ")
    elseif e.status == "A" then
      e.meta = "new snapshot"
      e.single_rel = e.head_rel
    elseif e.status == "D" then
      e.meta = "removed snapshot"
      e.single_rel = e.base_rel
    end
  end

  -- Modified first, largest visual diff on top, then adds, then removes.
  local order = { M = 0, A = 1, D = 2 }
  table.sort(entries, function(a, b)
    if a.status ~= b.status then return order[a.status] < order[b.status] end
    if a.status == "M" then return a.ae > b.ae end
    return a.key < b.key
  end)

  local cards = {}
  for _, e in ipairs(entries) do cards[#cards + 1] = render_card(e) end

  local summary = string.format(
    "%d modified \194\183 %d added \194\183 %d removed   (%s -> %s)",
    counts.M, counts.A, counts.D, base_label, head_label)

  -- Validate stages the on-disk golden, which only matches what is shown in
  -- working-tree mode; staging a historical ref would be meaningless.
  local stageable = opts.head == nil
  local index = out_dir .. "/index.html"
  util.write_file(index, render_report(summary, table.concat(cards), stageable))

  local serve_py = out_dir .. "/serve.py"
  util.write_file(serve_py, SERVER_PY)

  io.write(summary .. "\n")
  -- Best-effort: the report is already on disk, so a failed server launch
  -- (missing python3, port in use) should not crash the run.
  os.execute(string.format("python3 %s %s %s %d %d",
    shell_quote(serve_py), shell_quote(ROOT), shell_quote(out_dir),
    opts.port, opts.no_open and 0 or 1))
end

main()
