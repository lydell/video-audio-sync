module Buttons exposing (ButtonId(..), JumpAction, defaultKeyboardShortCuts, jumpActionsBackward, jumpActionsForward, shortcutsFromId, toString)

import Data.Point exposing (Direction(Backward, Forward))
import Dict
import Time exposing (Time)
import Types exposing (..)


type ButtonId
    = PlayPause MediaPlayerId
    | JumpByTime MediaPlayerId Direction Time
    | JumpByPoint MediaPlayerId Direction
    | OpenMedia MediaPlayerId
    | OpenPoints
    | OpenMultiple
    | Loop
    | AddRemovePoint
    | Warnings
    | Save
    | RemoveAll
    | ToggleShowKeyboardShortcuts
    | ToggleEditKeyboardShortcuts
    | HelpModal


type alias JumpAction =
    { timeOffset : Time
    , label : String
    , audioShortcut : String
    , videoShortcut : String
    }


toString : ButtonId -> String
toString id =
    id
        |> Basics.toString
        |> String.map
            (\char ->
                if char == ' ' then
                    '-'
                else
                    char
            )


jumpActionsForward : List JumpAction
jumpActionsForward =
    [ { timeOffset = 100 * Time.millisecond
      , label = "0.1s"
      , audioShortcut = "a"
      , videoShortcut = "q"
      }
    , { timeOffset = 1 * Time.second
      , label = "1s"
      , audioShortcut = "s"
      , videoShortcut = "w"
      }
    , { timeOffset = 1 * Time.minute
      , label = "1m"
      , audioShortcut = "d"
      , videoShortcut = "e"
      }
    , { timeOffset = 10 * Time.minute
      , label = "10m"
      , audioShortcut = "f"
      , videoShortcut = "r"
      }
    ]


jumpActionsBackward : List JumpAction
jumpActionsBackward =
    jumpActionsForward
        |> List.reverse
        |> List.map
            (\jumpAction ->
                { jumpAction | timeOffset = negate jumpAction.timeOffset }
            )


jumpShortcuts : (String -> String) -> List JumpAction -> List ( String, ButtonId )
jumpShortcuts transform jumpActions =
    jumpActions
        |> List.concatMap
            (\{ timeOffset, audioShortcut, videoShortcut } ->
                let
                    direction =
                        if timeOffset < 0 then
                            Backward
                        else
                            Forward
                in
                [ ( transform audioShortcut
                  , JumpByTime Audio direction timeOffset
                  )
                , ( transform videoShortcut
                  , JumpByTime Video direction timeOffset
                  )
                ]
            )


defaultKeyboardShortCuts : KeyboardShortcuts
defaultKeyboardShortCuts =
    [ ( "j", PlayPause Audio )
    , ( "u", PlayPause Video )
    , ( "g", JumpByPoint Audio Forward )
    , ( "G", JumpByPoint Audio Backward )
    , ( "t", JumpByPoint Video Forward )
    , ( "T", JumpByPoint Video Backward )
    , ( "h", OpenMedia Audio )
    , ( "y", OpenMedia Video )
    , ( "n", OpenPoints )
    , ( "b", OpenMultiple )
    , ( "m", Loop )
    , ( "k", AddRemovePoint )
    , ( "i", Warnings )
    , ( "o", Save )
    , ( "p", RemoveAll )
    , ( "z", ToggleShowKeyboardShortcuts )
    , ( "Z", ToggleEditKeyboardShortcuts )
    , ( "?", HelpModal )
    ]
        ++ jumpShortcuts identity jumpActionsForward
        ++ jumpShortcuts String.toUpper jumpActionsBackward
        |> Dict.fromList
        |> Dict.map (always toString)


shortcutsFromId : String -> KeyboardShortcuts -> List String
shortcutsFromId id shortcuts =
    shortcuts
        |> Dict.toList
        |> List.filter (Tuple.second >> (==) id)
        |> List.map Tuple.first
