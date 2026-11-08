# mnem0nic JavaScript client

One file, no dependencies: `mnem0nic.mjs`, an ES module on the standard `fetch` (Node 18+, Bun, Deno,
Cloudflare Workers). It talks to a running mnem0nic daemon's HTTP door, the address named by `[http]` in the
daemon's config.toml. `mnem0nic.d.mts` holds the types for TypeScript. Copy both files into your project.

```js
import { Mnem0nic } from "./mnem0nic.mjs";

const door = new Mnem0nic("http://127.0.0.1:8787", process.env.MNEM0NIC_HTTP_TOKEN);
await door.save("a curlew flock turned north at dawn", { title: "Curlew turn" });
console.log((await door.search("curlew flock")).text);
```

Keep the token out of the code: pass it from the environment, as above. The client never reads the
environment itself.

## Calls

Every method sends one POST and resolves with the parsed JSON reply.

| Call | What it does |
|---|---|
| `ping()` | `{ ok, build }` |
| `save(content, { title, metadata, mode })` | Saves a note. `mode` is `"verbatim"` (default: stored as it is, no model) or `"extract"` (also queues a note written through the deployment's provider) |
| `search(query, { limit = 20, maxDetails = 3 })` | Searches the project's memory |
| `timeline(query)` | What happened around a note |
| `workStateWrite(list, fields)` | Writes to a to-do list or working state |
| `workStateRead({ list, includeClosed })` | Reads them |

`save` resolves with `{ ok: true, extraction }`: `"off"` for the default `"verbatim"` mode; for `"extract"`,
`"queued"`, or no job at all: `"unavailable"` (the daemon's observer cannot run). The record is saved in every
case. Content or a title over the redaction limit (1,048,576 UTF-16 units) is refused with a 400 and stores
nothing.

## Errors

A tool-level validation problem arrives as a 200 with `isError: true` and is returned as an object, not thrown.
Every transport or auth failure throws `Mnem0nicError`: `.status` is the HTTP status of a refusal, and `null`
when no usable reply came (connection refused or timed out, a reply that is not JSON). A redirect throws with
its 3xx status. An unset token (`undefined` or empty) throws a `TypeError` before any call.

A 503 with the body `{"error":"busy"}` means the door is busy (it serves 32 connections at once). It is
answered before any route runs, so the client repeats it up to 3 times (after 200, 500 and 1000 ms; the
`backoff` option changes the waits) before throwing with `.status === 503` and `.busy === true`. No other
failure is repeated, a 503 from a proxy in front of the door included, because a repeated
`save(..., { mode: "extract" })` would queue a second paid note job.

The client sends the token only to the address you give it: a redirect is never followed. It sets no proxy;
Node reads proxy variables only if you set `NODE_USE_ENV_PROXY`, so leave that unset for the door.

## Options

`new Mnem0nic(baseUrl, token, { timeout = 30000, backoff = [200, 500, 1000] })`: `timeout` is milliseconds for
each attempt.
