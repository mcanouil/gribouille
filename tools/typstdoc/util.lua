local M = {}

function M.read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  return content
end

function M.write_file(path, content)
  local dir = path:match("^(.*)/[^/]+$")
  if dir and dir ~= "" then
    os.execute(string.format("mkdir -p %q", dir))
  end
  local f, err = io.open(path, "w")
  if not f then return nil, err end
  f:write(content)
  f:close()
  return true
end

function M.file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

function M.remove_file(path)
  os.execute(string.format("rm -f %q", path))
end

function M.remove_dir(path)
  os.execute(string.format("rm -rf %q", path))
end

function M.make_dir(path)
  os.execute(string.format("mkdir -p %q", path))
end

function M.find_typ_files(root)
  local cmd = string.format("find %q -name '*.typ' -type f 2>/dev/null", root)
  local handle = io.popen(cmd)
  if not handle then
    error("typstdoc: could not run `find`; macOS/Linux with `find` in PATH is required")
  end
  local out = handle:read("*a")
  handle:close()
  local files = {}
  for line in out:gmatch("[^\n]+") do
    table.insert(files, line)
  end
  table.sort(files)
  return files
end

function M.split_lines(text)
  local lines = {}
  local start = 1
  local len = #text
  while start <= len do
    local nl = text:find("\n", start, true)
    if nl then
      table.insert(lines, text:sub(start, nl - 1))
      start = nl + 1
    else
      table.insert(lines, text:sub(start))
      break
    end
  end
  if text:sub(-1) == "\n" then
    table.insert(lines, "")
  end
  return lines
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function M.slugify(s)
  local out = s:lower():gsub("[^%w]+", "-"):gsub("^%-", ""):gsub("%-$", "")
  return out
end

function M.basename_no_ext(path)
  local name = path:match("([^/]+)%.[^./]+$") or path:match("([^/]+)$") or path
  return name
end

function M.log_info(msg)
  io.stderr:write("typstdoc: " .. msg .. "\n")
end

function M.log_warn(msg)
  io.stderr:write("typstdoc: warning: " .. msg .. "\n")
end

function M.log_err(msg)
  io.stderr:write("typstdoc: error: " .. msg .. "\n")
end

return M
