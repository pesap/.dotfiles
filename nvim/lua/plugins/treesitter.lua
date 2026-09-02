-- Parser for file types
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			auto_install = false,
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
				"kdl",
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ao"] = "@comment.outer",
						["ic"] = "@class.inner",
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]m"] = "@function.outer",
						["]]"] = "@class.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
						["]["] = "@class.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer",
						["[["] = "@class.outer",
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
						["[]"] = "@class.outer",
					},
				},
				swap = {
					enable = true,
					swap_next = {
						["<leader>a"] = "@parameter.inner",
					},
					swap_previous = {
						["<leader>A"] = "@parameter.inner",
					},
				},
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

		-- Work around markdown injection crash in Neovim treesitter highlighter.
		vim.treesitter.query.set("markdown", "injections", "")
	end,
}
