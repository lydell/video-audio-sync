module DomId exposing (DomId(..), encode, fromString, toHtml, toString)

import Html
import Html.Attributes
import Json.Encode as Encode


type DomId
    = VideoArea
    | GraphicsArea
    | Audio
    | Video


toString : DomId -> String
toString id =
    case id of
        VideoArea ->
            "VideoArea"

        GraphicsArea ->
            "GraphicsArea"

        -- Tip: This means you can use the `audio` variable in the console!
        Audio ->
            "audio"

        -- Tip: This means you can use the `video` variable in the console!
        Video ->
            "video"


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
