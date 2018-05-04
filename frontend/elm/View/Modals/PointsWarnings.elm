module View.Modals.PointsWarnings exposing (view)

import Data.Point as Point exposing (Point)
import Html exposing (Html, li, p, strong, text, ul)
import Utils


view : List Point -> List (Html msg)
view points =
    let
        warnings =
            Point.validate points
    in
    [ p [] [ strong [] [ text "There are problems with your points." ] ]
    , p []
        [ text "The syncing program can handle slowing down audio down to "
        , strong []
            [ text <|
                toString Point.tempoMin
                    ++ " times"
            ]
        , text " or speeding up audio up to "
        , strong []
            [ text <|
                toString Point.tempoMax
                    ++ " times."
            ]
        ]
    , p [] [ text "The audio between some points would need to be slowed down or sped up more than that." ]
    , ul [] <|
        List.map (viewWarning >> li []) warnings
    ]


viewWarning : ( Int, Float ) -> List (Html msg)
viewWarning ( index, tempo ) =
    let
        start =
            if index == 0 then
                "From the start to point 1"
            else
                "Between point " ++ toString index ++ " and point " ++ toString (index + 1)
    in
    [ text <| start ++ ": "
    , strong []
        [ text <|
            Utils.precision 4 tempo
                ++ " times."
        ]
    ]
