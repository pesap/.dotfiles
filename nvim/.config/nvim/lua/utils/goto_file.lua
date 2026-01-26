local M = {}

--- Find the git root directory or fall back to cwd
---@return string
function M.get_project_root()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error == 0 and git_root and git_root ~= "" then
        return git_root
    end
    return vim.fn.getcwd()
end

--- Parse a path string into filepath, line, and column
--- Supports: file.py, file.py:42, file.py:42:10
---@param input string
---@return string filepath, number|nil line, number|nil column
function M.parse_path(input)
    -- Strip surrounding quotes and whitespace
    input = input:gsub("^[\"'%s]+", ""):gsub("[\"'%s]+$", "")

    local filepath, line, column

    -- Try to match file:line:column
    local f, l, c = input:match("^(.+):(%d+):(%d+)$")
    if f then
        return f, tonumber(l), tonumber(c)
    end

    -- Try to match file:line
    f, l = input:match("^(.+):(%d+)$")
    if f then
        return f, tonumber(l), nil
    end

    -- Just a filepath
    return input, nil, nil
end

--- Get the target text based on mode (WORD under cursor or visual selection)
---@param mode string
---@return string|nil
function M.get_target_text(mode)
    if mode == "v" or mode == "V" or mode == "\22" then
        -- Visual mode: get selected text
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.fn.getregion(start_pos, end_pos, { type = mode })
        if lines and #lines > 0 then
            return table.concat(lines, "\n")
        end
        return nil
    else
        -- Normal mode: get WORD under cursor
        return vim.fn.expand("<cWORD>")
    end
end

--- Search for a file relative to the project root
--- Tries: exact path from root -> buffer-relative -> absolute -> recursive find
---@param filepath string
---@param root string
---@return string|nil
function M.find_file(filepath, root)
    -- Try exact path from project root
    local from_root = root .. "/" .. filepath
    if vim.fn.filereadable(from_root) == 1 then
        return from_root
    end

    -- Try relative to current buffer's directory
    local buf_dir = vim.fn.expand("%:p:h")
    local from_buffer = buf_dir .. "/" .. filepath
    if vim.fn.filereadable(from_buffer) == 1 then
        return from_buffer
    end

    -- Try as absolute path
    if vim.fn.filereadable(filepath) == 1 then
        return filepath
    end

    -- Try recursive find from project root
    local basename = vim.fn.fnamemodify(filepath, ":t")
    local found = vim.fn.globpath(root, "**/" .. basename, false, true)
    if found and #found > 0 then
        -- If we find multiple matches, prefer ones that end with our filepath
        for _, f in ipairs(found) do
            if f:sub(-#filepath) == filepath then
                return f
            end
        end
        -- Otherwise return the first match
        return found[1]
    end

    return nil
end

--- Open fzf-lua as a fallback when file is not found
---@param query string
---@param root string
function M.fuzzy_fallback(query, root)
    local ok, fzf = pcall(require, "fzf-lua")
    if ok then
        fzf.files({
            cwd = root,
            query = query,
        })
    else
        vim.notify("File not found: " .. query, vim.log.levels.WARN)
    end
end

--- Main entry point for goto file functionality
---@param opts table|nil
function M.goto_file(opts)
    opts = opts or {}
    local mode = opts.mode or vim.fn.mode()

    -- Get the target text
    local target = M.get_target_text(mode)
    if not target or target == "" then
        vim.notify("No text under cursor", vim.log.levels.WARN)
        return
    end

    -- Parse the path
    local filepath, line, column = M.parse_path(target)
    if not filepath or filepath == "" then
        vim.notify("Could not parse path", vim.log.levels.WARN)
        return
    end

    -- Get project root
    local root = M.get_project_root()

    -- Try to find the file
    local found_path = M.find_file(filepath, root)

    if found_path then
        -- Open the file
        vim.cmd("edit " .. vim.fn.fnameescape(found_path))

        -- Jump to line if specified
        if line then
            vim.api.nvim_win_set_cursor(0, { line, (column or 1) - 1 })
        end
    else
        -- Fall back to fuzzy finder
        M.fuzzy_fallback(vim.fn.fnamemodify(filepath, ":t"), root)
    end
end

return M
