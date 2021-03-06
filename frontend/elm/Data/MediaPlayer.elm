module Data.MediaPlayer exposing (MediaPlayer, PlayState(..), empty, hasMedia, pause, play, updateCurrentTime, updateMetaData)

import Html.Events.Custom exposing (MetaDataDetails)
import Time exposing (Time)


type alias MediaPlayer =
    { size :
        { width : Float
        , height : Float
        }
    , duration : Time
    , currentTime : Time
    , playState : PlayState
    , name : String
    , url : Maybe String
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
    , name = ""
    , url = Nothing
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


hasMedia : MediaPlayer -> Bool
hasMedia mediaPlayer =
    case mediaPlayer.url of
        Just _ ->
            True

        Nothing ->
            False
