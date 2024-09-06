return {
	-- Set first the colorscheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- Tpope the GOAT
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"tpope/vim-surround",
	"tpope/vim-repeat",
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	-- sqlite
	"tpope/vim-dadbod",
	"kristijanhusak/vim-dadbod-ui",
	"kristijanhusak/vim-dadbod-completion",

	-- Adds git releated signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",

	-- Text aligment
	{ "echasnovski/mini.align", version = false },

	-- HardTime
	{ "takac/vim-hardtime" },

	-- Centerpand
	{ "smithbm2316/centerpad.nvim" },

	-- Harpoon
	"theprimeagen/harpoon",

	-- GitWorktree for bare repositories
	"theprimeagen/git-worktree.nvim",

	-- Scratchpad
	{
		"LintaoAmons/scratch.nvim",
		event = "VeryLazy",
	},

	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	-- Vim Slime
	{
		"jpalardy/vim-slime",
		config = function()
			vim.g.slime_target = "zellij"
			vim.cmd([[
		let g:slime_default_config = {"session_id": "current", "relative_pane": "right"}
		]])
		end,
	},

	-- Add function line on top
	{ "nvim-treesitter/nvim-treesitter-context" },

	-- Formatter
	{
		"stevearc/conform.nvim",
		opts = {
			event = { "BufReadPre", "BufNewFile" },
		},
	},

	-- Check commands for key binding.
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		lazy = true,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},

	-- Plugins with configuration
	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", opts = {} },

	{ "folke/neoconf.nvim", cmd = "Neoconf" },

	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
	},
	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-telescope/telescope-smart-history.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			-- "kkharji/sqlite.lua",
		},
	},

	-- NOTE: This is where your plugins related to LSP can be installed.
	--  The configuration is done below. Search for lspconfig to find it below.
	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ "j-hui/fidget.nvim", tag = "legacy", opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			"folke/neodev.nvim",
		},
	},
	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			{ "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		-- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = false,
				theme = "onedark",
				component_separators = "|",
				section_separators = "",
			},
		},
	},
}
