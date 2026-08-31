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

## Worktrunk and Herdr

Worktrunk owns Git worktree creation, paths, hooks, merges, and cleanup. Herdr
owns workspace presentation and focus. The Worktrunk plugin runs `wt` with
structured output, then registers the resulting checkout as a native Herdr
worktree workspace. The project picker above remains separate from worktree
selection.

Install the reviewed plugin revision after installing the locked tools:

```sh
herdr plugin install devashish2203/herdr-worktrunk --ref 9cde723b7c6ea5d3f4de94760888de0e4090727b --yes
```

Reload Herdr after changing its configuration:

```sh
herdr server reload-config
```

Inside Herdr, use the Worktrunk actions bound in `herdr/.config/herdr/config.toml`:
`prefix+shift+g` opens the default-branch picker, `prefix+shift+c` creates from
the current branch, `prefix+shift+r` includes remote branches, `prefix+shift+d`
removes a worktree, and `prefix+shift+m` merges one. Worktrunk's Zsh shell
integration owns directory changes for plain `wt switch`; the plugin passes
`--no-cd` and lets Herdr focus the workspace instead.

## Safe worktree synchronization

The private `git sync` alias keeps the original inline Git-config workflow.
Run it from the primary worktree. It refuses a dirty worktree, switches to
`main`, pulls with `--prune --ff-only`, and removes only clean Worktrunk
worktrees marked integrated or empty. It uses Worktrunk JSON schema 2 and
foreground removal. The companion `git rm-merged` alias now considers only
already-merged branches and uses normal `git branch -d`, never force deletion.

`git-checkouts` is a separate deployment boundary. Use `git push checkouts`
explicitly when a push should materialize a remote checkout; synchronization
never invokes that remote implicitly.
