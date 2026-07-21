# chrome-redirector

Firefox extension that opens any navigation to `*.google.com` in Google Chrome
instead of Firefox.

## Install

Requirements: Linux, Firefox, Google Chrome (or Chromium), `python3`.

```sh
git clone https://github.com/meltzg/chrome-redirector.git ~/chrome-redirector
cd ~/chrome-redirector
./install.sh
```

Then click **Add** in the Firefox prompt. That's it — google.com links now
open in Chrome.

> Keep the clone around: the native helper runs from inside it. To update,
> `git pull` and re-run `./install.sh`.

## Uninstall

- Remove the extension in Firefox (`about:addons`).
- `rm ~/.mozilla/native-messaging-hosts/com.meltzg.chrome_redirector.json`

## How it works

Firefox extensions can't launch external programs directly, so this has two
parts:

- `extension/` — a WebExtension with a blocking `webRequest` listener on
  top-level navigations matching `*://*.google.com/*` (matches `google.com`
  and any subdomain — mail, docs, drive, etc.). It cancels the navigation in
  Firefox and hands the URL off via native messaging. Leftover blank tabs
  from `target="_blank"` links are closed automatically.
- `native/open_in_chrome.py` — a native messaging host that receives the URL
  and launches `google-chrome` (falling back to `google-chrome-stable` /
  `chromium`). As a safety check it only accepts `http`/`https` URLs on
  `google.com` domains.

It intercepts *all* top-level navigations to google.com — clicked links,
typed URLs, and bookmarks alike. Subframe loads (embedded Google widgets,
OAuth iframes) are untouched.

## Maintainer: releasing a new version

Release Firefox only installs extensions signed by Mozilla. Signing is free
and automated (unlisted channel — the add-on is signed but not published on
addons.mozilla.org):

1. Get API credentials at
   <https://addons.mozilla.org/developers/addon/api/key/>
2. Bump `"version"` in `extension/manifest.json`.
3. Sign and commit the result:

   ```sh
   AMO_JWT_ISSUER=user:xxx:yyy AMO_JWT_SECRET=zzz ./sign.sh
   git add dist/*.xpi extension/manifest.json
   git commit -m "Release vX.Y.Z"
   ```

`build.sh` produces an unsigned zip in `dist/` if you just want to inspect
the package or load it temporarily via `about:debugging`.
