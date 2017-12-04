module View exposing (view)

import Element exposing (Element, column, el, empty, node, text)
import Element.Attributes exposing (attribute)
import Element.Events exposing (on)
import Json.Decode as Decode exposing (Decoder)
import StyleSheet exposing (Styles(..))
import Time exposing (Time)
import Types exposing (..)


view : Model -> Element Styles variation Msg
view model =
    column NoStyle
        []
        [ node "video"
            (el NoStyle
                [ attribute "src" "/sommaren_vid.mp4"
                , attribute "controls" "controls"
                , on "loadedmetadata" (decodeMediaMetaData VideoMetaData)
                ]
                empty
            )
        , node "audio"
            (el NoStyle
                [ attribute "src" "/sommaren.aac"
                , attribute "controls" "controls"
                , on "loadedmetadata" (decodeMediaMetaData AudioMetaData)
                ]
                empty
            )
        , el NoStyle [] (text ("Video duration: " ++ formatDuration model.videoDuration))
        , el NoStyle [] (text ("Audio duration: " ++ formatDuration model.audioDuration))
        ]


decodeMediaMetaData : (Time -> msg) -> Decoder msg
decodeMediaMetaData msg =
    Decode.at [ "currentTarget", "duration" ] Decode.float
        |> Decode.map msg


formatDuration : Time -> String
formatDuration duration =
    let
        hours =
            floor (duration / Time.hour)

        minutes =
            floor ((duration - toFloat hours) / Time.minute)

        seconds =
            floor ((duration - toFloat hours - toFloat minutes) / Time.second)

        milliseconds =
            floor ((duration - toFloat hours - toFloat minutes - toFloat seconds) / Time.millisecond)
    in
    pad hours 2 ++ ":" ++ pad minutes 2 ++ ":" ++ pad seconds 2 ++ "." ++ pad milliseconds 3


pad : Int -> Int -> String
pad number numChars =
    String.right numChars (String.repeat numChars "0" ++ toString number)
