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

  -- Make sure the current window is a normal one before collapsing. If the
  -- cursor is in the nvim-tree window, `:only` keeps that window and the later
  -- `:edit` takes over the tree's window, which makes nvim-tree re-open itself
  -- and can leave nvim with only an NvimTree window (which then auto-quits).
  local cur_buf = vim.api.nvim_win_get_buf(0)
  local cur_buftype = vim.api.nvim_get_option_value("buftype", { buf = cur_buf })
  if cur_buftype ~= "" then
    local switched = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
        vim.api.nvim_set_current_win(win)
        switched = true
        break
      end
    end
    if not switched then
      vim.cmd("vsplit")
      vim.cmd("enew")
    end
  end

  -- Collapse to a single window so no other window keeps a buffer alive.
  vim.cmd("silent only")
  vim.cmd("silent tabonly")

  local paths = vim.split(contents, "\n", { trimempty = true })

  if #paths > 0 then
    local function canonical(p)
      return vim.fn.fnameescape(vim.fn.fnamemodify(p, ":p"))
    end
    local function is_listed(buf)
      return vim.api.nvim_get_option_value("buflisted", { buf = buf })
    end

    -- Map each open (listed) buffer to its canonical path, so that buffers
    -- which are already open can be reused as-is (preserving undo history).
    local path_to_buf = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if is_listed(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" then
          path_to_buf[canonical(name)] = buf
        end
      end
    end

    -- Reuse already-open buffers (preserving undo history) when they are
    -- already in the saved order.
    local function order_already_matches()
      local listed = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if is_listed(buf) then
          table.insert(listed, buf)
        end
      end
      if #listed ~= #paths then
        return false
      end
      for i, p in ipairs(paths) do
        if listed[i] ~= path_to_buf[canonical(p)] then
          return false
        end
      end
      return true
    end

    if order_already_matches() then
      -- The buffers are already open, in the saved order: just switch to the
      -- first one of the set.
      vim.cmd("buffer " .. path_to_buf[canonical(paths[1])])
      return
    end

    -- Otherwise rebuild the buffer list from scratch so buffers come back in
    -- the exact order they were saved in. Switch to a scratch buffer first so
    -- that every listed buffer can be wiped without closing the last window.
    vim.cmd("enew")
    local cur_buf = vim.api.nvim_win_get_buf(0)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= cur_buf and is_listed(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end

    -- Open the set files in order; each becomes a fresh buffer appended to the
    -- end of the buffer list, restoring the saved order. Never touch unlisted
    -- plugin buffers (e.g. nvim-tree, which re-opens itself otherwise).
    for _, p in ipairs(paths) do
      vim.cmd("edit " .. vim.fn.fnameescape(p))
    end

    -- The scratch buffer above is normally reused by the first `:edit`; if a
    -- leftover empty buffer remains, wipe it (it is no longer shown in the
    -- window, so deleting it cannot close the last window).
    local cur_buf = vim.api.nvim_win_get_buf(0)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= cur_buf and is_listed(buf) and vim.api.nvim_buf_get_name(buf) == "" then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end

    -- Switch to the first buffer of the set.
    local first = canonical(paths[1])
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if is_listed(buf) and canonical(vim.api.nvim_buf_get_name(buf)) == first then
        vim.cmd("buffer " .. buf)
        break
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