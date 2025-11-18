vim.keymap.set("n", "<leader>d", function()
	local file = vim.api.nvim_buf_get_name(0)
	if file ~= "" then
		vim.cmd("Documented! " .. vim.fn.fnameescape(file))
	else
		vim.notify("No file associated with current buffer", vim.log.levels.WARN)
	end
end, { desc = "Run :Documented with current file" })
