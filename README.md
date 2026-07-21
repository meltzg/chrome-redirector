# chrome-redirector

Firefox extension that opens any navigation to `*.google.com` in Google Chrome
instead of Firefox.

## Install

Requirements: Firefox, Google Chrome (or Chromium), Python 3.

**Linux / macOS:**

```sh
git clone https://github.com/meltzg/chrome-redirector.git ~/chrome-redirector
cd ~/chrome-redirector
./install.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/meltzg/chrome-redirector.git $HOME\chrome-redirector
cd $HOME\chrome-redirector
powershell -ExecutionPolicy Bypass -File install.ps1
```

Then click **Add** in the Firefox prompt. That's it — google.com links now
open in Chrome.

> Keep the clone around: the native helper runs from inside it. To update,
> `git pull` and re-run the installer.
>
> Nothing runs at login or in the background — Firefox launches the helper
> on demand when a google.com link is opened, and it exits immediately after.

## Uninstall

- Remove the extension in Firefox (`about:addons`).
- Remove the native host registration:
  - Linux: `rm ~/.mozilla/native-messaging-hosts/com.meltzg.chrome_redirector.json`
  - macOS: `rm ~/Library/Application\ Support/Mozilla/NativeMessagingHosts/com.meltzg.chrome_redirector.json`
  - Windows: `Remove-Item HKCU:\Software\Mozilla\NativeMessagingHosts\com.meltzg.chrome_redirector`

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

Releases are automated: pushing a `vX.Y.Z` tag triggers
`.github/workflows/release.yml`, which signs the extension via
addons.mozilla.org (unlisted channel — signed but not published on AMO) and
publishes a GitHub Release with the signed `.xpi`. The install scripts pick
up the latest release automatically.

One-time setup: create AMO API credentials at
<https://addons.mozilla.org/developers/addon/api/key/> and add them as repo
secrets named `AMO_JWT_ISSUER` and `AMO_JWT_SECRET`.

To release:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

The workflow stamps the tag's version into `extension/manifest.json` at
build time, so the version committed in git is just a dev placeholder —
no version-bump commit needed. Versions must be new to AMO: pick a higher
version for each release, and don't reuse a tag's version even if the tag
is deleted.

For local testing, `build.sh` produces an unsigned zip in `dist/` (loadable
via `about:debugging`), and `sign.sh` can be run by hand with the AMO
credentials in the environment.
