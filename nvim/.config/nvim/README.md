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
│       ├── fzflua.lua    # Fuzzy finder + keymaps
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
- **Fuzzy Finder**: [fzf-lua](https://github.com/ibhagwan/fzf-lua) with custom PR review workflow
- **LSP**: Native 0.11+ (`vim.lsp.enable`) with [mason.nvim](https://github.com/williamboman/mason.nvim)
- **Completion**: [blink.cmp](https://github.com/saghen/blink.cmp)
- **Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim)
- **Git**: [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) + [vim-fugitive](https://github.com/tpope/vim-fugitive)
- **File Marks**: [harpoon](https://github.com/ThePrimeagen/harpoon) (harpoon2)

## Key Mappings

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>ff` | Find files |
| `<leader>gg` | Live grep |
| `<leader>gd` | Go to definition (fzf) |
| `<leader>gr` | Go to references (fzf) |
| `<leader>t` | Harpoon: add file |
| `<leader>mm` | Harpoon: toggle menu |
| `<leader>1-5` | Harpoon: jump to file 1-5 |
| `<leader>gs` | Git status (Fugitive) |
| `<leader>rp` | PR Review workflow |
| `gd` | Go to definition (native) |
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

[thorn.nvim](https://github.com/jpwol/thorn.nvim) with transparent background.

## Maintenance Notes

- All plugin configuration lives in `lua/plugins/` with `config()` functions
- No `after/plugin/` directory (migrated to lazy.nvim config)
- LSP configs are in `lsp/` using native 0.11+ format
- Keymaps are either in `keymaps.lua` (general) or plugin `config()` functions
