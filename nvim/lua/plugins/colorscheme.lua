-- Current colorscheme of choice
return {
	"metalelf0/kintsugi-nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("kintsugi").setup({
			variant = "dark",
			transparent = true,
			terminal_colors = true,
			bold_keywords = true,
			italic_comments = false,
		})
		vim.cmd.colorscheme("kintsugi-dark")

		vim.keymap.set("n", "<leader>tc", function()
			local ok, fzf = pcall(require, "fzf-lua")
			if ok then
				fzf.colorschemes({ prompt = "Theme❯ " })
				return
			end

			vim.ui.select({ "kintsugi-dark", "kintsugi-flared" }, { prompt = "Theme" }, function(choice)
				if choice then
					vim.cmd.colorscheme(choice)
				end
			end)
		end, { desc = "[T]heme [C]hoose" })
	end,
}
