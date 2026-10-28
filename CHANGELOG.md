# Changelog

All notable changes to mnem0nic are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-10-28

### Added

- **A small re-ranker puts the best results of a question in order.** When you ask for five
  results or more and your question is six words or more with nothing that looks like code or a
  path, a small model (TinyBERT, 18 MB, run by the memory daemon) reads the first ten results with
  your question and puts the best match first. It applies to `search`, `mem_search` and the past
  work handed over on every prompt. `mnem0nic install` and `mnem0nic embed` download it once, next
  to the search model; if that fails you are told, and search works without it. Turn it off with
  `rerank = false` under `[search]` in `config.toml` or `MNEM0NIC_RERANK=false`; an older mnem0nic
  rejects a `config.toml` that holds that key until the line is removed.

### Changed

- **Search puts the notes that match your words first.** Notes found by your words keep the first
  places, and the two nearest in meaning take the last two of the results (the first ten at most), so the note you meant
  comes first more often. It applies to `search`, `mem_search`, `memory_search` and the past work
  handed over on every prompt, whenever five results or more are asked for; fewer results keep the
  earlier order. Nothing is downloaded and no setting changes.

## [0.2.2] - 2026-10-26

### Added

- **Past work on every prompt, as claude-mem's `CLAUDE_MEM_SEMANTIC_INJECT`.** With
  `semantic_inject = true` under `[search]` in `config.toml`, every prompt of 20 characters or more
  reaches Claude Code or Codex with the project's best-matching notes, up to `semantic_inject_limit`
  (5 by default), so the agent sees past work before it starts. Off by default. `mnem0nic install`
  adds the hook; run it again after upgrading.

### Changed

- **Search by meaning works from install.** `mnem0nic install` now downloads the search model (130 MB,
  once) and indexes your history in the background; `--no-model` skips it, and `mnem0nic embed` still
  fetches it later. Without a network, install finishes and tells you to run `mnem0nic embed`.

## [0.2.1] - 2026-10-26

### Fixed

- **claude-mem history imported on two paired Macs is no longer kept twice.** 0.2.0 gave each
  imported record a new id on each Mac, so two Macs that had both imported the same claude-mem
  history each held all of it twice after their first sync. An imported record's id now comes from
  the record itself, so it is the same on every Mac. The first time mnem0nic runs after the upgrade,
  it removes the copies already doubled in the background, keeping each Mac's own. Before it removes
  anything it copies the search index to `index/metadata.before-0.2.1.sqlite` in its folder, which
  you can delete once you're happy. Your record files are not changed.
- **A Mac restored from a backup stays paired.** If it wrote more after the restore than it had lost,
  0.2.0 took it for a copy of itself, gave it a new identity and unpaired it from your other Macs.
- `mnem0nic reindex` works on a store holding a project from your other Mac that was never opened
  on this one, and keeps this Mac's own copy of each record.
- Session start no longer says sync with your other Mac has failed while it works: the Mac that
  answers no longer saves the other's passing port as its address.
- Session start returns its context even when a sync round cannot be queued.
- Looking for your other Mac on the network takes 3 seconds; it now happens at most once every 30
  seconds instead of on every hook.
- `mnem0nic install` asks to import claude-mem's history only until it has been imported.

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

[0.3.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.3.0
[0.2.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.2
[0.2.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.1
[0.2.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.0
[0.1.3]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.3
[0.1.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.2
[0.1.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.1
