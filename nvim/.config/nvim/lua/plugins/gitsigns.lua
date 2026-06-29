return {
	"lewis6991/gitsigns.nvim",
	opts = {
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")
			vim.keymap.set("n", "]h", function() gitsigns.nav_hunk("next") end, { buffer = bufnr, desc = "Next Hunk" })
			vim.keymap.set("n", "[h", function() gitsigns.nav_hunk("prev") end, { buffer = bufnr, desc = "Prev Hunk" })
		end,
	},
}
