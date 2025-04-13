-- Parser for file types
return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			auto_install = { enable = false },
			highlight = { enable = true },
			indent = { enable = true },
			sync_install = false,
			ensure_installed = {
				"c",
				"lua",
				"luadoc",
				"vim",
				"vimdoc",
				"python",
				"julia",
				"rust",
				"cpp",
				"html",
				"markdown",
				"markdown_inline",
				"sql",
				"xml",
				"csv",
				"json",
				"jq",
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<Enter>",
					node_incremental = "<Enter>",
					node_decremental = "<Backspace>",
					scope_incremental = "<S-CR>",
				},
			},
		})
	end,
}
