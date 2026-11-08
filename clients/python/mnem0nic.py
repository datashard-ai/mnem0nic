"""The mnem0nic Python client: plain POST calls to a daemon's HTTP door.

Zero dependencies — Python 3 stdlib only. Every method sends one POST with the
bearer token and returns the parsed JSON reply; every transport or auth failure
raises `Mnem0nicError`. A tool-level error is data: it arrives as a 200 with
`"isError": true` and is returned as a dict, not raised. The one failure repeated for you is the
door's own 503, {"error": "busy"}: it is answered before any route runs, so repeating the call is always safe.

© 2026 Xibit Digital. All rights reserved. Use is subject to the LICENSE.md of the mnem0nic repository
(https://github.com/datashard-ai/mnem0nic).
"""

import http.client
import json
import time
import urllib.error
import urllib.request


class Mnem0nicError(Exception):
    """A call that got no usable reply: a non-200 answer from the door (`status`
    is its HTTP status code), or no answer at all (`status` is None) — refused,
    reset or timed-out connection, or a reply that is not JSON."""

    def __init__(self, message, status=None, busy=False):
        super().__init__(message)
        self.status = status
        # True only for the door's own 503, {"error": "busy"}: the one failure that is safe to repeat.
        self.busy = busy


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # A 3xx is an error here: following it would carry the bearer token to wherever it points.
        return None


# No proxy (HTTP_PROXY and friends would carry the bearer token through a third party) and no redirects.
_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}), _NoRedirect)


class Mnem0nic:
    def __init__(self, base_url, token, timeout=30.0, backoff=(0.2, 0.5, 1.0)):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout
        # Seconds to wait before each retry of a 503, and so how many retries there are.
        self.backoff = backoff

    def _post(self, path, body):
        # The door's own 503 is at its connection cap, answered before any route runs: nothing happened,
        # so it is repeated, a bounded number of times. Nothing else is, a 503 from a proxy included: that
        # may have landed, and a repeated extract save queues a second paid note job.
        for wait in self.backoff:
            try:
                return self._post_once(path, body)
            except Mnem0nicError as err:
                if not err.busy:
                    raise
            time.sleep(wait)
        return self._post_once(path, body)

    def _post_once(self, path, body):
        request = urllib.request.Request(
            self.base_url + path,
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with _OPENER.open(request, timeout=self.timeout) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as err:
            try:
                text = err.read().decode("utf-8", "replace")[:500]
            except (OSError, http.client.HTTPException):
                text = ""
            busy = False
            if err.code == 503:
                try:
                    busy = json.loads(text).get("error") == "busy"
                except (ValueError, AttributeError):
                    busy = False
            raise Mnem0nicError(f"{err.code} {text}".strip(), err.code, busy) from err
        except (
            urllib.error.URLError,  # refused, unreachable, reset while connecting
            OSError,  # TimeoutError, ConnectionError, RemoteDisconnected while reading
            http.client.HTTPException,  # a reply cut short or malformed
            ValueError,  # JSONDecodeError, UnicodeDecodeError: a reply that is not JSON
        ) as err:
            raise Mnem0nicError(f"no usable reply from {path}: {err}") from err

    def ping(self):
        return self._post("/ping", {})

    def save(self, content, title=None, metadata=None, mode="verbatim"):
        body = {"content": content, "mode": mode}
        if title is not None:
            body["title"] = title
        if metadata is not None:
            body["metadata"] = metadata
        return self._post("/save", body)

    def search(self, query, limit=20, max_details=3):
        return self._post(
            "/search", {"query": query, "limit": limit, "maxDetails": max_details}
        )

    def work_state_write(self, list_name, fields):
        return self._post("/work-state/write", {"list": list_name, "fields": fields})

    def work_state_read(self, list_name=None, include_closed=False):
        return self._post(
            "/work-state/read", {"list": list_name, "includeClosed": include_closed}
        )

    def timeline(self, query):
        return self._post("/timeline", {"query": query})
