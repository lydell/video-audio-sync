module Data.KeyboardShortcuts exposing (KeyboardShortcuts, encodeKeyboardShortcuts, keyboardShortcutsDecoder, updateKeyboardShortcuts)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias KeyboardShortcuts =
    Dict String String


keyboardShortcutsDecoder : Decoder KeyboardShortcuts
keyboardShortcutsDecoder =
    Decode.dict Decode.string


encodeKeyboardShortcuts : KeyboardShortcuts -> Encode.Value
encodeKeyboardShortcuts =
    Dict.map (always Encode.string)
        >> Dict.toList
        >> Encode.object


updateKeyboardShortcuts : String -> String -> KeyboardShortcuts -> KeyboardShortcuts
updateKeyboardShortcuts firstKey secondKey keyboardShortcuts =
    let
        firstKeyShortcut =
            Dict.get firstKey keyboardShortcuts

        secondKeyShortcut =
            Dict.get secondKey keyboardShortcuts
    in
    keyboardShortcuts
        |> Dict.update firstKey (always secondKeyShortcut)
        |> Dict.update secondKey (always firstKeyShortcut)
