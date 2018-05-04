module Data.File exposing (ErroredFileDetails, File, FileType(..), InvalidFileDetails, OpenedFileAsTextDetails, OpenedFileAsUrlDetails, encodeFileType, erroredFileDecoder, fileTypeToHumanString, invalidFileDecoder, openedFileAsTextDecoder, openedFileAsUrlDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Custom
import Json.Encode as Encode


type alias File =
    { filename : String
    , content : String
    , mimeType : String
    }


type FileType
    = AudioFile
    | VideoFile
    | JsonFile


type alias OpenedFileAsTextDetails =
    { name : String
    , fileType : FileType
    , text : String
    }


type alias OpenedFileAsUrlDetails =
    { name : String
    , fileType : FileType
    , url : String
    }


type alias InvalidFileDetails =
    { name : String
    , expectedFileTypes : List FileType
    }


type alias ErroredFileDetails =
    { name : String
    , fileType : FileType
    }


openedFileAsTextDecoder : Decoder OpenedFileAsTextDetails
openedFileAsTextDecoder =
    Decode.map3 OpenedFileAsTextDetails
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)
        (Decode.field "content" Decode.string)


openedFileAsUrlDecoder : Decoder OpenedFileAsUrlDetails
openedFileAsUrlDecoder =
    Decode.map3 OpenedFileAsUrlDetails
        (Decode.field "name" Decode.string)
        (Decode.field "fileType" fileTypeDecoder)
        (Decode.field "url" Decode.string)


invalidFileDecoder : Decoder InvalidFileDetails
invalidFileDecoder =
    Decode.map2 InvalidFileDetails
        (Decode.field "name" Decode.string)
        (Decode.field "expectedFileTypes" (Decode.list fileTypeDecoder))


erroredFileDecoder : Decoder ErroredFileDetails
erroredFileDecoder =
    Decode.map2 ErroredFileDetails
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


encodeFileType : FileType -> Encode.Value
encodeFileType fileType =
    case fileType of
        AudioFile ->
            Encode.string "AudioFile"

        VideoFile ->
            Encode.string "VideoFile"

        JsonFile ->
            Encode.string "JsonFile"


fileTypeToHumanString : FileType -> String
fileTypeToHumanString fileType =
    case fileType of
        AudioFile ->
            "audio"

        VideoFile ->
            "video"

        JsonFile ->
            "JSON"
