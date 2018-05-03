module ModelUtils exposing (..)

import Time exposing (Time)
import Types exposing (..)


getCurrentTimes : Model -> ( Time, Time )
getCurrentTimes model =
    case model.loopState of
        Normal ->
            ( model.audio.currentTime
            , model.video.currentTime
            )

        Looping { audioTime, videoTime } ->
            ( audioTime
            , videoTime
            )
