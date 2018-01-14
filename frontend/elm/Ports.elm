port module Ports exposing (Area, IncomingMessage(..), OutgoingMessage(..), send, subscribe)

import DomId exposing (DomId)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias TaggedData =
    { tag : String
    , data : Encode.Value
    }


type OutgoingMessage
    = MeasureArea DomId
    | MediaPlay DomId
    | MediaPause DomId
    | MediaSeek DomId Float


type IncomingMessage
    = AreaMeasurement DomId Area


type alias Area =
    { width : Float
    , height : Float
    , x : Float
    , y : Float
    }


encode : OutgoingMessage -> TaggedData
encode outgoingMessage =
    case outgoingMessage of
        MeasureArea id ->
            { tag = "MeasureArea", data = Encode.string (DomId.toString id) }

        MediaPlay id ->
            { tag = "MediaPlay", data = Encode.string (DomId.toString id) }

        MediaPause id ->
            { tag = "MediaPause", data = Encode.string (DomId.toString id) }

        MediaSeek id time ->
            { tag = "MediaSeek"
            , data =
                Encode.object
                    [ ( "id", Encode.string (DomId.toString id) )
                    , ( "time", Encode.float time )
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


areaMeasurementDecoder : Decoder IncomingMessage
areaMeasurementDecoder =
    Decode.map2 AreaMeasurement
        (Decode.field "id"
            (Decode.string |> Decode.andThen (DomId.fromString >> fromResult))
        )
        (Decode.field "area" areaDecoder)


areaDecoder : Decoder Area
areaDecoder =
    Decode.map4 Area
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)


fromResult : Result String a -> Decoder a
fromResult result =
    case result of
        Ok a ->
            Decode.succeed a

        Err message ->
            Decode.fail message
