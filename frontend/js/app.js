import FileSaver from "file-saver";
import _ from "lodash";
import matchesAccept from "attr-accept";

import { Main } from "../elm/Main.elm";

import { openFiles, readFileAsText, seek, withElement } from "./effect-utils";

export default class App {
  constructor({
    rootElement,
    flags,
    fileTypes,
    persistKeyboardShortcuts,
    warnOnClose,
  }) {
    const elmApp = Main.embed(rootElement, flags);

    this.elmApp = elmApp;
    this.fileTypes = fileTypes;
    this.persistKeyboardShortcuts = persistKeyboardShortcuts;
    this.warnOnClose = warnOnClose;

    this.objectUrls = new Map();
    this.keyboardShortcuts = {};
    this.editingKeyboardShortcuts = false;

    // "NotRestarting" | "RestartingPaused" | "RestartingPlaying"
    this.restartingState = "NotRestarting";

    this.onDragEnter = this.onDragEnter.bind(this);
    this.onDragLeave = this.onDragLeave.bind(this);
    this.onDrop = this.onDrop.bind(this);
    this.onOpenedFiles = this.onOpenedFiles.bind(this);
    this.onKeydown = this.onKeydown.bind(this);
    this.shouldSuppressKeydown = this.shouldSuppressKeydown.bind(this);
  }

  sendToElm(tag, data) {
    this.elmApp.ports.jsToElm.send({
      tag,
      data,
    });
  }

  subscribeToElm() {
    this.elmApp.ports.elmToJs.subscribe(message => {
      switch (message.tag) {
        case "MeasureArea": {
          const id = message.data;
          withElement(id, message, element => {
            const rect = element.getBoundingClientRect();
            this.sendToElm("AreaMeasurement", {
              id,
              area: {
                width: rect.width,
                height: rect.height,
                x: rect.left,
                y: rect.top,
              },
            });
          });
          break;
        }

        case "Play": {
          const id = message.data;
          withElement(id, message, element => {
            switch (this.restartingState) {
              case "NotRestarting":
                element.play();
                break;
              case "RestartingPaused":
                this.restartingState = "RestartingPlaying";
                break;
              case "RestartingPlaying":
                // Do nothing.
                break;
              default:
                console.warn(
                  "Unknown this.restartingState",
                  this.restartingState,
                  message,
                );
            }
          });
          break;
        }

        case "Pause": {
          const id = message.data;
          withElement(id, message, element => {
            switch (this.restartingState) {
              case "NotRestarting":
                element.pause();
                break;
              case "RestartingPaused":
                // Do nothing.
                break;
              case "RestartingPlaying":
                this.restartingState = "RestartingPaused";
                break;
              default:
                console.warn(
                  "Unknown this.restartingState",
                  this.restartingState,
                  message,
                );
            }
          });
          break;
        }

        case "Seek": {
          const { id, time } = message.data;
          withElement(id, message, element => {
            if (element.seeking) {
              element.onseeked = seek.bind(null, element, time, null);
            } else {
              // Pass `null` as callback to clear previously queued seeks.
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

              // If the user pressed Pause at the very end of the loop, that can
              // actually happen a couple of milliseconds _after_ the loop end,
              // before the app has received a time update and knows to restart.
              // In such a case we should still go back to the start of the
              // loop, but not start playing again.
              const bothPaused = audioElement.paused && videoElement.paused;

              this.restartingState = bothPaused
                ? "RestartingPaused"
                : "RestartingPlaying";

              audioElement.pause();
              videoElement.pause();

              const callback = () => {
                if (!audioElement.seeking && !videoElement.seeking) {
                  if (this.restartingState === "RestartingPlaying") {
                    audioElement.play();
                    videoElement.play();
                  }
                  this.restartingState = "NotRestarting";
                }
              };

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
          const info = this.fileTypes[fileType];
          const expectedFileTypes = [fileType];

          if (info == null) {
            console.error("Unknown fileType", fileType, message);
            break;
          }

          openFiles({
            accept: info.accept,
            onOpenedFiles: this.onOpenedFiles.bind(this, expectedFileTypes),
          });
          break;
        }

        case "OpenMultipleFiles": {
          const accept = Object.values(this.fileTypes)
            .map(info => info.accept)
            .join(",");
          const expectedFileTypes = Object.keys(this.fileTypes);
          openFiles({
            accept,
            multiple: true,
            onOpenedFiles: this.onOpenedFiles.bind(this, expectedFileTypes),
          });
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

        case "StateSync": {
          const {
            keyboardShortcuts,
            editingKeyboardShortcuts,
            warnOnClose,
          } = message.data;

          this.keyboardShortcuts = keyboardShortcuts;
          this.editingKeyboardShortcuts = editingKeyboardShortcuts;

          this.persistKeyboardShortcuts(keyboardShortcuts);
          this.warnOnClose(warnOnClose);
          break;
        }

        default:
          console.error("Unexpected message", message);
      }
    });
  }

  onDragEnter() {
    this.sendToElm("DragEnter", null);
  }

  onDragLeave() {
    this.sendToElm("DragLeave", null);
  }

  onDrop(files) {
    for (const file of files) {
      this.reportOpenedFile(file);
    }
  }

  onOpenedFiles(expectedFileTypes, [acceptedFiles, rejectedFiles]) {
    for (const file of acceptedFiles) {
      this.reportOpenedFile(file);
    }

    for (const file of rejectedFiles) {
      this.sendToElm("InvalidFile", {
        name: file.name,
        expectedFileTypes,
      });
    }
  }

  onKeydown(data) {
    this.sendToElm("Keydown", data);
  }

  shouldSuppressKeydown(data) {
    return (
      _.has(this.keyboardShortcuts, data.key) || this.editingKeyboardShortcuts
    );
  }

  reportOpenedFile(file) {
    const maybeInfo = this.getFileInfo(file);

    if (maybeInfo == null) {
      this.sendToElm("InvalidFile", {
        name: file.name,
        expectedFileTypes: Object.keys(this.fileTypes),
      });
      return;
    }

    const { fileType, info } = maybeInfo;

    if (info.openAsUrl) {
      this.sendToElm("OpenedFileAsUrl", {
        name: file.name,
        fileType,
        url: this.openAsUrl(file, fileType),
      });
      return;
    }

    readFileAsText(file).then(
      content => {
        this.sendToElm("OpenedFileAsText", {
          name: file.name,
          fileType,
          content,
        });
      },
      () => {
        this.sendToElm("ErroredFile", {
          name: file.name,
          fileType,
        });
      },
    );
  }

  openAsUrl(file, fileType) {
    const previousUrl = this.objectUrls.get(fileType);

    if (previousUrl != null) {
      window.URL.revokeObjectURL(previousUrl);
    }

    const url = window.URL.createObjectURL(file);
    this.objectUrls.set(fileType, url);
    return url;
  }

  getFileInfo(file) {
    for (const [fileType, info] of Object.entries(this.fileTypes)) {
      if (matchesAccept(file, info.accept)) {
        return { fileType, info };
      }
    }
    return null;
  }
}
