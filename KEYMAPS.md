# Keymaps by program

> A quick reference for the shortcuts that make this setup feel like one
> workspace instead of a collection of separate applications.

Last updated: 2026-09-24 · Leader: `<Space>` in Neovim

## Find a shortcut

- [Neovim](#neovim) — editing, search, LSP, Git, and review workflows
- [Herdr](#herdr) — persistent project sessions and same-window switching
- [Alacritty](#alacritty) — terminal configuration
- [skhd](#skhd-macos) — macOS apps, spaces, and Yabai
- [Mango](#mango-wm-linux) — Linux windows, tags, and screenshots

---

## Neovim

Sources:
- `nvim/lua/keymaps.lua`
- `nvim/lua/plugins/fff.lua`
- `nvim/lua/plugins/fzflua.lua`
- `nvim/lua/plugins/harpoon.lua`
- `nvim/lua/plugins/mole.lua`
- `nvim/lua/plugins/tpope.lua`
- `nvim/lua/plugins/gitsigns.lua`
- `nvim/lua/plugins/treesitter.lua`
- `nvim/lua/plugins/vim-maximizer.lua`
- `nvim/lua/plugins/colorscheme.lua`
- `nvim/after/plugin/reviewer.lua`

Leader is `<Space>`. This page lists explicit custom mappings; plugin defaults are not exhaustive.

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

### Tree-sitter textobjects (`plugins/treesitter.lua`)

- `aa` / `ia` select outer/inner parameter
- `af` / `if` select outer/inner function
- `ac` / `ic` select outer/inner class
- `ao` selects outer comment
- `]m` / `[m` next/previous function start
- `]M` / `[M` next/previous function end
- `]]` / `[[` next/previous class start
- `][` / `[]` next/previous class end

### Theme picker (`plugins/colorscheme.lua`)

- `<leader>tc` open theme selector (fzf-lua colorschemes or `vim.ui.select` fallback)

### Review plugin toggle (`after/plugin/reviewer.lua`)

- `<leader>rp` `:ReviewToggle`

### Window maximize (`plugins/vim-maximizer.lua`)

- `<leader>wm` toggle maximizer

---

## Herdr

Sources:
- `herdr/config.toml`
- `bin/herdr-project`
- `bin/herdr-session-select`
- `bin/herdr-session-kill`
- `bin/herdr-remote`
- `bin/herdr-remote-launch`
- `bin/herdr-remote-terminal`
- `zshrc/config/50-functions.zsh`
- `alacritty/alacritty.toml`

| Key | Action |
|---|---|
| `Cmd+\\` (macOS) / `Super+\\` (Linux) in Alacritty | sends `Ctrl+\\`; Zsh opens the project picker, Herdr opens the session selector |
| `Ctrl+\\` in Zsh | open the Herdr project picker |
| `q` in the session selector | stop and delete the highlighted session after confirmation |
| `Esc` in the session selector | close the picker without action |
| `Cmd+Shift+R` (macOS) / `Super+Shift+R` (Linux) in Alacritty | open an SSH host picker and attach Herdr to the selected machine |
| `Ctrl+b`, then `q` | detach Herdr and return to the shell |
| `Cmd+1..9` / `Super+1..9` | switch directly to Herdr workspace 1..9 |
| `Ctrl+b`, then `Shift+G` | switch or create a Worktrunk worktree |
| `Ctrl+b`, then `Shift+C` | create a Worktrunk worktree from the current branch |
| `Ctrl+b`, then `Shift+R` | switch or create from remote branches |
| `Ctrl+b`, then `Shift+D` | remove a Worktrunk worktree |
| `Ctrl+b`, then `Shift+M` | merge a Worktrunk worktree |

`project-picker` discovers first-level projects under the shared project roots
with `fd`, and includes `~/.dotfiles` as an explicit project. It uses `fzf`
with a lightweight preview; pass a project directory directly to any launcher
to skip the picker. The project basename is sanitized into the multiplexer
session name.

In Alacritty, `Cmd+Shift+R` on macOS or `Super+Shift+R` on Linux opens a
separate Alacritty window for the remote picker. By default, its `fzf` list
contains literal SSH `Host` aliases from `~/.ssh/config` and omits targets
configured with `User git`. Set `HERDR_SSH_CONFIG` to use another SSH config
file. Discovery and the final SSH connection both use that override. Selecting
a host runs `ssh -t <host> herdr` by default, starting Herdr on the remote
machine in that terminal. The remote host must have Herdr installed and
on `PATH`. Esc or Ctrl+C cancels only the new picker, leaving the current
terminal or Herdr session untouched. Run `herdr-remote` directly from any
interactive Unix terminal to use the same picker.

Set `PROJECT_ROOTS` and `PROJECT_PATHS` as colon-separated overrides when
needed. Outside Herdr, `herdr-project` opens a project and starts its named
session. Inside Herdr, `Ctrl+\\` selects an existing session and switches to it
through the launcher. The picker shows sessions with a saved project path,
colors running-session paths green and stopped-session paths gray, and previews
the project. Sessions without a project path are omitted. Press `q` to stop and
delete the highlighted session after confirmation. Esc closes the picker without
action.
The deletion picker is also available with `herdr-project --session-kill`. It
stops a running named session, verifies it stopped, then deletes its saved state
after confirmation. The default session is excluded. Herdr 0.9.0 has no targeted
force-stop option, so a server that does not respond to `session stop` is left
intact. `herdr-kill-all` remains the separate all-session command and prompts
unless passed `--force`.

---

## Alacritty

Sources:
- `alacritty/alacritty.toml`
- `bin/herdr-remote-launch`
- `bin/herdr-remote-terminal`

Other Alacritty workflow settings:
- `live_config_reload = true`
- `dynamic_padding = true`
- `selection.save_to_clipboard = true`

---

## skhd (macOS)

Source:
- `skhd/skhdrc`

Configured hotkeys include:
- App/space switching: `alt-1/2/3/9/0` and `` alt-` `` (Ghostty)
- Private Safari: `cmd-return`
- Yabai fullscreen zoom toggle: `alt+shift-f`
- Space layout cycle: `alt-space` (bsp → stack → float)

---

## Mango WM (Linux)

Source:
- `mango/config-bindings.conf`

This file contains the full Linux keymap set (window focus/move/resize/layout/tags/screenshots/mouse/gestures), using ALT number bindings for workspace navigation.

Notable launchers:
- `Alt+Return` and `Super+Return` launch Alacritty
- `Super+S` switches to tag 4 and launches Palworld through Steam
- `Super+O` switches to tag 3 and opens the Bolt OSRS launcher


---

## Tip: commands to regenerate this index

Run these commands from the repository root. Each command is independent and
prints the relevant source file or matching lines; none changes files.

Neovim keymaps:

```bash
grep -R "vim.keymap.set" nvim -n
```

macOS `skhd` bindings:

```bash
cat skhd/skhdrc
```

Mango bindings:

```bash
cat mango/config-bindings.conf
```
