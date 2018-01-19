module MediaPlayer exposing (MediaPlayer, PlayState(..), empty, pause, play, updateCurrentTime, updateMetaData)

import Html.Events.Custom exposing (MetaDataDetails)
import Time exposing (Time)


type alias MediaPlayer =
    { size : { width : Float, height : Float }
    , duration : Time
    , currentTime : Time
    , playState : PlayState
    }


type PlayState
    = Playing
    | Paused


empty : MediaPlayer
empty =
    { size = { width = 0, height = 0 }
    , duration = 0
    , currentTime = 0
    , playState = Paused
    }


updateMetaData : MetaDataDetails -> MediaPlayer -> MediaPlayer
updateMetaData { duration, width, height } mediaPlayer =
    { mediaPlayer
        | size = { width = width, height = height }
        , duration = duration
    }


updateCurrentTime : Time -> MediaPlayer -> MediaPlayer
updateCurrentTime currentTime mediaPlayer =
    { mediaPlayer | currentTime = clamp 0 mediaPlayer.duration currentTime }


play : MediaPlayer -> MediaPlayer
play mediaPlayer =
    { mediaPlayer | playState = Playing }


pause : MediaPlayer -> MediaPlayer
pause mediaPlayer =
    { mediaPlayer | playState = Paused }
