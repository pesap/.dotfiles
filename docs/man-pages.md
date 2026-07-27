# Local man pages

The custom command manuals live in the `man` Stow package and install with the
same profile as Loom:

```console
$ loom setup --local --profile common
$ exec zsh
$ man loom
```

The package installs manuals under `~/.local/share/man/man1` and adds that
directory to `MANPATH` through the Zsh configuration.

Available manuals:

```console
$ man loom
$ man git-checkouts
$ man pr-digest
$ man zession
$ man wallpaperctl
```

To inspect a manual directly from the checkout without installing it:

```console
$ man -l man/.local/share/man/man1/loom.1
```

The Waybar, Mango, clipboard, and macOS helper scripts are implementation
helpers rather than stable interactive commands, so they do not each have a
separate manual page.
