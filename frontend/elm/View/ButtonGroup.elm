module View.ButtonGroup exposing (ButtonDetails, ButtonLabel(..), buttonGroup, emptyButton, formatKey)

import Buttons
import Data.KeyboardShortcuts as KeyboardShortcuts exposing (KeyboardShortcutState, KeyboardShortcutsWithState)
import Html exposing (Attribute, Html, button, div, span, text)
import Html.Attributes exposing (attribute, class, classList, id, title, type_)
import Html.Custom exposing (none)
import List.Extra
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


buttonGroup : KeyboardShortcutsWithState -> List (ButtonDetails msg) -> Html msg
buttonGroup { keyboardShortcuts, highlighted } buttons =
    div [ class "ButtonGroup" ]
        (List.map
            (\buttonDetails ->
                let
                    shortcutWithHighlight =
                        Buttons.shortcutsFromId buttonDetails.id keyboardShortcuts
                            |> List.head
                            |> Maybe.andThen
                                (\string ->
                                    List.Extra.find (Tuple.first >> (==) string) highlighted
                                        |> Maybe.withDefault ( string, KeyboardShortcuts.Regular )
                                        |> Just
                                )
                in
                buttonGroupButton shortcutWithHighlight buttonDetails
            )
            buttons
        )


buttonGroupButton : Maybe ( String, KeyboardShortcutState ) -> ButtonDetails msg -> Html msg
buttonGroupButton shortcut buttonDetails =
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
        , case shortcut of
            Just ( string, highlight ) ->
                span
                    [ classList
                        [ ( "ButtonGroup-keyboardShortcut", True )
                        , ( "is-toBeChanged", highlight == KeyboardShortcuts.ToBeChanged )
                        , ( "is-justChanged", highlight == KeyboardShortcuts.JustChanged )
                        ]
                    ]
                    [ text (formatKey string) ]

            Nothing ->
                none
        ]


formatKey : String -> String
formatKey key =
    if isLikelyShifted key then
        "⇧" ++ key
    else
        String.toUpper key


isLikelyShifted : String -> Bool
isLikelyShifted string =
    (String.toUpper string /= String.toLower string)
        && (String.toUpper string == string)
