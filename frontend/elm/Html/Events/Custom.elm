module Html.Events.Custom exposing (MetaDataDetails, onAudioMetaData, onMouseDown, onTimeUpdate, onVideoMetaData, preventContextMenu)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)
import Html.Events exposing (on, onWithOptions)
import Json.Decode as Decode exposing (Decoder)
import Mouse
import Time exposing (Time)


type alias MetaDataDetails =
    { duration : Time
    , width : Float
    , height : Float
    }


onMouseDown : (Mouse.Position -> msg) -> Attribute msg
onMouseDown msg =
    onWithOptions
        "mousedown"
        { stopPropagation = False, preventDefault = True }
        (decodeMousePosition |> Decode.map msg)


decodeMousePosition : Decoder Mouse.Position
decodeMousePosition =
    Decode.map2 Mouse.Position
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)


preventContextMenu : Attribute msg
preventContextMenu =
    attribute "oncontextmenu" "return false"


onAudioMetaData : (MetaDataDetails -> msg) -> Attribute msg
onAudioMetaData msg =
    on "loadedmetadata" (decodeAudioMetaData |> Decode.map msg)


onVideoMetaData : (MetaDataDetails -> msg) -> Attribute msg
onVideoMetaData msg =
    on "loadedmetadata" (decodeVideoMetaData |> Decode.map msg)


onTimeUpdate : (Time -> msg) -> Attribute msg
onTimeUpdate msg =
    on "timeupdate" (decodeCurrentTime |> Decode.map msg)


secondsToMilliseconds : Decoder Time -> Decoder Time
secondsToMilliseconds =
    Decode.map ((*) Time.second)


decodeDuration : Decoder Time
decodeDuration =
    Decode.at [ "currentTarget", "duration" ] Decode.float
        |> secondsToMilliseconds


decodeAudioMetaData : Decoder MetaDataDetails
decodeAudioMetaData =
    decodeDuration
        |> Decode.map
            (\duration ->
                { duration = duration
                , width = 0
                , height = 0
                }
            )


decodeVideoMetaData : Decoder MetaDataDetails
decodeVideoMetaData =
    Decode.map3
        (\duration width height ->
            { duration = duration
            , width = width
            , height = height
            }
        )
        decodeDuration
        (Decode.at [ "currentTarget", "videoWidth" ] Decode.float)
        (Decode.at [ "currentTarget", "videoHeight" ] Decode.float)


decodeCurrentTime : Decoder Time
decodeCurrentTime =
    Decode.at [ "currentTarget", "currentTime" ] Decode.float
        |> secondsToMilliseconds
