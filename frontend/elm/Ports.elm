port module Ports exposing (IncomingMessage(..), OutgoingMessage(..), keyboardShortcutsDecoder, send, subscribe)

import Data.Area exposing (Area, areaDecoder)
import Data.File exposing (ErroredFileDetails, File, FileType(..), InvalidFileDetails, OpenedFileDetails, encodeFileType, erroredFileDecoder, invalidFileDecoder, openedFileDecoder)
import Dict exposing (Dict)
import DomId exposing (DomId)
import Html.Events.Custom exposing (MouseButton(Left, Right))
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Custom
import Json.Encode as Encode
import Time exposing (Time)


port elmToJs : TaggedData -> Cmd msg


port jsToElm : (TaggedData -> msg) -> Sub msg


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
    | SaveFile File
    | OpenFile FileType
    | OpenMultipleFiles
    | ClickButton String MouseButton
    | StateSync StateSyncModel


type IncomingMessage
    = AreaMeasurement DomId Area
    | OpenedFile OpenedFileDetails
    | InvalidFile InvalidFileDetails
    | ErroredFile ErroredFileDetails
    | DragEnter
    | DragLeave
    | Keydown KeydownDetails


type alias KeydownDetails =
    { key : String
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    , shiftKey : Bool
    }


type alias StateSyncModel =
    { keyboardShortcuts : Dict String String
    , editingKeyboardShortcuts : Bool
    , warnOnClose : Maybe String
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

        SaveFile { filename, content, mimeType } ->
            { tag = "SaveFile"
            , data =
                Encode.object
                    [ ( "filename", Encode.string filename )
                    , ( "content", Encode.string content )
                    , ( "mimeType", Encode.string mimeType )
                    ]
            }

        OpenFile fileType ->
            { tag = "OpenFile"
            , data =
                Encode.object
                    [ ( "fileType", encodeFileType fileType )
                    ]
            }

        OpenMultipleFiles ->
            { tag = "OpenMultipleFiles"
            , data = Encode.null
            }

        ClickButton id mouseButton ->
            { tag = "ClickButton"
            , data =
                Encode.object
                    [ ( "id", Encode.string id )
                    , ( "right", encodeMouseButton mouseButton )
                    ]
            }

        StateSync model ->
            { tag = "StateSync"
            , data =
                Encode.object
                    [ ( "keyboardShortcuts"
                      , model.keyboardShortcuts
                            |> Dict.map (always Encode.string)
                            |> Dict.toList
                            |> Encode.object
                      )
                    , ( "editingKeyboardShortcuts"
                      , Encode.bool model.editingKeyboardShortcuts
                      )
                    , ( "warnOnClose"
                      , case model.warnOnClose of
                            Just message ->
                                Encode.string message

                            Nothing ->
                                Encode.null
                      )
                    ]
            }


decoder : String -> Result String (Decoder IncomingMessage)
decoder tag =
    case tag of
        "AreaMeasurement" ->
            Ok areaMeasurementDecoder

        "OpenedFile" ->
            openedFileDecoder
                |> Decode.map OpenedFile
                |> Ok

        "InvalidFile" ->
            invalidFileDecoder
                |> Decode.map InvalidFile
                |> Ok

        "ErroredFile" ->
            erroredFileDecoder
                |> Decode.map ErroredFile
                |> Ok

        "DragEnter" ->
            Decode.succeed DragEnter
                |> Ok

        "DragLeave" ->
            Decode.succeed DragLeave
                |> Ok

        "Keydown" ->
            keydownDecoder
                |> Ok

        _ ->
            Err ("Unknown message tag: " ++ tag)


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


encodeLoopMedia : DomId -> Time -> Encode.Value
encodeLoopMedia id time =
    Encode.object
        [ ( "id", DomId.encode id )
        , ( "time", Encode.float time )
        ]


encodeMouseButton : MouseButton -> Encode.Value
encodeMouseButton mouseButton =
    let
        right =
            case mouseButton of
                Left ->
                    False

                Right ->
                    True
    in
    Encode.bool right


areaMeasurementDecoder : Decoder IncomingMessage
areaMeasurementDecoder =
    Decode.map2 AreaMeasurement
        (Decode.field "id" domIdDecoder)
        (Decode.field "area" areaDecoder)


domIdDecoder : Decoder DomId
domIdDecoder =
    Decode.string
        |> Decode.andThen
            (DomId.fromString >> Json.Decode.Custom.fromResult)


keydownDecoder : Decoder IncomingMessage
keydownDecoder =
    Decode.map5 KeydownDetails
        (Decode.field "key" Decode.string)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        |> Decode.map Keydown


keyboardShortcutsDecoder : Decoder (Maybe (Dict String String))
keyboardShortcutsDecoder =
    Decode.nullable (Decode.dict Decode.string)
