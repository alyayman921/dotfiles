require("fzf-lua").setup {
  defaults = {
    file_icons = "mini",
  },
  winopts = {
    row = 0.5,
    height = 0.7,
  },
  files = {
    previewer = false,
    git_icons = true,
    -- show gitignored files as well (e.g., `.env`, build outputs)
    no_ignore = true,
    -- keep the nvim-config venv out of the picker
    file_ignore_patterns = { "%.venv/" },
  },
  grep = {
    RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
  },
}

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files" })
vim.keymap.set(
  "n",
  "<leader>fnf",
  "<cmd>FzfLua files cwd=~/.config/nvim<cr>",
  { desc = "Fuzzy find files in nvim config" }
)
vim.keymap.set(
  "n",
  "<leader>fng",
  "<cmd>FzfLua live_grep_native cwd=~/.config/nvim<cr>",
  { desc = "Fuzzy grep files in nvim config" }
)
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep_native<cr>", { desc = "Fuzzy grep files" })
vim.keymap.set(
  "n",
  "<leader>fh",
  "<cmd>FzfLua helptags<cr>",
  { desc = "Fuzzy grep tags in help files" }
)
vim.keymap.set(
  "n",
  "<leader>ft",
  "<cmd>FzfLua lsp_document_symbols<cr>",
  { desc = "Fuzzy search buffer tags" }
)
vim.keymap.set(
  "n",
  "<leader>fb",
  "<cmd>FzfLua buffers<cr>",
  { desc = "Fuzzy search opened buffers" }
)
vim.keymap.set(
  "n",
  "<leader>fr",
  "<cmd>FzfLua oldfiles<cr>",
  { desc = "Fuzzy search opened files history" }
)
