module Data.KeyboardShortcuts exposing (KeyboardShortcutState(..), KeyboardShortcuts, KeyboardShortcutsWithState, decoder, empty, encode, update)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Key =
    String


type alias KeyboardShortcuts =
    Dict Key String


type alias KeyboardShortcutsWithState =
    { keyboardShortcuts : KeyboardShortcuts
    , highlighted : List ( Key, KeyboardShortcutState )
    }


type KeyboardShortcutState
    = Regular
    | ToBeChanged
    | JustChanged


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


update : Key -> Key -> KeyboardShortcuts -> KeyboardShortcuts
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
