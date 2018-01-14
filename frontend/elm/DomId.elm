module DomId exposing (DomId(..), fromString, toString)


type DomId
    = IdVideoArea
    | IdControlsArea
    | IdVideo
    | IdAudio


toString : DomId -> String
toString id =
    case id of
        IdVideoArea ->
            "VideoArea"

        IdControlsArea ->
            "ControlsArea"

        IdVideo ->
            "video"

        IdAudio ->
            "audio"


fromString : String -> Result String DomId
fromString string =
    case string of
        "VideoArea" ->
            Ok IdVideoArea

        "ControlsArea" ->
            Ok IdControlsArea

        "video" ->
            Ok IdVideo

        "audio" ->
            Ok IdAudio

        _ ->
            Err <| "Unknown DOM id: " ++ string
