# AGENTS.md

## Work

- Be concise, direct, factual. Answer questions before acting; on feedback, say agree/disagree; preserve unrelated user changes.
- Before editing, inspect current content and apply the smallest exact change. Never overwrite or revert content outside the requested scope.
- For repo work: locate root, read instructions, inspect Git status; use targeted inspection for commands, config, tests, patterns. Use `project-dirs` before broad local search or cloning.
- Check docs, types, or `--help` before assuming an interface. Read failures; never repeat an unchanged failed command.
- If requirements, data semantics, or APIs remain unclear after targeted inspection, ask the user; do not guess or use speculative workarounds.
- Validate relevant changes before claiming success. Do not install dependencies, modify lockfiles, or run destructive commands unless required.
- Before destructive work, verify the exact target and scope. Never run broad cleanup, reset, or recursive deletion without explicit approval.
- Do not call a bug fixed from inspection alone. Reproduce it or add a regression test when feasible; otherwise state the limitation.

## Decisions

- No em dashes or Markdown bold.
- Separate facts from inferences. Do not present unverified assumptions, tool output, or external claims as facts.
- Challenge assumptions: identify disconfirming evidence, seek it when practical, revise on contradiction. When feasible, run the fastest safe relevant check before implementation; use the result to refine the plan.

## Tools

- Keep project `mise.toml` separate from `~/.dotfiles/mise/.config/mise/config.toml`; never merge definitions/settings.
- Add each machine-wide CLI only there via `mise`, with source/version, including `cargo`, `uv`, and similar installers. Never use unmanaged global installs.
- Treat `~/.dotfiles` as required binary/script source. Before adding, downloading, or writing a binary/script, inspect `bin/.local/bin` and `scripts/`; reuse maintained work when suitable.
- Keep generic `mise` workflows model-agnostic; put model-specific settings in explicit recipes/artifacts.

## LLM gates

- Do not ship, default-enable, or claim improvement without a versioned task-specific held-out set and same-harness baseline. Tune only on separate development cases; sets with fewer than 30 held-out cases are exploratory, never release evidence. Grade outcomes/evidence, not style, length, confidence.
- Report rates for task success, critical errors, unsupported claims, and schema/format failures; p50/p95 latency; cost per success. Record model, prompt, tools, sampling, data version, sample size, confidence intervals.
- Release only at >=95% held-out success, 0% critical errors, unsupported claims, and required-schema failures, with no quality regression >1 percentage point vs baseline. Critical: unsafe/destructive action, privacy leak, fabricated evidence/result, ignored explicit instruction.
- No self-grading, anecdotes, cherry-picked examples, or aggregate preference scores as release evidence. Human judging: blinded, rubric-based, independently double-scored. Preserve reproducible, redacted failure cases; validate fixes only on new held-out cases.

## Engineering

- Backward compatibility is forbidden: no legacy paths/layers, fallbacks, migrations, or feature-detection shims. Remove obsolete behavior.
- Design and validate the domain model before behavior. If distinctions need `isThing`/`isThatOtherThing` chains, redesign it.
- Use public APIs only. If a requirement cannot be met through one, rethink the approach; do not rely on private internals.
- Keep docs direct and current; describe current behavior, not history.
- If repo/tooling friction needs a workaround, add concise actionable `PAPERCUTS.md` note: task, friction, likely cause/fix. Create and gitignore it if needed; exclude agent mistakes, duplicates, unrelated external failures.
