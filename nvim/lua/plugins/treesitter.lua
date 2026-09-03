-- Parser installation and Tree-sitter features for Neovim 0.12+
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
		},
	},
	config = function()
		local treesitter = require("nvim-treesitter")
		local languages = {
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
		}

		treesitter.setup()
		treesitter.install(languages)

		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
			move = {
				set_jumps = true,
			},
		})

		local function select_textobject(query)
			return function()
				require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
			end
		end

		for key, query in pairs({
			aa = "@parameter.outer",
			ia = "@parameter.inner",
			af = "@function.outer",
			["if"] = "@function.inner",
			ac = "@class.outer",
			ic = "@class.inner",
			ao = "@comment.outer",
		}) do
			vim.keymap.set({ "x", "o" }, key, select_textobject(query))
		end

		local move = require("nvim-treesitter-textobjects.move")
		local move_keys = {
			["]m"] = { "goto_next_start", "@function.outer" },
			["]]"] = { "goto_next_start", "@class.outer" },
			["]M"] = { "goto_next_end", "@function.outer" },
			["]["] = { "goto_next_end", "@class.outer" },
			["[m"] = { "goto_previous_start", "@function.outer" },
			["[["] = { "goto_previous_start", "@class.outer" },
			["[M"] = { "goto_previous_end", "@function.outer" },
			["[]"] = { "goto_previous_end", "@class.outer" },
		}
		for key, value in pairs(move_keys) do
			vim.keymap.set({ "n", "x", "o" }, key, function()
				move[value[1]](value[2], "textobjects")
			end)
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"c",
				"lua",
				"python",
				"julia",
				"rust",
				"cpp",
				"html",
				"markdown",
				"sql",
				"xml",
				"csv",
				"json",
				"jq",
				"kdl",
			},
			callback = function(args)
				vim.treesitter.start(args.buf)
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})

		-- Work around markdown injection crash in Neovim treesitter highlighter.
		vim.treesitter.query.set("markdown", "injections", "")
	end,
}
