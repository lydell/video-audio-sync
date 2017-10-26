module View exposing (view)

import Element exposing (Element, el, text)
import StyleSheet exposing (Styles(..))
import Types exposing (..)


view : a -> Element Styles variation Msg
view model =
    el Title [] (text "hello!")
