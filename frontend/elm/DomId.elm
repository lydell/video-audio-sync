module DomId exposing (DomId(..), fromString, toString)


type DomId
    = VideoArea
    | ControlsArea
    | Video
    | Audio


toString : DomId -> String
toString id =
    case id of
        VideoArea ->
            "VideoArea"

        ControlsArea ->
            "ControlsArea"

        Video ->
            "video"

        Audio ->
            "audio"


fromString : String -> Result String DomId
fromString string =
    case string of
        "VideoArea" ->
            Ok VideoArea

        "ControlsArea" ->
            Ok ControlsArea

        "video" ->
            Ok Video

        "audio" ->
            Ok Audio

        _ ->
            Err <| "Unknown DOM id: " ++ string
