vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Open file tree
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Close buffer
vim.keymap.set("n", "<leader>q", ":bd<CR>")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move text around
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Half page and top page jump
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep cursos in the middle when searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Never press Q
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "q", "<nop>")

vim.keymap.set(
	"n",
	"<leader>sr",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "[S]earch[R]eplace word undercursors" }
)

vim.keymap.set("t", "<", "<C-\\><C-n><C-w>h", { silent = true })

-- Stop being a silly
vim.keymap.set("n", ":Wq", ":wq")
vim.keymap.set("n", ":Q", ":q")
