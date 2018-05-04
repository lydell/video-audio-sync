module View.Modals.Help exposing (view)

import Html exposing (Html, a, h1, li, p, strong, text, ul)
import Html.Attributes exposing (href)
import ModelUtils
import Utils
import View.Fontawesome exposing (Icon(Icon), fontawesome)


loopRadius : String
loopRadius =
    Utils.formatTime ModelUtils.loopRadius


view : List (Html msg)
view =
    [ h1 [] [ text "Video Audio Sync" ]
    , p [] [ text "Fix videos where the audio is out of sync, in much stranger ways than just a simple constant time shift." ]
    , p [] [ text "This tool lets you find points where the video and audio match, and save those points. Another tool then uses those points to speed up or slow down segments of the audio so that it syncs up with the video." ]
    , p [] [ text "To learn more, see the ", projectLink "#video-audio-sync-" [ text "project page." ] ]
    , p [] [ strong [] [ text "Note: " ], text "This currently ", projectLink "#browser-support" [ text "works best in Chrome." ] ]
    , p [] [ text "Open the ", projectLink "#usage" [ text "separated" ], text " ", icon "file-video", text " video and ", icon "file-audio", text " audio files." ]
    , p [] [ text "Use the ", icon "play", text " ", icon "backward", text " ", icon "forward", text " Playback buttons to find a spot where you’d like to sync the video and audio." ]
    , p [] [ strong [] [ text "Tip: " ], text "Right-click a button to make it control both audio and video at the same time. If you use the ", icon "keyboard", text " keyboard: Hold Control, Command or Alt while pressing a keyboard shortcut." ]
    , p [] [ text "Good syncing spots include:" ]
    , ul []
        [ li [] [ text "Somebody making a distinct noise, such as closing a door." ]
        , li [] [ text "Scene transitions, especially when going from indoors to outdoors." ]
        , li [] [ text "Closeups of people talking." ]
        ]
    , p [] [ text "When you’ve found a good spot, ", icon "pause", text " pause the video and find roughly the corresponding audio spot." ]
    , p [] [ text "Now press the ", icon "sync-alt", text <| " Loop button. It will loop around your spot, from " ++ loopRadius ++ " before to " ++ loopRadius ++ " after." ]
    , p [] [ text "While looping, tweak the video and audio positions using the more fine-grained time controls, until the audio and video are in sync in that little segment." ]
    , p [] [ text "When satisfied, press the ", icon "plus", text " Plus button to save the point." ]
    , p [] [ text "Then repeat for as many points you want. You can use the ", icon "step-backward", icon "step-forward", text " Jump buttons to go back to earlier points if you made a mistake. Points can be ", icon "minus", text " removed and ", icon "plus", text " replaced with new ones." ]
    , p [] [ text "Finally, click the ", icon "save", text " Save button to save your points to a file. You can also ", icon "file-alt", text " open previous files you’ve made if you want to tweak them." ]
    , p [] [ text "Once you’ve got the points file, ", projectLink "#usage" [ text "sync the audio and video back up" ], text " into one file." ]
    ]


icon : String -> Html msg
icon name =
    fontawesome (Icon name)


projectLink : String -> List (Html msg) -> Html msg
projectLink hash children =
    a [ href ("https://github.com/lydell/video-audio-sync" ++ hash) ]
        children
