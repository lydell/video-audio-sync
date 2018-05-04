module Data.DomId exposing (DomId(..), decoder, encode, toHtml)

import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Custom
import Json.Encode as Encode


type DomId
    = VideoArea
    | GraphicsArea
    | Audio
    | Video


toHtml : DomId -> Html.Attribute msg
toHtml id =
    Html.Attributes.id (toString id)


decoder : Decoder DomId
decoder =
    Decode.string
        |> Decode.andThen
            (fromString >> Json.Decode.Custom.fromResult)


encode : DomId -> Encode.Value
encode id =
    Encode.string (toString id)


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
