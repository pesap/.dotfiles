-- Using Lazy as plugin manager.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_ref = "v11.17.5"
local lazy_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=" .. lazy_ref,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("failed to clone lazy.nvim " .. lazy_ref)
	end
	local cloned_commit = vim.trim(vim.fn.system({ "git", "-C", lazypath, "rev-parse", "HEAD" }))
	if vim.v.shell_error ~= 0 or cloned_commit ~= lazy_commit then
		error("lazy.nvim checkout did not match the pinned commit")
	end
end
vim.opt.rtp:prepend(lazypath)

-- Example using a list of specs with the default options
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Personal configuration
require("opts")
require("prefs")
require("keymaps")
require("lazy").setup({
	spec = {
		{ import = "plugins" },
		{ import = "plugins.lsp" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "kintsugi-dark" } },
	-- automatically check for plugin updates
	checker = { enabled = false },
})
