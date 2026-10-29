<h1 align="center">
  <br>
  <a href="https://github.com/datashard-ai/mnem0nic">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
      <source media="(prefers-color-scheme: light)" srcset="assets/logo-light.png">
      <img src="assets/logo-light.png" alt="mnem0nic" width="420">
    </picture>
  </a>
</h1>

<h4 align="center">Persistent memory for <a href="https://claude.com/claude-code">Claude Code</a> and <a href="https://developers.openai.com/codex/cli">Codex</a>. Local, one binary, on the plan you already pay for.</h4>

<p align="center">
  <a href="https://github.com/datashard-ai/mnem0nic/releases/latest"><img src="https://img.shields.io/github/v/release/datashard-ai/mnem0nic?label=release&color=ea0026" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-Apple%20silicon-111111?logo=apple" alt="macOS on Apple silicon">
  <img src="https://img.shields.io/badge/works%20with-Claude%20Code%20%7C%20Codex-555555" alt="Works with Claude Code and Codex">
  <a href="LICENSE.md"><img src="https://img.shields.io/badge/licence-proprietary-lightgrey" alt="Proprietary licence"></a>
</p>

<p align="center">
  <img src="assets/install-demo.svg" alt="Installing mnem0nic and importing claude-mem history in the terminal" width="820">
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#key-features">Key Features</a> •
  <a href="#moving-from-claude-mem">Moving from claude-mem</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#syncing-your-macs">Syncing Your Macs</a> •
  <a href="#mcp-tools">MCP Tools</a> •
  <a href="#privacy">Privacy</a> •
  <a href="#redaction">Redaction</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#troubleshooting">Troubleshooting</a>
</p>

<p align="center">
  mnem0nic records your coding sessions on your own Mac, writes a short note after every turn, and gives
  your agent tools to search and pick up past work, across projects and across both CLIs.
</p>

---

## Quick Start

```sh
curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
mnem0nic install
```

Then restart Claude Code or Codex. That's it.

- The first command downloads the latest release, checks its SHA-256 checksum and puts `mnem0nic`
  in `~/.local/bin`.
- The second sets mnem0nic up for all your projects, in each CLI signed in with its own paid plan,
  after a dated backup of each settings file it changes, and downloads the search model (130 MB, once)
  for search by meaning.
- **Coming from claude-mem?** `mnem0nic install` finds your claude-mem history and offers to import
  it. Press Enter.

**Requirements:** a Mac with Apple silicon, and at least one of:

- **Claude Code**, signed in with a paid Claude plan (Pro, Max, Team or Enterprise);
- **Codex**, signed in with a paid ChatGPT plan (Plus, Pro, Business, Enterprise or Edu).

## Key Features

- 🧠 **Memory across sessions.** A new session starts with the project's recent context, and your
  agent can look up anything from earlier ones.
- 📝 **A note after every turn.** A small model writes what was done, learned and decided, so search
  finds the point, not just the words.
- 🔍 **Search by words and by meaning,** over notes and the word-for-word conversations.
- ✅ **To-do lists that last.** Open items are shown at the start of every session until they are
  done.
- 🔁 **claude-mem compatible.** The same MCP tools by name, and your claude-mem history imported at
  install.
- 🔄 **Your Macs in step.** Pair your Macs once with a six-digit code, and your memory follows you
  between them on your own network.
- 🔒 **Local.** Everything stays in private folders on your own Macs. No account, no telemetry, no
  server of ours.
- 💳 **Your own subscription.** Notes go through the paid plan you already use: your Claude plan for
  Claude Code, your ChatGPT plan for Codex. Never an API key, so never a per-token bill.
- ⚡ **One native binary.** No Node.js, no Python, nothing left running when you're idle.

## Moving from claude-mem

mnem0nic reads claude-mem's database directly, so your past sessions come with you, and your agent
keeps the same MCP tools by the same names (`mem_search`, `timeline`, `get_observations` and the
rest).

1. **Install, and import in the same step.** `mnem0nic install` finds claude-mem's database where
   claude-mem keeps it, even if you moved claude-mem's data folder, and asks whether to import it.
   Press Enter for yes. Without a terminal to answer it imports without asking; `--no-import` skips
   it. Once it's imported, installing again (an upgrade) doesn't ask again. If you answer no, the
   next install asks again.

2. **If you skipped it, the import stopped, or you kept claude-mem running:**

   ```sh
   mnem0nic import-claude-mem
   ```

   It reads claude-mem's database without changing it, and brings over your observations, session
   summaries, prompts, tool calls and to-do lists, each in the project it belongs to, redacting the
   secrets it recognises. About 35,000 observations took under 10 seconds in our tests. To import a
   copy kept somewhere else: `mnem0nic import-claude-mem --db /path/to/claude-mem.db`.

3. **Turn claude-mem off,** so the two don't both take notes:

   ```sh
   npx claude-mem uninstall
   ```

   This removes claude-mem's hooks and plugin and stops its worker, and keeps your data in
   `~/.claude-mem`. To keep claude-mem installed but off instead:
   `claude plugin disable claude-mem@thedotmack`. Then restart Claude Code.

4. **Search by meaning** comes with install: it downloads the search model once and indexes your
   imported history too. With `--no-model`, `mnem0nic embed` does it later.

The import adds only what is new, so you can keep both for a while, import again, then switch. When
you're happy, delete claude-mem's data with `rm -rf ~/.claude-mem`. Two differences to know: a
session reads only its own project's memory, and results of Datashard's tools are never stored.

## How It Works

```mermaid
flowchart LR
    A["Claude Code<br/>or Codex"] -- "hooks: start, each turn,<br/>compaction, end" --> B["mnem0nic<br/>on your Mac"]
    B --> C[("Private store<br/>~/.local/share/mnem0nic")]
    B -- "one call per turn,<br/>through your own plan" --> D["claude -p or<br/>codex exec"]
    D -- "observations<br/>and a summary" --> C
    C -- "MCP tools and<br/>session-start context" --> A
```

1. **Capture.** Hooks at session start, after each turn, before compaction and at session end record
   the conversation: your prompts, the agent's replies, and its tool calls with their input and
   output. Secrets that mnem0nic recognises (API keys, access tokens, private keys, password
   assignments and more: see [Redaction](#redaction)) are replaced before anything is stored. A
   prompt that is only a `<task-notification>` block, which a background agent sends back to the agent
   and you never typed, is not stored.
2. **Notes.** After each turn, a small model writes short notes about it, through the CLI you used and
   its own plan: Claude Haiku through `claude -p` for Claude Code turns, `codex exec` for Codex turns.
   Each CLI is checked for its paid plan at install, at every session start and before every note.
3. **Recall.** A new session starts with recent context for the project. During it, the MCP tools let
   the agent search past sessions, read notes and timelines, and keep to-do lists.

A background process starts when it is needed, writes the notes, holds the embedding model, and exits
after 15 idle minutes. It listens only on `127.0.0.1`, with a private token.

## Syncing Your Macs

Run this on two of your Macs, on the same network:

```sh
mnem0nic pair
```

The first shows a six-digit code; type it on the second. The code never travels over the network,
and a wrong code ends the pairing. From then on, whenever both Macs are on the same network, they sync
in the background.

- **What syncs:** notes, session summaries, prompts, to-do lists, checkpoints, and Claude Code's own
  memory notes for the project. Word-for-word conversations, tool calls and the search index stay on
  the Mac that recorded them. A prompt longer than 200,000 bytes is cut before it is sent.
- **How:** the Macs find each other over Bonjour, prove who they are with the keys they swapped at
  pairing, and sync over an encrypted link. A machine you didn't pair is refused before anything is
  sent.
- **Projects match by their Git remote,** so a repository checked out in different folders on each Mac
  is the same project. A folder outside Git matches by its name.
- **Apart, then together:** both Macs keep working while apart and catch up when they meet. If the same
  Claude Code note was edited on both, the later edit wins, the other stays in its history, and the
  next session start tells you.
- **While you're idle,** macOS keeps the sync port open for mnem0nic and starts it only when your other
  Mac connects.

```sh
mnem0nic devices                    # your paired Macs, and when each was last seen
mnem0nic sync status                # how far behind each one is
mnem0nic sync now                   # sync at once
mnem0nic unpair "Mac name"          # stop syncing with one
mnem0nic notes history NAME         # every version of a Claude Code note
```

## MCP Tools

claude-mem's tools, with the same names and parameters:

| Tool | What it does |
|---|---|
| `mem_search` | Search memory step by step: an index, then context, then the details you pick |
| `save_memory` | Save a note, decision, correction or handoff of your own |
| `search`, `timeline`, `get_observations` | Search with filters, see what happened around a note, read notes by id |
| `get_tool_uses` | Read the original input and output of tool calls already found |
| `work_state_write`, `work_state_read` | Keep to-do lists and working state across sessions |
| `session_start_context` | Show the context a new session starts with |
| `important_workflow` | How to use the tools above, for the agent |

mnem0nic's own tools, over the word-for-word conversations:

| Tool | What it does |
|---|---|
| `memory_search` | Search earlier conversations by words and meaning |
| `memory_get` | Read the messages around a search result |
| `memory_sessions` | List the project's recent sessions |
| `memory_save`, `memory_resume` | Save a checkpoint of your work, and resume from it on the same branch |

## Privacy

- **What stays on your Macs:** everything mnem0nic records, in `~/.local/share/mnem0nic`, readable
  only by your user account. With paired Macs, the records listed under
  [Syncing Your Macs](#syncing-your-macs) go between them, encrypted, and nowhere else.
- **What is sent, and where:** after each turn, its request, its tool calls (long input and output
  trimmed) and the agent's reply go to the provider of the CLI you used: Anthropic for Claude Code,
  OpenAI for Codex. They go through your own login, to the same provider that already handled the
  turn.
- **What is never sent:** the contents of files the agent only read (their paths are sent), images,
  the results of memory tools, and secrets that redaction recognises.
- **Nothing goes to us.** No account, no telemetry, no server of ours.
- **Datashard:** results of Datashard's tools are never stored. Facts are fetched again when needed,
  with your current access.

## Redaction

Before anything is stored, mnem0nic replaces each secret it recognises with
`<redacted type='NAME'/>`, where `NAME` says what kind of secret it was. It does this for the
conversations it captures, for notes you save with `save_memory`, and for history imported from
claude-mem. Text is redacted before it is cut to its stored length, so a secret near the cut is not
half kept. What a paired Mac sends you is stored as that Mac sent it. Older records show
`[redacted]` instead, and are not rewritten: a secret that an earlier version let through stays where
it is.

**On by default:**

| Name | What it covers |
|---|---|
| `aws_access_key` | AWS access key ids, permanent (`AKIA…`) and temporary (`ASIA…`) |
| `aws_secret_key`, `aws_session_token` | The value after `AWS_SECRET_ACCESS_KEY` or `SecretAccessKey`, and after `AWS_SESSION_TOKEN` or `SessionToken` |
| `github_pat`, `anthropic_key`, `openai_key`, `stripe_key`, `google_api_key`, `slack_token` | Keys and tokens with a known prefix, including Slack `xapp-` and `xoxe-` |
| `jwt`, `claude_mem_key` | JSON web tokens, and claude-mem's own keys |
| `private_key_pem` | A whole private key block, PGP too |
| `bearer_token`, `authorization` | A Bearer token, and the credential in any `Authorization` header (Basic, Token and the rest; the scheme word stays) |
| `cookie` | The value of a `Cookie` or `Set-Cookie` header |
| `url_credentials` | The user and password in a URL or connection string |
| `assigned_secret` | The value after `password`, `passwd`, `secret`, `token`, `api_key`, `access_key` or `client_secret`, with `=` or `:`, in plain text or inside a tool call's JSON. Six characters or more (four for a password; a bare number needs six digits, so `password=1234` stays as it is, while `"1234"` in quotes is redacted); a quoted value is taken whole, spaces and all |

**Off by default.** Two more patterns go by the name alone, with no known prefix to go on, so they are
less certain and you switch them on yourself: `generic_password` (names ending in `password`,
`passwd` or `_pwd`, such as `DB_PASSWORD=`) and `generic_token` (names ending in `_token`, `_secret`
or `_api_key`, such as `NPM_TOKEN=`, and a few config-file shapes such as `--token` flags and `token:`
lines). Until you switch them on, `NPM_TOKEN=…` and `DB_PASSWORD=…` are stored as written.

Redaction is pattern matching: it catches the shapes above, not every secret. It does not cover
to-do lists written with `work_state_write`, checkpoints, or Claude Code's memory notes synced between
your Macs. A single field longer than 1,048,576 UTF-16 code units (about a million characters) is
replaced whole by `<redacted type='oversize'/>`.

To change what is redacted, add a `[redaction]` section to `config.toml`:

```toml
[redaction]
generic = true                  # also use the two patterns that go by the name alone
disabled = ["cookie"]           # built-in patterns to switch off, by name
log_matches = true              # count matches in redact.log
custom = [
  { name = "company_token", regex = "INTERNAL-[A-Z0-9]{8}" },
]
```

- **`custom`** patterns run before the built-in ones, once, on the text as it arrives. A name is 1 to
  64 letters, digits or `_`, and appears in the marker. The regex is Rust's [regex syntax](https://docs.rs/regex), so no look-around.
- **`MNEM0NIC_REDACT_GENERIC`** and **`MNEM0NIC_REDACT_LOG_MATCHES`** do the same as `generic` and
  `log_matches` and take precedence over the file. `true`, `on`, `yes` or `1` turn them on, a blank
  value counts as not set, and any other value turns them off. A variable set in your shell does not
  reach an import that an already-running background process performs; put the setting in
  `config.toml`.
- **Mistakes.** A mistyped key, a `custom` entry without a name and a regex, a name in `disabled`
  that is not a built-in, and a custom pattern whose name or regex does not work are each skipped, with
  a warning on stderr (the hook's or the memory server's). The rest of the section applies, and a typo
  cannot switch a built-in pattern off. A custom regex that does not compile keeps the last version of
  the same name that worked, if there was one.
- **A section that cannot be used.** A value of the wrong type (`generic = 7`), or a `config.toml`
  that cannot be read or is not valid TOML, is not used at all. mnem0nic keeps the settings that last
  loaded without a warning, which it saves in `redaction.last-good.toml` in the memory folder (only you
  can read it), or the built-in patterns if there are none, and says so on stderr. A `config.toml`
  that is missing means the built-in patterns, and leaves the saved copy as it is.
- **The match log.** With `log_matches` on, mnem0nic adds a `pattern,count` line to `redact.log` in
  the memory folder each time it replaces something. It never writes what it found. Only you can read
  the file, and it stops growing past 1 MiB. It shows which patterns fire and how often, the generic
  ones too once they are on.
- **When a change takes effect.** Hooks and commands read `[redaction]` the first time they redact
  something, and a hook or command that redacts nothing reads nothing. The background process reads
  it at the start of each claude-mem import, with the environment it was started with; its other jobs
  redact nothing. The memory server reads it when it first saves a note and keeps those settings, so
  restart Claude Code or Codex after a change.
- **Older versions.** An older mnem0nic rejects a `config.toml` that has a `[redaction]` section, and
  cannot look up the project until the section is removed. Without the section, nothing changes.
- **Paired Macs.** Update both together. A Mac still on an older version can hold a claude-mem record
  twice when an updated Mac sends it one that the new patterns changed, and a copy made that way
  stays after the Mac is updated.

## Configuration

Settings live in `~/.local/share/mnem0nic/config.toml`:

```toml
[observer]
client = "off"                  # turn the notes off; capture and search keep working
model = "claude-haiku-5-5"      # the model for Claude Code turns
codex_model = "gpt-6-luna"      # the model for Codex turns
parallel = 3                    # note calls at once, from 1 to 8

[search]
semantic_inject = true          # past work on every prompt; off by default
semantic_inject_limit = 5       # how many notes, from 1 to 20
# rerank = true                 # uncomment to let the re-ranker order the best results (off by default)
```

With `semantic_inject` on, every prompt of 20 characters or more reaches Claude with the project's
best-matching notes, as claude-mem's `CLAUDE_MEM_SEMANTIC_INJECT` does, so it sees past work before
it starts. The notes go to Claude Code or Codex with the prompt. It works best with search by
meaning (`mnem0nic embed`); without it, it hands over the notes that share words with the prompt.

The re-ranker is off by default: on real history it added about 40 to 70 ms to each question it
reordered and gave no better first place. To turn it on, set `rerank = true` (or `1`, or `"on"` or
`"yes"` with the quotes) under `[search]`, or `MNEM0NIC_RERANK=true` for one run (the variable also
takes `on`, `yes` and `1`); any other value leaves it off, and the variable takes precedence over the
file. Then `mnem0nic install` or `mnem0nic embed` downloads its model (18 MB, once), if you
run it with the setting in place, e.g. `MNEM0NIC_RERANK=true mnem0nic embed`. With it on, when you ask
for five results or more with a question of six words or more that holds nothing that looks like code
or a path, a small model (TinyBERT, run by the memory daemon) reads the first ten results with your
question and puts the best match first. A short lookup, a path or an identifier is never reordered.
Claude Code sessions that are already open keep the setting they started with, and use a re-ranker
downloaded later only after they restart. Do not put that line in a `config.toml` that an older
mnem0nic also reads: it rejects the key, and cannot look up the project until the line is removed.

Environment variables take precedence: `MNEM0NIC_OBSERVER_CLIENT`, `MNEM0NIC_OBSERVER_MODEL`,
`MNEM0NIC_OBSERVER_CODEX_MODEL`, `MNEM0NIC_OBSERVER_PARALLEL`, `MNEM0NIC_SEMANTIC_INJECT` and
`MNEM0NIC_SEMANTIC_INJECT_LIMIT` and `MNEM0NIC_RERANK`. `MNEM0NIC_REDACT_GENERIC` and
`MNEM0NIC_REDACT_LOG_MATCHES` are described under [Redaction](#redaction). `MNEM0NIC_HOME` moves the
memory folder. For the installer, `MNEM0NIC_VERSION=0.2.0` pins a version and `MNEM0NIC_INSTALL_DIR`
sets the folder.

## Commands

| Command | What it does |
|---|---|
| `mnem0nic install [--no-import] [--no-model]` | Set up the hooks and MCP server, download the search model (`--no-model` skips it; the re-ranker is fetched too only if it is switched on), and offer to import claude-mem's history |
| `mnem0nic uninstall [--purge]` | Remove them; `--purge` also deletes your memory |
| `mnem0nic search "words"` | Search this project's sessions from the terminal |
| `mnem0nic sessions` | List this project's recent sessions |
| `mnem0nic embed` | Download the search model, and the re-ranker if it is switched on, when install didn't, and index what is new |
| `mnem0nic import-claude-mem` | Import your claude-mem history |
| `mnem0nic daemon status` | Show the background process |
| `mnem0nic pair` | Pair this Mac with another of yours, with a six-digit code |
| `mnem0nic devices`, `mnem0nic unpair NAME` | List your paired Macs; stop syncing with one |
| `mnem0nic sync status`, `mnem0nic sync now` | See how sync is doing; sync at once |
| `mnem0nic project merge OLD NEW` | Read a project's older memory as part of another |

`mnem0nic help` lists every command.

## Upgrade and Uninstall

Upgrade by running the install command again, then `mnem0nic install`, then restart Claude Code or
Codex: a session keeps the mnem0nic MCP server it started with until you restart it. Your memory,
settings and pairings are kept.

```sh
mnem0nic uninstall            # removes the hooks and MCP server, keeps your memory
mnem0nic uninstall --purge    # also deletes ~/.local/share/mnem0nic
rm ~/.local/bin/mnem0nic
```

## Troubleshooting

- **"mnem0nic is off in this session"** at the start of a session: that CLI isn't signed in with a paid
  plan of its own. The message says what to do; then start a new session.
- **`command not found: mnem0nic`:** `~/.local/bin` isn't on your `PATH`. Add it with
  `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`, then open a new terminal.
- **macOS blocks the program** after a download from the releases page in a browser: use the install
  command, or run `xattr -d com.apple.quarantine ~/.local/bin/mnem0nic` once.
- **Notes don't appear:** check `mnem0nic daemon status`, and that `claude` or `codex` runs in your
  terminal.
- **Your Macs don't sync:** they must be on the same network, and some guest or office networks block
  the Bonjour messages they find each other with. `mnem0nic sync status` shows when each was last
  seen. macOS may ask once whether mnem0nic may use the local network: allow it.

## Support

Report bugs and ask questions in [Issues](https://github.com/datashard-ai/mnem0nic/issues). Report
security problems privately, as [SECURITY.md](SECURITY.md) describes. Release notes are in
[CHANGELOG.md](CHANGELOG.md).

## Licence

mnem0nic is proprietary software. © 2026 Xibit Digital. All rights reserved. Use is subject to
[LICENSE.md](LICENSE.md). It includes open-source components, listed with their licences in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

<p align="center"><sub>mnem0nic, by Xibit Digital · <a href="https://datashard.ai/mnem0nic">datashard.ai/mnem0nic</a></sub></p>
