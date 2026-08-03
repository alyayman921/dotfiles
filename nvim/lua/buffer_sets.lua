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

  -- Close everything currently open.
  vim.cmd("tabdo silent! %bwipeout!")

  local paths = vim.split(contents, "\n", { trimempty = true })
  for _, p in ipairs(paths) do
    vim.fn.fnameescape(p)
  end

  if #paths > 0 then
    for _, p in ipairs(paths) do
      vim.cmd("edit " .. vim.fn.fnameescape(p))
    end
    local shown = vim.api.nvim_win_get_buf(0)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) == "" and buf ~= shown then
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