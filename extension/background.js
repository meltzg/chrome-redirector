const NATIVE_HOST = "com.meltzg.chrome_redirector";

// Hosts that must stay in Firefox: OAuth / "Sign in with Google" flows
// break if the navigation is hijacked mid-login.
const PASSTHROUGH_HOSTS = ["accounts.google.com"];

function isPassthrough(url) {
  try {
    const { hostname } = new URL(url);
    return PASSTHROUGH_HOSTS.some(
      (host) => hostname === host || hostname.endsWith("." + host)
    );
  } catch {
    return false;
  }
}

browser.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (isPassthrough(details.url)) {
      return {};
    }

    browser.runtime
      .sendNativeMessage(NATIVE_HOST, { url: details.url })
      .catch((err) => {
        console.error("chrome-redirector: failed to reach native host:", err);
      });

    // If the link opened a brand-new tab (target=_blank), cancelling the
    // request leaves an empty about:blank tab behind — clean it up.
    if (details.tabId >= 0) {
      browser.tabs
        .get(details.tabId)
        .then((tab) => {
          if (tab.url === "about:blank") {
            return browser.tabs.remove(tab.id);
          }
        })
        .catch(() => {});
    }

    return { cancel: true };
  },
  {
    urls: ["*://*.google.com/*"],
    types: ["main_frame"],
  },
  ["blocking"]
);
