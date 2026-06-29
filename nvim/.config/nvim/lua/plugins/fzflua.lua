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
		lsp = {
			jump1 = true,
			symbols = {
				symbol_style = 2,
			},
			finder = {
				prompt = "LSP❯ ",
			},
			code_actions = {
				previewer = "codeaction",
			},
		},
		diagnostics = {
			multiline = 2,
		},
	},
	config = function(_, opts)
		local builtin = require("fzf-lua")
		builtin.setup(opts)

		vim.keymap.set("n", "<leader>fb", builtin.builtin, { desc = "[F]ind [B]uiltin" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
		vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "[F]ind [M]ark" })
		vim.keymap.set("n", "<leader>sb", builtin.git_branches, { desc = "[S]witch [B]ranch" })

		vim.keymap.set("n", "<leader>fl", builtin.lsp_finder, { desc = "[F]ind [L]SP locations" })
		vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { desc = "[F]ind [D]efinitions" })
		vim.keymap.set("n", "<leader>fD", builtin.lsp_declarations, { desc = "[F]ind [D]eclarations" })
		vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "[F]ind [R]eferences" })
		vim.keymap.set("n", "<leader>fi", builtin.lsp_implementations, { desc = "[F]ind [I]mplementations" })
		vim.keymap.set("n", "<leader>fT", builtin.lsp_typedefs, { desc = "[F]ind [T]ype definitions" })
		vim.keymap.set({ "n", "x" }, "<leader>fa", builtin.lsp_code_actions, { desc = "[F]ind code [A]ctions" })
		vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "[F]ind document [S]ymbols" })
		vim.keymap.set("n", "<leader>fS", builtin.lsp_live_workspace_symbols, { desc = "[F]ind workspace [S]ymbols" })
		vim.keymap.set("n", "<leader>fe", builtin.diagnostics_document, { desc = "[F]ind document diagnostics" })
		vim.keymap.set("n", "<leader>fE", builtin.diagnostics_workspace, { desc = "[F]ind workspace diagnostics" })
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

		vim.keymap.set("n", "<leader>rf", function()
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
		end, { desc = "[R]eview [F]iles" })

		vim.keymap.set("n", "<leader>rr", function()
			pr_review.base = nil
			pr_review.reviewed = {}
			pr_review.files = {}
			vim.notify("PR review session reset")
		end, { desc = "[R]eview [R]eset" })
	end,
}
