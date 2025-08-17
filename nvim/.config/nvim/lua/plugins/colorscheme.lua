-- Current colorscheme of choice
return {
	"eldritch-theme/eldritch.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("eldritch").setup({
			transparent = true, -- Set to true for transparency
		})
		vim.cmd.colorscheme("eldritch")
	end,
}
