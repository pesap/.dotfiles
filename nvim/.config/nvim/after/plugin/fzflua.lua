local builtin = require("fzf-lua")

vim.keymap.set("n", "<leader>ff", builtin.files, { desc = "[F]ind [F]iles in project directory" })
vim.keymap.set("n", "<leader>fb", builtin.builtin, { desc = "[F]ind [B]uiltin" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
vim.keymap.set("n", "<leader>gr", builtin.lsp_references, { desc = "LSP: [G]o to [R]eferences" })
vim.keymap.set("n", "<leader>gd", builtin.lsp_definitions, { desc = "LSP: [G]o to [D]efinitions" })
vim.keymap.set("n", "<leader>gp", builtin.grep_project, { desc = "[G]rep [P]roject" })
vim.keymap.set("n", "<leader>gg", builtin.live_grep_native, { desc = "[G]rep native" })
vim.keymap.set("n", "<leader>gw", builtin.grep_cword, { desc = "[G]rep current [w]ord" })
vim.keymap.set("n", "<leader>gW", builtin.grep_cWORD, { desc = "[G]rep current [W]ord" })
vim.keymap.set("n", "<leader>/", builtin.grep_curbuf, { desc = "[G]rep current buffer" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "[F]ind [M]ark" })
vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "[G]it [F]iles" })
vim.keymap.set("n", "<leader>sb", builtin.git_branches, { desc = "[S]witch [B]ranch" })
vim.keymap.set("n", "<leader>fn", function()
	builtin.files({ cwd = "~/.config/nvim" })
end, { desc = "[F]ind [N]eovim" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "[F]ind [S]ymbol" })

vim.keymap.set("n", "<leader>fd", function()
	builtin.files({ cwd = "~/dev/" })
end, { desc = "[F]ind [D]ev Project" })

vim.keymap.set("n", "<leader>fp", function()
	builtin.files({ prompt = "Packages ", cmd = "fd --type f . -E .git", cwd = "./packages/" })
end, { desc = "[F]ind [P]ackage" })

vim.keymap.set("n", "<leader>ft", function()
	builtin.files({
		prompt = "Test Files❯ ",
		cmd = "fd --type f . tests -E .git", -- search only inside tests/
	})
end, { desc = "Fuzzy find test files" })
