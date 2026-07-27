# Design and safety

> Explanation · Why this repository is split into packages, profiles, and
> separate update paths.

## Configuration is not runtime state

A dotfiles checkout should describe how a machine is configured, not become a
second package manager or a backup of every mutable directory in `$HOME`.

That is why the repository tracks source configuration and small scripts, while
these remain outside Stow:

- `~/.rustup` and `~/.cargo` hold Rust toolchains and Cargo state;
- `~/.local/share/mise` holds mise-managed tools and downloads;
- plugin caches, shell history, and editor state remain user-owned runtime data.

The boundary makes a checkout portable and keeps `git diff` meaningful.

## Stow packages are the linking boundary

Each top-level package mirrors paths relative to `$HOME`:

```text
zshrc/.config/zshrc/30-tools.zsh
└── ~/.config/zshrc/30-tools.zsh
```

GNU Stow creates the link. Editing the repository source changes the live
configuration after the relevant package is applied, while the repository
still has one obvious source of truth.

Loom's setup and apply commands add guardrails around Stow because a generic
`stow --adopt` workflow is too destructive for a live home directory. They
preflight, back up conflicts where appropriate, and reject undeclared or
runtime-state packages.

## Profiles are a blast-radius control

`common` is intentionally boring: it contains the shell, terminal, editor,
shared tools, and scripts that can be useful on either supported OS. Desktop
configuration is opt-in because window managers, bars, and platform settings
have a larger failure radius.

The profile is used in three places:

1. `loom setup` decides what to link;
2. `loom apply` decides what to refresh;
3. `loom check` decides what should exist.

Keeping these decisions in [`packages.conf`](../packages.conf) prevents the
three workflows from drifting apart.

## Why desktop updates are different

A typo in a shell alias is inconvenient. A broken window-manager configuration
can make a graphical session hard to use. `loom desktop` therefore does not behave like ordinary Stow:

1. it requires a clean Git tree, so the rollback source is unambiguous;
2. it applies only WM-scoped packages;
3. it runs platform smoke checks;
4. it asks for confirmation in an interactive session;
5. it restores the last-known-good tag if checks fail or confirmation expires.

`loom setup` remains the right tool for initial setup and `loom apply` handles
general package changes. `loom desktop` is the guarded promotion path for
desktop changes.

## Validation is intentionally read-only

CI and local validation should reveal missing dependencies, not install them as
a side effect. `scripts/validate.sh` sets mise's auto-install flags to `0`,
then checks syntax, structured configuration, plugin artifacts, keymap drift,
regressions, and whitespace. Tool installation is a separate explicit step:

```console
$ loom tools install
$ loom check --repo
```

This separation also makes failures reproducible: a validation run reports the
state of the checkout and environment that already exist.
