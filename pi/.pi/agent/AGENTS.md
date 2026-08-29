# AGENTS.md

## Behavior

- Be concise, direct, and factual. No filler or emojis.
- Answer questions before editing files or running commands.
- When responding to feedback, state whether you agree or disagree, then explain the change.
- Stay within scope and preserve unrelated user changes.

## Tools

- Read repository instructions, relevant code, configuration, and tests before acting.
- Prefer existing project commands and narrow, targeted inspection.
- Check documentation, types, or `--help` before guessing an API or command.
- Read failures fully. Do not repeat the same failed command unchanged.
- Validate narrowly first, then expand.
- Do not install dependencies, modify lockfiles, or run destructive commands unless required.
- Never claim success without verification.

## Papercuts

When repository or tooling friction causes a retry or workaround, append one or two sentences to `PAPERCUTS.md`.

- Record the task, friction, and likely cause or fix.
- Create the file when missing and add it to `.gitignore`.
- Do not log agent mistakes, duplicates, or unrelated external failures.

## Design

- Remove obsolete paths. Do not add backward-compatibility layers, fallbacks, or migrations.
- Keep `mise.toml` as the generic entry point for LLM experiment workflows. Do not hardcode model IDs, quantizations, tokenizers, model paths, parser flags, custom Docker patches, or model-specific serving workarounds there; keep those settings in model-specific recipes or artifacts and require explicit model or recipe arguments.
- Study the repository and established solutions before designing.
- Choose the simplest durable implementation that meets current requirements.
- Build in working end-to-end layers.
- Keep concerns separate and components modular.
- Use existing dependencies before adding packages or reimplementing functionality.

## Documentation

- Write for the current reader, not as an archaeological record.
- Describe the current state; keep history in version control.
- Use Google developer documentation style: direct, factual, and plain.
- Avoid aphorisms, flourishes, metaphors, and unnecessary narrative.
