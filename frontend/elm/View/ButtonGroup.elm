module View.ButtonGroup exposing (ButtonDetails, ButtonLabel(..), buttonGroup, emptyButton)

import Html exposing (Attribute, Html, button, div, label, span, text)
import Html.Attributes exposing (attribute, class, classList, id, title, type_)
import Html.Custom exposing (none)
import View.Fontawesome exposing (Icon(Icon), fontawesome)


type alias ButtonDetails msg =
    { id : String
    , icon : Icon
    , title : String
    , label : ButtonLabel
    , badge : Maybe String
    , pressed : Bool
    , attributes : List (Attribute msg)
    }


type ButtonLabel
    = NoLabel
    | LeftLabel String
    | RightLabel String


emptyButton : ButtonDetails msg
emptyButton =
    { id = ""
    , icon = Icon ""
    , title = ""
    , label = NoLabel
    , badge = Nothing
    , pressed = False
    , attributes = []
    }


buttonGroup : List (ButtonDetails msg) -> Html msg
buttonGroup buttons =
    div [ class "ButtonGroup" ] (List.map buttonGroupButton buttons)


buttonGroupButton : ButtonDetails msg -> Html msg
buttonGroupButton buttonDetails =
    let
        label labelText =
            span
                [ attribute "aria-hidden" "true"
                , class "ButtonGroup-buttonLabel"
                ]
                [ text labelText ]

        icon =
            fontawesome buttonDetails.icon
    in
    button
        ([ type_ "button"
         , id buttonDetails.id
         , title buttonDetails.title
         , classList
            [ ( "ButtonGroup-button", True )
            , ( "is-pressed", buttonDetails.pressed )
            ]
         ]
            ++ buttonDetails.attributes
        )
        [ div [ class "ButtonGroup-buttonInner" ] <|
            case buttonDetails.label of
                NoLabel ->
                    [ icon ]

                LeftLabel labelText ->
                    [ label labelText, icon ]

                RightLabel labelText ->
                    [ icon, label labelText ]
        , case buttonDetails.badge of
            Just badgeText ->
                span [ class "ButtonGroup-buttonBadge" ] [ text badgeText ]

            Nothing ->
                none
        ]
