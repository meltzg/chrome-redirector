#!/usr/bin/env python3
"""Native messaging host: receives a URL from the Firefox extension and
opens it in Google Chrome. Launched on demand by Firefox — not a daemon."""

import json
import os
import platform
import shutil
import struct
import subprocess
import sys
from urllib.parse import urlparse


def find_chrome():
    system = platform.system()
    if system == "Darwin":
        candidates = [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            os.path.expanduser(
                "~/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            ),
        ]
        for path in candidates:
            if os.path.exists(path):
                return path
    elif system == "Windows":
        for base in (
            os.environ.get("PROGRAMFILES"),
            os.environ.get("PROGRAMFILES(X86)"),
            os.environ.get("LOCALAPPDATA"),
        ):
            if base:
                path = os.path.join(
                    base, "Google", "Chrome", "Application", "chrome.exe"
                )
                if os.path.exists(path):
                    return path
    for name in ("google-chrome", "google-chrome-stable", "chromium",
                 "chromium-browser", "chrome"):
        path = shutil.which(name)
        if path:
            return path
    return None


CHROME = find_chrome()


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


def launch_detached(args):
    kwargs = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
    if platform.system() == "Windows":
        kwargs["creationflags"] = (
            subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
        )
    else:
        kwargs["start_new_session"] = True
    subprocess.Popen(args, **kwargs)


def main():
    while True:
        message = read_message()
        if message is None:
            break

        url = message.get("url", "")
        if not CHROME:
            send_message({"ok": False, "error": "chrome not found"})
            continue
        if not url_is_allowed(url):
            send_message({"ok": False, "error": "url not allowed"})
            continue

        launch_detached([CHROME, url])
        send_message({"ok": True})


if __name__ == "__main__":
    main()
