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
~ (home-level project directories)
~/personal
~/sandbox
```

`~/.dotfiles` is included as an explicit project. Override the lists with
`PROJECT_ROOTS` and `PROJECT_PATHS`, using colon-separated values.

Herdr is the only project sessionizer. It consumes the shared selected
directory:

```text
herdr-project [DIRECTORY]
```

Without an argument it opens the shared picker. With an argument it skips
selection and opens the project in a Herdr workspace.

Herdr needs a small amount of additional handoff logic because nested Herdr
clients are not supported. Its project launcher uses the native Herdr popup to
ask the outer launcher to switch sessions cleanly. Other sessionizers are not
part of this configuration.
