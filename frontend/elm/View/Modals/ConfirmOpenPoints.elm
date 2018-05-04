module View.Modals.ConfirmOpenPoints exposing (view)

import Html exposing (Html, code, p, strong, text)
import View.Modal as Modal


view : { cancel : msg, confirm : msg, name : String } -> Html msg
view { cancel, confirm, name } =
    Modal.confirm
        { cancel = ( cancel, "No, keep my current points!" )
        , confirm = ( confirm, "Yes, replace them!" )
        }
        [ p []
            [ text "This replaces all points you have added with the ones in "
            , code [] [ text name ]
            , text "."
            ]
        , p [] [ strong [] [ text "Are you sure?" ] ]
        ]
