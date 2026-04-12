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
			glob_flag = "--iglob", -- case insensitive globs
		},
		files = {
			rg_opts = { "--glob", "!*.{xml,.git,venv}" },
		},
		fzf = {
			["ctrl-q"] = "select-all+accept",
		},
	},
	config = function(_, opts)
		local builtin = require("fzf-lua")
		builtin.setup(opts)

		vim.keymap.set("n", "<leader>ff", builtin.files, { desc = "[F]ind [F]iles in project directory" })
		vim.keymap.set("n", "<leader>fb", builtin.builtin, { desc = "[F]ind [B]uiltin" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
		vim.keymap.set("n", "<leader>gr", builtin.lsp_references, { desc = "LSP: [G]o to [R]eferences" })
		vim.keymap.set("n", "<leader>gd", builtin.lsp_definitions, { desc = "LSP: [G]o to [D]efinitions" })
		vim.keymap.set("n", "<leader>gp", builtin.grep_project, { desc = "[G]rep [P]roject" })
		vim.keymap.set("n", "<leader>gg", builtin.live_grep_native, { desc = "[G]rep native" })
		vim.keymap.set("n", "<leader>gw", builtin.grep_cword, { desc = "[G]rep current [w]ord" })
		vim.keymap.set("n", "<leader>gW", builtin.grep_cWORD, { desc = "[G]rep current [W]ord" })
		vim.keymap.set("n", "<leader>/", builtin.grep_curbuf, { desc = "[G]rep current buffer" })
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
		vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "[F]ind [M]ark" })
		vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "[G]it [F]iles" })
		vim.keymap.set("n", "<leader>sb", builtin.git_branches, { desc = "[S]witch [B]ranch" })
		vim.keymap.set("n", "<leader>fn", function()
			builtin.files({ cwd = "~/.config/nvim" })
		end, { desc = "[F]ind [N]eovim" })
		vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "[F]ind [S]ymbol" })
		vim.keymap.set("n", "<leader>ws", builtin.lsp_live_workspace_symbols, { desc = "[W]orkspace [S]ymbols" })
		vim.keymap.set("n", "<leader>fd", function()
			builtin.files({ cwd = "~/dev/" })
		end, { desc = "[F]ind [D]ev Project" })
		vim.keymap.set("n", "<leader>fp", function()
			builtin.files({ prompt = "Packages ", cmd = "fd --type f . -E .git", cwd = "./packages/" })
		end, { desc = "[F]ind [P]ackage" })
		vim.keymap.set("n", "<leader>ft", function()
			builtin.files({
				prompt = "Test Files❯ ",
				cmd = "fd --type f . tests -E .git",
			})
		end, { desc = "Fuzzy find test files" })

		-- PR Review functionality
		local pr_review = { base = nil, reviewed = {}, files = {} }
		local function pr_open_picker()
			local base = pr_review.base
			local reviewed = pr_review.reviewed
			local files = pr_review.files
			local done = vim.tbl_count(reviewed)

			local entries = {}
			for _, f in ipairs(files) do
				local prefix = reviewed[f] and "[x]" or "[ ]"
				table.insert(entries, prefix .. " " .. f)
			end

			local function strip_prefix(s)
				return s:gsub("^%[.%] ", "")
			end

			builtin.fzf_exec(entries, {
				prompt = "PR (" .. base .. ") [" .. done .. "/" .. #files .. "]❯ ",
				actions = {
					["default"] = function(selected)
						local file = strip_prefix(selected[1])
						reviewed[file] = true
						vim.cmd("edit " .. file)
					end,
					["ctrl-d"] = function(selected)
						local file = strip_prefix(selected[1])
						reviewed[file] = true
						vim.cmd("edit " .. file)
						vim.cmd("Gvdiffsplit " .. base)
					end,
				},
				previewer = false,
				fzf_opts = {
					["--no-sort"] = "",
					["--preview"] = [[f="$(echo {} | sed 's/^\[.\] //')"; bat --style=numbers --color=always -- "$f" 2>/dev/null || cat -n "$f"]],
					["--preview-window"] = "right",
				},
			})
		end

		vim.keymap.set("n", "<leader>rp", function()
			if pr_review.base then
				pr_open_picker()
				return
			end
			local base = vim.fn.input("Base branch: ", "main")
			if base == "" then
				return
			end
			pr_review.base = base
			pr_review.reviewed = {}
			pr_review.files = vim.fn.systemlist("git diff --name-only " .. vim.fn.shellescape(base) .. "...HEAD")
			pr_open_picker()
		end, { desc = "[R]eview [P]R files" })

		vim.keymap.set("n", "<leader>rr", function()
			pr_review.base = nil
			pr_review.reviewed = {}
			pr_review.files = {}
			vim.notify("PR review session reset")
		end, { desc = "[R]eview [R]eset" })
	end,
}
