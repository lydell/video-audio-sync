module View exposing (view)

import Html exposing (Html, audio, div, p, text, video)
import Html.Attributes exposing (controls, src)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder)
import Time exposing (Time)
import Types exposing (..)


view : Model -> Html Msg
view model =
    div []
        [ video
            [ src "/sommaren_video.mp4"
            , controls True
            , on "loadedmetadata" (decodeMediaMetaData VideoMetaData)
            ]
            []
        , audio
            [ src "/sommaren_audio.aac"
            , controls True
            , on "loadedmetadata" (decodeMediaMetaData AudioMetaData)
            ]
            []
        , p [] [ text ("Video duration: " ++ formatDuration model.videoDuration) ]
        , p [] [ text ("Audio duration: " ++ formatDuration model.audioDuration) ]
        ]


decodeMediaMetaData : (Time -> msg) -> Decoder msg
decodeMediaMetaData msg =
    Decode.at [ "currentTarget", "duration" ] Decode.float
        |> Decode.map ((*) Time.second >> msg)


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
    in
    pad hours 2 ++ ":" ++ pad minutes 2 ++ ":" ++ pad seconds 2 ++ "." ++ pad milliseconds 3


divRem : Float -> Float -> ( Int, Float )
divRem numerator divisor =
    let
        whole =
            truncate (numerator / divisor)

        rest =
            numerator - toFloat whole * divisor
    in
    ( whole, rest )


pad : Int -> Int -> String
pad number numChars =
    String.right numChars (String.repeat numChars "0" ++ toString number)
