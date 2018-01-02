import { Main } from "../elm/Main.elm";
import "../css/main.css";

const app = Main.embed(document.getElementById("app"));

app.ports.elmToJs.subscribe(message => {
  switch (message.tag) {
    case "TestOut":
      console.log("TestOut", message.data);
      app.ports.jsToElm.send({ tag: "TestIn", data: "Hello, Elm!" });
      break;

    case "JsPlay": {
      console.log("play");

      const video = document.querySelector("video");

      if (video) {
        video.play();
      }

      const audio = document.querySelector("audio");

      if (audio) {
        audio.play();
      }

      break;
    }

    case "JsPause": {
      console.log("pause");

      const video = document.querySelector("video");

      if (video) {
        video.pause();
      }

      const audio = document.querySelector("audio");

      if (audio) {
        audio.pause();
      }

      break;
    }

    default:
      console.error("Unexpected message", message);
  }
});
