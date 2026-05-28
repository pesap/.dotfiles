# Keymaps by Program

Last updated: 2026-05-18

This is a central index of keymaps configured in this dotfiles repo, grouped by program.

---

## Neovim

Sources:
- `nvim/.config/nvim/lua/keymaps.lua`
- `nvim/.config/nvim/lua/plugins/fzflua.lua`
- `nvim/.config/nvim/lua/plugins/harpoon.lua`
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
- `<leader>qo` → quickfix open (overrides earlier "close other buffers" mapping)
- `j` / `k` → wrapped-line aware movement
- `J` / `K` (visual) → move selected lines down/up
- `<C-d>` / `<C-u>` → half page jump, centered
- `n` / `N` → next/prev search result, centered
- `Q` and `q` → disabled
- `<leader>sr` → substitute word under cursor in file
- `<leader>sp` → grep word under cursor project-wide
- `<leader>srp` → project-wide replace via quickfix
- `<leader>qc` → quickfix close
- `<leader>qj` / `<leader>qk` → quickfix next/prev + center
- `<leader>qh` / `<leader>ql` → quickfix first/last
- `<` (terminal mode) → leave terminal + move left
- `:Wq` → `:wq`
- `:Q` → `:q`
- `*` / `#` → search word without jumping
- `<Esc>` → clear search highlight
- `//` (visual) → search selection
- Arrow keys → warn to use hjkl
- `<leader>-` / `<leader>_` → horizontal/vertical split
- `zz` → scroll current line near top (+ offset)
- `<leader>ww` → switch window
- `<leader>gF` (n,v) → go to file (+line) helper

### FZF-Lua (`plugins/fzflua.lua`)

- `<leader>ff` files
- `<leader>fb` builtins
- `<leader>fk` keymaps
- `<leader>gr` LSP references
- `<leader>gd` LSP definitions
- `<leader>gp` grep project
- `<leader>gg` live grep native
- `<leader>gw` / `<leader>gW` grep current word/WORD
- `<leader>/` grep current buffer
- `<leader><leader>` buffers
- `<leader>fm` marks
- `<leader>gf` git files
- `<leader>sb` git branches
- `<leader>fn` files in `~/.config/nvim`
- `<leader>fs` document symbols
- `<leader>ws` workspace symbols
- `<leader>fd` files in `~/dev/`
- `<leader>fp` files in `./packages/`
- `<leader>ft` files in `tests/`
- `<leader>rp` PR review picker workflow
- `<leader>rr` PR review reset

### Harpoon (`plugins/harpoon.lua`)

- `<leader>t` add file
- `<leader>mm` toggle Harpoon menu
- `<leader>1..5` jump to Harpoon slots
- `<leader>n` next Harpoon entry
- `<leader>p` previous Harpoon entry

### Git / Fugitive (`plugins/tpope.lua`)

- `<leader>gb` `:GBrowse`
- `<leader>gd` `:Gdiff`
- `<leader>gl` toggle `:Git log %`
- `<leader>gs` toggle `:Git` status

### Gitsigns (`plugins/gitsigns.lua`)

- `<leader>hn` next hunk
- `<leader>hp` previous hunk

### Theme picker (`plugins/colorscheme.lua`)

- `<leader>tc` open theme selector (fzf-lua colorschemes or `vim.ui.select` fallback)

### Review plugin toggle (`after/plugin/reviewer.lua`)

- `<leader>rp` `:ReviewToggle`

### Window maximize (`plugins/vim-maximizer.lua`)

- `<leader>wm` toggle maximizer

### Neovim mapping collisions to be aware of

- `<leader>rp`: defined in both `fzflua.lua` and `after/plugin/reviewer.lua`
- `<leader>gd`: defined in both `fzflua.lua` and `tpope.lua`
- `<leader>qo`: defined twice in `keymaps.lua`; final mapping is quickfix open

---

## Zellij

Sources:
- `zellij/.config/zellij/config.kdl`
- `zellij/.config/zellij/layouts/default.kdl`
- `zellij/.config/zellij/layouts/dev.kdl`
- `zellij/.config/zellij/layouts/pi.kdl`

### Mode keymaps (full)

#### `normal`

| Key | Action |
|---|---|
| `Ctrl+l` | switch to Locked mode |
| `Ctrl+p` / `Ctrl+t` / `Ctrl+n` / `Ctrl+h` / `Ctrl+b` | enter Pane/Tab/Resize/Move/Tmux mode |
| `Alt+1..4` | go to tab 1..4 + return to Locked mode |
| `Alt+f` | open floating `zsh` pane + return to Locked mode |
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
| `Ctrl+\\` / `Alt+\\` | run floating `zession` Bash picker + stay Locked |

#### `resize`

| Key | Action |
|---|---|
| `Ctrl+n` | switch to Normal mode |
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
| `Ctrl+p` | switch to Normal mode |
| `h` / `Left` | move focus left |
| `l` / `Right` | move focus right |
| `j` / `Down` | move focus down |
| `k` / `Up` | move focus up |
| `p` | switch focus |
| `n` | new pane + Normal mode |
| `d` | new pane down + Normal mode |
| `r` | new pane right + Normal mode |
| `x` | close focused pane + Normal mode |
| `f` | toggle pane fullscreen + Normal mode |
| `z` | toggle pane frames + Normal mode |
| `w` | toggle floating panes + Normal mode |
| `e` | toggle pane embed/floating + Normal mode |
| `c` | rename pane mode |

#### `move`

| Key | Action |
|---|---|
| `Ctrl+h` | switch to Normal mode |
| `n` / `Tab` | move pane |
| `p` | move pane backwards |
| `h` / `Left` | move pane left |
| `j` / `Down` | move pane down |
| `k` / `Up` | move pane up |
| `l` / `Right` | move pane right |

#### `tab`

| Key | Action |
|---|---|
| `Ctrl+t` | switch to Normal mode |
| `r` | rename tab mode |
| `h` / `Left` / `Up` / `k` | go to previous tab |
| `l` / `Right` / `Down` / `j` | go to next tab |
| `n` | new tab + Normal mode |
| `x` | close tab + Normal mode |
| `s` | **unbound** (toggle active sync removed) |
| `b` | break pane + Normal mode |
| `]` | break pane right + Normal mode |
| `[` | break pane left + Normal mode |
| `1..9` | go to tab 1..9 + Normal mode |
| `Tab` | toggle previous tab |

#### `scroll`

| Key | Action |
|---|---|
| `Ctrl+s` | switch to Normal mode |
| `e` | edit scrollback + Normal mode |
| `s` | EnterSearch mode |
| `Ctrl+c` | scroll to bottom + Normal mode |
| `j` / `Down` | scroll down |
| `k` / `Up` | scroll up |
| `Ctrl+f` / `PageDown` / `Right` / `l` | page scroll down |
| `Ctrl+b` / `PageUp` / `Left` / `h` | page scroll up |
| `d` | half-page scroll down |
| `u` | half-page scroll up |

#### `search`

| Key | Action |
|---|---|
| `Ctrl+s` | switch to Normal mode |
| `Ctrl+c` | scroll to bottom + Normal mode |
| `j` / `Down` | scroll down |
| `k` / `Up` | scroll up |
| `Ctrl+f` / `PageDown` / `Right` / `l` | page scroll down |
| `Ctrl+b` / `PageUp` / `Left` / `h` | page scroll up |
| `d` | half-page scroll down |
| `u` | half-page scroll up |
| `n` | next search result |
| `p` | previous search result |
| `c` | toggle case sensitivity |
| `w` | toggle wrap |
| `o` | toggle whole-word |

#### `entersearch`

| Key | Action |
|---|---|
| `Ctrl+c` / `Esc` | switch to Scroll mode |
| `Enter` | switch to Search mode |

#### `renametab`

| Key | Action |
|---|---|
| `Ctrl+c` | switch to Normal mode |
| `Esc` | undo rename + Tab mode |

#### `renamepane`

| Key | Action |
|---|---|
| `Ctrl+c` | switch to Normal mode |
| `Esc` | undo rename + Pane mode |

#### `session`

| Key | Action |
|---|---|
| `Ctrl+o` | switch to Normal mode inside Session mode only |
| `Ctrl+s` | switch to Scroll mode |
| `d` | detach |
| `w` | open/focus session-manager plugin (floating) + Normal mode |

#### `tmux`

| Key | Action |
|---|---|
| `[` | switch to Scroll mode |
| `Ctrl+b` | write `Ctrl+b` + Normal mode |
| `"` | new pane down + Normal mode |
| `%` | new pane right + Normal mode |
| `z` | toggle fullscreen + Normal mode |
| `c` | new tab + Normal mode |
| `,` | rename tab mode |
| `p` | previous tab + Normal mode |
| `n` | next tab + Normal mode |
| `Left/Right/Up/Down` | move focus + Normal mode |
| `h/j/k/l` | move focus + Normal mode |
| `o` | focus next pane |
| `d` | detach |
| `Space` | next swap layout |
| `x` | close focused pane + Normal mode |
| `Ctrl+o` | **unbound** Session mode entry |
| `Ctrl+f` | switch to Session mode |

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
| normal | `Alt+f` | open floating `zsh` pane + return to Locked mode |
| normal | `Alt+p` | floating pane inventory + return to Locked mode |
| normal | `Alt+t` | run floating pinned `just test` pane + return to Locked mode |
| normal | `Ctrl+y` | open layout picker plugin + return to Locked mode |
| tab | `1..4` | go to tab 1..4 + return to Locked mode |
| pane/tab/resize/move/tmux/scroll | `Esc` / `Enter` or mode entry key | return to Normal mode |

### Mode/keymap notes

- Zellij starts in `locked` mode so app-level keys pass through by default.
- `Ctrl+l` toggles between `locked` and `normal`; use it to unlock Zellij controls or lock back into app keymaps.
- `Ctrl+o` is intentionally unbound globally so Pi can use it to expand tools.
- `Alt+d` detaches directly from locked mode.
- Inside `zession`, `Ctrl-D`/`Alt-D` deletes the selected saved/live session entry; `Esc`/`Ctrl-C` closes the picker.
- `default.kdl`, `dev.kdl`, `pi.kdl`, and `vibe.kdl` add a top `zellij-locked-indicator` row that shows `🔐` only while locked.

### Theme notes

- Zellij theme is explicitly set to built-in `tokyo-night-storm`
- This now matches the broader Tokyo Night terminal/editor palette better than the default theme

### Layout-specific notes (`default.kdl`)

- `term` tab: regular terminal only
- Use `Alt+f` for a floating terminal pane

### Layout-specific notes (`vibe.kdl`)

- `pi` tab: large left `pi`, top-right `pi`, bottom-right scratch terminal
- `review` tab: `nvim` in the project cwd with `ReviewToggle` opened
- `scratch` tab: single scratch terminal

### Layout-specific notes (`dev.kdl`)

- `code` tab: `nvim` + `pi`
- `review` tab: `gitu` + `pi`
- In both tabs, primary pane width is fixed to `110` columns (to match default Neovim width), secondary `pi` pane fills remainder
- Tests are ephemeral: use `Alt+t` to open floating pinned `just test`

---

## Alacritty

Source:
- `alacritty/.config/alacritty/alacritty.toml`

Keyboard handling:
- `Cmd+1..4` in Alacritty sends `Alt+1..4` escape sequences to Zellij.
- `Super+1..4` does the same on Linux when the window manager does not intercept it.
- Zellij binds `Alt+1..4` directly in locked and normal modes.
- Physical `Alt+1/2/3/9/0` on macOS belongs to skhd app/space switching, not Zellij.

Other Alacritty workflow settings:
- `live_config_reload = true`
- `dynamic_padding = true`
- `selection.save_to_clipboard = true`

---

## skhd (macOS)

Source:
- `skhd/.config/skhd/skhdrc`

Configured hotkeys include:
- App/space switching: `alt-1/2/3/9/0`
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
