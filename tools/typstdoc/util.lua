local M = {}

local function log(prefix, msg)
  io.stderr:write("typstdoc: " .. prefix .. msg .. "\n")
end

function M.log_info(msg) log("", msg) end
function M.log_warn(msg) log("warning: ", msg) end
function M.log_err(msg) log("error: ", msg) end

function M.die(msg)
  error("typstdoc: " .. msg, 0)
end

-- Run a shell command and die on failure. `os.execute` returns true/nil on
-- Lua 5.2+ and an exit-status number on 5.1; accept both conventions.
function M.run(cmd)
  local ok = os.execute(cmd)
  if ok ~= true and ok ~= 0 then
    M.die("command failed: " .. cmd)
  end
end

function M.ensure_parent(path)
  local dir = path:match("^(.*)/[^/]+$")
  if dir and dir ~= "" then
    M.run(string.format("mkdir -p %q", dir))
  end
end

function M.read_file(path)
  local f, err = io.open(path, "rb")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  return content
end

function M.copy_file(src, dst)
  local content, err = M.read_file(src)
  if not content then return nil, err end
  return M.write_file(dst, content)
end

function M.popen_capture(cmd)
  local handle = io.popen(cmd)
  if not handle then return nil, "popen failed" end
  local out = handle:read("*a")
  local _, _, code = handle:close()
  return code or 0, out
end

function M.write_file(path, content)
  M.ensure_parent(path)
  local f, err = io.open(path, "wb")
  if not f then return nil, err end
  f:write(content)
  f:close()
  return true
end

function M.file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

function M.dir_exists(path)
  local handle = io.popen(string.format("test -d %q && echo yes 2>/dev/null", path))
  if not handle then return false end
  local out = handle:read("*a")
  handle:close()
  return out:match("yes") ~= nil
end

function M.remove_dir(path)
  M.run(string.format("rm -rf %q", path))
end

-- Best-effort cleanup: the target tree may not exist yet, so `find` failures
-- are deliberately ignored.
function M.remove_generated_files(path, pattern)
  os.execute(string.format("find %q -type f -name %q -delete 2>/dev/null", path, pattern))
  os.execute(string.format("find %q -mindepth 1 -type d -empty -delete 2>/dev/null", path))
end

function M.make_dir(path)
  M.run(string.format("mkdir -p %q", path))
end

local function popen_lines(cmd)
  local handle = io.popen(cmd)
  if not handle then M.die("could not run: " .. cmd) end
  local out = handle:read("*a")
  handle:close()
  return out
end

function M.find_typ_files(root)
  local out = popen_lines(string.format("find %q -name '*.typ' -type f 2>/dev/null", root))
  local files = {}
  for line in out:gmatch("[^\n]+") do files[#files + 1] = line end
  table.sort(files)
  return files
end

function M.list_dir_files(dir)
  local out = popen_lines(string.format("find %q -maxdepth 1 -type f 2>/dev/null", dir))
  local names = {}
  for path in out:gmatch("[^\n]+") do
    local name = path:match("([^/]+)$")
    if name and not name:match("^%.") then names[#names + 1] = name end
  end
  table.sort(names)
  return names
end

function M.split_lines(text)
  local lines = {}
  local start = 1
  local len = #text
  while start <= len do
    local nl = text:find("\n", start, true)
    if nl then
      lines[#lines + 1] = text:sub(start, nl - 1)
      start = nl + 1
    else
      lines[#lines + 1] = text:sub(start)
      break
    end
  end
  if text:sub(-1) == "\n" then lines[#lines + 1] = "" end
  return lines
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.slugify(s)
  return (s:lower():gsub("[^%w]+", "-"):gsub("^%-", ""):gsub("%-$", ""))
end

function M.find_balanced_block(text, header_pattern)
  local start = text:find(header_pattern)
  if not start then return nil end
  local open_paren = text:find("[%({]", start)
  if not open_paren then return nil end
  local opener = text:sub(open_paren, open_paren)
  local closer = (opener == "(") and ")" or "}"
  local depth = 0
  local in_string = false
  local string_char
  local i = open_paren
  local len = #text
  while i <= len do
    local c = text:sub(i, i)
    if in_string then
      if c == "\\" and i < len then
        i = i + 2
      else
        if c == string_char then in_string = false end
        i = i + 1
      end
    elseif c == '"' or c == "'" then
      in_string = true
      string_char = c
      i = i + 1
    elseif c == "/" and text:sub(i + 1, i + 1) == "/" then
      local nl = text:find("\n", i, true)
      i = (nl or len) + 1
    elseif c == opener then
      depth = depth + 1
      i = i + 1
    elseif c == closer then
      depth = depth - 1
      if depth == 0 then return text:sub(open_paren + 1, i - 1) end
      i = i + 1
    else
      i = i + 1
    end
  end
  return nil
end

return M
