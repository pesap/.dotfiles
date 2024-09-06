local conform = require("conform")
conform.setup({
	opts = {
		notify_on_error = false,
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		python = { "isort", "ruff_fix", "ruff_format" },
		-- Use a sub-list to run only the first available formatter
		javascript = { { "prettierd", "prettier" } },
		json = { { "prettier" } },
		yaml = { { "prettier" } },
		sql = { { "sql-formatter" } },
	},
})
vim.keymap.set("x", "<leader>cv", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end, { desc = "[C]ode format range (in [V]isual mode)" })

-- 	"stevearc/conform.nvim",
-- 	event = { "BufReadPre", "BufNewFile" },
-- 	config = function()
-- 		local conform = require("conform")
-- 		conform.setup({
-- 			opts = {
-- 				notify_on_error = false,
-- 				format_on_save = {
-- 					timeout_ms = 500,
-- 					lsp_fallback = true,
-- 				},
-- 			},
-- 			formatters_by_ft = {
-- 				lua = { "stylua" },
-- 				-- Conform will run multiple formatters sequentially
-- 				python = { "isort", "ruff_fix", "ruff_format" },
-- 				-- Use a sub-list to run only the first available formatter
-- 				javascript = { { "prettierd", "prettier" } },
-- 				json = { { "prettier" } },
-- 				markdown = { { "prettier" } },
-- 				sql = { { "sql-formatter" } },
-- 				-- have other formatters configured.
-- 				["_"] = { "trim_whitespace" },
-- 			},
-- 		})
--
-- 		vim.keymap.set({ "n", "v" }, "<leader>cv", function()
-- 			conform.format({
-- 				lsp_fallback = true,
-- 				async = false,
-- 				timeout_ms = 500,
-- 			})
-- 		end, { desc = "[C]ode format range (in [V]isual mode)" })
-- 	end,
-- }
