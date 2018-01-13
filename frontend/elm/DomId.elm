module DomId exposing (DomId(..), fromString, toString)


type DomId
    = IdVideoArea
    | IdControlsArea


toString : DomId -> String
toString =
    Basics.toString


fromString : String -> Result String DomId
fromString string =
    case string of
        "IdVideoArea" ->
            Ok IdVideoArea

        "IdControlsArea" ->
            Ok IdControlsArea

        _ ->
            Err <| "Unknown DOM ID: " ++ string
