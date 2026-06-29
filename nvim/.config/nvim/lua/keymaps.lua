vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "v" }, "s", "<Nop>", { silent = true })

-- Resource file
vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>", { desc = "Source file" })

-- Open file tree
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Close buffer
vim.keymap.set("n", "<leader>qq", ":bd<CR>", { desc = "Close current buffer" })
vim.keymap.set("n", "<leader>qo", ":%bd|e#<CR>", { desc = "Close all buffers but the one I am on" })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move text around
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Half page and top page jump
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
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
	{ desc = "[S]earch[R]eplace word undercursors (curent file)" }
)

vim.keymap.set(
	"n",
	"<leader>sp",
	[[:silent! grep! "\<<C-r><C-w>\>" . | copen<CR>]],
	{ desc = "[S]earch [P]roject-wide word under cursor" }
)
vim.keymap.set(
	"n",
	"<leader>srp",
	[[:cfdo %s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "[S]earch [R]eplace [P]roject-wide word under cursor" }
)

vim.keymap.set("n", "<leader>qf", ":copen<CR>", { desc = "[Q]uick[f]ix open" })
vim.keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "[Q]uickfix [c]lose" })
vim.keymap.set("n", "<leader>qj", ":cnext<CR>zz", { desc = "[Q]uickfix [j]next (centered)" })
vim.keymap.set("n", "<leader>qk", ":cprev<CR>zz", { desc = "[Q]uickfix [k]prev (centered)" })
vim.keymap.set("n", "<leader>qh", ":cfirst<CR>", { desc = "[Q]uickfix [h]first" })
vim.keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "[Q]uickfix [l]last" })

vim.keymap.set("t", "<", "<C-\\><C-n><C-w>h", { silent = true })

-- Stop being a silly
vim.keymap.set("n", ":Wq", ":wq")
vim.keymap.set("n", ":Q", ":q")

-- Search improvements
-- Don't jump on * search (keep position)
vim.keymap.set("n", "*", "*N", { desc = "Search word (no jump)" })
vim.keymap.set("n", "#", "#N", { desc = "Search word backward (no jump)" })
-- Clear search highlight
vim.keymap.set("n", "<Esc>", ":noh<CR>", { desc = "Clear search highlight" })
-- Visual mode search for selection
vim.keymap.set("v", "//", 'y/<C-R>"<CR>', { desc = "Search for selection" })
vim.keymap.set("n", "<leader>sd", function()
	vim.diagnostic.open_float()
end, { desc = "[S]ee [D]iagnostic" })

-- Force to use hjkl
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Split windows
vim.keymap.set("n", "<leader>-", "<cmd>split<CR>")
vim.keymap.set("n", "<leader>_", "<cmd>vsplit<CR>")
vim.keymap.set("n", "zz", function()
	return "zt" .. math.floor(vim.fn.winheight(0) / 4) .. "<C-y>"
end, { expr = true, desc = "Scroll current line to top + offset" })

vim.keymap.set("n", "<leader>ww", "<C-w><C-w>", { silent = true })

-- Go to file with line number support
local goto_file = require("utils.goto_file")
vim.keymap.set({ "n", "v" }, "<leader>gF", function()
    local mode = vim.fn.mode()
    goto_file.goto_file({ mode = mode })
end, { desc = "[G]o to [F]ile with line number" })
