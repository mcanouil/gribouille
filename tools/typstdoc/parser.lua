local util = require("util")
local model = require("model")
local theme_keys = require("theme_keys")

local M = {}

local repo_root

function M.set_root(path)
  repo_root = path
end

local VALID_CATEGORIES = {
  Core = true, Labs = true, Geoms = true, Stats = true, Scales = true,
  Coord = true, Positions = true, Facets = true, Themes = true,
  Datasets = true, Guides = true, Utilities = true, Helpers = true,
}

local VALID_STABILITY = { stable = true, experimental = true, deprecated = true }

local KNOWN_TAGS = {
  ["@category"] = true, ["@subcategory"] = true, ["@stability"] = true, ["@since"] = true,
  ["@param"] = true, ["@arity"] = true, ["@returns"] = true,
  ["@examples"] = true, ["@examples-static"] = true, ["@see"] = true,
  ["@internal"] = true, ["@advanced"] = true,
  ["@theme-keys"] = true, ["@named-keys"] = true,
}

local PIPELINE_HOOKS = { draw = true, apply = true }

local function error_at(file, line, msg)
  error(string.format("%s:%d: %s", file, line, msg), 0)
end

local function strip_doc_prefix(s, marker)
  local body = s:sub(#marker + 1)
  if body:sub(1, 1) == " " then body = body:sub(2) end
  -- tinymist parses bare @name in /// as a label ref; sources write \@ to silence it.
  return (body:gsub("\\@", "@"))
end

local function parse_signature_params(raw, file, line)
  local depth = 0
  local buf = {}
  local parts = {}
  local in_string = false
  local string_char = nil
  local i = 1
  local len = #raw
  while i <= len do
    local c = raw:sub(i, i)
    if in_string then
      table.insert(buf, c)
      if c == "\\" and i < len then
        table.insert(buf, raw:sub(i + 1, i + 1))
        i = i + 1
      elseif c == string_char then
        in_string = false
      end
    elseif c == '"' or c == "'" then
      in_string = true
      string_char = c
      table.insert(buf, c)
    elseif c == "/" and raw:sub(i + 1, i + 1) == "/" then
      i = raw:find("\n", i, true) or len
    elseif c == "(" or c == "[" or c == "{" then
      depth = depth + 1
      table.insert(buf, c)
    elseif c == ")" or c == "]" or c == "}" then
      depth = depth - 1
      table.insert(buf, c)
    elseif c == "," and depth == 0 then
      table.insert(parts, util.trim(table.concat(buf)))
      buf = {}
    else
      table.insert(buf, c)
    end
    i = i + 1
  end
  local last = util.trim(table.concat(buf))
  if last ~= "" then table.insert(parts, last) end

  local params = {}
  for _, part in ipairs(parts) do
    if part ~= "" then
      local variadic = false
      local body = part
      if body:sub(1, 2) == ".." then
        variadic = true
        body = body:sub(3)
      end
      local name, default = body:match("^([%w_%-]+)%s*:%s*(.+)$")
      if name then
        table.insert(params, model.new_param({ name = name, variadic = variadic, default = util.trim(default) }))
      else
        local bare = body:match("^([%w_%-]+)%s*$")
        if bare then
          table.insert(params, model.new_param({ name = bare, variadic = variadic }))
        else
          error_at(file, line, "could not parse parameter: " .. part)
        end
      end
    end
  end
  return params
end

local function skip_value_binding(lines, start_idx, rhs)
  local depth = 0
  local in_string = false
  local string_char = nil
  local function consume(s)
    local li = 1
    local ll = #s
    while li <= ll do
      local c = s:sub(li, li)
      if in_string then
        if c == "\\" and li < ll then li = li + 1
        elseif c == string_char then in_string = false end
      elseif c == '"' or c == "'" then
        in_string = true; string_char = c
      elseif c == "/" and s:sub(li + 1, li + 1) == "/" then
        return
      elseif c == "(" or c == "[" or c == "{" then
        depth = depth + 1
      elseif c == ")" or c == "]" or c == "}" then
        depth = depth - 1
      end
      li = li + 1
    end
  end
  consume(rhs)
  if depth <= 0 then return start_idx end
  local j = start_idx + 1
  while j <= #lines and depth > 0 do
    consume(lines[j])
    if depth <= 0 then return j end
    j = j + 1
  end
  return start_idx
end

local function collect_signature(lines, start_idx, file)
  local line = lines[start_idx]
  local name = line:match("^#let%s+([%w_%-]+)")
  if not name then
    error_at(file, start_idx, "#let without identifier")
  end
  local rest = line:match("^#let%s+[%w_%-]+(.*)$") or ""
  local rest_trim = util.trim(rest)
  if rest_trim:sub(1, 1) ~= "(" then
    local end_line = start_idx
    if rest_trim:sub(1, 1) == "=" then
      end_line = skip_value_binding(lines, start_idx, rest_trim:sub(2))
    end
    return { name = name, is_value = true, params = {}, signature_raw = name, end_line = end_line }
  end
  local paren_open = rest:find("%(")
  local before_paren = rest:sub(1, paren_open - 1)
  local after_paren = rest:sub(paren_open + 1)
  local buf = { after_paren }
  local depth = 1
  local i = 1
  local len = #after_paren
  local in_string = false
  local string_char = nil
  local finished = false
  while i <= len and not finished do
    local c = after_paren:sub(i, i)
    if in_string then
      if c == "\\" and i < len then i = i + 1
      elseif c == string_char then in_string = false end
    elseif c == '"' or c == "'" then
      in_string = true; string_char = c
    elseif c == "/" and after_paren:sub(i + 1, i + 1) == "/" then
      break
    elseif c == "(" or c == "[" or c == "{" then
      depth = depth + 1
    elseif c == ")" or c == "]" or c == "}" then
      depth = depth - 1
      if depth == 0 then finished = true; len = i - 1; buf[1] = after_paren:sub(1, len); break end
    end
    i = i + 1
  end
  local end_line = start_idx
  if not finished then
    local j = start_idx + 1
    while j <= #lines and not finished do
      local ln = lines[j]
      table.insert(buf, "\n")
      local li = 1
      local ll = #ln
      local chunk_start = 1
      while li <= ll and not finished do
        local c = ln:sub(li, li)
        if in_string then
          if c == "\\" and li < ll then li = li + 1
          elseif c == string_char then in_string = false end
        elseif c == '"' or c == "'" then
          in_string = true; string_char = c
        elseif c == "/" and ln:sub(li + 1, li + 1) == "/" then
          break
        elseif c == "(" or c == "[" or c == "{" then
          depth = depth + 1
        elseif c == ")" or c == "]" or c == "}" then
          depth = depth - 1
          if depth == 0 then
            finished = true
            table.insert(buf, ln:sub(chunk_start, li - 1))
            end_line = j
            break
          end
        end
        li = li + 1
      end
      if not finished then
        table.insert(buf, ln)
        end_line = j
      end
      j = j + 1
    end
  end
  if not finished then
    error_at(file, start_idx, "unterminated parameter list for #let " .. name)
  end
  local raw_params = table.concat(buf)
  local params = parse_signature_params(raw_params, file, start_idx)
  local signature_raw = "#let " .. name .. before_paren .. "(" .. raw_params .. ")"
  return {
    name = name,
    is_value = false,
    params = params,
    signature_raw = signature_raw,
    end_line = end_line,
  }
end

local function merge_continuations(doc_lines)
  local merged = {}
  local in_fence = false
  for _, line in ipairs(doc_lines) do
    local trimmed = util.trim(line)
    if trimmed:match("^```") then
      in_fence = not in_fence
      table.insert(merged, line)
    elseif in_fence then
      table.insert(merged, line)
    elseif line:sub(1, 1):match("%s") and #merged > 0 and util.trim(merged[#merged]) ~= "" then
      merged[#merged] = merged[#merged] .. " " .. trimmed
    else
      table.insert(merged, line)
    end
  end
  return merged
end

local function parse_doc_block(doc_lines, file, start_line, opts)
  opts = opts or {}
  doc_lines = merge_continuations(doc_lines)
  local doc = model.new_doc_block()
  local mode = "summary"
  local para = {}
  local list_items = {}
  local i = 1
  local n = #doc_lines

  local function flush_para()
    if #para > 0 then
      local text = util.trim(table.concat(para, " "))
      if mode == "summary" then
        doc.summary = text
        mode = "description"
      elseif mode == "description" then
        table.insert(doc.description, text)
      end
      para = {}
    end
  end

  local function flush_list()
    if #list_items > 0 then
      local text = table.concat(list_items, "\n")
      if mode == "summary" then
        doc.summary = text
        mode = "description"
      else
        table.insert(doc.description, text)
      end
      list_items = {}
    end
  end

  local function flush_block()
    flush_list()
    flush_para()
  end

  local function is_list_line(s)
    local first = s:sub(1, 2)
    return first == "- " or first == "* " or first == "+ "
  end

  local function is_table_line(s)
    return s:sub(1, 1) == "|"
  end

  while i <= n do
    local line = doc_lines[i]
    local trimmed_line = util.trim(line)
    if trimmed_line == "" then
      flush_block()
    elseif trimmed_line:sub(1, 1) == "@" then
      flush_block()
      local tag, rest = trimmed_line:match("^(@[%w%-]+)%s*(.*)$")
      if not KNOWN_TAGS[tag] then
        error_at(file, start_line + i - 1, "unknown tag: " .. tag)
      end
      if tag == "@category" then
        local cat = util.trim(rest)
        if not VALID_CATEGORIES[cat] then
          error_at(file, start_line + i - 1, "invalid @category: " .. cat)
        end
        if doc.category then
          error_at(file, start_line + i - 1, "duplicate @category")
        end
        doc.category = cat
      elseif tag == "@subcategory" then
        local sub = util.trim(rest)
        if sub == "" then
          error_at(file, start_line + i - 1, "empty @subcategory")
        end
        if doc.subcategory then
          error_at(file, start_line + i - 1, "duplicate @subcategory")
        end
        doc.subcategory = sub
      elseif tag == "@stability" then
        local st = util.trim(rest)
        if not VALID_STABILITY[st] then
          error_at(file, start_line + i - 1, "invalid @stability: " .. st)
        end
        doc.stability = st
      elseif tag == "@since" then
        doc.since = util.trim(rest)
      elseif tag == "@internal" then
        doc.is_internal = true
      elseif tag == "@advanced" then
        doc.is_advanced = true
      elseif tag == "@returns" then
        doc.returns = util.trim(rest)
      elseif tag == "@see" then
        for ref in rest:gmatch("@[%w%-_]+") do
          table.insert(doc.see, ref)
        end
      elseif tag == "@theme-keys" then
        if opts.skip_theme_keys then
          doc.has_theme_keys = true
        else
          if not repo_root then
            error_at(file, start_line + i - 1,
              "@theme-keys requires parser.set_root() before parse_file()")
          end
          table.insert(doc.description, theme_keys.render(repo_root))
        end
      elseif tag == "@named-keys" then
        for key in rest:gmatch("[%w_%-]+") do
          table.insert(doc.named_keys, key)
        end
      elseif tag == "@param" then
        local variadic = false
        local body = rest
        if body:sub(1, 2) == ".." then
          variadic = true
          body = body:sub(3)
        end
        local pname, pdesc = body:match("^([%w_%-]+)%s*(.*)$")
        if not pname then
          error_at(file, start_line + i - 1, "could not parse @param: " .. rest)
        end
        table.insert(doc.params, { name = pname, variadic = variadic, description = util.trim(pdesc) })
      elseif tag == "@arity" then
        local sig, desc = rest:match("^(%b()):%s*(.*)$")
        if not sig then
          error_at(file, start_line + i - 1, "expected `@arity (sig): desc`, got: " .. rest)
        end
        table.insert(doc.arities, model.new_arity({ signature = sig, description = desc }))
      elseif tag == "@examples" or tag == "@examples-static" then
        local render = (tag == "@examples")
        local segments = {}
        local prose_paras = {}
        local prose_buf = {}
        local function flush_prose_para()
          if #prose_buf > 0 then
            table.insert(prose_paras, util.trim(table.concat(prose_buf, " ")))
            prose_buf = {}
          end
        end
        local function flush_prose_segment()
          flush_prose_para()
          if #prose_paras > 0 then
            table.insert(segments, {
              kind = "prose",
              text = table.concat(prose_paras, "\n\n"),
            })
            prose_paras = {}
          end
        end
        local first_caption = util.trim(rest)
        if first_caption ~= "" then
          table.insert(prose_buf, first_caption)
        end
        local j = i + 1
        while j <= n do
          local ln = doc_lines[j]
          local trimmed_inner = util.trim(ln)
          if trimmed_inner:sub(1, 1) == "@" then
            local maybe_tag = trimmed_inner:match("^(@[%w%-]+)")
            if maybe_tag and KNOWN_TAGS[maybe_tag] then
              break
            end
          end
          if trimmed_inner:match("^```") then
            flush_prose_segment()
            local attrs = {}
            local src = {}
            local k = j + 1
            while k <= n do
              local code_ln = doc_lines[k]
              local code_trim = util.trim(code_ln)
              if code_trim:match("^```%s*$") then
                break
              end
              local consumed = false
              if code_trim:match("^//|") then
                local attr_line = code_trim:gsub("^//|%s*", "")
                local ak, av = attr_line:match("^([%w%-]+)%s*:%s*(.*)$")
                if ak then
                  attrs[ak] = util.trim(av)
                  consumed = true
                end
              end
              if not consumed then
                table.insert(src, code_ln)
              end
              k = k + 1
            end
            if k > n then
              error_at(file, start_line + i - 1, tag .. " fence never closes")
            end
            table.insert(segments, {
              kind = "code",
              source = table.concat(src, "\n"),
              attributes = attrs,
            })
            j = k + 1
          elseif trimmed_inner == "" then
            flush_prose_para()
            j = j + 1
          else
            table.insert(prose_buf, trimmed_inner)
            j = j + 1
          end
        end
        flush_prose_segment()
        local has_code = false
        for _, seg in ipairs(segments) do
          if seg.kind == "code" then
            has_code = true
            break
          end
        end
        if not has_code then
          error_at(file, start_line + i - 1, tag .. " block must contain at least one code fence")
        end
        table.insert(doc.examples, model.new_example({
          render = render,
          segments = segments,
        }))
        i = j - 1
      end
    else
      if is_list_line(trimmed_line) or is_table_line(trimmed_line) then
        flush_para()
        table.insert(list_items, trimmed_line)
      else
        flush_list()
        table.insert(para, line)
      end
    end
    i = i + 1
  end
  flush_block()

  if not doc.summary or doc.summary == "" then
    error_at(file, start_line, "doc block missing summary sentence")
  end

  return doc
end

function M.parse_file(file, opts)
  opts = opts or {}
  local content, err = util.read_file(file)
  if not content then error("typstdoc: cannot read " .. file .. ": " .. tostring(err)) end
  local lines = util.split_lines(content)
  local module_block
  local functions = {}
  local pending_doc_lines
  local pending_doc_start
  local i = 1
  local n = #lines

  while i <= n do
    local line = lines[i]
    local trimmed = util.trim(line)

    if trimmed:sub(1, 4) == "///!" and not pending_doc_lines and not module_block then
      local buf = {}
      local start = i
      while i <= n and util.trim(lines[i]):sub(1, 4) == "///!" do
        table.insert(buf, strip_doc_prefix(util.trim(lines[i]), "///!"))
        i = i + 1
      end
      module_block = { start = start, lines = buf }
      goto continue
    end

    if trimmed:sub(1, 3) == "///" and trimmed:sub(1, 4) ~= "///!" then
      if not pending_doc_lines then
        pending_doc_lines = {}
        pending_doc_start = i
      end
      table.insert(pending_doc_lines, strip_doc_prefix(trimmed, "///"))
      i = i + 1
      goto continue
    end

    if pending_doc_lines then
      if trimmed == "" or trimmed:sub(1, 7) == "#import" then
        i = i + 1
        goto continue
      end
      if trimmed:sub(1, 4) == "#let" then
        local sig = collect_signature(lines, i, file)
        local doc = parse_doc_block(pending_doc_lines, file, pending_doc_start, opts)
        table.insert(functions, model.new_function({
          name = sig.name,
          file = file,
          line = pending_doc_start,
          signature_params = sig.params,
          signature_raw = sig.signature_raw,
          is_value = sig.is_value,
          doc = doc,
        }))
        pending_doc_lines = nil
        pending_doc_start = nil
        i = sig.end_line + 1
        goto continue
      end
      error_at(file, pending_doc_start, "doc block not followed by a #let declaration")
    end

    if trimmed:sub(1, 4) == "#let" then
      local sig = collect_signature(lines, i, file)
      local is_private = sig.name:sub(1, 1) == "_" or PIPELINE_HOOKS[sig.name]
      if not is_private then
        table.insert(functions, model.new_function({
          name = sig.name,
          file = file,
          line = i,
          signature_params = sig.params,
          signature_raw = sig.signature_raw,
          is_value = sig.is_value,
          doc = nil,
        }))
      end
      i = sig.end_line + 1
      goto continue
    end

    i = i + 1
    ::continue::
  end

  return {
    file = file,
    module = module_block,
    functions = functions,
  }
end

function M.parse_lib(lib_path)
  local content, err = util.read_file(lib_path)
  if not content then error("typstdoc: cannot read " .. lib_path .. ": " .. tostring(err)) end
  local lines = util.split_lines(content)
  local exports = {}
  local order = {}
  local categories = {}
  local current_category

  local idx = 1
  while idx <= #lines do
    local trimmed = util.trim(lines[idx])
    local banner = trimmed:match("^//%s*([A-Z][%w%s%-]*)%s*%.?$")
    if banner then
      local cat = util.trim(banner)
      if VALID_CATEGORIES[cat] then
        current_category = cat
        if not categories[cat] then
          categories[cat] = true
          table.insert(order, cat)
        end
      end
    else
      local import_path, names = trimmed:match('^#import%s+"([^"]+)"%s*:%s*(.+)$')
      if import_path and names and import_path:match("^src/") then
        local start_line = idx
        if names:sub(1, 1) == "(" then
          local buf = { names:sub(2) }
          local close_idx = buf[1]:find("%)")
          if close_idx then
            buf[1] = buf[1]:sub(1, close_idx - 1)
          else
            local j = idx + 1
            while j <= #lines do
              local ln = lines[j]
              local rel = ln:find("%)")
              if rel then
                table.insert(buf, ln:sub(1, rel - 1))
                idx = j
                break
              end
              table.insert(buf, ln)
              j = j + 1
            end
          end
          names = table.concat(buf, " ")
        end
        for name in names:gmatch("[%w_%-]+") do
          if not exports[name] then
            exports[name] = {
              name = name,
              source = import_path,
              category = current_category,
              line = start_line,
            }
          end
        end
      end
    end
    idx = idx + 1
  end

  return {
    exports = exports,
    category_order = order,
  }
end

function M.validate_function(fn, lib_info, opts)
  opts = opts or {}
  local is_exported = lib_info.exports[fn.name] ~= nil
  if not fn.doc then
    if is_exported then
      error_at(fn.file, fn.line, "exported function `" .. fn.name .. "` has no doc block")
    end
    return
  end
  local doc = fn.doc

  if is_exported then
    local expected = lib_info.exports[fn.name].category
    if not doc.category then
      error_at(fn.file, fn.line, "exported `" .. fn.name .. "` missing @category")
    end
    if expected and doc.category ~= expected then
      error_at(fn.file, fn.line,
        string.format("@category `%s` does not match lib.typ banner `%s`", doc.category, expected))
    end
  end

  if not fn.is_value then
    local sig_names = {}
    for _, p in ipairs(fn.signature_params) do sig_names[p.name] = p end
    local doc_names = {}
    for _, p in ipairs(doc.params) do doc_names[p.name] = p end

    -- A `..args` rest binding forwards arbitrary kwargs to a delegate;
    -- the doc block then describes the *delegate's* params, so we relax
    -- both directions of the param/signature check.
    local has_variadic = false
    for _, p in ipairs(fn.signature_params) do
      if p.variadic then has_variadic = true; break end
    end
    for _, p in ipairs(fn.signature_params) do
      if not doc_names[p.name] and not p.variadic then
        error_at(fn.file, fn.line,
          string.format("@param `%s` missing from doc block for `%s`", p.name, fn.name))
      end
    end
    if not has_variadic then
      for _, p in ipairs(doc.params) do
        if not sig_names[p.name] then
          error_at(fn.file, fn.line,
            string.format("@param `%s` not in signature of `%s`", p.name, fn.name))
        end
      end
    end
  end

  if not doc.returns and not fn.is_value and not doc.is_internal then
    util.log_warn(string.format("%s:%d: `%s` missing @returns", fn.file, fn.line, fn.name))
  end

  if doc and not is_exported and not doc.is_internal and not doc.is_advanced then
    util.log_warn(string.format("%s:%d: `%s` has /// doc but is not exported (add @internal or @advanced)",
      fn.file, fn.line, fn.name))
  end
end

return M
