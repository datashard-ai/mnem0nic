# Changelog

All notable changes to mnem0nic are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.5.0] - 2026-10-30

### Added

- **Text inside `<private>` tags is never stored.** `<private>…</private>` is removed from your
  prompts, the agent's replies, and the input and output of tool calls, and from imported claude-mem
  history, before anything else is done to the text: before it is cut to its stored length, redacted,
  stored, sent to the notes model or sent to a paired Mac. Five more tags are treated the same way, which
  with `<private>` makes the six that claude-mem removes: `<claude-mem-context>`, `<system_instruction>`, `<system-instruction>`,
  `<persisted-output>` and `<system-reminder>`. The rules are claude-mem's: an opening tag may carry
  attributes, a closing tag ends the earliest opening tag of its name that is still open and everything
  between goes, nested and overlapping blocks are removed whole, names are case-sensitive, and a tag
  with no closing tag is left as written, so `explain how <private> works` is kept. A tool call's input
  is cleaned string by string, so it stays valid JSON. A prompt that is only private text is not stored
  at all: no message, no prompt record, no note.
- **Excluded projects.** `excluded_projects = [...]` under `[capture]` in `config.toml`, or
  `MNEM0NIC_EXCLUDED_PROJECTS` (comma-separated), which replaces the file's list. Patterns are
  claude-mem's (`*`, `**`, `?`, a leading `~`, the whole path or just the folder's name, `dir/**` also
  matches `dir`), and the file also takes claude-mem's form, one comma-separated string. A session is
  tested by the folder it runs in and by its project's root: a pattern that matches the project's root
  (the root itself, or `parent/**`) excludes every session in that project, and a pattern that matches
  only a subfolder excludes the sessions started there. In an excluded project every hook returns at once, on Claude
  Code and on Codex: nothing is stored or noted, and no start-of-session context or past work is
  handed back; the only thing a hook records is how far each excluded session's transcript was read (a
  session id and a number, in `excluded-offsets/`), so removing an exclusion never brings back what was
  typed meanwhile. A note queued before the project was excluded is not written, `mnem0nic
  import-claude-mem` leaves out the project's history (each row is also tested by the folder its own
  session or call recorded, a call with none by its session's, then the project), and `work_state_write` answers "Not saved". Searching, reading and
  `save_memory` still work. Hooks and note jobs read the file every time; the background process reads the
  environment variable only when it starts, so run `mnem0nic daemon stop` after changing it. An older
  mnem0nic rejects a `config.toml` that has a `[capture]` section, and cannot look up the project until
  it is removed.
- **Three more secrets are redacted:** GitLab access tokens (`glpat-…`, including the longer ones with
  dot-separated parts), Hugging Face user tokens (`hf_…`) and npm access tokens (`npm_…`).

### Changed

- **Calls to Datashard's tools are no longer stored at all.** Before, the call's input was kept and
  only its result was replaced by a note. Now there is no message and no tool record for the call, its
  result goes nowhere, the notes model never sees it, and the claude-mem import skips it. A tool counts
  when its name contains `datashard`, in any letter case, and a Codex `exec` script that calls one is
  left out too. Records stored by an earlier version are not rewritten (their results stay replaced),
  but the notes model no longer reads them.
- **The notes model gets each tool input and output cut on its own.** Each is cut to at most 16,000
  characters, keeping the first 60% and the last 30% of the limit, and the tool calls of one turn share
  about 160,000 characters of tool text (the characters kept: the cut markers and escaping come on
  top), so a short field leaves what it does not need to the longer ones. The gap is now
  marked `<elided chars="…" original_size_chars="…" reason="oversize" />`, which names the original
  size. It was 2,000 characters a field and 40,000 for a turn, which cut a 6,400-character output in a
  turn of 19 tool calls to about 1,050. Long outputs now reach the notes model in more detail, so a turn
  with large outputs uses more of your plan's allowance.

### Known limits

- The agent's reply and tool calls in a turn whose prompt was only private text are still stored, as
  claude-mem does, and may quote what you wrapped. The tool calls are filed with the turn before.
- `<private>` tags are not removed from a chat you paste without them, from anything already stored,
  or from text written through `save_memory`, `work_state_write`, a checkpoint or Claude Code's memory
  notes synced between your Macs.
- A `<private>` block that opens in one string of a tool call's input and closes in another is not
  removed, so that the stored input stays valid JSON. A mention of an opening tag earlier in the same
  text as a real block goes with it, as in claude-mem.
- A `config.toml` that cannot be read, or whose `[capture]` section is mistaken, excludes nothing.
- The project root is matched by its real path, so a pattern written through a symlink matches the
  folder a session was started in but not the root. Imported claude-mem sessions that recorded no
  folder (most of the old ones) are judged by their project alone.
- A note queued before a project was excluded learns the session's folder from its tool calls, so a
  session with no tool call is judged by its project's root alone.
- An imported claude-mem record's id is made from its text before private blocks come out, and it must
  not change, so that your Macs hold the record once. A short private value, such as a PIN, could
  therefore be guessed from the id and the stored record.

## [0.4.0] - 2026-10-29

### Added

- **More secrets are redacted.** Temporary AWS key ids (`ASIA…`), the value after
  `AWS_SECRET_ACCESS_KEY` or `AWS_SESSION_TOKEN`, Slack `xapp-` and `xoxe-` tokens, Google API keys,
  claude-mem's own keys, PGP private key blocks, the credential in any
  `Authorization` header (Basic and Token as well as Bearer), `Cookie` and `Set-Cookie` values, and the
  user and password in a URL. A `password` value of four characters is now taken (a bare number needs six
  digits, so `password=1234` stays as it is and `"1234"` in quotes is redacted); a quoted value is
  taken whole, spaces and all; and secrets are found inside the JSON of a tool call, and after a line
  break in it.
- **A `[redaction]` section in `config.toml`.** `generic` switches on two patterns that go by the name
  alone (`generic_password` for names such as `DB_PASSWORD`, `generic_token` for names such as
  `NPM_TOKEN`), `disabled` switches built-in patterns off by name, `custom` adds your own as
  `{ name, regex }`, and `log_matches` keeps counts. `MNEM0NIC_REDACT_GENERIC` and
  `MNEM0NIC_REDACT_LOG_MATCHES` take precedence over the file; a variable set in your shell does not
  reach an import that an already-running background process performs, so put the setting in
  `config.toml`. The generic patterns are off by default, so `NPM_TOKEN=…` and `DB_PASSWORD=…` are
  still stored as written until you switch them on.
  - A mistyped key, a `custom` entry without a name and a regex, a name in `disabled` that is not a
    built-in, and a custom pattern whose name or regex does not work are each skipped with a warning on
    stderr, and the rest of the section applies. A typo cannot switch a built-in pattern off, and a
    custom regex that stops compiling keeps the last version of its name that worked.
  - A section with a value of the wrong type, or a `config.toml` that cannot be read or is not valid
    TOML, is not used: the settings that last loaded without a warning stay in force (kept in
    `redaction.last-good.toml` in the memory folder), or the built-in patterns if there are none.
  - An older mnem0nic rejects a `config.toml` with this section and cannot look up the project until
    it is removed.
  - A hook or command reads the section the first time it redacts something. The background process
    reads it at the start of each claude-mem import; the memory server reads it when it first saves a
    note and keeps those settings, so restart Claude Code or Codex after a change.
- **A match log.** With `log_matches` on, `redact.log` in the memory folder gets a `pattern,count` line
  for each replacement, never what was found. It is readable only by you and stops growing past 1 MiB.

### Changed

- **A redacted secret is now marked `<redacted type='NAME'/>`,** where `NAME` is the pattern that
  found it, instead of `[redacted]`. The notes model is told what the marker means. Records stored
  before this keep `[redacted]` and any secret an earlier version let through; they are not
  rewritten. What a paired Mac sends you is stored as that Mac sent it.
- **A prompt that is only a `<task-notification>` block is no longer stored,** and gets no note. It
  is text a background agent sends back to the agent, not something you typed. The replies and tool
  calls after one are still stored.
- **Imported claude-mem records keep the ids 0.3.2 gave them,** although the new patterns change the
  text they hold. Update both paired Macs together: a Mac still on 0.3.2 can hold such a record twice
  when an updated Mac sends it one that the new patterns changed, and a copy made that way stays after
  the Mac is updated.

### Known limits

- A secret that is a bare number in JSON, such as `{"token": 12345678}`, is replaced by a marker, and
  the marker is not a JSON number, so the text is not valid JSON afterwards, as before. In a note's
  `metadata` that drops the note's `metadata`.
- Redaction does not cover `work_state_write`, checkpoints, or Claude Code's memory notes synced
  between your Macs.
- A single prompt, reply or tool input longer than 1,048,576 UTF-16 code units is not scanned: it is
  stored as the marker `<redacted type='oversize'/>` alone, so a very large paste is not kept.

### Fixed

- **A secret across the cut in a tool call was stored half kept.** Tool-call text was cut to 300
  characters before it was redacted, so a secret that straddled the cut was partly stored, and a
  private key whose last line fell past the cut was stored as raw key text. It is now redacted before
  it is cut.
- A test only: `an_observer_job_killed_mid_call_resumes_without_duplicate_notes` no longer races on its
  fake `claude`'s marker file (it killed the daemon before the fake had removed the marker).

## [0.3.2] - 2026-10-29

### Changed

- **The small re-ranker added in 0.3.0 is now off by default.** On real history it added about 40 to
  70 ms to each question it reordered without a clear gain in the results. Turn it on with
  `rerank = true` under `[search]` in `config.toml`, or with `MNEM0NIC_RERANK=true`. Only `true`,
  `on`, `yes` or `1` count as on (in `config.toml`, write `on` and `yes` in quotes: unquoted they are
  not valid TOML and make the whole file unreadable); anything else leaves it off, and an older
  `rerank = false` line is still valid. `mnem0nic install` and `mnem0nic embed` download its 18 MB
  model only when it is on, and a model already downloaded stays. A `config.toml` that cannot be read
  now leaves it off. A memory server that is already running keeps its setting until its session is
  restarted; the notes handed over with each prompt follow `config.toml` at once. The keyword-first
  order of results is unchanged.

## [0.3.1] - 2026-10-28

### Fixed

- **A model download that stops no longer hangs `mnem0nic install` or `mnem0nic embed`.** If the
  search model or the re-ranker sends nothing for 60 seconds, the download is given up with a
  message. `mnem0nic install` carries on without it; run `mnem0nic embed` later to try again, and a
  search model download that was cut picks up where it stopped.
- **A to-do you updated after a `mnem0nic reindex` could keep showing its old status.** Reindex gave
  entries written before 0.2.0 an ordering number above every newer one, so a newer update to the same
  item lost to them. Reindex now keeps later updates on top. An update that was already hidden stays
  hidden until you write it again.
- **The background sync log no longer fills with lines about your own Mac.** Each Mac found itself on
  the network and logged "refused a machine that is not paired". It now ignores itself, so such a
  line in that log means some other machine tried to connect and is not paired. Lines already in
  the log stay.

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

[Unreleased]: https://github.com/datashard-ai/mnem0nic/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.5.0
[0.4.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.4.0
[0.3.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.3.2
[0.3.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.3.1
[0.3.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.3.0
[0.2.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.2
[0.2.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.1
[0.2.0]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.2.0
[0.1.3]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.3
[0.1.2]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.2
[0.1.1]: https://github.com/datashard-ai/mnem0nic/releases/tag/v0.1.1
