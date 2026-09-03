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
owns workspace presentation and focus. The user Worktrunk hooks call Herdr's
public worktree/workspace CLI so direct Worktrunk commands stay visible in
Herdr:

- `post-switch` opens or focuses the matching native Herdr worktree workspace.
- `post-remove` closes Herdr panes whose cwd is the removed worktree.

The hooks skip operations launched by the Herdr Worktrunk plugin, which
already performs the same UI registration. The project picker above remains
separate from worktree selection.

Install the reviewed plugin revision after installing the locked tools if you
want its Herdr picker and merge actions:

```sh
herdr plugin install devashish2203/herdr-worktrunk --ref 9cde723b7c6ea5d3f4de94760888de0e4090727b --yes
```

Reload Herdr after changing its configuration:

```sh
herdr server reload-config
```

Inside Herdr, use the Worktrunk actions bound in `herdr/config.toml`:
`prefix+shift+g` opens the default-branch picker, `prefix+shift+c` creates from
the current branch, `prefix+shift+r` includes remote branches, `prefix+shift+d`
removes a worktree, and `prefix+shift+m` merges one. These actions use
Worktrunk's hooks and the plugin's `--no-cd`/native workspace handoff. For a
plain `wt switch` in a normal Herdr pane, the post-switch hook opens or focuses
the destination workspace without needing the picker.

## Safe worktree synchronization

The private `git sync` alias keeps the original inline Git-config workflow.
Run it from the primary worktree. It refuses a dirty worktree, switches to
`main`, pulls with `--prune --ff-only`, and removes only clean Worktrunk
worktrees marked integrated or empty. It uses Worktrunk JSON schema 2 and
removes them in the foreground; each `wt remove` therefore runs the
post-remove hook and closes panes for the stale worktree. The
companion `git rm-merged` alias force-deletes local branches whose upstream is
gone, including unmerged branches. A branch still checked out in another
worktree is retained because Git will not delete an attached branch.

`git-checkouts` is a separate deployment boundary. Use `git push checkouts`
explicitly when a push should materialize a remote checkout; synchronization
never invokes that remote implicitly.
