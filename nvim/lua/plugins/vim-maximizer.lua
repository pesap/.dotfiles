return {
	"szw/vim-maximizer",
	config = function()
		vim.keymap.set("n", "<leader>wm", "<cmd>MaximizerToggle<CR>", { desc = "[W]indow [M]aximize/[M]inimize a split" })
	end,
}
