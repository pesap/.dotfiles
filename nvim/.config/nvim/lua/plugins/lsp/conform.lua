local prettier_config = vim.fn.stdpath("config") .. "/.prettierrc.yaml"

return {
	"stevearc/conform.nvim",
	enabled = true,
	tag = "stable",
	opts = {
		formatters_by_ft = {
			markdown = { "prettier" },
		},
		formatters = {
			prettier = {
				prepend_args = { "--config", prettier_config },
			},
		},
	},
}
