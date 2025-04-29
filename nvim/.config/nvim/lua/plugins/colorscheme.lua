-- Current colorscheme of choice
return {
	"srt0/everblush.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("everblush").setup({
			transparent = false, -- Set to true for transparency
		})
		vim.cmd.colorscheme("everblush")
	end,
}
