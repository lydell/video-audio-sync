module View.Modal exposing (alertModal, confirmModal)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)


modal : msg -> List (Html msg) -> List (Html msg) -> Html msg
modal msg buttons children =
    div [ class "Modal" ]
        [ div [ class "Modal-backdrop", onClick msg ] []
        , div [ class "Modal-content" ]
            [ div [ class "Modal-contentInner" ] children
            , div [ class "Modal-buttons" ] buttons
            ]
        ]


modalButton : msg -> String -> Html msg
modalButton msg label =
    button [ type_ "button", class "Modal-button", onClick msg ]
        [ text label
        ]


alertModal : msg -> List (Html msg) -> Html msg
alertModal msg children =
    modal
        msg
        [ modalButton msg "Close"
        ]
        children


confirmModal :
    { cancel : ( msg, String ), confirm : ( msg, String ) }
    -> List (Html msg)
    -> Html msg
confirmModal { cancel, confirm } children =
    modal
        (Tuple.first cancel)
        [ uncurry modalButton cancel
        , uncurry modalButton confirm
        ]
        children
