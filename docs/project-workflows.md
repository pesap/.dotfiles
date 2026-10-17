# Project workflows

The project workflow has one small shared interface:

```text
project-picker [DIRECTORY]  -> selected directory
```

`project-picker` and the Herdr session picker share discovery. Edit
[`project_paths`](../project_paths) in this checkout to choose predefined folders.
The default list is:

```text
~/.dotfiles
~/dev/*
~/work/*
~/sandbox/*
~/personal/*
```

An exact path pins that folder. A final `/*` includes only immediate child
folders, not a recursive scan. Use absolute paths or `~/` paths. Spaces are
literal, so do not quote paths. Blank lines and lines starting with `#` are
ignored. Missing folders and resolved project paths containing line breaks are
skipped. The file is data, not an executable shell configuration. Set `PROJECT_PATHS_FILE` to use another list.

`project_paths` is the strict picker allowlist. Zoxide only orders those
projects by its ranking, including visits to their subfolders. It never adds
folders, even Git repositories outside the list. Unvisited entries retain file
order. An explicitly pinned folder remains available even if it is hidden or
is not a Git repository.

Entries are deduplicated by physical project path. Git subdirectories and
linked worktrees resolve to their primary checkout. For a bare repository, the
first non-bare checkout is used. There is no implicit home-directory scan.

Linked-worktree mappings are cached between picker openings. The allowlist,
folder discovery, zoxide ranking, and saved-session state are still read fresh.
A cache hit older than 10 seconds starts a detached background refresh. Mappings
older than five minutes are no longer used. A changed `.git` link or missing
primary directory invalidates a mapping immediately. Cold lookups query Git.

The cache contains checkout paths, Git-link contents, primary paths, and lookup
timestamps, not candidate lists or running-state flags. It is stored at
`$XDG_CACHE_HOME/project-picker/worktrees.json` when that override is set.
Otherwise the location is `~/Library/Caches/project-picker/worktrees.json` on
macOS or `~/.cache/project-picker/worktrees.json` on Linux. Writes use atomic
replacement, with private directory and file permissions. Cache errors do not
prevent discovery. Set `PROJECT_PICKER_CACHE=0` to bypass persistent cache
reads, writes, and background refresh.

Herdr is the only project sessionizer. It consumes the shared selected
directory:

```text
herdr-project [DIRECTORY]
```

Without an argument it opens the shared picker. With an argument it skips
selection and opens the project in a Herdr workspace.

Inside Herdr, `Ctrl+\\` opens a combined session and project picker. Enter
switches to a saved session or starts a named session for a project without one.
Project entries and saved sessions must match the `project_paths` allowlist.
A session displays its base project path while its preview uses the active
workspace directory. A saved session suppresses the duplicate project entry
and keeps that project's zoxide ordering. The separate session manager,
`herdr-project --session-kill`, still lists unconfigured sessions for cleanup.
Sessions without a project path remain omitted.

The pickers use Bash, Git, zoxide, jq, and fzf. Previews run only for the
highlighted entry, using bat for `README.md` or fd for a short file listing.
Project discovery does not run either preview tool. The combined picker starts
fzf concurrently with candidate generation. Path normalization uses Bash
built-ins without per-folder subprocesses and restores the caller's directory
state. JSON parsing and formatting are batched rather than spawning jq for each
project or session.

Herdr needs a small amount of additional handoff logic because nested Herdr
clients are not supported. Its project launcher uses the native Herdr popup to
ask the outer launcher to switch sessions cleanly. Other sessionizers are not
part of this configuration.

## Validate picker startup

From the checkout root, with the configured tools installed, run this
non-interactive test. It creates isolated folders under `/var/tmp`, runs no live
Herdr session actions, and cleans up only its validated test directory:

```sh
bash tests/project-test.sh
```

Success prints `project tests: ok`. The startup regression case loads 300
folders and 40 saved sessions through the row builder and real fzf filter. It
fails if loading takes one second or longer, or if JSON process counts grow
with the candidate count. This measures candidate loading, not terminal drawing
or Herdr popup animation. Filesystem and machine load affect elapsed time.

From the same checkout root with Bash, Git, and jq installed, run the cache
lifecycle test. It uses isolated cache directories and a controlled clock under
`/var/tmp`, with no live session actions or changes to your normal cache:

```sh
bash tests/project-cache-test.sh
```

Success prints `project cache tests: ok`. This checks warm hits, changed Git
links, expiry, nonblocking refresh, fresh session status, cache errors, private
permissions, and concurrent atomic writes.

## Worktrunk and Herdr

The mise entries link only each tool's declarative `config.toml`. Herdr
sessions, plugin state, logs, and Worktrunk approvals remain beside those files
in the runtime config directories, outside the dotfiles checkout. If an
existing machine still has `~/.config/herdr` or `~/.config/worktrunk` as a
directory symlink to this checkout, stop its Herdr sessions and move the
non-config contents into real config directories before applying the file
entries. Applying the file entries while those parent symlinks remain would
create nested links in the checkout instead of moving the runtime state.

Worktrunk owns Git worktree creation, paths, hooks, merges, and cleanup. Herdr
owns workspace presentation, navigation, and focus. The user Worktrunk hooks
call Herdr's public worktree/workspace CLI so direct Worktrunk commands stay
visible in Herdr:

- `[switch] cd = false` leaves the invoking Herdr pane in its source workspace.
- `post-switch` opens or focuses the matching native Herdr worktree workspace
  only if the checkout still exists when the hook runs.
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
removes them in the foreground. Worktrunk still runs `post-remove` hooks in the
background; that hook closes panes for the removed worktree. The companion
`git rm-merged` alias force-deletes local branches whose upstream is gone,
including unmerged branches. A branch still checked out in another worktree is
retained because Git will not delete an attached branch.

`git-checkouts` is a separate deployment boundary. Use `git push checkouts`
explicitly when a push should materialize a remote checkout; synchronization
never invokes that remote implicitly.
