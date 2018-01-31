import matchesAccept from "attr-accept";
import FileSaver from "file-saver";
import { Main } from "../elm/Main.elm";
import "../css/main.css";

const FILE_TYPES = {
  AudioFile: {
    // Chrome oddly didn't show .aac files in the upload dialog for me, so I
    // had to add .aac explicitly.
    accept: "audio/*,.aac",
    openAsUrl: true,
  },
  VideoFile: {
    accept: "video/*",
    openAsUrl: true,
  },
  JsonFile: {
    accept: "application/json",
    openAsUrl: false,
  },
};

function start() {
  const app = Main.embed(document.getElementById("app"));

  setupDragAndDrop(app);

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
        return;
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
    const url = window.URL.createObjectURL(file);
    success(url);
    window.setTimeout(() => {
      window.URL.revokeObjectURL(url);
    }, 0);
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

// Wait for CSS to load in development.
window.setTimeout(start, 0);
