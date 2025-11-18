return {
	"ibhagwan/fzf-lua",
	dependencies = { "echasnovski/mini.icons" },
	opts = {
		previewers = {
			builtin = {
				syntax_limit_b = 1024 * 100, --100 KB
			},
		},
		grep = {
			rg_glob = true,
			glob_glab = "--iglob", -- case insensitive globs
		},
		files = {
			rg_opts = { "--glob", "!*.{xml,.git,venv}" },
		},
		fzf = {
			["ctrl-q"] = "select-all+accept",
		},
	},
}
