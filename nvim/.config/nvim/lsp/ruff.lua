-- @type vim.lsp.Config
return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = { ".git", "pyproject.toml", "requirements.txt" },
	completitions = {
		lsp = {
			enabled = true,
		},
	},
	telemetry = { enabled = true },
	init_options = {
		configurationPreference = "project",
		format = { preview = true },
	},
}
