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

      case "MediaPlay": {
        const id = message.data;
        withElement(id, message, element => {
          element.play();
        });
        break;
      }

      case "MediaPause": {
        const id = message.data;
        withElement(id, message, element => {
          element.pause();
        });
        break;
      }

      case "MediaSeek": {
        const { id, time } = message.data;
        withElement(id, message, element => {
          if (element.seeking) {
            element.onseeked = seek.bind(null, element, time);
          } else {
            seek(element, time);
          }
        });
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

function seek(media, time) {
  const seconds = time / 1000;
  if (media.fastSeek) {
    media.fastSeek(seconds);
  } else {
    media.currentTime = seconds;
  }
  media.onseeked = null;
}

// Wait for CSS to load in development.
window.setTimeout(start, 0);
