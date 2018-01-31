port module Ports exposing (Area, File, FileType(..), IncomingMessage(..), OutgoingMessage(..), send, subscribe)

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
    | SaveFile File
    | OpenFile FileType
    | OpenMultipleFiles


type IncomingMessage
    = AreaMeasurement DomId Area
    | OpenedFile { name : String, fileType : FileType, content : String }
    | InvalidFile { name : String, expectedFileTypes : List FileType }
    | ErroredFile { name : String, fileType : FileType }
    | DragEnter
    | DragLeave


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
            { tag = "Save"
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
    Decode.map3
        (\name fileType content ->
            OpenedFile
                { name = name
                , fileType = fileType
                , content = content
                }
        )
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)
        (Decode.field "content" Decode.string)


invalidFileDecoder : Decoder IncomingMessage
invalidFileDecoder =
    Decode.map2
        (\name expectedFileTypes ->
            InvalidFile
                { name = name
                , expectedFileTypes = expectedFileTypes
                }
        )
        (Decode.field "name" Decode.string)
        (Decode.field "expectedFileTypes" (Decode.list fileTypeDecoder))


erroredFileDecoder : Decoder IncomingMessage
erroredFileDecoder =
    Decode.map2
        (\name fileType ->
            ErroredFile
                { name = name
                , fileType = fileType
                }
        )
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)


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
