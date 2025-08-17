return {
	"sj2tpgk/nvim-eldoc",
	event = "CursorHold",
	lazy = true,
	init = function()
		vim.opt.updatetime = 700
	end,
	config = function()
		require("nvim-eldoc").setup()
		vim.cmd([[
			hi link Eldoc Normal
			hi link EldocCur Identifier
		]])
	end,
}
