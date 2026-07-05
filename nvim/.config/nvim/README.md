# NVim Config

Modern Neovim configuration using native LSP (0.11+) and lazy.nvim.

## Structure

```
~/.config/nvim/
├── init.lua              # Entry point (Lazy bootstrap)
├── lazy-lock.json        # Lockfile for reproducible builds
├── lua/
│   ├── opts.lua          # Core vim options
│   ├── keymaps.lua       # General keymaps
│   ├── prefs.lua         # LSP enable list + diagnostics
│   └── plugins/          # Plugin specs (Lazy.nvim)
│       ├── colorscheme.lua
│       ├── commenter.lua
│       ├── fff.lua       # FFF file picker + keymaps
│       ├── fzflua.lua    # LSP/buffer/git branch pickers + PR review workflow
│       ├── gitsigns.lua  # Git signs
│       ├── harpoon.lua   # File marks
│       ├── mini.lua      # Mini.statusline
│       ├── mole.lua
│       ├── slime.lua     # REPL integration (zellij)
│       ├── tpope.lua     # Fugitive + tpope essentials
│       ├── treesitter.lua
│       ├── vim-maximizer.lua
│       ├── whichkey.lua
│       └── lsp/          # LSP-related plugins
│           ├── blink.lua      # Completion
│           ├── conform.lua    # Formatting
│           └── mason.lua      # LSP installer
└── lsp/                  # Native LSP configs (0.11+)
    ├── bash.lua
    ├── julia.lua
    ├── lua.lua
    ├── pyright.lua
    ├── ruff.lua
    └── rust.lua
```

## Key Features

- **Plugin Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **File Picker**: [FFF](https://github.com/dmtrKovalenko/fff) for frecency-ranked file search
- **Fuzzy Finder**: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for non-FFF pickers (LSP, buffers, git branches, PR review)
- **LSP**: Native 0.11+ (`vim.lsp.enable`) with [mason.nvim](https://github.com/williamboman/mason.nvim)
- **Completion**: [blink.cmp](https://github.com/saghen/blink.cmp)
- **Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim)
- **Git**: [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) + [vim-fugitive](https://github.com/tpope/vim-fugitive)
- **File Marks**: [harpoon](https://github.com/ThePrimeagen/harpoon) (harpoon2)

## Key Mappings

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>ff` | Find files (FFF) |
| `<leader>gg` | Live grep (FFF) |
| `<leader>gw` | Grep word/selection (FFF) |
| `<leader>/` | Grep current buffer (FFF) |
| `<leader>fl` | Find LSP locations (fzf) |
| `<leader>fd` / `<leader>fr` | Find LSP definitions/references (fzf) |
| `<leader>fs` / `<leader>fS` | Find LSP document/workspace symbols (fzf) |
| `<leader>fa` | Find LSP code actions (fzf) |
| `<leader>fe` / `<leader>fE` | Find LSP document/workspace diagnostics (fzf) |
| `<leader>sd` | See diagnostic under cursor/current line |
| `<leader>qo` | Close other buffers |
| `<leader>qf` | Quickfix open |
| `<leader>ha` | Harpoon: add file |
| `<leader>hm` | Harpoon: toggle menu |
| `<leader>1-5` | Harpoon: jump to file 1-5 |
| `<leader>hn` / `<leader>hp` | Harpoon: next/previous file |
| `<leader>tc` | Theme picker (colorschemes) |
| `<leader>gs` | Git status (Fugitive) |
| `<leader>gD` | Git diff (Fugitive) |
| `<leader>rp` | Review panel toggle |
| `<leader>rf` | PR review file picker |
| `gd` / `<leader>gd` | Go to definition (native LSP) |
| `K` | Hover docs |
| `gra` | Code action |
| `grn` | Rename |

## LSP Servers

Enabled via `vim.lsp.enable()`:
- Lua (lua-language-server)
- Python (pyright + ruff)
- Julia (LanguageServer.jl)
- Bash (bash-language-server)
- Rust (rust-analyzer)

## Formatters (conform.nvim)

| Filetype | Formatter |
|----------|-----------|
| Python | ruff_organize_imports → ruff_fix → ruff_format |
| Lua | stylua |
| JSON/YAML/Markdown | prettier |
| Shell | shfmt |

Auto-format on save is enabled.

## Colorscheme

[kintsugi-nvim](https://github.com/metalelf0/kintsugi-nvim) (`kintsugi-dark`) with transparent background.

## Maintenance Notes

- All plugin configuration lives in `lua/plugins/` with `config()` functions
- No `after/plugin/` directory (migrated to lazy.nvim config)
- LSP configs are in `lsp/` using native 0.11+ format
- Keymaps are either in `keymaps.lua` (general) or plugin `config()` functions
