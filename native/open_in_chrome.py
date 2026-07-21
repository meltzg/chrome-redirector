#!/usr/bin/env python3
"""Native messaging host: receives a URL from the Firefox extension and
opens it in Google Chrome."""

import json
import shutil
import struct
import subprocess
import sys
from urllib.parse import urlparse

CHROME = (
    shutil.which("google-chrome")
    or shutil.which("google-chrome-stable")
    or shutil.which("chromium")
    or shutil.which("chromium-browser")
)


def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) < 4:
        return None
    length = struct.unpack("=I", raw_length)[0]
    return json.loads(sys.stdin.buffer.read(length).decode("utf-8"))


def send_message(message):
    encoded = json.dumps(message).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("=I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def url_is_allowed(url):
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        return False
    host = parsed.hostname or ""
    return host == "google.com" or host.endswith(".google.com")


def main():
    while True:
        message = read_message()
        if message is None:
            break

        url = message.get("url", "")
        if not CHROME:
            send_message({"ok": False, "error": "chrome not found in PATH"})
            continue
        if not url_is_allowed(url):
            send_message({"ok": False, "error": "url not allowed"})
            continue

        subprocess.Popen(
            [CHROME, url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        send_message({"ok": True})


if __name__ == "__main__":
    main()
