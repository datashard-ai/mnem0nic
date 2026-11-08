/**
 * The mnem0nic JavaScript client: plain POST calls to a daemon's HTTP door.
 *
 * One file, no dependencies, an ES module on the standard `fetch`: Node 18+, Bun, Deno and Cloudflare
 * Workers. Every method sends one POST with the bearer token and returns the parsed JSON reply; every
 * transport or auth failure throws `Mnem0nicError`. A tool-level error is data: it arrives as a 200 with
 * `isError: true` and is returned as an object, not thrown. The one failure repeated for you is the door's
 * own 503, `{"error":"busy"}`: it is answered before any route runs, so repeating the call is always safe.
 *
 * © 2026 Xibit Digital. All rights reserved. Use is subject to the LICENSE.md of the mnem0nic repository
 * (https://github.com/datashard-ai/mnem0nic).
 */

/** A call that got no usable reply: a non-2xx answer or a redirect (`status` is its HTTP status, where the
 * runtime reports one), or none at all (`status` is null): a refused, reset or timed-out connection, or a
 * reply that is not JSON. `busy` is true only for the door's own 503, `{"error":"busy"}`. */
export class Mnem0nicError extends Error {
  constructor(message, status = null, busy = false) {
    super(message);
    this.name = "Mnem0nicError";
    this.status = status;
    this.busy = busy;
  }
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export class Mnem0nic {
  /**
   * @param {string} baseUrl The door's address, for example "http://127.0.0.1:8787".
   * @param {string} token The door's bearer token. Pass it from the environment; the client never reads it.
   * @param {{timeout?: number, backoff?: number[]}} [options] `timeout` in milliseconds for each attempt;
   *   `backoff` is the wait in milliseconds before each retry of a 503, and so how many retries there are.
   */
  constructor(baseUrl, token, { timeout = 30000, backoff = [200, 500, 1000] } = {}) {
    if (typeof token !== "string" || token === "") {
      throw new TypeError("the door's token must be a non-empty string (is the environment variable set?)");
    }
    this.baseUrl = baseUrl.replace(/\/+$/, "");
    this.token = token;
    this.timeout = timeout;
    this.backoff = backoff;
  }

  async #post(path, body) {
    // The door's own 503 is at its connection cap, answered before any route runs: nothing happened, so
    // it is repeated, a bounded number of times. Nothing else is, a 503 from a proxy included: that may
    // have landed, and a repeated extract save queues a second paid note job.
    for (const wait of this.backoff) {
      try {
        return await this.#postOnce(path, body);
      } catch (err) {
        if (!(err instanceof Mnem0nicError) || !err.busy) throw err;
      }
      await sleep(wait);
    }
    return this.#postOnce(path, body);
  }

  async #postOnce(path, body) {
    let response;
    let text;
    try {
      response = await fetch(this.baseUrl + path, {
        method: "POST",
        headers: { Authorization: `Bearer ${this.token}`, "Content-Type": "application/json" },
        body: JSON.stringify(body),
        // A 3xx is an error here: following it would carry the bearer token to wherever it points.
        redirect: "manual",
        signal: AbortSignal.timeout(this.timeout),
      });
      if (response.type === "opaqueredirect" || (response.status >= 300 && response.status < 400)) {
        await response.body?.cancel().catch(() => {});
        throw new Mnem0nicError(`${path} answered with a redirect, which is not followed`, response.status || null);
      }
      text = await response.text();
    } catch (err) {
      if (err instanceof Mnem0nicError) throw err;
      throw new Mnem0nicError(`no usable reply from ${path}: ${err?.cause?.message ?? err?.message ?? err}`);
    }
    if (!response.ok) {
      let busy = false;
      if (response.status === 503) {
        try {
          busy = JSON.parse(text)?.error === "busy";
        } catch {
          busy = false;
        }
      }
      throw new Mnem0nicError(`${response.status} ${text.slice(0, 500)}`.trim(), response.status, busy);
    }
    try {
      return JSON.parse(text);
    } catch (err) {
      throw new Mnem0nicError(`no usable reply from ${path}: the reply is not JSON`);
    }
  }

  ping() {
    return this.#post("/ping", {});
  }

  /** `mode` is "verbatim" (the default: stored as it is, no model) or "extract" (also queues a note). */
  save(content, { title, metadata, mode = "verbatim" } = {}) {
    const body = { content, mode };
    if (title !== undefined && title !== null) body.title = title;
    if (metadata !== undefined && metadata !== null) body.metadata = metadata;
    return this.#post("/save", body);
  }

  search(query, { limit = 20, maxDetails = 3 } = {}) {
    return this.#post("/search", { query, limit, maxDetails });
  }

  workStateWrite(list, fields) {
    return this.#post("/work-state/write", { list, fields });
  }

  workStateRead({ list = null, includeClosed = false } = {}) {
    return this.#post("/work-state/read", { list, includeClosed });
  }

  timeline(query) {
    return this.#post("/timeline", { query });
  }
}
