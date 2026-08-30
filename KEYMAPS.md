# Keymaps by program

> A quick reference for the shortcuts that make this setup feel like one
> workspace instead of a collection of separate applications.

Last updated: 2026-07-26 · Leader: `<Space>` in Neovim

## Find a shortcut

- [Neovim](#neovim) — editing, search, LSP, Git, and review workflows
- [Herdr](#herdr) — persistent project sessions and same-window switching
- [Alacritty](#alacritty) — terminal configuration
- [skhd](#skhd-macos) — macOS apps, spaces, and Yabai
- [Mango](#mango-wm-linux) — Linux windows, tags, and screenshots

---

## Neovim

Sources:
- `nvim/.config/nvim/lua/keymaps.lua`
- `nvim/.config/nvim/lua/plugins/fff.lua`
- `nvim/.config/nvim/lua/plugins/fzflua.lua`
- `nvim/.config/nvim/lua/plugins/harpoon.lua`
- `nvim/.config/nvim/lua/plugins/mole.lua`
- `nvim/.config/nvim/lua/plugins/tpope.lua`
- `nvim/.config/nvim/lua/plugins/gitsigns.lua`
- `nvim/.config/nvim/lua/plugins/vim-maximizer.lua`
- `nvim/.config/nvim/lua/plugins/colorscheme.lua`
- `nvim/.config/nvim/after/plugin/reviewer.lua`

Leader is `<Space>`.

### Core (`lua/keymaps.lua`)

- `<Space>` (n,v) → `<Nop>`
- `s` (n,v) → `<Nop>`
- `<leader>o` → save + source current file
- `<leader>pv` → open netrw explorer
- `<leader>qq` → close current buffer
- `<leader>qo` → close all buffers but current
- `j` / `k` → wrapped-line aware movement
- `J` / `K` (visual) → move selected lines down/up
- `<C-d>` / `<C-u>` → half page jump, centered
- `n` / `N` → next/prev search result, centered
- `Q` and `q` → disabled
- `<leader>sr` → substitute word under cursor in file
- `<leader>sp` → grep word under cursor project-wide
- `<leader>srp` → project-wide replace via quickfix
- `<leader>qf` → quickfix open
- `<leader>qc` → quickfix close
- `<leader>qj` / `<leader>qk` → quickfix next/prev + center
- `<leader>qh` / `<leader>ql` → quickfix first/last
- `<` (terminal mode) → leave terminal + move left
- `:Wq` → `:wq`
- `:Q` → `:q`
- `*` / `#` → search word without jumping
- `<Esc>` → clear search highlight
- `//` (visual) → search selection
- `<leader>sd` → see diagnostic under cursor/current line
- Arrow keys → warn to use hjkl
- `<leader>-` / `<leader>_` → horizontal/vertical split
- `zz` → scroll current line near top (+ offset)
- `<leader>ww` → switch window
- `<leader>gF` (n,v) → go to file (+line) helper

### FFF / FZF-Lua (`plugins/fff.lua`, `plugins/fzflua.lua`)

- `<leader>ff` files
- `<leader>fb` builtins
- `<leader>fk` keymaps
- `<leader>gp` grep project
- `<leader>gg` live grep native
- `<leader>gw` (n,x) grep current word/selection
- `<leader>gW` grep current WORD
- `<leader>/` grep current buffer
- `<leader><leader>` buffers
- `<leader>fm` marks
- `<leader>gf` git files
- `<leader>sb` git branches
- `<leader>fn` files in `~/.config/nvim`
- `<leader>fP` files in `~/dev/`
- `<leader>fp` files in `./packages/`
- `<leader>ft` files in `tests/`
- `<leader>fl` LSP finder
- `<leader>fd` LSP definitions
- `<leader>fD` LSP declarations
- `<leader>fr` LSP references
- `<leader>fi` LSP implementations
- `<leader>fT` LSP type definitions
- `<leader>fa` LSP code actions
- `<leader>fs` LSP document symbols
- `<leader>fS` LSP workspace symbols
- `<leader>fe` document diagnostics
- `<leader>fE` workspace diagnostics
- `<leader>rf` PR review picker workflow
- `<leader>rr` PR review reset

### Harpoon (`plugins/harpoon.lua`)

- `<leader>ha` add file
- `<leader>hm` toggle Harpoon menu
- `<leader>1..5` jump to Harpoon slots
- `<leader>hn` next Harpoon entry
- `<leader>hp` previous Harpoon entry

### Mole (`plugins/mole.lua`)

- `<leader>ma` annotate visual selection
- `<leader>ms` start annotation session
- `<leader>mq` stop annotation session
- `<leader>mr` resume annotation session
- `<leader>mw` toggle annotation window
- `<CR>` / `gd` jump to annotation location in Mole side panel
- `]a` / `[a` next/previous annotation in Mole side panel

### Git / Fugitive (`plugins/tpope.lua`)

- `<leader>gb` `:GBrowse`
- `<leader>gd` LSP definition
- `<leader>gD` `:Gdiff`
- `<leader>gl` toggle `:Git log %`
- `<leader>gs` toggle `:Git` status

### Gitsigns (`plugins/gitsigns.lua`)

- `]h` next hunk
- `[h` previous hunk

### Theme picker (`plugins/colorscheme.lua`)

- `<leader>tc` open theme selector (fzf-lua colorschemes or `vim.ui.select` fallback)

### Review plugin toggle (`after/plugin/reviewer.lua`)

- `<leader>rp` `:ReviewToggle`

### Window maximize (`plugins/vim-maximizer.lua`)

- `<leader>wm` toggle maximizer

### Neovim mapping collisions to be aware of

- No known duplicate mappings in the edited Neovim files.

---

## Herdr

Sources:
- `herdr/.config/herdr/config.toml`
- `bin/.local/bin/herdr-project`
- `zshrc/.config/zshrc/50-functions.zsh`
- `alacritty/.config/alacritty/alacritty.toml`

| Key | Action |
|---|---|
| `Cmd+\\` (macOS) / `Super+\\` (Linux) | open Herdr project picker |
| `Ctrl+\\` | open Herdr project picker from a terminal |
| `Ctrl+b`, then `q` | detach Herdr and return to the shell |
| `Cmd+1..9` / `Super+1..9` | switch directly to Herdr workspace 1..9 |

`project-picker` discovers first-level projects under the shared project roots
with `fd`, and includes `~/.dotfiles` as an explicit project. It uses `fzf`
with a lightweight preview; pass a project directory directly to any launcher
to skip the picker. The project basename is sanitized into the multiplexer
session name.

Set `PROJECT_ROOTS` and `PROJECT_PATHS` as colon-separated overrides when
needed. `herdr-project` opens a project outside Herdr and uses its native popup
handoff when switching from inside Herdr. From a shell outside Herdr,
`herdr-kill-all` terminates every session and deletes all named-session state;
it prompts unless passed `--force`.

---

## Alacritty

Source:
- `alacritty/.config/alacritty/alacritty.toml`

Other Alacritty workflow settings:
- `live_config_reload = true`
- `dynamic_padding = true`
- `selection.save_to_clipboard = true`

---

## skhd (macOS)

Source:
- `skhd/.config/skhd/skhdrc`

Configured hotkeys include:
- App/space switching: `alt-1/2/3/9/0` and `` alt-` `` (Ghostty)
- Private Safari: `cmd-return`
- Yabai fullscreen zoom toggle: `alt+shift-f`
- Space layout cycle: `alt-space` (bsp → stack → float)

---

## Mango WM (Linux)

Source:
- `mango/.config/mango/config-bindings.conf`

This file contains the full Linux keymap set (window focus/move/resize/layout/tags/screenshots/mouse/gestures), using ALT number bindings for workspace navigation.

Notable launchers:
- `Alt+Return` launches Alacritty
- `Super+S` switches to tag 4 and launches Palworld through Steam
- `Super+O` switches to tag 3 and opens the Bolt OSRS launcher


---

## Tip: commands to regenerate this index

Run these commands from the repository root. Each command is independent and
prints the relevant source file or matching lines; none changes files.

Neovim keymaps:

```bash
grep -R "vim.keymap.set" nvim/.config/nvim -n
```

macOS `skhd` bindings:

```bash
cat skhd/.config/skhd/skhdrc
```

Mango bindings:

```bash
cat mango/.config/mango/config-bindings.conf
```
