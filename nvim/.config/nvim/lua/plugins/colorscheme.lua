-- Current colorscheme of choice
return {
	"jpwol/thorn.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		vim.cmd.colorscheme("thorn")
	end,
}
