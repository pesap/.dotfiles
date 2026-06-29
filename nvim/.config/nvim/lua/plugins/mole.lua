return {
	"zion-off/mole.nvim",
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {
		-- Store sessions in Neovim's cache dir (~/.cache/nvim/mole by default)
		session_dir = vim.fn.stdpath("cache") .. "/mole",

		-- Include code snippets in annotations (change to "location" for just file:line)
		capture_mode = "snippet",

		-- Auto open side panel when starting
		auto_open_panel = true,

		-- Show gutter signs on annotated lines
		virtual_text = true,

		-- Resume via vim.ui.select; mole does not currently integrate with fzf-lua directly
		picker = "select",

		-- Keybindings
		keys = {
			annotate = "<leader>ma",        -- visual mode: annotate selection
			start_session = "<leader>ms",   -- start new session
			stop_session = "<leader>mq",    -- stop session
			resume_session = "<leader>mr",  -- resume previous session
			toggle_window = "<leader>mw",   -- toggle side panel
			jump_to_location = { "<CR>", "gd" }, -- in side panel: jump to code
			next_annotation = "]a",         -- next annotation in panel
			prev_annotation = "[a",         -- prev annotation in panel
		},

		-- Side panel size
		window = {
			width = 0.3,
		},

		-- Input popup
		input = {
			width = 50,
			border = "rounded",
			expand_key = "<C-e>", -- expand to multiline buffer
		},
	},
}
