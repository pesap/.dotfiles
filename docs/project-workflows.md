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
owns workspace presentation, navigation, and focus. The user Worktrunk hooks
call Herdr's public worktree/workspace CLI so direct Worktrunk commands stay
visible in Herdr:

- `[switch] cd = false` leaves the invoking Herdr pane in its source workspace.
- `post-switch` opens or focuses the matching native Herdr worktree workspace.
- `post-remove` closes Herdr panes whose cwd is the removed worktree.

The post-switch hook runs for both direct and plugin-launched `wt switch`
operations. Herdr's open operation is idempotent, so an existing workspace is
focused rather than duplicated. Keeping directory changes with Herdr is
important: a detached post-switch hook must not see the invoking pane already
at the destination and mistake it for the destination workspace. From a
non-Herdr shell, pass Worktrunk's explicit `--cd` option when you want that
shell to change directory. The project picker above remains separate from
worktree selection.

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
plain `wt switch` in a Herdr pane, the post-switch hook opens or focuses the
destination workspace without needing the picker. The destination workspace
becomes the visible Herdr workspace; the source pane remains available in its
original workspace.

### Agent-first worktrees

The user alias `wt agent BRANCH` creates a new worktree and launches the
mise-managed Pi CLI inside it:

```sh
wt agent feature-name
```

For a one-off prompt, use Worktrunk directly:

```sh
wt switch --create feature-name --execute pi -- "Implement the requested change"
```

### Worktree dashboard

Worktrunk is configured to generate branch summaries using the existing Pi
commit-generation command. View summaries, CI state, PRs, and worktree status
with:

```sh
wt list --full
```

### Pull request worktrees

Switch directly to a pull request branch, or browse open pull requests in the
interactive picker:

```sh
wt switch pr:123
wt switch --prs
```

The PR picker requires an authenticated forge CLI such as `gh` or `glab`.

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
