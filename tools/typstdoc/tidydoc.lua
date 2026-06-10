#!/usr/bin/env lua
-- Rewrites gribouille `///` docstrings into the tidy-style comments that the
-- Tinymist language server renders on hover. Run over the staged `src/` at
-- packaging time (see tools/package.sh): the repo sources keep the rich
-- `@`-tag format the .qmd generator needs, while the published package ships
-- LSP-friendly docstrings.
--
-- `///` lines are Typst line comments, so the compiler ignores whatever we
-- write here; Tinymist is the only consumer.
--
-- Usage: tidydoc.lua <src-dir>   (rewrites every .typ file in place)

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end
package.path = script_dir() .. "/?.lua;" .. package.path

local util = require("util")
local parser = require("parser")

local M = {}

-- A bare `@name` cross-reference unescapes to a Typst label ref that resolves
-- to nothing in a hover; show the target as inline code instead.
local function refs_to_code(s)
  if not s or s == "" then return s end
  return (s:gsub("@([%w_%-]+)", "`%1`"))
end

local function push(out, line) out[#out + 1] = line end
local function blank(out) out[#out + 1] = "///" end

-- Emit a text blob as `///` lines, preserving any embedded newlines (a list or
-- table stored as one description string keeps its own line breaks).
local function prose(out, text)
  for _, ln in ipairs(util.split_lines(refs_to_code(text))) do
    if ln == "" then blank(out) else push(out, "/// " .. ln) end
  end
end

local function variadic_names(fn)
  local set = {}
  for _, p in ipairs(fn.signature_params) do
    if p.variadic then set[p.name] = true end
  end
  return set
end

local function emit_doc(fn)
  local doc = fn.doc
  local out = {}

  prose(out, doc.summary)

  for _, para in ipairs(doc.description) do
    blank(out)
    prose(out, para)
  end

  if doc.stability == "deprecated" then
    blank(out); push(out, "/// *Deprecated.*")
  elseif doc.stability == "experimental" then
    blank(out); push(out, "/// *Experimental.*")
  end

  if #doc.params > 0 then
    local vnames = variadic_names(fn)
    blank(out)
    for _, p in ipairs(doc.params) do
      local desc = refs_to_code(p.description or "")
      if (p.variadic or vnames[p.name]) and #doc.named_keys > 0 then
        if desc ~= "" then desc = desc .. " " end
        desc = desc .. "Accepted keys: " .. table.concat(doc.named_keys, ", ") .. "."
      end
      push(out, "/// - " .. p.name .. ": " .. desc)
    end
  end

  if #doc.arities > 0 then
    blank(out); push(out, "/// Call forms:")
    for _, a in ipairs(doc.arities) do
      push(out, string.format("/// - `%s%s`: %s", fn.name, a.signature, refs_to_code(a.description)))
    end
  end

  if doc.returns and doc.returns ~= "" then
    blank(out); push(out, "/// Returns: " .. refs_to_code(doc.returns))
  end

  if doc.has_theme_keys then
    blank(out); push(out, "/// See the package reference for the full theme key catalogue.")
  end

  if #doc.see > 0 then
    local names = {}
    for _, ref in ipairs(doc.see) do names[#names + 1] = "`" .. ref:gsub("^@", "") .. "`" end
    blank(out); push(out, "/// See also: " .. table.concat(names, ", ") .. ".")
  end

  for _, ex in ipairs(doc.examples) do
    for _, seg in ipairs(ex.segments) do
      if seg.kind == "prose" then
        if seg.text and seg.text ~= "" then blank(out); prose(out, seg.text) end
      elseif seg.kind == "code" then
        blank(out); push(out, "/// ```typst")
        for _, ln in ipairs(util.split_lines(seg.source)) do
          if ln == "" then blank(out) else push(out, "/// " .. ln) end
        end
        push(out, "/// ```")
      end
    end
  end

  return out
end

-- The doc block is the contiguous run of `///` lines starting at `start`
-- (module `///!` banners are not function docs and end the run).
local function block_end(lines, start)
  local j = start
  while j <= #lines do
    local t = util.trim(lines[j])
    if t:sub(1, 3) == "///" and t:sub(1, 4) ~= "///!" then j = j + 1 else break end
  end
  return j - 1
end

local function splice(lines, s, e, replacement)
  local out = {}
  for k = 1, s - 1 do out[#out + 1] = lines[k] end
  for _, ln in ipairs(replacement) do out[#out + 1] = ln end
  for k = e + 1, #lines do out[#out + 1] = lines[k] end
  return out
end

function M.transform_file(path)
  local parsed = parser.parse_file(path, { skip_theme_keys = true })
  local docs = {}
  for _, fn in ipairs(parsed.functions) do
    if fn.doc then docs[#docs + 1] = fn end
  end
  if #docs == 0 then return false end

  -- Splice bottom-up so each block's recorded start line stays valid.
  table.sort(docs, function(a, b) return a.line > b.line end)

  local lines = util.split_lines(util.read_file(path))
  for _, fn in ipairs(docs) do
    local e = block_end(lines, fn.line)
    lines = splice(lines, fn.line, e, emit_doc(fn))
  end
  util.write_file(path, table.concat(lines, "\n"))
  return true
end

function M.transform_dir(dir)
  local count = 0
  for _, path in ipairs(util.find_typ_files(dir)) do
    if M.transform_file(path) then count = count + 1 end
  end
  return count
end

local invoked_as_script = arg and arg[0] and arg[0]:match("tidydoc%.lua$")
if invoked_as_script then
  local dir = arg[1]
  if not dir then
    io.stderr:write("usage: tidydoc.lua <src-dir>\n")
    os.exit(1)
  end
  local ok, result = pcall(M.transform_dir, dir)
  if not ok then
    util.log_err(tostring(result))
    os.exit(1)
  end
  util.log_info(string.format("tidydoc: rewrote docstrings in %d file(s) under %s", result, dir))
end

return M
