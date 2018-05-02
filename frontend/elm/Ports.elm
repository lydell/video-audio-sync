port module Ports exposing (Area, ErroredFileDetails, File, FileType(..), IncomingMessage(..), InvalidFileDetails, OpenedFileDetails, OutgoingMessage(..), keyboardShortcutsDecoder, send, subscribe)

import Dict exposing (Dict)
import DomId exposing (DomId)
import Html.Events.Custom exposing (MouseButton(Left, Right))
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
    | SaveFile File
    | OpenFile FileType
    | OpenMultipleFiles
    | WarnOnClose (Maybe String)
    | ClickButton String MouseButton
    | PersistKeyboardShortcuts (Dict String String)


type IncomingMessage
    = AreaMeasurement DomId Area
    | OpenedFile OpenedFileDetails
    | InvalidFile InvalidFileDetails
    | ErroredFile ErroredFileDetails
    | DragEnter
    | DragLeave
    | Keydown KeydownDetails


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


type FileType
    = AudioFile
    | VideoFile
    | JsonFile


type alias OpenedFileDetails =
    { name : String
    , fileType : FileType
    , content : String
    }


type alias InvalidFileDetails =
    { name : String
    , expectedFileTypes : List FileType
    }


type alias ErroredFileDetails =
    { name : String
    , fileType : FileType
    }


type alias KeydownDetails =
    { key : String
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    , shiftKey : Bool
    , defaultPrevented : Bool
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
                    [ ( "fileType", Encode.string (toString fileType) )
                    ]
            }

        OpenMultipleFiles ->
            { tag = "OpenMultipleFiles"
            , data = Encode.null
            }

        WarnOnClose maybeMessage ->
            { tag = "WarnOnClose"
            , data =
                case maybeMessage of
                    Just message ->
                        Encode.string message

                    Nothing ->
                        Encode.null
            }

        ClickButton id mouseButton ->
            { tag = "ClickButton"
            , data =
                Encode.object
                    [ ( "id", Encode.string id )
                    , ( "right", encodeMouseButton mouseButton )
                    ]
            }

        PersistKeyboardShortcuts keyboardShortcuts ->
            { tag = "PersistKeyboardShortcuts"
            , data =
                keyboardShortcuts
                    |> Dict.map (always Encode.string)
                    |> Dict.toList
                    |> Encode.object
            }


decoder : String -> Result String (Decoder IncomingMessage)
decoder tag =
    case tag of
        "AreaMeasurement" ->
            Ok areaMeasurementDecoder

        "OpenedFile" ->
            Ok openedFileDecoder

        "InvalidFile" ->
            Ok invalidFileDecoder

        "ErroredFile" ->
            Ok erroredFileDecoder

        "DragEnter" ->
            Ok <| Decode.succeed DragEnter

        "DragLeave" ->
            Ok <| Decode.succeed DragLeave

        "Keydown" ->
            Ok <| keydownDecoder

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


areaDecoder : Decoder Area
areaDecoder =
    Decode.map4 Area
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)


openedFileDecoder : Decoder IncomingMessage
openedFileDecoder =
    Decode.map3 OpenedFileDetails
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)
        (Decode.field "content" Decode.string)
        |> Decode.map OpenedFile


invalidFileDecoder : Decoder IncomingMessage
invalidFileDecoder =
    Decode.map2 InvalidFileDetails
        (Decode.field "name" Decode.string)
        (Decode.field "expectedFileTypes" (Decode.list fileTypeDecoder))
        |> Decode.map InvalidFile


erroredFileDecoder : Decoder IncomingMessage
erroredFileDecoder =
    Decode.map2 ErroredFileDetails
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)
        |> Decode.map ErroredFile


fileTypeDecoder : Decoder FileType
fileTypeDecoder =
    Decode.string
        |> Decode.andThen (stringToFileType >> Json.Decode.Custom.fromResult)


stringToFileType : String -> Result String FileType
stringToFileType string =
    case string of
        "AudioFile" ->
            Ok AudioFile

        "VideoFile" ->
            Ok VideoFile

        "JsonFile" ->
            Ok JsonFile

        _ ->
            Err ("Unknown fileType: " ++ string)


keydownDecoder : Decoder IncomingMessage
keydownDecoder =
    Decode.map6 KeydownDetails
        (Decode.field "key" Decode.string)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "defaultPrevented" Decode.bool)
        |> Decode.map Keydown


keyboardShortcutsDecoder : Decoder (Maybe (Dict String String))
keyboardShortcutsDecoder =
    Decode.nullable (Decode.dict Decode.string)
