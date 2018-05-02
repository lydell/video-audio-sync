import matchesAccept from "attr-accept";
import FileSaver from "file-saver";
import { Main } from "../elm/Main.elm";
import "../css/main.css";

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

const objectUrls = new Map();

function start() {
  const params = new window.URLSearchParams(
    DEBUG ? window.location.search : "",
  );

  const warnOnClose = !DEBUG || Boolean(params.get("warn_on_close"));

  removeLoader();

  const app = Main.embed(document.getElementById("app"), {
    audio: params.get("audio"),
    video: params.get("video"),
    keyboardShortcuts: getLocalStorage(LS_KEY_KEYBOARD_SHORTCUTS),
  });

  setupDragAndDrop(app);
  setupKeyboard(app);

  app.ports.elmToJs.subscribe(message => {
    switch (message.tag) {
      case "MeasureArea": {
        const id = message.data;
        withElement(id, message, element => {
          const rect = element.getBoundingClientRect();
          app.ports.jsToElm.send({
            tag: "AreaMeasurement",
            data: {
              id,
              area: {
                width: rect.width,
                height: rect.height,
                x: rect.left,
                y: rect.top,
              },
            },
          });
        });
        break;
      }

      case "Play": {
        const id = message.data;
        withElement(id, message, element => {
          element.play();
        });
        break;
      }

      case "Pause": {
        const id = message.data;
        withElement(id, message, element => {
          element.pause();
        });
        break;
      }

      case "Seek": {
        const { id, time } = message.data;
        withElement(id, message, element => {
          // Pass `null` as callback to clear previously queued seeks.
          if (element.seeking) {
            element.onseeked = seek.bind(null, element, time, null);
          } else {
            seek(element, time, null);
          }
        });
        break;
      }

      case "RestartLoop": {
        const { audio, video } = message.data;

        withElement(audio.id, message, audioElement => {
          withElement(video.id, message, videoElement => {
            if (audioElement.seeking || videoElement.seeking) {
              console.warn("Aborting RestartLoop attempt due to seeking", {
                audioSeeking: audioElement.seeking,
                videoSeeking: videoElement.seeking,
                message,
              });
              return;
            }

            audioElement.pause();
            videoElement.pause();

            function callback() {
              if (!audioElement.seeking && !videoElement.seeking) {
                audioElement.play();
                videoElement.play();
              }
            }

            seek(audioElement, audio.time, callback);
            seek(videoElement, video.time, callback);
          });
        });
        break;
      }

      case "SaveFile": {
        const { filename, content, mimeType } = message.data;
        const blob = new window.Blob([content], {
          type: `${mimeType};charset=utf-8`,
        });
        FileSaver.saveAs(blob, filename);
        break;
      }

      case "OpenFile": {
        const { fileType } = message.data;
        const info = FILE_TYPES[fileType];
        const expectedFileTypes = [fileType];

        if (info == null) {
          console.error("Unknown fileType", fileType, message);
          break;
        }

        openFile({ accept: info.accept, expectedFileTypes, app });
        break;
      }

      case "OpenMultipleFiles": {
        const accept = Object.values(FILE_TYPES)
          .map(info => info.accept)
          .join(",");
        const expectedFileTypes = Object.keys(FILE_TYPES);
        openFile({ accept, multiple: true, expectedFileTypes, app });
        break;
      }

      case "WarnOnClose": {
        const maybeMessage = message.data;

        if (!warnOnClose) {
          return;
        }

        window.onbeforeunload =
          maybeMessage == null
            ? null
            : event => {
                event.returnValue = maybeMessage;
                return maybeMessage;
              };
        break;
      }

      case "ClickButton": {
        const { id, right } = message.data;
        withElement(id, message, element => {
          // Focus the element after Elm has re-rendered since Firefox has a
          // weird bug where the entire window loses focus if a focused
          // `<button>` gets disabled.
          window.requestAnimationFrame(() => {
            element.focus();
          });
          if (right) {
            element.dispatchEvent(new window.CustomEvent("contextmenu"));
          } else {
            element.click();
          }
        });
        break;
      }

      case "PersistKeyboardShortcuts": {
        setLocalStorage(LS_KEY_KEYBOARD_SHORTCUTS, message.data);
        break;
      }

      default:
        console.error("Unexpected message", message);
    }
  });
}

function withElement(id, message, callback) {
  const element = document.getElementById(id);

  if (element == null) {
    console.error("Could not find element with id", id, message);
    return;
  }

  callback(element);
}

function removeLoader() {
  withElement("loader", "loading/fallback", element => {
    element.remove();
  });
}

function seek(media, time, callback) {
  media.onseeked = callback;
  const seconds = time / 1000;
  media.currentTime = seconds;
}

function setupDragAndDrop(app) {
  function dragEnter() {
    document.body.style.pointerEvents = "none";
    app.ports.jsToElm.send({ tag: "DragEnter", data: null });
  }

  function dragLeave() {
    document.body.style.pointerEvents = "";
    app.ports.jsToElm.send({ tag: "DragLeave", data: null });
  }

  document.addEventListener(
    "dragenter",
    event => {
      event.preventDefault();
      dragEnter();
    },
    false,
  );

  document.addEventListener(
    "dragover",
    event => {
      event.preventDefault();
    },
    false,
  );

  document.addEventListener(
    "dragleave",
    event => {
      if (event.target === document.documentElement) {
        dragLeave();
      }
    },
    false,
  );

  document.addEventListener(
    "drop",
    event => {
      event.preventDefault();
      dragLeave();
      for (const file of event.dataTransfer.files) {
        reportOpenedFile(file, app);
      }
    },
    false,
  );
}

function getFileType(file) {
  for (const [fileType, info] of Object.entries(FILE_TYPES)) {
    if (matchesAccept(file, info.accept)) {
      return fileType;
    }
  }
  return null;
}

function openFile({ accept, multiple = false, expectedFileTypes, app }) {
  const fileInput = document.createElement("input");
  fileInput.type = "file";

  fileInput.accept = accept;
  fileInput.multiple = multiple;

  fileInput.onchange = () => {
    fileInput.onchange = null;

    for (const file of fileInput.files) {
      if (matchesAccept(file, accept)) {
        reportOpenedFile(file, app);
      } else {
        app.ports.jsToElm.send({
          tag: "InvalidFile",
          data: {
            name: file.name,
            expectedFileTypes,
          },
        });
      }
    }
  };

  fileInput.click();
}

function reportOpenedFile(file, app) {
  const fileType = getFileType(file);
  const info = FILE_TYPES[fileType];

  if (fileType == null) {
    app.ports.jsToElm.send({
      tag: "InvalidFile",
      data: {
        name: file.name,
        expectedFileTypes: Object.keys(FILE_TYPES),
      },
    });
    return;
  }

  function success(content) {
    app.ports.jsToElm.send({
      tag: "OpenedFile",
      data: {
        name: file.name,
        fileType,
        content,
      },
    });
  }

  function failure() {
    app.ports.jsToElm.send({
      tag: "ErroredFile",
      data: {
        name: file.name,
        fileType,
      },
    });
  }

  if (info.openAsUrl) {
    const previousUrl = objectUrls.get(fileType);

    if (previousUrl != null) {
      window.URL.revokeObjectURL(previousUrl);
    }

    const url = window.URL.createObjectURL(file);
    objectUrls.set(fileType, url);
    success(url);
    return;
  }

  const reader = new window.FileReader();

  reader.onload = event => {
    const text = event.target.result;
    success(text);
  };

  reader.onabort = failure;
  reader.onerror = failure;

  reader.readAsText(file);
}

const IGNORED = /^($|Dead$|Alt|Control|Hyper|Meta|Shift|Super|OS)/;

function setupKeyboard(app) {
  document.addEventListener(
    "keydown",
    event => {
      const { key: rawKey } = event;
      const key = rawKey === " " ? "Space" : rawKey;

      if (IGNORED.test(key)) {
        return;
      }

      let defaultPrevented = false;

      if (key.length === 1) {
        event.preventDefault();
        defaultPrevented = true;
      }

      app.ports.jsToElm.send({
        tag: "Keydown",
        data: {
          key,
          altKey: event.altKey,
          ctrlKey: event.ctrlKey,
          metaKey: event.metaKey,
          shiftKey: event.shiftKey,
          defaultPrevented,
        },
      });
    },
    true,
  );
}

function getLocalStorage(key) {
  try {
    const data = window.localStorage.getItem(key);
    return data == null ? null : JSON.parse(data);
  } catch (error) {
    console.warn("Failed to read from localStorage", {
      key,
      error,
    });
  }
  return null;
}

function setLocalStorage(key, data) {
  try {
    window.localStorage.setItem(key, JSON.stringify(data));
  } catch (error) {
    console.warn("Failed to write to localStorage", {
      key,
      data,
      error,
    });
  }
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
