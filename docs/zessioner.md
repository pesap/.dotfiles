# Zessioner

`bin/.local/bin/zessioner` is the context-neutral picker used by workflows such as `zellij-zessioner`. Herdr uses the intentionally smaller `herdr-sessionizer` command instead.

The picker owns:

- zoxide project discovery filtered by `ZESSIONER_ROOTS`;
- deterministic ordering and duplicate suppression;
- the fzf interface and keyboard bindings;
- generic Git previews;
- project/context row parsing.

It does not know how a context is created, focused, or closed. That behavior is supplied by an adapter.

## Adapter interface

Pass an executable adapter with `--adapter`:

```text
adapter --rows
adapter --select KIND ID PATH NAME
adapter --close ID NAME
```

`--rows` emits tab-separated records:

```text
kind  id  path  name  state  rank  sort-key
```

`kind` is `project` for rows owned by the picker or an adapter-specific value such as `zellij`. The `state` value may be `current`, `active`, or `idle`; it controls the row marker. `rank` controls grouping, and `sort-key` controls ordering within a group.

The picker invokes `--select` after Enter. Project rows use `-` as their sentinel `ID`; the adapter decides how to create a context for the supplied path. `--close` is only invoked for adapter rows; project rows cannot be deleted by the generic UI.

## Example

```sh
zessioner \
  --adapter "$HOME/.local/bin/zellij-zessioner-adapter" \
  --roots "$HOME/dev:$HOME/work" \
  --prompt 'session › '
```

A Zellij, tmux, editor, or plain-shell workflow can reuse `zessioner` by implementing the three adapter operations. No multiplexer-specific protocol belongs in the picker itself.
