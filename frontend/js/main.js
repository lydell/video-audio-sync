import { Main } from "../elm/Main.elm";
import "../css/main.css";

function start() {
  const app = Main.embed(document.getElementById("app"));

  app.ports.elmToJs.subscribe(message => {
    switch (message.tag) {
      case "MeasureArea": {
        const id = message.data;
        const element = document.getElementById(id);

        if (element == null) {
          console.error("Could not find element with id", id);
          return;
        }

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
        break;
      }

      case "JsVideoPlayState": {
        const playing = message.data;
        const video = document.querySelector("video");
        if (video) {
          if (playing) {
            video.play();
          } else {
            video.pause();
          }
        } else {
          console.error("Could not find video.");
        }
        break;
      }

      case "JsAudioPlayState": {
        const playing = message.data;
        const audio = document.querySelector("audio");
        if (audio) {
          if (playing) {
            audio.play();
          } else {
            audio.pause();
          }
        } else {
          console.error("Could not find audio.");
        }
        break;
      }

      case "VideoSeek": {
        const time = message.data / 1000;
        const video = document.querySelector("video");
        if (video) {
          if (video.seeking) {
            video.onseeked = seek.bind(null, video, time);
          } else {
            seek(video, time);
          }
        } else {
          console.error("Could not find video.");
        }
        break;
      }

      case "AudioSeek": {
        const time = message.data / 1000;
        const audio = document.querySelector("audio");
        if (audio) {
          if (audio.seeking) {
            audio.onseeked = seek.bind(null, audio, time);
          } else {
            seek(audio, time);
          }
        } else {
          console.error("Could not find audio.");
        }
        break;
      }

      default:
        console.error("Unexpected message", message);
    }
  });
}

function seek(media, time) {
  if (media.fastSeek) {
    media.fastSeek(time);
  } else {
    media.currentTime = time;
  }
  media.onseeked = null;
}

// Wait for CSS to load in development.
window.setTimeout(start, 0);
