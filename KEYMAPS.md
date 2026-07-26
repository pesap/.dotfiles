# Keymaps by Program

Last updated: 2026-07-26

This is a central index of keymaps configured in this dotfiles repo, grouped by program.

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

## Zellij

Sources:
- `zellij/.config/zellij/config.kdl`
- `zellij/.config/zellij/layouts/default.kdl`

### Configured mode keymaps

#### `normal`

| Key | Action |
|---|---|
| `Ctrl+l` | switch to Locked mode |
| `Ctrl+p` / `Ctrl+t` / `Ctrl+n` / `Ctrl+h` / `Ctrl+b` | enter Pane/Tab/Resize/Move/Tmux mode |
| `Alt+1..4` | go to tab 1..4 + return to Locked mode |
| `Alt+f` | toggle floating panes + return to Locked mode |
| `Alt+p` | open floating pane inventory (`list-panes --all --json`) + return to Locked mode |
| `Alt+t` | run floating pinned `just test` pane + return to Locked mode |
| `Alt+Shift+h` / `Alt+Shift+l` | resize decrease/increase |
| `Alt+{` / `Alt+}` | move focus up/down + return to Locked mode |
| `Ctrl+\\` / `Alt+\\` | run floating `zession` Bash picker + return to Locked mode |
| `Ctrl+y` | open layout picker plugin + return to Locked mode |

#### `locked`

| Key | Action |
|---|---|
| `Ctrl+l` | switch to Normal mode |
| `Alt+d` | detach session |
| `Alt+f` | toggle floating panes |
| `Alt+1..4` | go to tab 1..4 + stay Locked |
| `Ctrl+\\` / `Alt+\\` | run floating `zession` Bash picker + stay Locked |

#### `resize`

| Key | Action |
|---|---|
| `Ctrl+n` / `Esc` / `Enter` | switch to Normal mode |
| `Ctrl+l` | switch to Locked mode |
| `h` / `Left` | resize increase left |
| `j` / `Down` | resize increase down |
| `k` / `Up` | resize increase up |
| `l` / `Right` | resize increase right |
| `H` | resize decrease left |
| `J` | resize decrease down |
| `K` | resize decrease up |
| `L` | resize decrease right |
| `=` / `+` | resize increase |
| `-` | resize decrease |

#### `pane`

| Key | Action |
|---|---|
| `Ctrl+p` / `Esc` / `Enter` | switch to Normal mode |
| `Ctrl+l` | switch to Locked mode |
| `h` / `Left` | move focus left |
| `l` / `Right` | move focus right |
| `j` / `Down` | move focus down |
| `k` / `Up` | move focus up |
| `p` | switch focus |
| `n` | new pane right + Normal mode |
| `d` | new pane down + Normal mode |
| `r` | new pane right + Normal mode |
| `s` | new stacked pane + Normal mode |
| `x` | close focused pane + Normal mode |
| `f` | toggle pane fullscreen + Normal mode |
| `w` | toggle floating panes + Normal mode |
| `e` | toggle pane embed/floating + Normal mode |

#### `move`

| Key | Action |
|---|---|
| `Ctrl+h` / `Esc` / `Enter` | switch to Normal mode |
| `Ctrl+l` | switch to Locked mode |
| `n` / `Tab` | move pane |
| `h` / `Left` | move pane left |
| `j` / `Down` | move pane down |
| `k` / `Up` | move pane up |
| `l` / `Right` | move pane right |

#### `tab`

| Key | Action |
|---|---|
| `Ctrl+t` / `Esc` / `Enter` | switch to Normal mode |
| `Ctrl+l` | switch to Locked mode |
| `r` | rename tab mode |
| `h` / `Left` / `Up` / `k` | go to previous tab |
| `l` / `Right` / `Down` / `j` | go to next tab |
| `n` | new tab + Normal mode |
| `x` | close tab + Normal mode |
| `s` | toggle active sync + Normal mode |
| `1..4` | go to tab 1..4 + Locked mode |

#### `renametab`

| Key | Action |
|---|---|
| `Esc` | undo rename + Tab mode |
| `Ctrl+c` | undo rename + Tab mode |
| `Enter` | accept rename + Normal mode |

#### `tmux`

| Key | Action |
|---|---|
| `Ctrl+b` / `Esc` / `Enter` | switch to Normal mode |
| `Ctrl+l` | switch to Locked mode |
| `"` | new pane down + Normal mode |
| `%` | new pane right + Normal mode |
| `z` | toggle fullscreen + Normal mode |
| `c` | new tab + Normal mode |
| `,` | rename tab mode |
| `p` | previous tab + Normal mode |
| `n` | next tab + Normal mode |
| `h/j/k/l` or arrows | move focus + Normal mode |
| `d` | detach |

### Zellij keymaps

`keybinds clear-defaults=true` is intentional: only keys listed here are active, so hidden default bindings such as `Ctrl+g` are not present.

| Mode | Key | Action |
|---|---|---|
| locked | `Ctrl+l` | unlock to Normal mode |
| locked | `Alt+d` | detach |
| locked/normal | `Alt+1..4` | go to tab 1..4 + return to Locked mode |
| locked/normal | `Ctrl+\\` / `Alt+\\` | run floating `zession` Bash picker |
| normal | `Ctrl+l` | lock Zellij |
| normal | `Ctrl+p` / `Ctrl+t` / `Ctrl+n` / `Ctrl+h` / `Ctrl+b` | enter Pane/Tab/Resize/Move/Tmux mode |
| locked/normal | `Alt+f` | toggle floating panes |
| normal | `Alt+p` | floating pane inventory + return to Locked mode |
| normal | `Alt+t` | run floating pinned `just test` pane + return to Locked mode |
| normal | `Ctrl+y` | open layout picker plugin + return to Locked mode |
| tab | `1..4` | go to tab 1..4 + return to Locked mode |
| pane/tab/resize/move/tmux | `Esc` / `Enter` or mode entry key | return to Normal mode |

### Mode/keymap notes

- Zellij starts in `locked` mode so app-level keys pass through by default.
- `Ctrl+l` toggles between `locked` and `normal`; use it to unlock Zellij controls or lock back into app keymaps.
- `Ctrl+o` is intentionally unbound globally so Pi can use it to expand tools.
- `Alt+d` detaches directly from locked mode.
- Inside `zession`, `Ctrl-D`/`Alt-D` deletes the selected saved/live session entry; `Esc`/`Ctrl-C` closes the picker.
- `default.kdl` provides the status row, vertical tab list, and terminal pane.

### Theme notes

- Zellij theme is explicitly set to built-in `tokyo-night-storm`
- This now matches the broader Tokyo Night terminal/editor palette better than the default theme

### Layout-specific notes (`default.kdl`)

- `term` tab: regular terminal only
- Use `Alt+f` for a floating terminal pane

---

## Alacritty

Source:
- `alacritty/.config/alacritty/alacritty.toml`

Keyboard handling:
- `Cmd+1..4` in Alacritty sends `Alt+1..4` escape sequences to Zellij.
- `Super+1..4` does the same on Linux when the window manager does not intercept it.
- Zellij binds `Alt+1..4` directly in locked and normal modes.
- Physical `Alt+1/2/3/9/0` and `` Alt+` `` on macOS belong to skhd app/space switching, not Zellij.

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

Notable launcher:
- `Alt+Return` launches Alacritty

Note: SUPER+1..4 is reserved for Alacritty/Zellij tab selection; Linux workspace switching uses the configured Ctrl/Alt bindings instead.

---

## Tip: quick grep commands to regenerate this index

```bash
# Neovim keymaps
grep -R "vim.keymap.set" nvim/.config/nvim -n

# Zellij bindings
grep -n "bind \"" zellij/.config/zellij/config.kdl

# skhd
cat skhd/.config/skhd/skhdrc

# Mango
cat mango/.config/mango/config-bindings.conf
```
