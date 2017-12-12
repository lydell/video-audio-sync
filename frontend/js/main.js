import { Main } from "../elm/Main.elm";
import "../css/main.css";

const app = Main.embed(document.getElementById("app"));

app.ports.elmToJs.subscribe(message => {
  switch (message.tag) {
    case "TestOut":
      console.log("TestOut", message.data);
      app.ports.jsToElm.send({ tag: "TestIn", data: "Hello, Elm!" });
      break;

    default:
      console.error("Unexpected message", message);
  }
});
