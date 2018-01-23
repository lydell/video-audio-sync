module Utils exposing (..)

import List.Extra
import Time exposing (Time)
import Types exposing (..)


maxPointOffset : Time
maxPointOffset =
    0.05 * Time.second


formatDuration : Time -> String
formatDuration duration =
    let
        ( hours, hoursRest ) =
            divRem duration Time.hour

        ( minutes, minutesRest ) =
            divRem hoursRest Time.minute

        ( seconds, secondsRest ) =
            divRem minutesRest Time.second

        ( milliseconds, millisecondsRest ) =
            divRem secondsRest Time.millisecond

        pad number numChars =
            String.padLeft numChars '0' (toString number)
    in
    pad hours 2
        ++ ":"
        ++ pad minutes 2
        ++ ":"
        ++ pad seconds 2
        ++ "."
        ++ pad milliseconds 3


divRem : Float -> Float -> ( Int, Float )
divRem numerator divisor =
    let
        whole =
            truncate (numerator / divisor)

        rest =
            numerator - toFloat whole * divisor
    in
    ( whole, rest )


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


getSelectedPoint :
    { audioTime : Time, videoTime : Time }
    -> List Point
    -> Maybe Point
getSelectedPoint { audioTime, videoTime } points =
    points
        |> List.map
            (\point ->
                let
                    audioDistance =
                        abs (point.audioTime - audioTime)

                    videoDistance =
                        abs (point.videoTime - videoTime)
                in
                ( audioDistance, videoDistance, point )
            )
        |> List.filter
            (\( audioDistance, videoDistance, _ ) ->
                (audioDistance < maxPointOffset)
                    && (videoDistance < maxPointOffset)
            )
        |> List.Extra.minimumBy
            (\( audioDistance, videoDistance, _ ) ->
                audioDistance + videoDistance
            )
        |> Maybe.map (\( _, _, point ) -> point)


getClosestPoint :
    (Point -> Time)
    -> Direction
    -> Time
    -> List Point
    -> Maybe Point
getClosestPoint getTime direction time points =
    points
        |> List.map (\point -> ( getTime point - time, point ))
        |> List.filter
            (\( distance, _ ) ->
                case direction of
                    Forward ->
                        distance >= maxPointOffset

                    Backward ->
                        distance <= -maxPointOffset
            )
        |> List.Extra.minimumBy (Tuple.first >> abs)
        |> Maybe.map Tuple.second
