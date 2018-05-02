import "../css/main.css";
import { getLocalStorage, setLocalStorage, withElement } from "./effect-utils";
import { setupGlobalDragAndDrop, setupGlobalKeydown } from "./global-listeners";
import App from "./app";

const LS_KEY_KEYBOARD_SHORTCUTS = "keyboardShortcuts";

// Chrome does not appear to show .aac and .json files unless explicitly
// mentioned via file extension.
const FILE_TYPES = {
  AudioFile: {
    accept: "audio/*,.aac",
    openAsUrl: true,
  },
  VideoFile: {
    accept: "video/*,.mp4",
    openAsUrl: true,
  },
  JsonFile: {
    accept: "application/json,.json",
    openAsUrl: false,
  },
};

function start() {
  const params = new window.URLSearchParams(
    DEBUG ? window.location.search : "",
  );

  const allowWarnOnClose = !DEBUG || Boolean(params.get("warn_on_close"));

  withElement("loader", "loading/fallback element", element => {
    element.remove();
  });

  withElement("app", "main app element", element => {
    const flags = {
      audio: params.get("audio"),
      video: params.get("video"),
      keyboardShortcuts: getLocalStorage(LS_KEY_KEYBOARD_SHORTCUTS),
    };

    const app = new App({
      rootElement: element,
      flags,
      allowWarnOnClose,
      fileTypes: FILE_TYPES,
      persistKeyboardShortcuts: keyboardShortcuts => {
        setLocalStorage(LS_KEY_KEYBOARD_SHORTCUTS, keyboardShortcuts);
      },
    });

    app.subscribeToElm();
    setupGlobalDragAndDrop(app);
    setupGlobalKeydown(app);
  });
}

// Wait for CSS to load in development.
if (DEBUG) {
  // eslint-disable-next-line func-style
  const poll = () => {
    // main.css sets `--css-applied: true;` so we can look for that.
    if (
      window
        .getComputedStyle(document.documentElement)
        .getPropertyValue("--css-applied")
        .trim() === "true"
    ) {
      start();
    } else {
      window.setTimeout(poll, 10);
    }
  };
  poll();
} else {
  start();
}
