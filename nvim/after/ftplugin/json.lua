vim.keymap.set({ "n", "v" }, ",f", ":JSONFormat<cr>", {
  buffer = true,
  silent = true,
})
