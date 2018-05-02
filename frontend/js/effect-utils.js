import matchesAccept from "attr-accept";

import { partition } from "./pure-utils";

export function withElement(id, message, callback) {
  const element = document.getElementById(id);

  if (element == null) {
    console.error("Could not find element with id", id, message);
    return;
  }

  callback(element);
}

export function seek(media, time, callback) {
  media.onseeked = callback;
  const seconds = time / 1000;
  media.currentTime = seconds;
}

export function openFiles({ accept, multiple = false, onOpenedFiles }) {
  const fileInput = document.createElement("input");
  fileInput.type = "file";

  fileInput.accept = accept;
  fileInput.multiple = multiple;

  fileInput.onchange = () => {
    fileInput.onchange = null;

    onOpenedFiles(
      partition(fileInput.files, file => matchesAccept(file, accept)),
    );
  };

  fileInput.click();
}

export function readFileAsText(file) {
  return new Promise((resolve, reject) => {
    const reader = new window.FileReader();

    reader.onload = event => {
      const text = event.target.result;
      resolve(text);
    };

    reader.onabort = reject;
    reader.onerror = reject;

    reader.readAsText(file);
  });
}

export function getLocalStorage(key) {
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

export function setLocalStorage(key, data) {
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
