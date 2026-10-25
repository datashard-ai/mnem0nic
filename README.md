# mnem0nic

**Persistent memory for Claude Code and Codex.** mnem0nic records your coding sessions on your own
machine, writes a short note after every turn, and gives your agent tools to search and resume past
work, across projects and across both CLIs.

- **One native binary.** No Node.js, no Python, nothing left running when you're idle.
- **Local.** Your memory lives in a private folder on your Mac. Nothing goes to us: there is no
  account and no telemetry.
- **Your own subscription.** Notes are written through the paid plan you already use: your Claude plan
  for Claude Code, your ChatGPT plan for Codex. Never an API key, so never a per-token bill.
- **claude-mem compatible.** The same MCP tools by name, and a one-command import of your claude-mem
  history.

[Install](#install) · [Moving from claude-mem](#moving-from-claude-mem) · [How it works](#how-it-works) ·
[Privacy](#privacy) · [Configuration](#configuration) · [Uninstall](#uninstall) · [Changelog](CHANGELOG.md)

## Requirements

- A Mac with Apple silicon.
- At least one of:
  - **Claude Code**, signed in with a paid Claude plan (Pro, Max, Team or Enterprise);
  - **Codex**, signed in with a paid ChatGPT plan (Plus, Pro, Business, Enterprise or Edu).

mnem0nic works only through these plans. A CLI signed in with an API key, or running on Amazon Bedrock
or Google Vertex AI, is not set up, and mnem0nic says why.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
mnem0nic install
```

The first command downloads the latest release, checks its SHA-256 checksum, and puts `mnem0nic` in
`~/.local/bin`. Set `MNEM0NIC_VERSION=0.1.1` to pin a version, or `MNEM0NIC_INSTALL_DIR` to install
somewhere else.

The second command sets mnem0nic up for all your projects, in each CLI that is signed in with its own
paid plan:

- capture hooks in Claude Code's user settings (`~/.claude/settings.json`) and in Codex's
  (`~/.codex/hooks.json`), after a dated backup of each file;
- the `mnem0nic` MCP server, added to each CLI for all projects.

Restart Claude Code or Codex afterwards. Codex asks you once to trust the new hooks. Running
`mnem0nic install` again is safe: it replaces its own hooks and leaves everything else as it is.

**Optional:** `mnem0nic embed` downloads a 130 MB embedding model from Hugging Face, once, so that
search also finds things by meaning, not only by their words.

**Coming from claude-mem?** Bring your history with you: see
[Moving from claude-mem](#moving-from-claude-mem).

## Moving from claude-mem

mnem0nic reads claude-mem's database directly, so your past sessions come with you. It offers the
same MCP tools by the same names (`mem_search`, `timeline`, `get_observations` and the rest), so
your agent keeps working the way it did.

1. **Install mnem0nic,** as above:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
   mnem0nic install
   ```

2. **Import your history:**

   ```sh
   mnem0nic import-claude-mem
   ```

   It reads `~/.claude-mem/claude-mem.db` without changing it. It brings over your observations,
   session summaries, prompts, tool calls and to-do lists, each in the project it belongs to, and
   redacts the secrets it recognises on the way in. Large histories are quick: about 35,000
   observations took under 10 seconds in our tests. If you moved claude-mem's data folder, point
   to the database:

   ```sh
   mnem0nic import-claude-mem --db /path/to/claude-mem.db
   ```

3. **Turn claude-mem off,** so that the two don't both take notes:

   ```sh
   npx claude-mem uninstall
   ```

   This removes claude-mem's hooks and plugin and stops its background worker. It keeps your data
   in `~/.claude-mem`. If you'd rather keep claude-mem installed but off, run
   `claude plugin disable claude-mem@thedotmack` instead. Then restart Claude Code.

4. **Optional: search by meaning.** `mnem0nic embed` downloads the model once and indexes your
   imported history too.

5. **Check it.** In a project you worked on with claude-mem, run
   `mnem0nic search "a word from an old session"`, or ask your agent what it remembers.

You can run the import again at any time: it adds only what is new. So you can keep both tools for
a while, import once more, then switch. When you're happy with mnem0nic, delete claude-mem's data
with `rm -rf ~/.claude-mem`.

Two differences to know: a session reads only its own project's memory, and results of Datashard's
tools are never stored.

## How it works

1. **Capture.** Hooks at session start, after each turn, before compaction and at session end record
   the conversation: your prompts, the agent's replies, and its tool calls with their input and
   output. Secrets that mnem0nic recognises (API keys, access tokens, private keys, password
   assignments) are redacted before anything is stored.
2. **Notes.** After each turn, a small model writes short notes about it: what was done, what was
   learned, what was decided. Claude Code turns are noted through `claude -p` with Claude Haiku, and
   Codex turns through `codex exec`, each with that CLI's own login and plan.
3. **Recall.** At the start of a session, recent context for the project is added. During the
   session, the MCP tools let the agent search past sessions by words or by meaning, read notes and
   timelines, and keep to-do lists from one session to the next.

A background process starts when it is needed. It writes the notes and holds the embedding model,
and exits after 15 idle minutes. It listens only on `127.0.0.1`, with a private token.

### MCP tools

claude-mem's tools, with the same names and parameters: `mem_search`, `save_memory`,
`important_workflow`, `search`, `timeline`, `get_observations`, `get_tool_uses`, `work_state_write`,
`work_state_read` and `session_start_context`.

mnem0nic's own tools, over the word-for-word conversations: `memory_search`, `memory_get`,
`memory_sessions`, `memory_resume` and `memory_save`.

## Privacy

- **What stays on your Mac:** everything mnem0nic records, in `~/.local/share/mnem0nic`, readable only
  by your user account.
- **What is sent, and where:** after each turn, its request, its tool calls (long input and output
  trimmed) and the agent's reply go to the provider of the CLI you used: Anthropic for Claude Code,
  OpenAI for Codex. They go through your own login, to the same provider that already handled that
  turn.
- **What is never sent:** the contents of files the agent only read (their paths are sent), images,
  the results of memory tools, and secrets that redaction recognises.
- **Nothing goes to Xibit Digital.** There is no account, no telemetry and no server of ours.
- **Datashard:** results of Datashard's tools are never stored. Facts are fetched again when needed,
  with your current access.

To turn the notes off and keep capture and search, see [Configuration](#configuration).

## Configuration

Settings live in `~/.local/share/mnem0nic/config.toml`:

```toml
[observer]
client = "off"                  # turn the notes off; capture and search keep working
model = "claude-haiku-5-5"      # the model for Claude Code turns
codex_model = "gpt-6-luna"      # the model for Codex turns
parallel = 3                    # note calls at once, from 1 to 8
```

Environment variables take precedence: `MNEM0NIC_OBSERVER_CLIENT`, `MNEM0NIC_OBSERVER_MODEL`,
`MNEM0NIC_OBSERVER_CODEX_MODEL` and `MNEM0NIC_OBSERVER_PARALLEL`. `MNEM0NIC_HOME` moves the memory
folder.

## Commands

| Command | What it does |
|---|---|
| `mnem0nic install` | Set up the hooks and MCP server for Claude Code and Codex |
| `mnem0nic uninstall [--purge]` | Remove them; `--purge` also deletes your memory |
| `mnem0nic search "words"` | Search this project's sessions from the terminal |
| `mnem0nic sessions` | List this project's recent sessions |
| `mnem0nic embed` | Download the embedding model, once, for search by meaning |
| `mnem0nic import-claude-mem` | Import your claude-mem history |
| `mnem0nic daemon status` | Show the background process |
| `mnem0nic --version` | Show the version |

`mnem0nic help` lists every command.

## Upgrade

Run the install command again, then `mnem0nic install`. Your memory and settings are kept.

## Uninstall

```sh
mnem0nic uninstall            # removes the hooks and MCP server, keeps your memory
mnem0nic uninstall --purge    # also deletes ~/.local/share/mnem0nic
rm ~/.local/bin/mnem0nic
```

## Troubleshooting

- **"mnem0nic is off in this session"** at the start of a session: that CLI isn't signed in with a paid
  plan of its own. The message says what to do; after that, start a new session.
- **`command not found: mnem0nic`:** `~/.local/bin` isn't on your `PATH`. Add it with
  `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`, then open a new terminal.
- **macOS blocks the program** after a download from the releases page in a browser: use the install
  command above, or run `xattr -d com.apple.quarantine ~/.local/bin/mnem0nic` once.
- **Notes don't appear:** check `mnem0nic daemon status`, and that `claude` or `codex` runs in your
  terminal.

## Support

Report bugs and ask questions in [Issues](https://github.com/datashard-ai/mnem0nic/issues). Report
security problems privately, as described in [SECURITY.md](SECURITY.md).

## Licence

mnem0nic is proprietary software. © 2026 Xibit Digital. All rights reserved. Use is subject to
[LICENSE.md](LICENSE.md). It includes open-source components, listed with their licences in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
