module Data.KeyboardShortcuts exposing (KeyboardShortcuts, decoder, empty, encode, update)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias KeyboardShortcuts =
    Dict String String


empty : KeyboardShortcuts
empty =
    Dict.empty


decoder : Decoder KeyboardShortcuts
decoder =
    Decode.dict Decode.string


encode : KeyboardShortcuts -> Encode.Value
encode =
    Dict.map (always Encode.string)
        >> Dict.toList
        >> Encode.object


update : String -> String -> KeyboardShortcuts -> KeyboardShortcuts
update firstKey secondKey keyboardShortcuts =
    let
        firstKeyShortcut =
            Dict.get firstKey keyboardShortcuts

        secondKeyShortcut =
            Dict.get secondKey keyboardShortcuts
    in
    keyboardShortcuts
        |> Dict.update firstKey (always secondKeyShortcut)
        |> Dict.update secondKey (always firstKeyShortcut)
