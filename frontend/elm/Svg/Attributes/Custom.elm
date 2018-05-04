module Svg.Attributes.Custom exposing (points)

import Svg
import Svg.Attributes


points : List ( number, number ) -> Svg.Attribute msg
points coords =
    coords
        |> List.map (\( x, y ) -> toString x ++ "," ++ toString y)
        |> String.join " "
        |> Svg.Attributes.points
