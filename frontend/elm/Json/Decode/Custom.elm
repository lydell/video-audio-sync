module Json.Decode.Custom exposing (fromResult)

import Json.Decode as Decode exposing (Decoder)


fromResult : Result String a -> Decoder a
fromResult result =
    case result of
        Ok a ->
            Decode.succeed a

        Err message ->
            Decode.fail message
