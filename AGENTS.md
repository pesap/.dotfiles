# Agent Instructions

This repository manages files that are linked into a live user account. Treat
the real home directory and everything beneath it as production user data, not
as a disposable test environment.

## Non-negotiable filesystem safety

- Never recursively delete `$HOME`, `~`, `/home/morgoth`, the repository root,
  a workspace root, or any parent of those locations.
- Never use `HOME`, `home`, `CODEX_HOME`, or another standard environment
  variable as a temporary-directory variable or deletion target.
- Never use this unsafe pattern or any equivalent:

  ```sh
  HOME="$(mktemp -d)" command
  rm -rf "$HOME"
  ```

  An inline assignment applies to the command only; a later expansion of
  `$HOME` can resolve to the real home directory.
- Never pass an unresolved variable, command substitution, glob, empty string,
  symlink, or user-controlled path to `rm -r`, `rm -rf`, `find -delete`, or an
  equivalent recursive/destructive operation.
- Never run broad destructive Git commands such as `git clean -fdx`,
  `git reset --hard`, or `git checkout --` unless the user explicitly requests
  that exact operation and exact scope.
- Game saves, Steam data, personal files, credentials, browser data, and other
  non-dotfile content under the home directory are always out of scope.

## Safe temporary tests

- Put disposable test environments on the root filesystem with a narrowly
  named variable, for example:

  ```sh
  dotfiles_test_dir="$(mktemp -d /var/tmp/dotfiles-test.XXXXXX)"
  ```

- Pass a temporary home only to the command that needs it:

  ```sh
  env HOME="$dotfiles_test_dir" command
  ```

- Before cleanup, resolve and validate the exact target. It must:
  - be non-empty;
  - resolve beneath `/var/tmp/dotfiles-test.`;
  - not be a symlink;
  - not equal `/var/tmp`, `/tmp`, the repository, a workspace root, or the real
    home directory.
- Prefer an automatically managed temporary directory. If explicit cleanup is
  necessary, delete only the validated `dotfiles_test_dir`; never delete via
  `$HOME`.
- Keep the test command and its cleanup in the same script scope. Do not rely
  on environment-variable assignments persisting across commands.

## Markdown command examples

- Make every command example copy-pastable as written. Prefer one complete command per code block; do not present a sequence of dependent commands as if it were one pasteable command.
- When commands must run together, combine them into a single safe shell snippet with explicit sequencing (`&&` where failure should stop the next step), or provide a small script the user can copy as one unit.
- State the expected starting directory, required tools, environment variables, prompts, files changed, and whether the command is read-only or modifies the machine before the command block.
- After the block, explain what successful output or end state the user should expect. Call out commands that may prompt, take time, require confirmation, or fail safely.
- Keep examples honest: do not omit setup steps, hide side effects, or imply that a later command ran when the pasted command only ran the first line.

## Dotfile installation and Stow

- Inspect `git status` before changing anything. Existing modifications belong
  to the user unless proven otherwise; preserve them.
- Before `stow`, `restow`, bootstrap, install, or migration operations, inspect
  the script and run the available dry-run/verbose mode first.
- Never use `stow --adopt`, replace real files, remove conflicts, or overwrite
  user data without explicit user approval and a recoverable backup.
- Scope installation commands to named packages and explicit target
  directories. Do not run repository-wide cleanup as part of testing.
- Back up every real file that an installation would replace. Verify the backup
  before modifying the original.
- Tests for install scripts must target the validated temporary home, never the
  live home directory.

## Failure handling

- If a command times out, is interrupted, changes the current directory
  unexpectedly, or makes the repository disappear, stop immediately.
- After a timeout, verify whether the process is still running and inspect the
  affected paths before taking any further action.
- Do not reclone, recreate, restow, or continue an installer after unexpected
  filesystem loss. Preserve evidence, report the incident, and prioritize
  recovery.
- If the safety of a path or operation is uncertain, do not run it. Ask the
  user for direction.
