return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets" },
	version = "1.*",
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		fuzzy = { implementation = "prefer_rust_with_warning" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		appearance = {
			nerd_font_variant = "mono",
		},
		completion = {
			keyword = { range = "full" },

			accept = { auto_brackets = { enabled = false } },

			list = { selection = { preselect = true, auto_insert = true } },
			documentation = { auto_show = false },
		},
		keymap = {
			preset = "default",
			["<Tab>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<C-k>"] = { "show_signature", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["C-n"] = { "snippet_backward", "fallback" },
			["C-p"] = { "snippet_backward", "fallback" },
		},
	},
	opts_extend = { "sources.default" },
}
