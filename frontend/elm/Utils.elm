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


canAddPoint : List Point -> Point -> Bool
canAddPoint points potentialNewPoint =
    let
        hasSelected getTime =
            List.any
                (\point ->
                    let
                        distance =
                            abs (getTime point - getTime potentialNewPoint)
                    in
                    distance <= maxPointOffset
                )
                points

        countBefore getTime =
            points
                |> List.filter
                    (\point -> getTime point < getTime potentialNewPoint)
                |> List.length
    in
    (potentialNewPoint.audioTime > 0)
        && (potentialNewPoint.videoTime > 0)
        && not (hasSelected .audioTime)
        && not (hasSelected .videoTime)
        && (countBefore .audioTime == countBefore .videoTime)


splitExtension : String -> ( String, String )
splitExtension filename =
    let
        separator =
            "."

        parts =
            filename |> String.split separator |> List.reverse
    in
    case parts of
        [] ->
            ( "", "" )

        [ base ] ->
            ( base, "" )

        extension :: rest ->
            ( String.join separator (List.reverse rest), extension )


truncateJsonDecodeErrorMessage : String -> String
truncateJsonDecodeErrorMessage message =
    let
        probe =
            " but instead got: "

        indexes =
            String.indexes probe message
    in
    case indexes of
        [] ->
            message

        index :: _ ->
            let
                split =
                    index + String.length probe

                start =
                    String.left split message

                end =
                    String.dropLeft split message
            in
            start ++ ellipsis 50 end


ellipsis : Int -> String -> String
ellipsis maxLength string =
    if String.length string > maxLength then
        String.left (maxLength - 1) string ++ "…"
    else
        string


precision : Int -> Float -> String
precision maxNumDecimals float =
    let
        string =
            toString float
    in
    case String.split "." string of
        [ before, after ] ->
            if String.length after > maxNumDecimals then
                -- This doesn’t round properly, but whatever.
                "~" ++ before ++ "." ++ String.left maxNumDecimals after
            else
                string

        _ ->
            string
