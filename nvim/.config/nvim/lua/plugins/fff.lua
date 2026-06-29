return {
	"dmtrKovalenko/fff.nvim",
	url = "https://github.com/dmtrKovalenko/fff",
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	lazy = false,
	opts = {
		prompt = "Files❯ ",
		title = "FFFiles",
		max_results = 100,
		lazy_sync = true,
		layout = {
			height = 0.8,
			width = 0.8,
			prompt_position = "bottom",
			preview_position = "right",
			preview_size = 0.5,
			flex = { size = 130, wrap = "top" },
			show_scrollbar = true,
			path_shorten_strategy = "middle_number",
		},
		preview = {
			enabled = true,
			line_numbers = false,
			wrap_lines = false,
		},
		keymaps = {
			close = "<Esc>",
			select = "<CR>",
			select_split = "<C-s>",
			select_vsplit = "<C-v>",
			select_tab = "<C-t>",
			move_up = { "<Up>", "<C-p>" },
			move_down = { "<Down>", "<C-n>" },
			preview_scroll_up = "<C-u>",
			preview_scroll_down = "<C-d>",
			toggle_select = "<Tab>",
			send_to_quickfix = "<C-q>",
		},
		frecency = {
			enabled = true,
			db_path = vim.fn.stdpath("cache") .. "/fff_nvim",
		},
		history = {
			enabled = true,
			db_path = vim.fn.stdpath("cache") .. "/fff_queries",
		},
		git = {
			status_text_color = false,
		},
		grep = {
			smart_case = true,
			modes = { "plain", "regex", "fuzzy" },
			enable_filename_constraint = true,
		},
		debug = {
			enabled = false,
			show_scores = false,
		},
	},
	config = function(_, opts)
		local fff = require("fff")
		fff.setup(opts)

		local function current_file_query()
			local file = vim.fn.expand("%:.")
			if file == "" then
				return nil
			end
			return file .. " "
		end

		vim.keymap.set("n", "<leader>ff", function()
			fff.find_files()
		end, { desc = "[F]ind [F]iles in project directory" })

		vim.keymap.set("n", "<leader>fn", function()
			fff.find_files_in_dir(vim.fn.expand("~/.config/nvim"))
		end, { desc = "[F]ind [N]eovim" })

		vim.keymap.set("n", "<leader>fP", function()
			fff.find_files_in_dir(vim.fn.expand("~/dev"))
		end, { desc = "[F]ind Dev [P]roject" })

		vim.keymap.set("n", "<leader>fp", function()
			fff.find_files({ title = "Packages", query = "packages/" })
		end, { desc = "[F]ind [P]ackage" })

		vim.keymap.set("n", "<leader>ft", function()
			fff.find_files({ title = "Test Files", query = "tests/" })
		end, { desc = "Fuzzy find test files" })

		vim.keymap.set("n", "<leader>gf", function()
			fff.find_files()
		end, { desc = "[G]it [F]iles" })

		vim.keymap.set("n", "<leader>gp", function()
			fff.live_grep({ title = "Grep Project" })
		end, { desc = "[G]rep [P]roject" })

		vim.keymap.set("n", "<leader>gg", function()
			fff.live_grep({ title = "Live Grep" })
		end, { desc = "[G]rep native" })

		vim.keymap.set({ "n", "x" }, "<leader>gw", function()
			fff.live_grep_under_cursor({ title = "Grep Word" })
		end, { desc = "[G]rep current [w]ord/selection" })

		vim.keymap.set("n", "<leader>gW", function()
			fff.live_grep({ title = "Grep WORD", query = vim.fn.expand("<cWORD>") })
		end, { desc = "[G]rep current [W]ord" })

		vim.keymap.set("n", "<leader>/", function()
			fff.live_grep({ title = "Grep Current Buffer", query = current_file_query() })
		end, { desc = "[G]rep current buffer" })
	end,
}
