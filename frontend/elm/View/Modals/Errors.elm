module View.Modals.Errors exposing (view)

import Data.File as File
import Data.Model exposing (Error(..))
import Html exposing (Html, code, li, p, strong, text, ul)
import Utils


view : List Error -> List (Html msg)
view errors =
    [ p []
        [ strong []
            [ text <|
                case errors of
                    [] ->
                        "No errors!"

                    [ _ ] ->
                        "There was an error with your file."

                    _ ->
                        "There were some errors with your files."
            ]
        ]
    , ul [] <|
        List.map (viewError >> li []) errors
    ]


viewError : Error -> List (Html msg)
viewError error =
    case error of
        InvalidFileError { name, expectedFileTypes } ->
            let
                expected =
                    case expectedFileTypes of
                        [] ->
                            "nothing"

                        _ ->
                            Utils.humanList "or"
                                (List.map File.fileTypeToHumanString expectedFileTypes)
            in
            [ code [] [ text name ]
            , text <| " is invalid. Expected " ++ expected ++ "."
            ]

        ErroredFileError { name, fileType } ->
            [ text "Failed to read "
            , code [] [ text name ]
            , text <| " as " ++ File.fileTypeToHumanString fileType ++ "."
            ]

        MediaError { name, fileType } ->
            [ text "Failed to play "
            , code [] [ text name ]
            , text <|
                " as "
                    ++ File.fileTypeToHumanString fileType
                    ++ ". The file is either unsupported, broken or invalid."
            ]

        InvalidPointsError { name, message } ->
            [ p []
                [ text "Failed to parse "
                , code [] [ text name ]
                , text <| " as " ++ File.fileTypeToHumanString File.JsonFile ++ ". "
                ]
            , p [] [ code [] [ text (Utils.truncateJsonDecodeErrorMessage message) ] ]
            ]
