module View.Modals.ConfirmRemoveAllPoints exposing (view)

import Html exposing (Html, p, strong, text)
import View.Modal as Modal


view : { cancel : msg, confirm : msg } -> Html msg
view { cancel, confirm } =
    Modal.confirm
        { cancel = ( cancel, "No, keep them!" )
        , confirm = ( confirm, "Yes, remove them!" )
        }
        [ p [] [ text "This removes all points you have added." ]
        , p [] [ strong [] [ text "Are you sure?" ] ]
        ]
