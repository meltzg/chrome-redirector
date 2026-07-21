const NATIVE_HOST = "com.meltzg.chrome_redirector";

browser.webRequest.onBeforeRequest.addListener(
  (details) => {
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
