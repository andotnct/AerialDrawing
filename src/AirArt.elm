port module AirArt exposing (main)

import Angle
import Browser
import Browser.Dom
import Browser.Events
import Camera3d
import Color
import Direction3d
import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onMouseDown, onMouseUp)
import Json.Decode as Decode exposing (Decoder)
import Length
import Pixels
import Point3d
import Quantity exposing (Quantity)
import Scene3d
import Scene3d.Material as Material
import Sphere3d
import Task
import Vector3d exposing (Vector3d)
import Viewpoint3d



--PORTS


port requestPointerLock : () -> Cmd msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init () =
    ( { width = Quantity.zero
      , height = Quantity.zero
      , eyePoint = { x = 0.0, y = 0.0, z = 0.0 }
      , focalVector = { x = 1.0, y = 0.0, z = 0.0 }
      , keyStatus = { up = False, down = False, left = False, right = False, space = False, shift = False }
      , isClick = False
      , points = []
      , numPoints = 0
      }
    , Task.perform
        (\{ viewport } ->
            ResizeWindow
                (Pixels.int (round viewport.width))
                (Pixels.int (round viewport.height))
        )
        Browser.Dom.getViewport
    )



-- MODEL


type alias Model =
    { width : Quantity Int Pixels.Pixels
    , height : Quantity Int Pixels.Pixels
    , eyePoint : Point3dModel
    , focalVector : Point3dModel
    , keyStatus : KeyStatusModel
    , isClick : Bool
    , points : List PointModel
    , numPoints : Int
    }


type alias Point3dModel =
    { x : Float
    , y : Float
    , z : Float
    }


type alias KeyStatusModel =
    { up : Bool
    , down : Bool
    , left : Bool
    , right : Bool
    , space : Bool
    , shift : Bool
    }


type alias PointModel =
    { coord : Point3dModel
    , color : String
    , size : Int
    }



-- MSG


type Msg
    = ResizeWindow (Quantity Int Pixels.Pixels) (Quantity Int Pixels.Pixels)
    | RequestPointerLock
    | KeyChanged Bool String
    | DisableIsClick
    | TimeDelta Float
    | MouseMove (Quantity Float Pixels.Pixels) (Quantity Float Pixels.Pixels)
    | DrawPoints (Quantity Float Pixels.Pixels) (Quantity Float Pixels.Pixels)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ResizeWindow width height ->
            ( { model | width = width, height = height }, Cmd.none )

        RequestPointerLock ->
            ( { model | isClick = True }, requestPointerLock () )

        TimeDelta dt ->
            let
                position =
                    if model.keyStatus.up == True then
                        { x = model.eyePoint.x + model.focalVector.x, y = model.eyePoint.y + model.focalVector.y, z = model.eyePoint.z + model.focalVector.z }

                    else
                        { x = model.eyePoint.x, y = model.eyePoint.y, z = model.eyePoint.z }

                focus =
                    if model.keyStatus.down == True then
                        { x = model.focalVector.x + model.focalVector.x, y = model.focalVector.y + model.focalVector.y, z = model.focalVector.z + model.focalVector.z }

                    else
                        { x = model.focalVector.x, y = model.focalVector.y, z = model.focalVector.z }
            in
            ( { model | eyePoint = position, focalVector = focus }, Cmd.none )

        KeyChanged isDown key ->
            ( { model | keyStatus = updateKeyStatus isDown key model.keyStatus }, Cmd.none )

        DisableIsClick ->
            ( { model | isClick = False }, Cmd.none )

        MouseMove dx dy ->
            let
                dxFloat =
                    Pixels.toFloat dx

                dyFloat =
                    Pixels.toFloat dy

                newFocalVector =
                    { x =
                        if model.focalVector.y > 0.0 then
                            model.focalVector.x + dxFloat / 200

                        else
                            model.focalVector.x - dxFloat / 200
                    , y =
                        if model.focalVector.x > 0.0 then
                            model.focalVector.y - dxFloat / 200

                        else
                            model.focalVector.y + dxFloat / 200
                    , z = model.focalVector.z - dyFloat / 200
                    }
            in
            ( { model | focalVector = newFocalVector }, Cmd.none )

        DrawPoints dx dy ->
            if model.isClick == True then
                ( { model | points = model.points ++ [ { coord = { x = model.eyePoint.x + model.focalVector.x * 20, y = model.eyePoint.y + model.focalVector.y * 20, z = model.eyePoint.z + model.focalVector.z * 20 }, color = "red", size = 2 } ], numPoints = model.numPoints + 1 }, Cmd.none )

            else
                ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize (\width height -> ResizeWindow (Pixels.int width) (Pixels.int height))
        , Browser.Events.onAnimationFrameDelta TimeDelta
        , Browser.Events.onMouseMove drawPointsDecoder
        , Browser.Events.onMouseMove mouseMoveDecoder
        , Browser.Events.onKeyUp (Decode.map (KeyChanged False) (Decode.field "key" Decode.string))
        , Browser.Events.onKeyDown (Decode.map (KeyChanged True) (Decode.field "key" Decode.string))
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        square =
            Scene3d.quad (Material.color Color.blue)
                (Point3d.meters -100 -100 -1)
                (Point3d.meters 100 -100 -1)
                (Point3d.meters 100 100 -1)
                (Point3d.meters -100 100 -1)

        square2 =
            Scene3d.quad (Material.color Color.red)
                (Point3d.meters 100 -100 -100)
                (Point3d.meters 100 -100 100)
                (Point3d.meters 100 100 100)
                (Point3d.meters 100 100 -100)

        square3 =
            Scene3d.quad (Material.color Color.green)
                (Point3d.meters -100 -100 -100)
                (Point3d.meters -100 -100 100)
                (Point3d.meters -100 100 100)
                (Point3d.meters -100 100 -100)

        square4 =
            Scene3d.quad (Material.color Color.yellow)
                (Point3d.meters -100 -100 -100)
                (Point3d.meters -100 -100 100)
                (Point3d.meters 100 -100 100)
                (Point3d.meters 100 -100 -100)

        square5 =
            Scene3d.quad (Material.color Color.green)
                (Point3d.meters 99 -10 -10)
                (Point3d.meters 99 -10 10)
                (Point3d.meters 99 10 10)
                (Point3d.meters 99 10 -10)

        camera =
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.lookAt
                        { eyePoint = Point3d.meters model.eyePoint.x model.eyePoint.y model.eyePoint.z
                        , focalPoint = Point3d.meters (model.focalVector.x + model.eyePoint.x) (model.focalVector.y + model.eyePoint.y) (model.focalVector.z + model.eyePoint.z)
                        , upDirection = Direction3d.positiveZ
                        }
                , verticalFieldOfView = Angle.degrees 30
                }
    in
    div
        [ id "canvas"
        , onMouseDown RequestPointerLock
        , onMouseUp DisableIsClick
        ]
        [ Scene3d.unlit
            { entities = [ square, square2, square3, square4, square5 ] ++ createSphereEntities model.points model.numPoints
            , camera = camera
            , clipDepth = Length.meters 1
            , background = Scene3d.transparentBackground
            , dimensions = ( model.width, model.height )
            }
        ]



-- FUNCTIONS


mouseMoveDecoder : Decoder Msg
mouseMoveDecoder =
    Decode.oneOf
        [ Decode.map2
            MouseMove
            (Decode.field "movementX" (Decode.map Pixels.float Decode.float))
            (Decode.field "movementY" (Decode.map Pixels.float Decode.float))
        ]


drawPointsDecoder : Decoder Msg
drawPointsDecoder =
    Decode.oneOf
        [ Decode.map2
            DrawPoints
            (Decode.field "movementX" (Decode.map Pixels.float Decode.float))
            (Decode.field "movementY" (Decode.map Pixels.float Decode.float))
        ]


updateKeyStatus : Bool -> String -> KeyStatusModel -> KeyStatusModel
updateKeyStatus isDown key keys =
    case key of
        "w" ->
            { keys | up = isDown }

        "a" ->
            { keys | left = isDown }

        "s" ->
            { keys | down = isDown }

        "d" ->
            { keys | right = isDown }

        " " ->
            { keys | space = isDown }

        "Shift" ->
            { keys | shift = isDown }

        _ ->
            keys


createSphereEntities points n =
    let
        material =
            Material.nonmetal
                { baseColor = Color.lightBlue
                , roughness = 0.4
                }

        sphereEntity =
            case List.head points of
                Just firstPoint ->
                    Scene3d.sphere material <|
                        Sphere3d.withRadius (Length.centimeters 50) (Point3d.meters firstPoint.coord.x firstPoint.coord.y firstPoint.coord.z)

                Nothing ->
                    Scene3d.sphere material <|
                        Sphere3d.withRadius (Length.centimeters 0) Point3d.origin
    in
    if n > 0 then
        sphereEntity :: createSphereEntities (List.drop 1 points) (n - 1)

    else
        []