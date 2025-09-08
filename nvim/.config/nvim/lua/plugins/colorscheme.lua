-- Current colorscheme of choice
return {
	"nyoom-engineering/oxocarbon.nvim",
	-- "eldritch-theme/eldritch.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		-- require("eldritch").setup({
		-- 	transparent = true, -- Set to true for transparency
		-- })
		vim.opt.background = "dark"
		vim.cmd.colorscheme("oxocarbon")
	end,
}
