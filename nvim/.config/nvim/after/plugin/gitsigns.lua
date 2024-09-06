require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local cmap = function(mode, key, func, desc, opts)
			if desc then
				desc = "Gitsigns: " .. desc
			end
			opts = opts or {}
			opts.buffer = bufnr
			opts.desc = desc
			vim.keymap.set(mode, key, func, opts)
		end

		-- Navigation
		cmap("n", "]c", function()
			if vim.wo.diff then
				return "]c"
			end
			vim.schedule(function()
				gs.next_hunk()
			end)
			return "<Ignore>"
		end, "[H]unk next", { expr = true })

		cmap("n", "[c", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(function()
				gs.prev_hunk()
			end)
			return "<Ignore>"
		end, "[H]unk previous", { expr = true })
		cmap("n", "<leader>hs", gs.stage_hunk, "[H]unk stage")
		cmap("n", "<leader>hr", gs.reset_hunk, "[H]unk reset")
		cmap("v", "<leader>hs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end)
		cmap("v", "<leader>hr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end)
		cmap("n", "<leader>hS", gs.stage_buffer)
		cmap("n", "<leader>hu", gs.undo_stage_hunk)
		cmap("n", "<leader>hR", gs.reset_buffer)
		cmap("n", "<leader>hp", gs.preview_hunk, "[H]unk preview")
		cmap("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, "[H]unk blame")
		cmap("n", "<leader>tb", gs.toggle_current_line_blame, "[T]oggle blame")
		cmap("n", "<leader>hd", gs.diffthis, "[H]unk diff")
		cmap("n", "<leader>hD", function()
			gs.diffthis("~")
		end)
		cmap("n", "<leader>td", gs.toggle_deleted)
	end,
})
