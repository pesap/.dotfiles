-- Detect .kdl files inside the arco project as arco_kdl filetype
vim.filetype.add({
	pattern = {
		[".*/arco/.*%.kdl"] = "arco_kdl",
	},
})

-- Regex-based sub-highlighting for arco_math_text nodes.
-- The grammar keeps math text as a single opaque token for correct parsing;
-- this adds sub-highlights for operators, keywords, numbers, and brackets.
local ns = vim.api.nvim_create_namespace("arco_math_hl")
local group = vim.api.nvim_create_augroup("ArcoMathHL", { clear = true })

-- Multi-char operators first so they take priority over single-char.
local math_patterns = {
	{ "<=", "@operator" },
	{ ">=", "@operator" },
	{ "==", "@operator" },
	{ "!=", "@operator" },
	{ "[<>=+%-%*/]", "@operator" },
	{ "%f[%a_]for%f[^%w_]", "@keyword" },
	{ "%f[%a_]in%f[^%w_]", "@keyword" },
	{ "%f[%a_]and%f[^%w_]", "@keyword" },
	{ "%f[%a_]or%f[^%w_]", "@keyword" },
	{ "%f[%a_]not%f[^%w_]", "@keyword" },
	{ "%d+%.?%d*", "@number" },
	{ "[%[%]]", "@punctuation.bracket" },
	{ "[%(%)%,]", "@punctuation.delimiter" },
}

-- Cache the parsed query — it never changes.
local math_query

local function highlight_math_text(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "arco_kdl")
	if not ok or not parser then
		return
	end

	local tree = parser:parse()[1]
	if not tree then
		return
	end

	if not math_query then
		math_query = vim.treesitter.query.parse("arco_kdl", "(arco_math_text) @math")
	end

	for _, node in math_query:iter_captures(tree:root(), bufnr) do
		local sr, sc, er, ec = node:range()
		local lines = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)
		for i, line in ipairs(lines) do
			local row = sr + i - 1
			local col_start = row == sr and sc or 0
			local col_end = row == er and ec or #line
			local region = line:sub(col_start + 1, col_end)

			-- Track which byte positions are already highlighted
			-- so multi-char operators aren't double-covered by single-char patterns.
			local covered = {}
			for _, pat in ipairs(math_patterns) do
				local s, e = 0, 0
				while true do
					s, e = region:find(pat[1], e + 1)
					if not s then
						break
					end
					-- Skip if any byte in this range is already covered
					local overlap = false
					for pos = s, e do
						if covered[pos] then
							overlap = true
							break
						end
					end
					if not overlap then
						for pos = s, e do
							covered[pos] = true
						end
						vim.api.nvim_buf_set_extmark(bufnr, ns, row, col_start + s - 1, {
							end_col = col_start + e,
							hl_group = pat[2],
							priority = 200,
						})
					end
				end
			end
		end
	end
end

local timer = vim.uv.new_timer()

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = "arco_kdl",
	callback = function(args)
		local bufnr = args.buf
		highlight_math_text(bufnr)
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				timer:stop()
				timer:start(50, 0, vim.schedule_wrap(function()
					if vim.api.nvim_buf_is_valid(bufnr) then
						highlight_math_text(bufnr)
					end
				end))
			end,
		})
	end,
})
