module View.Modals.Help exposing (view)

import Html exposing (Html, a, h1, li, p, span, strong, text, ul)
import Html.Attributes exposing (class, href)
import ModelUtils
import Utils
import View.Icons as Icons
import View.Modal as Modal


view : msg -> Html msg
view msg =
    Modal.alert msg content


loopRadius : String
loopRadius =
    Utils.formatTime ModelUtils.loopRadius


content : List (Html msg)
content =
    [ h1 [] [ text "Video Audio Sync" ]
    , p []
        [ text "Fix videos where the audio is out of sync, in much stranger ways than just a simple constant time shift."
        ]
    , p []
        [ text "This tool lets you find points where the video and audio match, and save those points. Another tool then uses those points to speed up or slow down segments of the audio so that it syncs up with the video."
        ]
    , p []
        [ text "To learn more, see the "
        , projectLink "#video-audio-sync-" [ text "project page." ]
        ]
    , p []
        [ strong [] [ text "Note: " ]
        , text "This currently "
        , projectLink "#browser-support" [ text "works best in Chrome." ]
        ]
    , p []
        [ text "Open the "
        , projectLink "#usage" [ text "separated" ]
        , text " "
        , icon Icons.film
        , text " video and "
        , icon Icons.volume2
        , text " audio files."
        ]
    , p []
        [ text "Use the "
        , icon Icons.play
        , text " "
        , icon Icons.rewind
        , text " "
        , icon Icons.fastForward
        , text " Playback buttons to find a spot where you’d like to sync the video and audio."
        ]
    , p []
        [ strong [] [ text "Tip: " ]
        , text "Right-click a button to make it control both audio and video at the same time. If you use the "
        , icon Icons.command
        , text " keyboard: Hold Control, Command or Alt while pressing a keyboard shortcut."
        ]
    , p []
        [ text "Good syncing spots include:"
        ]
    , ul []
        [ li [] [ text "Somebody making a distinct noise, such as closing a door." ]
        , li [] [ text "Scene transitions, especially when going from indoors to outdoors." ]
        , li [] [ text "Closeups of people talking." ]
        ]
    , p []
        [ text "When you’ve found a good spot, "
        , icon Icons.pause
        , text " pause the video and find roughly the corresponding audio spot."
        ]
    , p []
        [ text "Now press the "
        , icon Icons.repeat
        , text <| " Loop button. It will loop around your spot, from " ++ loopRadius ++ " before to " ++ loopRadius ++ " after."
        ]
    , p []
        [ text "While looping, tweak the video and audio positions using the more fine-grained time controls, until the audio and video are in sync in that little segment."
        ]
    , p []
        [ text "When satisfied, press the "
        , icon Icons.plus
        , text " Plus button to save the point."
        ]
    , p []
        [ text "Then repeat for as many points you want. Use the "
        , icon Icons.skipBack
        , text " "
        , icon Icons.skipForward
        , text " Jump buttons to go back to earlier points if you made a mistake. Points can be "
        , icon Icons.minus
        , text " removed and "
        , icon Icons.plus
        , text " replaced with new ones."
        ]
    , p []
        [ text "Finally, click the "
        , icon Icons.save
        , text " Save button to save your points to a file. You can also "
        , icon Icons.fileText
        , text " open previous files you’ve made if you want to tweak them."
        ]
    , p []
        [ text "Once you’ve got the points file, "
        , projectLink "#usage" [ text "sync the audio and video back up" ]
        , text " into one file."
        ]
    ]


icon : Html msg -> Html msg
icon iconHtml =
    span [ class "HelpButton" ] [ iconHtml ]


projectLink : String -> List (Html msg) -> Html msg
projectLink hash children =
    a [ href ("https://github.com/lydell/video-audio-sync" ++ hash) ]
        children
