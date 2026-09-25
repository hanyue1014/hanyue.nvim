-- ============================================================
-- CLANGD INCLUDE PATHS
-- VS Code's `${workspaceFolder}/**`, but for clangd
--
-- clangd only knows the include paths you hand it. Without a
-- compile_commands.json it doesn't know that `<foo.h>` lives three folders
-- over. This scans the folder you opened for every directory holding
-- headers and writes them into a compile_flags.txt as `-I` lines.
--
--   :ClangdScan     scan a folder and write compile_flags.txt
--   :ClangdStatus   which config clangd would pick up for this buffer
--
-- Pure Lua (vim.fs / vim.uv), no shelling out, so it works on native
-- Windows the same as in WSL.
-- ============================================================

-- Scans that go past either limit write nothing. A whole BSP baseline has
-- 400+ include dirs; point the scan at the subfolder you're working in.
local MAX_DEPTH = 8
local MAX_DIRS = 256

-- If any of these sits between the file and the startup folder, clangd is
-- already taken care of and we stay quiet. `.clangd-ignore` is our own
-- marker for "I said no here", clangd itself doesn't know about it.
local MARKERS = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.clangd-ignore' }

local HEADER_EXTS = { h = true, hh = true, hpp = true, hxx = true, inl = true }

-- Generated or vendored trees, scanning them only adds noise
local SKIP_DIRS = { build = true, out = true, node_modules = true }

local is_windows = vim.fn.has 'win32' == 1
local home = vim.fs.normalize(vim.uv.os_homedir())

local function notify(msg, level) vim.notify('clangd: ' .. msg, level or vim.log.levels.INFO) end

-- Windows paths are case insensitive, `C:/Users` and `c:/users` are the same folder
local function same_path(a, b)
  if is_windows then return a:lower() == b:lower() end
  return a == b
end

local function exists(path) return vim.uv.fs_stat(path) ~= nil end

local function is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

local function absolute(path) return vim.fs.normalize(vim.fs.abspath(vim.fs.normalize(path))) end

-- clangd searches every parent folder for its config, with no upper bound.
-- A compile_flags.txt in $HOME or at a drive root would apply to every C
-- file on the machine.
local function is_forbidden(dir) return same_path(dir, home) or vim.fs.dirname(dir) == dir end

local function is_inside(path, dir) return same_path(path, dir) or same_path(path:sub(1, #dir + 1), dir .. '/') end

-- [[ Startup folder ]]
-- `nvim foo` does NOT cd into foo, cwd stays wherever the shell was. So:
--   nvim <dir>    that dir, made absolute (`nvim .` included)
--   nvim          the cwd
--   nvim <file>   nil, a quick edit, never prompt
-- Worked out once and remembered, a later `:cd` doesn't move it.
local startup_dir, startup_resolved = nil, false

local function get_startup_dir()
  if not startup_resolved then
    startup_resolved = true
    if vim.fn.argc() == 0 then
      startup_dir = vim.fs.normalize(vim.uv.cwd())
    elseif is_dir(vim.fn.argv(0)) then
      startup_dir = absolute(vim.fn.argv(0))
    end
  end
  return startup_dir
end

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Remember the folder nvim was started on, for :ClangdScan',
  group = vim.api.nvim_create_augroup('hanyue-clangd-startup', { clear = true }),
  once = true,
  callback = function() get_startup_dir() end,
})

-- [[ Scan ]]
-- Every directory under `root` that directly holds a header, shallowest
-- first. Bounded on both axes:
--   depth  directories MAX_DEPTH + 1 deep are peeked into but not walked.
--          If one holds headers, the tree goes deeper than we're willing to go.
--   count  more than MAX_DIRS header directories.
-- Returns the list, or nil plus a reason when a bound was hit.
local function scan(root)
  local found, too_deep = {}, nil
  local stack = { { root, 0 } }
  local visited, last_shown = 0, 0

  -- The scan blocks, so the screen only updates when told to. Shows the
  -- folder being read, at most every 50ms so drawing doesn't slow it down.
  -- No percentage, the total isn't known until the walk is done.
  local function show_progress(dir)
    local now = vim.uv.hrtime()
    if now - last_shown < 50e6 then return end
    last_shown = now
    local prefix = ('clangd: scanned %d folders, %d with headers: '):format(visited, #found)
    local rel = dir == root and '.' or dir:sub(#root + 2)
    local room = vim.v.echospace - #prefix
    if #rel > room then rel = '...' .. rel:sub(-(room - 3)) end
    vim.api.nvim_echo({ { prefix .. rel } }, false, {})
    vim.cmd.redraw()
  end

  while #stack > 0 do
    local dir, depth = unpack(table.remove(stack))
    visited = visited + 1
    show_progress(dir)
    local handle = vim.uv.fs_scandir(dir)
    local has_header = false

    while handle do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end
      local path = dir .. '/' .. name
      -- Some filesystems don't report a type, ask for it. Symlinks are
      -- left alone so a link loop can't send us in circles.
      if not type then type = (vim.uv.fs_lstat(path) or {}).type end

      if type == 'directory' and depth <= MAX_DEPTH and not name:match '^%.' and not SKIP_DIRS[name] then
        table.insert(stack, { path, depth + 1 })
      elseif type == 'file' and HEADER_EXTS[(name:match '%.([^.]+)$' or ''):lower()] then
        has_header = true
      end
    end

    if has_header then
      if depth > MAX_DEPTH then
        too_deep = too_deep or dir
      else
        table.insert(found, dir)
        if #found > MAX_DIRS then return nil, ('more than %d header directories'):format(MAX_DIRS) end
      end
    end
  end

  if too_deep then return nil, ('headers deeper than %d levels, e.g. %s'):format(MAX_DEPTH, too_deep) end

  table.sort(found, function(a, b)
    local da, db = select(2, a:gsub('/', '')), select(2, b:gsub('/', ''))
    if da ~= db then return da < db end
    return a < b
  end)
  return found
end

-- [[ Writing ]]
local function read_lines(path)
  local file = io.open(path, 'rb')
  if not file then return {} end
  local lines = vim.split(file:read '*a', '\r?\n', { trimempty = true })
  file:close()
  return lines
end

local function write_lines(path, lines)
  local file, err = io.open(path, 'wb')
  if not file then return false, err end
  file:write(table.concat(lines, '\n'), #lines > 0 and '\n' or '')
  file:close()
  return true
end

-- The .git of the repo `dir` belongs to. `.git` is a file rather than a
-- folder in submodules and worktrees, pointing at the real one.
local function git_dir(dir)
  local dot_git = vim.fs.find('.git', { upward = true, path = dir, stop = vim.fs.dirname(home) })[1]
  if not dot_git then return nil end
  if is_dir(dot_git) then return dot_git end
  local target = (read_lines(dot_git)[1] or ''):match '^gitdir:%s*(.-)%s*$'
  if not target then return nil end
  if not target:match '^/' and not target:match '^%a:' then target = vim.fs.dirname(dot_git) .. '/' .. target end
  return vim.fs.normalize(target)
end

-- No slash in the patterns, so they match at any depth in the repo
local function add_git_excludes(dir)
  local git = git_dir(dir)
  if not git then return end
  local exclude = git .. '/info/exclude'
  local lines = read_lines(exclude)
  local changed = false
  for _, pattern in ipairs { 'compile_flags.txt', '.clangd', '.clangd-ignore' } do
    if not vim.tbl_contains(lines, pattern) then
      table.insert(lines, pattern)
      changed = true
    end
  end
  if changed then
    vim.fn.mkdir(git .. '/info', 'p')
    write_lines(exclude, lines)
  end
end

local function restart_clangd()
  if #vim.lsp.get_clients { name = 'clangd' } > 0 then pcall(vim.cmd, 'lsp restart clangd') end
end

local function write_ignore(dir)
  local ok, err = write_lines(dir .. '/.clangd-ignore', {})
  if not ok then return notify('could not write .clangd-ignore: ' .. err, vim.log.levels.ERROR) end
  add_git_excludes(dir)
  notify('wrote ' .. dir .. "/.clangd-ignore, won't ask here again")
end

local function write_flags(dir)
  local found, why = scan(dir)
  if not found then
    return notify(('%s, nothing written. Re-run :ClangdScan on a narrower folder.'):format(why), vim.log.levels.WARN)
  end

  -- One -I per header folder and nothing else, the whole file is rewritten
  -- every time
  local path = dir .. '/compile_flags.txt'
  local lines = {}
  for _, include in ipairs(found) do
    table.insert(lines, '-I' .. (include == dir and '.' or include:sub(#dir + 2)))
  end

  local ok, err = write_lines(path, lines)
  if not ok then return notify('could not write compile_flags.txt: ' .. err, vim.log.levels.ERROR) end
  -- A compile_flags.txt means the earlier "no" doesn't apply anymore
  os.remove(dir .. '/.clangd-ignore')
  add_git_excludes(dir)
  notify(('wrote %d include dirs to %s'):format(#found, path))
  restart_clangd()
end

-- [[ :ClangdScan ]]
-- Asks for a folder, prefilled with the startup folder.
--   a folder     scan it, write compile_flags.txt there
--   n            write an empty .clangd-ignore in the prefilled folder,
--                so it never asks there again
--   Esc / empty  do nothing. Easy to hit by accident, so it must not write
--                anything permanent. Asks again next session, or run
--                :ClangdScan whenever.
local prompting = false

local function clangd_scan()
  if prompting then return end
  prompting = true
  local default = get_startup_dir() or vim.fs.normalize(vim.uv.cwd())

  vim.ui.input({ prompt = 'clangd: scan for headers (n to never ask here): ', default = default, completion = 'dir' }, function(input)
    prompting = false
    input = vim.trim(input or '')
    if input == '' then return notify 'skipped for now, run :ClangdScan when you want it' end

    local skip = input == 'n'
    local dir = skip and default or absolute(input)

    if is_forbidden(dir) then
      return notify(
        ('refusing to write in %s. clangd searches every parent folder, so config there would apply to every C file under it.'):format(dir),
        vim.log.levels.ERROR
      )
    end
    if not is_dir(dir) then return notify(dir .. ' is not a folder', vim.log.levels.ERROR) end

    if skip then
      write_ignore(dir)
    else
      write_flags(dir)
    end
  end)
end

vim.api.nvim_create_user_command('ClangdScan', clangd_scan, { desc = 'Scan a folder for header dirs, write compile_flags.txt' })

-- [[ Prompt on attach ]]
-- Walk up from the file towards the startup folder. Stop at whichever
-- comes first: the startup folder, a folder with .git, or $HOME. Any
-- marker on the way means clangd will find it (it searches ancestors with
-- no limit), so there's nothing to ask.
local function has_marker(file, stop)
  for dir in vim.fs.parents(file) do
    for _, marker in ipairs(MARKERS) do
      if exists(dir .. '/' .. marker) then return true end
    end
    if same_path(dir, stop) or same_path(dir, home) or exists(dir .. '/.git') then return false end
  end
  return false
end

-- Asks at most once per session on its own. The markers normally keep it
-- quiet anyway, this covers the answers that write nothing (Esc, a refused
-- folder, a scan over the limits), which would otherwise ask again on
-- every C file you open. :ClangdScan by hand always works.
local auto_prompted = false

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Offer :ClangdScan when clangd has no config for this project',
  group = vim.api.nvim_create_augroup('hanyue-clangd-scan', { clear = true }),
  callback = function(event)
    if auto_prompted then return end
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client or client.name ~= 'clangd' then return end

    -- `nvim file.c` is a quick edit, leave it alone
    local stop = get_startup_dir()
    if not stop then return end

    -- Only files inside the startup folder. Jumping to a definition in
    -- /usr/include shouldn't ask about /usr/include.
    local file = vim.api.nvim_buf_get_name(event.buf)
    if vim.bo[event.buf].buftype ~= '' or file == '' then return end
    file = vim.fs.normalize(file)
    if not is_inside(file, stop) or has_marker(file, stop) then return end

    auto_prompted = true
    vim.schedule(clangd_scan)
  end,
})

-- [[ :ClangdStatus ]]
-- clangd has no request for "which compile command did you use", that only
-- shows up in :LspLog. This repeats clangd's own lookup instead: nearest
-- parent with compile_commands.json (or build/compile_commands.json),
-- else compile_flags.txt, plus any .clangd config files on the way.
vim.api.nvim_create_user_command('ClangdStatus', function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then return notify('this buffer has no file behind it', vim.log.levels.WARN) end
  file = vim.fs.normalize(file)

  local client = vim.lsp.get_clients({ name = 'clangd', bufnr = 0 })[1]
  local root = not client and 'clangd is not attached to this buffer' or client.root_dir or 'none, single file mode'
  local lines = { 'root: ' .. root }

  local database, configs = nil, {}
  for dir in vim.fs.parents(file) do
    if not database then
      for _, candidate in ipairs { '/compile_commands.json', '/build/compile_commands.json', '/compile_flags.txt' } do
        if exists(dir .. candidate) then
          database = dir .. candidate
          break
        end
      end
    end
    if exists(dir .. '/.clangd') then table.insert(configs, dir .. '/.clangd') end
  end

  if database and database:match 'compile_flags%.txt$' then
    local count = #vim.tbl_filter(function(line) return line:match '^%-I' end, read_lines(database))
    table.insert(lines, ('flags: %s (%d include dirs)'):format(database, count))
  else
    table.insert(lines, 'flags: ' .. (database or 'none, clangd is guessing'))
  end
  table.insert(lines, 'config: ' .. (#configs > 0 and table.concat(configs, ', ') or 'none'))
  notify(table.concat(lines, '\n'))
end, { desc = 'Show which compile flags clangd picks up for this buffer' })
