local glance = require("glance")

glance.setup {
  height = 25,
  border = {
    enable = true,
  },
}

vim.keymap.set("n", "<leader>gd", "<cmd>Glance definitions<cr>")
vim.keymap.set("n", "<leader>gr", "<cmd>Glance references<cr>")
vim.keymap.set("n", "<leader>gi", "<cmd>Glance implementations<cr>")
