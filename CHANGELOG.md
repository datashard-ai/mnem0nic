# Changelog

All notable changes to mnem0nic are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-10-26

### Added

- **Your Macs in step.** Run `mnem0nic pair` on two of your Macs and type the six-digit code one of
  them shows. From then on, whenever both are on the same network, they sync your memory between
  them: notes, session summaries, prompts, to-do lists, checkpoints, and Claude Code's own memory
  notes. There is no server and no account; only Macs you paired take part, and the link between
  them is encrypted.
- **Catching up.** Both Macs keep working while apart and catch up when they meet again, with nothing
  sent twice. A record that cannot be applied is set aside after three tries instead of blocking the
  rest. If the same Claude Code note was edited on both, the later edit is kept, the other stays in
  its history (`mnem0nic notes history NAME`), and the next session start says so.
- **New commands:** `mnem0nic pair`, `devices`, `unpair`, `sync status`, `sync now`,
  `notes history` and `project merge`.

### Changed

- **A project is named after its Git remote** (`org/repo`), so it keeps its memory when its folder
  moves, every clone and worktree of a repository shares it, and it has the same name on each of your
  Macs. Memory recorded under the old folder-based names stays where it was and is still found.
- After pairing, macOS keeps the sync port open for mnem0nic and starts it only when your other Mac
  connects; nothing runs while you're idle. `mnem0nic uninstall` removes it.

## [0.1.3] - 2026-10-25

### Added

- **`mnem0nic install` brings your claude-mem history over.** When claude-mem's database is on your
  Mac, it asks whether to import it (Enter means yes), and imports it without asking when there is
  no terminal to answer. `--no-import` skips it. The import only reads claude-mem's database, and
  running it again adds only what is new.

## [0.1.2] - 2026-10-25

### Changed

- **`mnem0nic import-claude-mem` finds your claude-mem history on its own,** where claude-mem keeps it,
  even if you moved claude-mem's data folder. `--db` is only needed for a copy kept somewhere else.
- **Clearer messages:** if there is no claude-mem database, the import says where it looked.
  `mnem0nic install` points to the step-by-step guide for moving from claude-mem.

## [0.1.1] - 2026-10-25

First public release.

### Added

- **One-command setup.** `mnem0nic install` sets up capture and the MCP tools for all your projects, in
  Claude Code and Codex, and backs up each settings file it changes. `mnem0nic uninstall` removes
  them again; `--purge` also deletes your memory.
- **Capture** of Claude Code and Codex sessions: prompts, replies, and tool calls with their input and
  output, with recognised secrets redacted.
- **Notes after every turn,** written through each CLI's own paid plan: Claude Code turns with Claude
  Haiku, Codex turns with `codex exec`.
- **Paid plans only.** Each CLI is set up only when it is signed in with its own paid plan, and checked
  again at every session start and before every note. API keys, Amazon Bedrock and Google Vertex AI
  are never used.
- **Search** by words, and by meaning once `mnem0nic embed` has downloaded the model.
- **claude-mem compatibility:** the same MCP tools by name, and `mnem0nic import-claude-mem` to bring
  your history over.
- **Install script** that checks each download's SHA-256 checksum.

[0.1.3]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.3
[0.1.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.2
[0.1.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.1
