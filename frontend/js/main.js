import { Main } from "../elm/Main.elm";
import "../css/main.css";

const app = Main.embed(document.getElementById("app"));

app.ports.elmToJs.subscribe(message => {
  switch (message.tag) {
    case "TestOut":
      console.log("TestOut", message.data);
      app.ports.jsToElm.send({ tag: "TestIn", data: "Hello, Elm!" });
      break;

    case "JsPlay":
      withMedia((video, audio) => {
        video.play();
        audio.play();
      });
      break;

    case "JsPause":
      withMedia((video, audio) => {
        video.pause();
        audio.pause();
      });
      break;

    default:
      console.error("Unexpected message", message);
  }
});

function withMedia(fn) {
  const video = document.querySelector("video");
  const audio = document.querySelector("audio");

  if (video && audio) {
    fn(video, audio);
  } else {
    console.error("Could not find both video and audio.", { video, audio });
  }
}
