module View exposing (view)

import Html exposing (Html, audio, button, div, p, text, video)
import Html.Attributes exposing (src, type_, width)
import Html.Events exposing (on, onClick)
import Json.Decode as Decode exposing (Decoder)
import Svg exposing (line, svg)
import Svg.Attributes exposing (stroke, viewBox, x1, x2, y1, y2)
import Time exposing (Time)
import Types exposing (..)


controlsHeight : Int
controlsHeight =
    -- px
    150


view : Model -> Html Msg
view model =
    let
        viewBoxString =
            [ 0, 0, model.windowSize.width, 200 ]
                |> List.map toString
                |> String.join " "

        aspectRatio =
            model.videoSize.width / model.videoSize.height

        maxWidth =
            toFloat model.windowSize.width

        maxHeight =
            toFloat (model.windowSize.height - controlsHeight)

        heightIfMaxWidth =
            maxWidth / aspectRatio

        clampedWidth =
            if heightIfMaxWidth <= maxHeight then
                maxWidth
            else
                maxHeight * aspectRatio

        finalWidth =
            min model.videoSize.width clampedWidth
    in
    div []
        [ video
            [ src "/sommaren_video.mp4"
            , width (truncate finalWidth)
            , on "loadedmetadata" (decodeVideoMetaData VideoMetaData)
            ]
            []
        , audio
            [ src "/sommaren_audio.aac"
            , on "loadedmetadata" (decodeAudioMetaData AudioMetaData)
            ]
            []
        , p [] [ text ("Video duration: " ++ formatDuration model.videoDuration) ]
        , p [] [ text ("Audio duration: " ++ formatDuration model.audioDuration) ]
        , svg [ viewBox viewBoxString ]
            [ line [ x1 "0", y1 "10", x2 "200", y2 "10", stroke "black" ] []
            ]
        , div []
            [ button
                [ type_ "button"
                , onClick <|
                    if model.playing then
                        Pause
                    else
                        Play
                ]
                [ text <|
                    if model.playing then
                        "Pause"
                    else
                        "Play"
                ]
            ]
        ]


decodeVideoMetaData : (VideoMetaDataDetails -> msg) -> Decoder msg
decodeVideoMetaData msg =
    Decode.map3
        (\duration width height ->
            msg
                { duration = duration * Time.second
                , width = width
                , height = height
                }
        )
        (Decode.at [ "currentTarget", "duration" ] Decode.float)
        (Decode.at [ "currentTarget", "videoWidth" ] Decode.float)
        (Decode.at [ "currentTarget", "videoHeight" ] Decode.float)


decodeAudioMetaData : (AudioMetaDataDetails -> msg) -> Decoder msg
decodeAudioMetaData msg =
    Decode.at [ "currentTarget", "duration" ] Decode.float
        |> Decode.map
            (\duration ->
                msg
                    { duration = duration * Time.second
                    }
            )


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
