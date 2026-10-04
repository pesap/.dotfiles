# Neovim configuration

Modern Neovim configuration using native LSP (0.12+) and lazy.nvim.

## Structure

```
~/.config/nvim/
├── after/       # Runtime integrations, filetype settings, and Julia LSP script
├── init.lua     # Entry point and Lazy.nvim bootstrap
├── lazy-lock.json
├── lsp/         # Native LSP server configs
└── lua/
    ├── keymaps.lua
    ├── opts.lua
    ├── prefs.lua
    ├── plugins/ # Lazy.nvim plugin specs and setup
    │   └── lsp/ # Completion and formatting specs
    └── utils/   # Shared helpers
```

## Key Features

- **Plugin Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **File Picker**: [FFF](https://github.com/dmtrKovalenko/fff) for frecency-ranked file search
- **Fuzzy Finder**: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for non-FFF pickers (LSP, buffers, git branches, PR review)
- LSP: Native Neovim 0.12+ (`vim.lsp.enable`); managed server executables come from mise
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

From the dotfiles repository root, install the managed tools:

```sh
mise -C . install --locked
```

The enabled servers are selected in `lua/prefs.lua`:
- Lua (`lua-language-server`)
- Python (Ruff)
- Julia (`LanguageServer.jl`)
- Rust (`rust-analyzer`)

Mise installs Julia itself, not its `LanguageServer` package. Add that package
to Julia's default environment once; this changes Julia state under `$HOME/.julia`:

```sh
mise -C . exec -- julia --startup-file=no -e 'using Pkg; Pkg.add("LanguageServer")'
```

`lsp/bash.lua` and `lsp/pyright.lua` are present but are not enabled.

## Formatters (conform.nvim)

| Filetype | Formatter |
|----------|-----------|
| Python | ruff_organize_imports → ruff_fix → ruff_format |
| Lua | stylua |
| Shell | shfmt |

Auto-format on save is enabled.

## Colorscheme

[kintsugi-nvim](https://github.com/metalelf0/kintsugi-nvim) (`kintsugi-dark`) with transparent background.

## Maintenance Notes

- Lazy.nvim plugin specs live in `lua/plugins/` and use `opts`, `config`, or plugin defaults as appropriate.
- `after/` contains runtime integrations and filetype settings; Julia LSP startup is in `after/julia-ls.jl`.
- Formatter setup lives in `lua/plugins/lsp/conform.lua`.
- Native LSP configs are in `lsp/` and are enabled from `lua/prefs.lua`.
- General keymaps live in `lua/keymaps.lua`; plugin mappings are defined with plugin setup or in `after/plugin/` integrations.
