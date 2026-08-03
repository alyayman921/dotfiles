local M = {}

local function get_work_dir()
  local dir = vim.fs.joinpath(vim.fn.getcwd(), ".nvim")
  vim.fn.mkdir(dir, "p")
  return dir
end

-- Mimic sublime's save_open_tabs: write currently open file buffers to the
-- next setN.txt file (N = highest existing + 1).
function M.save_open_buffers()
  local paths = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buftype") == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(paths, name)
      end
    end
  end

  if #paths == 0 then
    vim.notify("Save Open Buffers: no named buffers to write out.", vim.log.levels.WARN)
    return
  end

  local dir = get_work_dir()
  local next_n = 1
  while vim.fn.filereadable(vim.fs.joinpath(dir, "set" .. next_n .. ".txt")) == 1 do
    next_n = next_n + 1
  end

  local out_path = vim.fs.joinpath(dir, "set" .. next_n .. ".txt")
  local f = io.open(out_path, "w")
  if not f then
    vim.notify("Save Open Buffers: could not write list: " .. out_path, vim.log.levels.ERROR)
    return
  end
  f:write(table.concat(paths, "\n"))
  f:close()

  vim.notify(string.format("Saved %d open buffer(s) to %s", #paths, out_path))
end

-- Mimic sublime's load_tab_set: save dirty buffers, then close all buffers and
-- reopen the ones listed in setN.txt.
function M.load_buffer_set(n)
  local target_dir = get_work_dir()
  local list_path = vim.fn.fnamemodify(target_dir, ":p") .. "set" .. n .. ".txt"

  if vim.fn.filereadable(list_path) == 0 then
    vim.notify(string.format("Load Buffer Set: %s not found", list_path), vim.log.levels.WARN)
    return
  end

  -- Save any dirty, file-backed buffers before wiping.
  local skipped = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "modified") then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent write!")
        end)
      else
        table.insert(skipped, vim.api.nvim_buf_get_name(buf))
      end
    end
  end

  if #skipped > 0 then
    vim.notify(
      "Load Buffer Set: skipped unsaved buffer(s): " .. table.concat(skipped, ", "),
      vim.log.levels.WARN
    )
  end

  local f = io.open(list_path, "r")
  if not f then
    vim.notify("Load Buffer Set: could not read: " .. list_path, vim.log.levels.ERROR)
    return
  end
  local contents = f:read("*a")
  f:close()

  -- Collapse to a single window so no other window keeps a buffer alive.
  vim.cmd("silent only")
  vim.cmd("silent tabonly")

  local paths = vim.split(contents, "\n", { trimempty = true })

  if #paths > 0 then
    -- Open the set files; each becomes a new (or re-matched) buffer.
    for _, p in ipairs(paths) do
      vim.cmd("edit " .. vim.fn.fnameescape(p))
    end

    -- Build the set of buffers that should survive: the just-opened files.
    local wanted = {}
    for _, p in ipairs(paths) do
      wanted[vim.fn.fnameescape(vim.fn.fnamemodify(p, ":p"))] = true
    end
    local function is_wanted(buf)
      local path = vim.fn.fnameescape(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p"))
      return wanted[path]
    end

    -- If the current window still shows the unnamed default buffer (for
    -- example when a set entry failed to open), switch to an imported buffer
    -- first. Deleting the buffer shown in the only window would close the last
    -- window and quit nvim.
    local cur_buf = vim.api.nvim_win_get_buf(0)
    if vim.api.nvim_buf_get_name(cur_buf) == "" then
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= cur_buf and is_wanted(buf) then
          vim.cmd("buffer " .. buf)
          cur_buf = vim.api.nvim_win_get_buf(0)
          break
        end
      end
    end

    -- Wipe every buffer that is not one of the just-opened set files (this
    -- also closes the leftover empty default buffer), but never the buffer
    -- shown in the current window (deleting it would close the last window and
    -- quit nvim).
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= cur_buf and not is_wanted(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

function M.delete_buffer_set(n)
  local list_path = vim.fs.joinpath(get_work_dir(), "set" .. n .. ".txt")

  if vim.fn.filereadable(list_path) == 0 then
    vim.notify(string.format("Delete Buffer Set: %s not found", list_path), vim.log.levels.WARN)
    return
  end

  vim.fn.delete(list_path)
  vim.notify(string.format("Deleted buffer set %d (%s)", n, list_path))
end

return M