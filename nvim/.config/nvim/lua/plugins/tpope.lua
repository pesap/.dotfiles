-- Plugin responsable of making sure that we use correct tabs or spaces
return {
	{ "tpope/vim-fugitive", config = function()
		vim.keymap.set("n", "<leader>gb", vim.cmd.GBrowse, { desc = "[G]it [B]rowse" })
		vim.keymap.set("n", "<leader>gd", vim.cmd.Gdiff, { desc = "[G]it [D]iff" })

		local gitlog_buf = nil
		vim.keymap.set("n", "<leader>gl", function()
			if gitlog_buf and vim.api.nvim_buf_is_valid(gitlog_buf) then
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == gitlog_buf then
						vim.api.nvim_win_close(win, true)
					end
				end
				gitlog_buf = nil
				return
			end
			vim.cmd("Git log %")
			gitlog_buf = vim.api.nvim_get_current_buf()
		end, { desc = "[G]it [l]og (toggle Fugitive)" })

		vim.keymap.set("n", "<leader>gs", function()
			local fugitive_buf = nil
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) then
					local buf_name = vim.api.nvim_buf_get_name(buf)
					if buf_name:match("fugitive://") then
						fugitive_buf = buf
						break
					end
				end
			end
			if fugitive_buf then
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == fugitive_buf then
						vim.api.nvim_win_close(win, true)
					end
				end
			else
				vim.cmd("Git")
			end
		end, { desc = "[G]it [S]tatus (Fugitive)" })

		vim.api.nvim_create_user_command("ReviewPR", function(opts)
			local base = opts.args ~= "" and opts.args or "main"
			vim.cmd("enew")
			vim.bo.buftype = "nofile"
			vim.bo.bufhidden = "wipe"
			vim.bo.filetype = "git"
			vim.cmd("r !git diff --name-status " .. vim.fn.shellescape(base) .. "...HEAD")
			vim.cmd("1d")
			vim.api.nvim_buf_set_name(0, "PR Review (" .. base .. ")")
		end, {
			nargs = "?",
			complete = function()
				local branches = vim.fn.systemlist("git branch -a --format='%(refname:short)'")
				return branches
			end,
			desc = "List files changed vs base branch (default: main)",
		})
	end },
	"tpope/vim-sleuth",
	"tpope/vim-rhubarb",
	"tpope/vim-surround",
	"tpope/vim-repeat",
}
