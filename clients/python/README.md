# mnem0nic Python client

One file, zero dependencies (Python 3 stdlib): talks to a running mnem0nic
daemon's HTTP door — the port named by `[http]` in the daemon's config.toml.

```python
from mnem0nic import Mnem0nic

door = Mnem0nic("http://127.0.0.1:<http-port>", os.environ["MNEM0NIC_HTTP_TOKEN"])
door.save("a curlew flock turned north at dawn", title="Curlew turn")
print(door.search("curlew flock")["text"])
```

Keep the token out of the code: pass it from the environment
(`MNEM0NIC_HTTP_TOKEN`), as above — the client never reads the environment
itself.

`save` replies `{"ok": true, "extraction": ...}`: `"off"` for the default
`mode="verbatim"`; for `mode="extract"`, `"queued"`, or no job at all:
`"unavailable"` (the daemon's observer cannot run). The record is saved in
every such case. A `content` or `title` over the redactor's limit (1,048,576
UTF-16 units, about a million characters) is refused with a 400 and stores
nothing: split it.

Every method is a plain call that sends one POST and returns the parsed JSON
reply: `ping`, `save`, `search`, `work_state_write`, `work_state_read`,
`timeline`. A tool-level validation arrives as a 200 with `"isError": true`
and comes back as a dict — every transport or auth failure raises
`Mnem0nicError`: `.status` is the HTTP status of a refusal, and `None` when
no usable reply came (connection refused or timed out, reply not JSON). A
503 with the body `{"error": "busy"}` means the door is busy (it serves 32 connections at once) and is answered
before any route runs, so the client repeats it up to 3 times (after 0.2, 0.5
and 1 s; `backoff=` changes the waits) before raising `Mnem0nicError` with
`.status == 503` and `.busy` true; no other failure is retried, a 503 from a proxy in front of the door included, because a repeated
`save(..., mode="extract")` would queue a second paid note job. The client
sends the token only to the URL you give it: no proxy from the
environment, no redirects followed. That shape is exactly what an agent or a
LangChain `@tool` wraps: no LangChain dependency, no async requirement, no
globals.
