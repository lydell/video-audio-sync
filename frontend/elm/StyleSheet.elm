module StyleSheet exposing (Styles(..), styleSheet)

import Color
import Style exposing (StyleSheet)
import Style.Color as Color
import Style.Font as Font


type Styles
    = Title
    | NoStyle


styleSheet : StyleSheet Styles variation
styleSheet =
    Style.styleSheet
        [ Style.style Title
            [ Color.text Color.darkGrey
            , Color.background Color.white
            , Font.size 16
            ]
        ]
