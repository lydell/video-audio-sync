module DomId exposing (DomId(..), fromString, toHtml, encode, toString)

import Html
import Html.Attributes
import Json.Encode as Encode


type DomId
    = VideoArea
    | GraphicsArea
    | Video
    | Audio


toString : DomId -> String
toString id =
    case id of
        VideoArea ->
            "VideoArea"

        GraphicsArea ->
            "GraphicsArea"

        Video ->
            "video"

        Audio ->
            "audio"


toHtml : DomId -> Html.Attribute msg
toHtml id =
    Html.Attributes.id (toString id)


encode : DomId -> Encode.Value
encode id =
    Encode.string (toString id)


fromString : String -> Result String DomId
fromString string =
    case string of
        "VideoArea" ->
            Ok VideoArea

        "GraphicsArea" ->
            Ok GraphicsArea

        "video" ->
            Ok Video

        "audio" ->
            Ok Audio

        _ ->
            Err <| "Unknown DOM id: " ++ string
