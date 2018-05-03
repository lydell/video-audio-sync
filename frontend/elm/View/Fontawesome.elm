module View.Fontawesome exposing (Icon(..), fontawesome)

import Html exposing (Html, span)
import Html.Attributes exposing (attribute, class)


type Icon
    = Icon String
    | CustomIcon String String


fontawesome : Icon -> Html msg
fontawesome icon =
    let
        ( namePart, extraClass ) =
            case icon of
                Icon name ->
                    ( name, "" )

                CustomIcon name extra ->
                    ( name, extra )
    in
    span
        [ attribute "aria-hidden" "true"
        , class ("fas fa-" ++ namePart ++ " " ++ extraClass)
        ]
        []
