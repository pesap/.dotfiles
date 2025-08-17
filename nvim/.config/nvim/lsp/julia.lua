return {
	cmd = {
		"julia",
		"--startup-file=no",
		"--history-file=no",
		vim.fn.expand("~/.config/nvim/after/julia-ls.jl"),
	},
	filetypes = { "julia" },
	root_markers = { "Project.toml", "Manifest.toml", ".git" },
	settings = {},
}
