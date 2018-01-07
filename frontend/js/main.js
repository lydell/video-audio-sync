import { Main } from "../elm/Main.elm";
import "../css/main.css";

const app = Main.embed(document.getElementById("app"));

app.ports.elmToJs.subscribe(message => {
  switch (message.tag) {
    case "TestOut":
      console.log("TestOut", message.data);
      app.ports.jsToElm.send({ tag: "TestIn", data: "Hello, Elm!" });
      break;

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

    default:
      console.error("Unexpected message", message);
  }
});
