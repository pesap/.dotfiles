# Private configuration

The public repository contains portable defaults only. Machine-specific model
endpoints, private provider definitions, identities, and local paths belong in
the private `personal` submodule.

## Enable the private package

From an existing checkout with access to the private repository:

```sh
git submodule update --init personal && ./bin/.local/bin/loom setup --local --profile common
```

The private package currently supplies:

- `~/.pi/agent/extensions/dgx-spark.ts` for the private Pi provider; it only
  registers when `DGX_SPARK_BASE_URL` is set
- `~/.config/dotfiles/private.env` for private Hermes and local-provider
  environment variables
- personal Git identity and aliases

Without the submodule, built-in Pi providers and the public model context
configuration still work, but the private custom provider is not installed.

## Secrets

Do not put API keys, OAuth tokens, SSH private keys, or passwords in either
repository. Use environment variables, `~/.pi/agent/auth.json`, or the host's
credential manager. The private submodule is an access boundary for
configuration, not a secret store.

When changing a private endpoint, update the private submodule configuration and
restart the affected process. Do not add the endpoint to the public package.
