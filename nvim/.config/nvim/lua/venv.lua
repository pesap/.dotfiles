local function activate_venv()
	local root_path = vim.fn.getcwd() -- Get the current working directory
	local venv_path = root_path .. "/.venv/bin/activate"

	local function file_exists(path)
		local f = io.open(path, "rb")
		if f then
			f:close()
			return true
		else
			return false
		end
	end

	if file_exists(venv_path) then
		local command = "source " .. venv_path
		local handle = vim.fn.jobstart(command, {
			on_exit = function(job_id, exit_code, signal)
				if exit_code == 0 then
					vim.notify("Virtual environment activated.", vim.log.levels.INFO, {})
				else
					vim.notify(
						"Error activating virtual environment (exit code: " .. exit_code .. ").",
						vim.log.levels.ERROR,
						{}
					)
				end
			end,
			detached = true, -- Run in the background
			pty = false, -- Don't need a pseudo-terminal
		})
		if handle > 0 then
			return true
		else
			vim.notify("Failed to start activation job.", vim.log.levels.ERROR, {})
			return false
		end
	else
		vim.notify("No .venv found in the root directory.", vim.log.levels.WARN, {})
		return false
	end
end

local M = {}

function M.setup()
	vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
		callback = function()
			-- Only run if the current buffer is in a directory (not a special buffer)
			if vim.fn.isdirectory(vim.fn.getcwd()) == 1 then
				activate_venv()
			end
		end,
	})
end

return M
