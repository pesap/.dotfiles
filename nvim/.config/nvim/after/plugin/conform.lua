local conform = require("conform")
conform.setup({
	formatters_by_ft = {
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		lua = { "stylua" },
		python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
		sh = { "shfmt" },
	},
	stop_after_first = false,
	format_on_save = {
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000, -- default: 1000
	},
})
