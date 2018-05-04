# Video Audio Sync [![Build Status][travis-badge]][travis-link]

_Work in progress._

Fix videos where the audio is out of sync, in much stranger ways than just a
simple constant time shift.

## Background

I transferred some old VHS cassettes to my computer using a video capture tool.
The results were good, except that the audio was out-of-sync.

The audio tracks of the videos were longer than the video tracks. But speeding
the audio up to match in length didn’t help. (The videos are so long that you
can’t hear the speed difference.) The audio was still not in sync. It turned out
that the amount of time the audio was off differed throughout the video. We’re
talking everything from a couple of seconds up to one and a half minutes, with
no predictable pattern.

Instead of speeding up the entire audio track, different segments of it needs to
be sped up differently. I couldn’t find a tool that could do that in a somewhat
automated fashion, so I built one myself (using technology I know and enjoy).

## Requirements:

* [Chrome]
* [Python] 3.5
* [ffmpeg] 3.3

Later versions might work as well.

### Browser support

I noticed that [Firefox] does not report the correct length of the audio.
[Chrome] \(and [Chromium]) does, however. The app _should_ work in any modern
browser, but be aware that browsers may interpret media files differently. Also,
I haven’t really tested anything other than Firefox and Chrome.

## Usage

1.  Run `python3 extract.py summer94.mp4 aac` to separate the video and audio of
    `summer94.mp4` their own files (assuming `aac` is the audio format).
2.  Open the separated video and audio files in the [browser-based sync
    tool][app].
3.  Find matching points of video and audio using the tool and download the
    resulting points file.
4.  Run `python3 sync.py summer94_video.mp4 summer94_audio.aac points.json` to
    speed up and slow down segments of `summer94_audio.aac` according to
    `points.json` and then produce a single file again.

## Development

For the frontend you’ll need [Node.js] 8 (or possibly later) and some knowledge
about [Elm] and web technology.

1.  `npm install`
2.  `npm run elm-install`
3.  `npm start`

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
* `yarn run test` is run by [Travis CI].

## License

[MIT](LICENSE)

[app]: https://lydell.github.io/video-audio-sync/
[chrome]: https://www.google.com/chrome/index.html
[chromium]: https://www.chromium.org/
[elm-analyse]: https://github.com/stil4m/elm-analyse
[elm-format]: https://github.com/avh4/elm-format
[elm]: http://elm-lang.org/
[eslint]: https://eslint.org/
[ffmpeg]: https://ffmpeg.org/
[firefox]: https://www.mozilla.org/firefox/
[node.js]: https://nodejs.org/en/
[onbeforeunload]: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload
[python]: https://www.python.org/
[stylelint]: https://stylelint.io/
[travis ci]: https://travis-ci.org/
[travis-badge]: https://travis-ci.org/lydell/video-audio-sync.svg?branch=master
[travis-link]: https://travis-ci.org/lydell/video-audio-sync
