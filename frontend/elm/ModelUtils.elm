module ModelUtils exposing (..)

import Data.Model exposing (LoopState(Looping, Normal), Model)
import Time exposing (Time)


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
