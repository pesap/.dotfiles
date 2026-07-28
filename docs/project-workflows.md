# Project workflows

The project workflow has one small shared interface:

```text
project-picker [DIRECTORY]  -> selected directory
```

`project-picker` uses `project-dirs` for discovery. The provider searches the
first level under these roots:

```text
~/dev
~/work
~/projects
~/personal
~/sandbox
```

`~/.dotfiles` is included as an explicit project. Override the lists with
`PROJECT_ROOTS` and `PROJECT_PATHS`, using colon-separated values.

The multiplexer launchers all consume the same selected directory:

```text
tmux-project [DIRECTORY]
zellij-project [DIRECTORY]
herdr-project [DIRECTORY]
```

Without an argument they open the shared picker. With an argument they skip
selection. Each launcher creates or reuses a session named after the project
basename, then attaches or switches according to the current multiplexer
context.

Herdr needs a small amount of additional handoff logic because nested Herdr
clients are not supported. Its project launcher uses the native Herdr popup to
ask the outer launcher to switch sessions cleanly.
