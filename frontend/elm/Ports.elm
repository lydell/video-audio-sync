port module Ports exposing (IncomingMessage(..), OutgoingMessage(..), send, subscribe)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias TaggedData =
    { tag : String
    , data : Encode.Value
    }


type OutgoingMessage
    = TestOut String
    | JsVideoPlayState Bool
    | JsAudioPlayState Bool


type IncomingMessage
    = TestIn String


encode : OutgoingMessage -> TaggedData
encode outgoingMessage =
    case outgoingMessage of
        TestOut string ->
            { tag = "TestOut", data = Encode.string string }

        JsVideoPlayState playing ->
            { tag = "JsVideoPlayState", data = Encode.bool playing }

        JsAudioPlayState playing ->
            { tag = "JsAudioPlayState", data = Encode.bool playing }


decoder : String -> Result String (Decoder IncomingMessage)
decoder tag =
    case tag of
        "TestIn" ->
            Ok <| Decode.map TestIn Decode.string

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
