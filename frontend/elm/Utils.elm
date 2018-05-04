module Utils exposing (..)

import Time exposing (Time)


formatDuration : Time -> String
formatDuration duration =
    let
        ( hours, hoursRest ) =
            divRem duration Time.hour

        ( minutes, minutesRest ) =
            divRem hoursRest Time.minute

        ( seconds, secondsRest ) =
            divRem minutesRest Time.second

        ( milliseconds, _ ) =
            divRem secondsRest Time.millisecond

        pad number numChars =
            String.padLeft numChars '0' (toString number)
    in
    pad hours 2
        ++ ":"
        ++ pad minutes 2
        ++ ":"
        ++ pad seconds 2
        ++ "."
        ++ pad milliseconds 3


divRem : Float -> Float -> ( Int, Float )
divRem numerator divisor =
    let
        whole =
            truncate (numerator / divisor)

        rest =
            numerator - toFloat whole * divisor
    in
    ( whole, rest )


splitExtension : String -> ( String, String )
splitExtension filename =
    let
        separator =
            "."

        parts =
            filename |> String.split separator |> List.reverse
    in
    case parts of
        [] ->
            ( "", "" )

        [ base ] ->
            ( base, "" )

        extension :: rest ->
            ( String.join separator (List.reverse rest), extension )


truncateJsonDecodeErrorMessage : String -> String
truncateJsonDecodeErrorMessage message =
    let
        probe =
            " but instead got: "

        indexes =
            String.indexes probe message
    in
    case indexes of
        [] ->
            message

        index :: _ ->
            let
                split =
                    index + String.length probe

                start =
                    String.left split message

                end =
                    String.dropLeft split message
            in
            start ++ ellipsis 50 end


ellipsis : Int -> String -> String
ellipsis maxLength string =
    if String.length string > maxLength then
        String.left (maxLength - 1) string ++ "…"
    else
        string


precision : Int -> Float -> String
precision maxNumDecimals float =
    let
        string =
            toString float
    in
    case String.split "." string of
        [ before, after ] ->
            if String.length after > maxNumDecimals then
                -- This doesn’t round properly, but whatever.
                "~" ++ before ++ "." ++ String.left maxNumDecimals after
            else
                string

        _ ->
            string


humanList : String -> List String -> String
humanList joinWord strings =
    case List.reverse strings of
        [] ->
            ""

        [ string ] ->
            string

        last :: rest ->
            let
                start =
                    rest
                        |> List.reverse
                        |> String.join ", "
            in
            start ++ " " ++ joinWord ++ " " ++ last
