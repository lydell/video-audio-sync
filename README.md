# Video Audio Sync

_Work in progress._

Tool for syncing up video and audio.

1.  `python3 extract.py my_video.mp4 aac`
2.  Upload the extracted video and audio files to the browser-based sync tool.
3.  Sync points of video and audio using the tool and download the resulting
    points file.
4.  `python3 sync.py my_video_video.mp4 my_video_audio.aac points.json`

## Development

Requirements:

* [Node.js] 8
* [Python] 3.5
* [ffmpeg] 3.3

(Later versions might work as well.)

You need to know [Elm] and web technology, and perhaps a little bit about Python
and ffmeg.

1.  `npm install`
2.  `npm start`

Magic GET parameters:

* `?audio=audio.aac&video=video.mp4`: Pre-load audio and video so you don’t have
  to upload the files so often. Put `audio.aac` and `video.mp4` in the `build/`
  directory (you might need to create it first).
* `?warn_on_close=1`: Test [onbeforeunload].

Additional tasks:

* `yarn run elm-analyse` runs [elm-analyse].
* `yarn run elm-format` runs [elm-format]. `yarn run elm-forma -- --yes` to
  avoid the prompt.
* `yarn run eslint` runs [ESLint]. `yarn run eslint -- --fix` fixes most errors.
* `yarn run stylelint` runs [stylelint]. `yarn run stylelint -- --fix` fixes
  most errors.
* `yarn run fix` runs all format/lint tools in autofix mode.
* `yarn run build` makes a production build.

## License

[MIT](LICENSE)

[elm-analyse]: https://github.com/stil4m/elm-analyse
[elm-format]: https://github.com/avh4/elm-format
[elm]: http://elm-lang.org/
[eslint]: https://eslint.org/
[ffmpeg]: https://ffmpeg.org/
[node.js]: https://nodejs.org/en/
[onbeforeunload]: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload
[python]: https://www.python.org/
[stylelint]: https://stylelint.io/
