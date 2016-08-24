module Perspective exposing (..)

{-|
Embed and compose Views

Basics
@docs View, elim, empty

Maps
@docs map, mapModel, mapMsg

Slip in a value
@docs first, second

Fail
@docs failModel, failMsg

Function Msg
@docs sproodle
-}

import Html exposing (Html)
import Html.App as Html


{-|
The standard TEA view function
as a type.
-}
type alias View model msg =
    model -> Html msg


{-|
One usage of `map` not
to overlook, embeding a sub View

```
type Msg = Sub SubMsg

type SubMsg = Inc | Dec

type alias Model = { sub : Int }

subView : Int -> Html SubMsg

view : Model -> Html Msg
view = div []
  [ h1 [] [text "Foo"]
  , map .sub Sub subView ]
```
-}
map : (a -> b) -> (c -> d) -> View b c -> View a d
map ab cd bc =
    Html.map cd << bc << ab


{-|
Pre process the model
-}
mapModel : (a -> b) -> View b msg -> View a msg
mapModel =
    flip map identity


{-|
Post process the msg
-}
mapMsg : (b -> c) -> View a b -> View a c
mapMsg =
    map identity


{-|
Pass a value through to the msg,
on the right hand side of a tuple
-}
first : View a b -> View ( a, c ) ( b, c )
first ab ( a, c ) =
    Html.map (flip (,) c) (ab a)


{-|
Pass a value through to the msg,
on the left hand side of a tuple
-}
second : View a b -> View ( c, a ) ( c, b )
second v ( c, a ) =
    Html.map ((,) c) (v a)


{-|
Handle Html that fires functions.
(Haskell calls this uncurry',
there is no way I'm calling this thing uncurry,
its sproodle)
-}
sproodle : View a (b -> c) -> View ( a, b ) c
sproodle =
    mapMsg (uncurry (<|)) << first


{-|
Fully generic View, fits in everywhere
-}
empty : View a b
empty =
    always <| Html.text ""


{-|
Transform a View such that, passing an `Err` blanks the view.
-}
failModel : View a b -> View (Result c a) (Result c b)
failModel v aXORc =
    case aXORc of
        Ok a ->
            Html.map Ok (v a)

        _ ->
            Html.text ""


{-|
Eliminate a Result
(bundled here since its common with above functions)
-}
elim : (a -> b) -> (c -> b) -> Result a c -> b
elim f g e =
    case e of
        Ok y ->
            g y

        Err x ->
            f x


{-| Included for completeness
-}
failMsg : View a b -> View (Result a c) (Result b c)
failMsg =
    let
        dissolve =
            elim Ok Err
    in
        map dissolve dissolve << failModel
