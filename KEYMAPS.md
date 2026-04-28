# Keymaps by Program

Last updated: 2026-04-28

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

No direct binds in this block (navigation mostly comes from shared blocks below).

#### `locked`

| Key | Action |
|---|---|
| `Ctrl+l` | switch to Normal mode |

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
| `Ctrl+o` | switch to Normal mode |
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

### Shared keymaps (`shared_except ...`)

These apply on top of mode keymaps.

#### `shared_except "locked"`

| Key | Action |
|---|---|
| `Ctrl+g` | default locked-toggle removed (key is reused below) |
| `Ctrl+l` | switch to Locked mode |
| `Ctrl+q` | **unbound** |
| `Alt+f` | toggle floating panes |
| `Alt+n` | new pane |
| `Alt+i` / `Alt+o` | move tab left/right |
| `Alt+h/j/k/l` (+ arrows variants) | focus movement |
| `Alt+Shift+l` / `Alt+Shift+h` | resize increase/decrease |
| `Alt+=` / `Alt++` / `Alt+-` | resize increase/decrease |
| `Alt+[` / `Alt+]` | previous/next swap layout |
| `Alt+{` / `Alt+}` | move focus up/down + Normal mode (great with stacked lanes) |
| `Super+1` / `Super+2` | go to tab 1/2 + Normal mode |
| `Alt+1` / `Alt+2` | fallback go to tab 1/2 + Normal mode |
| `Alt+t` | run floating pinned `just test` pane + Normal mode |
| `Alt+p` | fast pane selector (`room.wasm`) + Normal mode |
| `Alt+Shift+p` | floating pane inventory (`zellij action list-panes --all --json`) + Normal mode |
| `Ctrl+\\` | open `room.wasm` pane selector |
| `Ctrl+y` | open layout picker plugin (tiled, non-floating) |
| `Ctrl+'` / `Ctrl+g` | run `zellij-sessionizer` floating + switch to Locked |

#### `shared_except "normal" "locked"`

| Key | Action |
|---|---|
| `Enter` / `Esc` | switch to Normal mode |

#### Mode entry shared keys

| Block | Key | Action |
|---|---|---|
| `shared_except "pane" "locked"` | `Ctrl+p` | switch to Pane mode |
| `shared_except "resize" "locked"` | `Ctrl+n` | switch to Resize mode |
| `shared_except "scroll" "locked"` | `Ctrl+f` | **unbound** Scroll mode entry |
| `shared_except "session" "locked"` | `Ctrl+o` | **unbound** Session mode entry |
| `shared_except "session" "locked"` | `Ctrl+s` | switch to Session mode |
| `shared_except "tab" "locked"` | `Ctrl+t` | switch to Tab mode |
| `shared_except "move" "locked"` | `Ctrl+h` | switch to Move mode |
| `shared_except "tmux" "locked"` | `Ctrl+b` | switch to Tmux mode |

### Layout-specific notes (`dev.kdl`)

- `code` tab: `nvim` + `pi`
- `review` tab: `gitu` + `pi`
- Tests are ephemeral: use `Alt+t` to open floating pinned `just test`

---

## Alacritty

Source:
- `alacritty/.config/alacritty/alacritty.toml`

Custom keyboard remaps:
- `Cmd+1` sends `ESC 1` (used by Zellij as `Alt 1`)
- `Cmd+2` sends `ESC 2` (used by Zellij as `Alt 2`)

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

This file contains the full Linux keymap set (window focus/move/resize/layout/tags/screenshots/mouse/gestures), including ALT/SUPER fallback bindings for workspace navigation.

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
