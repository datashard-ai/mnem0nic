/** Types for mnem0nic.mjs, the JavaScript client for a mnem0nic daemon's HTTP door. */

export class Mnem0nicError extends Error {
  /** The HTTP status of a refusal or a redirect (where the runtime reports one), or null when no usable reply came. */
  status: number | null;
  /** True only for the door's own 503, `{"error":"busy"}`, which the client has already repeated. */
  busy: boolean;
  constructor(message: string, status?: number | null, busy?: boolean);
}

export interface Mnem0nicOptions {
  /** Milliseconds for each attempt (default 30000). */
  timeout?: number;
  /** Milliseconds to wait before each retry of a 503, and so how many retries there are (default [200, 500, 1000]). */
  backoff?: number[];
}

/** A tool-level reply: a validation problem arrives with `isError: true` and is data, not an exception. */
export interface ToolReply {
  isError?: boolean;
  text?: string;
  [key: string]: unknown;
}

export interface SaveReply {
  ok: boolean;
  /** "off" for a verbatim save; for an extract save "queued", or "unavailable" when no note can be written. */
  extraction?: "off" | "queued" | "unavailable";
  [key: string]: unknown;
}

export class Mnem0nic {
  constructor(baseUrl: string, token: string, options?: Mnem0nicOptions);
  ping(): Promise<{ ok: boolean; build: string }>;
  save(
    content: string,
    options?: { title?: string | null; metadata?: Record<string, unknown> | null; mode?: "verbatim" | "extract" },
  ): Promise<SaveReply>;
  search(query: string, options?: { limit?: number; maxDetails?: number }): Promise<ToolReply>;
  workStateWrite(list: string, fields: Record<string, unknown>): Promise<ToolReply>;
  workStateRead(options?: { list?: string | null; includeClosed?: boolean }): Promise<ToolReply>;
  timeline(query: string): Promise<ToolReply>;
}
