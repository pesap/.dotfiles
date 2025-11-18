vim.keymap.set("n", "<leader>gb", vim.cmd.GBrowse, { desc = "[G]it [B]rowse" })
-- vim.keymap.set("n", "<leader>gb", vim.cmd.Gblame, { desc = "[G]it [B]lame" })
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

	-- Open Git log for current file
	vim.cmd("Git log %")

	-- Save the new buffer
	gitlog_buf = vim.api.nvim_get_current_buf()
end, { desc = "[G]it [l]og (toggle Fugitive)" })

vim.keymap.set("n", "<leader>gs", function()
	-- Check if a Fugitive buffer is open
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
		-- Close Fugitive window
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == fugitive_buf then
				vim.api.nvim_win_close(win, true)
			end
		end
	else
		-- Open Git status
		vim.cmd("Git")
	end
end, { desc = "[G]it [S]tatus (Fugitive)" })
