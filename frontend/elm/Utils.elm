module Utils exposing (..)

import Time exposing (Time)


type alias PartionedTime =
    { hours : Int
    , minutes : Int
    , seconds : Int
    , milliseconds : Int
    , rest : Float
    }


partitionTime : Time -> PartionedTime
partitionTime time =
    let
        ( hours, hoursRest ) =
            divRem time Time.hour

        ( minutes, minutesRest ) =
            divRem hoursRest Time.minute

        ( seconds, secondsRest ) =
            divRem minutesRest Time.second

        ( milliseconds, rest ) =
            divRem secondsRest Time.millisecond
    in
    { hours = hours
    , minutes = minutes
    , seconds = seconds
    , milliseconds = milliseconds
    , rest = rest
    }


formatDuration : Time -> String
formatDuration duration =
    let
        { hours, minutes, seconds, milliseconds } =
            partitionTime duration

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


formatTime : Time -> String
formatTime time =
    let
        { hours, minutes, seconds, milliseconds } =
            partitionTime time

        segments =
            [ ( hours, "hour" )
            , ( minutes, "minute" )
            , ( seconds, "second" )
            , ( milliseconds, "millisecond" )
            ]

        formatSegment ( quantity, name ) =
            toString quantity ++ " " ++ name ++ pluralize quantity
    in
    segments
        |> List.filter (\( quantity, _ ) -> quantity > 0)
        |> List.map formatSegment
        |> humanList "and"


pluralize : Int -> String
pluralize number =
    if number == 1 then
        ""
    else
        "s"


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
