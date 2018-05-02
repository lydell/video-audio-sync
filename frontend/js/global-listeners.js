const IGNORED_KEY_REGEX = /^($|Dead$|Alt|Control|Hyper|Meta|Shift|Super|OS)/;

export function setupGlobalDragAndDrop({ onDragEnter, onDragLeave, onDrop }) {
  function dragEnter() {
    document.body.style.pointerEvents = "none";
    onDragEnter();
  }

  function dragLeave() {
    document.body.style.pointerEvents = "";
    onDragLeave();
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
      onDrop(event.dataTransfer.files);
    },
    false,
  );
}

export function setupGlobalKeydown({ onKeydown, shouldSuppressKeydown }) {
  document.addEventListener(
    "keydown",
    event => {
      const { key: rawKey } = event;
      const key = rawKey === " " ? "Space" : rawKey;
      const data = {
        key,
        altKey: event.altKey,
        ctrlKey: event.ctrlKey,
        metaKey: event.metaKey,
        shiftKey: event.shiftKey,
      };

      if (IGNORED_KEY_REGEX.test(key)) {
        return;
      }

      if (shouldSuppressKeydown(data)) {
        event.preventDefault();
      }

      onKeydown(data);
    },
    true,
  );
}
