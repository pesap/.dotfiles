# Private configuration

The public repository contains portable defaults only. Machine-specific model
endpoints, private provider definitions, identities, and local paths belong in
the private `personal` submodule.

## Enable the private package

From the dotfiles repository root, initialize the private submodule and apply
its mise environment:

```sh
git submodule update --init personal && mise -E personal bootstrap --only dotfiles --yes
```

The personal package uses a flat layout so its files are easy to inspect:

```text
personal/
├── codex-litellm
├── dgx-spark.ts
├── gitconfig
├── gitconfig-work
└── private.env
```

Mise maps these files to their required home-directory locations. `private.env`
is copied rather than symlinked so private environment configuration stays
local to the machine. Re-run the same command after pulling changes to either
the public repository or the private submodule.

The private package supplies:

- `~/.pi/agent/extensions/dgx-spark.ts` for the private Pi provider; it only
  registers when `DGX_SPARK_BASE_URL` is set
- `~/.config/dotfiles/private.env` for private Hermes and local-provider
  environment variables
- personal Git identity and aliases through `~/.gitconfig` and
  `~/.gitconfig-work`
- `~/.local/bin/codex-litellm` for the local Codex wrapper

Without the submodule, built-in Pi providers and the public model context
configuration still work, but the private custom provider is not installed.

## Secrets

Do not put API keys, OAuth tokens, SSH private keys, or passwords in either
repository. Use environment variables, `~/.pi/agent/auth.json`, or the host's
credential manager. The private submodule is an access boundary for
configuration, not a secret store.

When changing a private endpoint, update the private submodule configuration
and restart the affected process. Do not add the endpoint to the public
package.
