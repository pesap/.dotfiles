return {
	"stevearc/conform.nvim",
	enabled = true,
	tag = "stable",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
			sh = { "shfmt" },
		},
		stop_after_first = false,
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 1000,
		},
	},
}
