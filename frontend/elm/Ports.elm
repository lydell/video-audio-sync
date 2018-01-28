port module Ports exposing (Area, File, IncomingMessage(..), OutgoingMessage(..), send, subscribe)

import DomId exposing (DomId)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Custom
import Json.Encode as Encode
import Time exposing (Time)


type alias TaggedData =
    { tag : String
    , data : Encode.Value
    }


type OutgoingMessage
    = MeasureArea DomId
    | Play DomId
    | Pause DomId
    | Seek DomId Time
    | RestartLoop { audioTime : Time, videoTime : Time }
    | Save File


type IncomingMessage
    = AreaMeasurement DomId Area


type alias Area =
    { width : Float
    , height : Float
    , x : Float
    , y : Float
    }


type alias File =
    { filename : String
    , content : String
    , mimeType : String
    }


encode : OutgoingMessage -> TaggedData
encode outgoingMessage =
    case outgoingMessage of
        MeasureArea id ->
            { tag = "MeasureArea", data = DomId.encode id }

        Play id ->
            { tag = "Play", data = DomId.encode id }

        Pause id ->
            { tag = "Pause", data = DomId.encode id }

        Seek id time ->
            { tag = "Seek"
            , data =
                Encode.object
                    [ ( "id", DomId.encode id )
                    , ( "time", Encode.float time )
                    ]
            }

        RestartLoop { audioTime, videoTime } ->
            { tag = "RestartLoop"
            , data =
                Encode.object
                    [ ( "audio", encodeLoopMedia DomId.Audio audioTime )
                    , ( "video", encodeLoopMedia DomId.Video videoTime )
                    ]
            }

        Save { filename, content, mimeType } ->
            { tag = "Save"
            , data =
                Encode.object
                    [ ( "filename", Encode.string filename )
                    , ( "content", Encode.string content )
                    , ( "mimeType", Encode.string mimeType )
                    ]
            }


decoder : String -> Result String (Decoder IncomingMessage)
decoder tag =
    case tag of
        "AreaMeasurement" ->
            Ok <| areaMeasurementDecoder

        _ ->
            Err <| "Unknown message tag: " ++ tag


send : OutgoingMessage -> Cmd msg
send =
    encode >> elmToJs


subscribe : (Result String IncomingMessage -> msg) -> Sub msg
subscribe tagger =
    jsToElm <|
        \{ tag, data } ->
            decoder tag
                |> Result.andThen (flip Decode.decodeValue data)
                |> tagger


port elmToJs : TaggedData -> Cmd msg


port jsToElm : (TaggedData -> msg) -> Sub msg


encodeLoopMedia : DomId -> Time -> Encode.Value
encodeLoopMedia id time =
    Encode.object
        [ ( "id", DomId.encode id )
        , ( "time", Encode.float time )
        ]


areaMeasurementDecoder : Decoder IncomingMessage
areaMeasurementDecoder =
    Decode.map2 AreaMeasurement
        (Decode.field "id"
            (Decode.string
                |> Decode.andThen
                    (DomId.fromString >> Json.Decode.Custom.fromResult)
            )
        )
        (Decode.field "area" areaDecoder)


areaDecoder : Decoder Area
areaDecoder =
    Decode.map4 Area
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
