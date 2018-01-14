module Html.Attributes.Custom exposing (muted)

import Html exposing (Attribute)
import Html.Attributes exposing (property)
import Json.Encode as Encode


muted : Bool -> Attribute msg
muted bool =
    property "muted" (Encode.bool bool)
