import FileSaver from "file-saver";
import { Main } from "../elm/Main.elm";
import "../css/main.css";

function start() {
  const app = Main.embed(document.getElementById("app"));

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

      case "Save": {
        const { filename, content, mimeType } = message.data;
        const blob = new window.Blob([content], {
          type: `${mimeType};charset=utf-8`,
        });
        FileSaver.saveAs(blob, filename);
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

// Wait for CSS to load in development.
window.setTimeout(start, 0);
