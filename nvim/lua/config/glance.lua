local glance = require("glance")

glance.setup {
  height = 25,
  border = {
    enable = true,
  },
}

vim.keymap.set("n", ",gd", "<cmd>Glance definitions<cr>")
vim.keymap.set("n", ",gr", "<cmd>Glance references<cr>")
vim.keymap.set("n", ",gi", "<cmd>Glance implementations<cr>")
