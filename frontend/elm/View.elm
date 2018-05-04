module View exposing (view)

import Data.DomId as DomId
import Data.Model exposing (..)
import Html exposing (Html, div)
import Html.Attributes exposing (class, classList)
import Html.Custom exposing (none)
import Html.Events.Custom exposing (preventContextMenu)
import ModelUtils
import View.EditKeyboardShortcuts
import View.FileDragOverlay exposing (fileDragOverlay)
import View.GeneralToolbar exposing (generalToolbar)
import View.Graphics
import View.Media
import View.MediaPlayerToolbar exposing (mediaPlayerToolbar)
import View.Modals.ConfirmOpenPoints
import View.Modals.ConfirmRemoveAllPoints
import View.Modals.Errors
import View.Modals.Help
import View.Modals.PointsWarnings


view : Model -> Html Msg
view model =
    div [ class "Layout" ]
        [ div [ class "Layout-videoWrapper", DomId.toHtml DomId.VideoArea ] <|
            case View.EditKeyboardShortcuts.view model of
                Just content ->
                    [ content ]

                Nothing ->
                    View.Media.view model
        , div
            [ classList
                [ ( "Layout-controls", True )
                , ( "is-editKeyboardShortcuts", model.editKeyboardShortcuts /= NotEditing )
                ]
            , preventContextMenu
            ]
            (controls model)
        , modals model
        , if model.isDraggingFile then
            fileDragOverlay
          else
            none
        ]


controls : Model -> List (Html Msg)
controls model =
    let
        shownKeyboardShortcuts =
            ModelUtils.shownKeyboardShortcuts model
    in
    [ mediaPlayerToolbar Video
        model.video
        model.loopState
        shownKeyboardShortcuts
        model.editKeyboardShortcuts
    , View.Graphics.view model
    , mediaPlayerToolbar Audio
        model.audio
        model.loopState
        shownKeyboardShortcuts
        model.editKeyboardShortcuts
    , generalToolbar model shownKeyboardShortcuts
    ]


modals : Model -> Html Msg
modals model =
    div []
        [ if model.pointsWarningsModalOpen then
            View.Modals.PointsWarnings.view ClosePointsWarningsModal model.points
          else
            none
        , if model.confirmRemoveAllPointsModalOpen then
            View.Modals.ConfirmRemoveAllPoints.view
                { cancel = CloseRemoveAllPoints
                , confirm = RemoveAllPoints
                }
          else
            none
        , case model.confirmOpenPoints of
            Just { name, points } ->
                View.Modals.ConfirmOpenPoints.view
                    { cancel = CloseOpenPoints
                    , confirm = OpenConfirmedPoints points
                    , name = name
                    }

            Nothing ->
                none
        , case model.errors of
            [] ->
                none

            errors ->
                View.Modals.Errors.view CloseErrorsModal (List.reverse errors)
        , if model.helpModalOpen then
            View.Modals.Help.view CloseHelpModal
          else
            none
        ]
