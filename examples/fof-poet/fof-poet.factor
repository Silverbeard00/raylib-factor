! Copyright (C) 2019J Jack Lucas
! See http://factorcode.org/license.txt for BSD license.
USING: raylib.ffi kernel sequences locals alien.enums
namespaces math classes.struct accessors combinators math.ranges
sequences.deep continuations assocs classes.tuple math.functions random
    math.parser ;
IN: fof-poet

TUPLE: square posx posy size container ;

SYMBOL: grid-size
SYMBOL: grid

: make-window ( -- )
    800 600 "Mad Dash til Balderdash" init-window
    10 set-target-fps ;

: clear-window ( -- )
    RAYWHITE clear-background ;

! The Grid
: setup-grid ( -- )
    40 grid-size set ;

! Remove the points that would lie outside the canvas
: game-height ( -- height )
    get-screen-height grid-size get - ;

: game-width ( -- width )
    get-screen-width grid-size get - ;

: make-grid-line ( x range -- list )
    [ length ] keep 
    [ swap <repetition> ] dip
    zip
    [ [ grid-size get H{ } clone square boa ] with-datastack ] map ;

: setup-grid-squares ( -- )
    0 game-width grid-size get <range>
    [ 0 game-height grid-size get <range> make-grid-line ]
    map flatten grid set ;

: draw-square ( grid-square -- )
    tuple-slots
    [ drop dup BLACK draw-rectangle-lines ]
    with-datastack drop ;

: draw-grid ( -- )
    grid get [ draw-square ] each ;

! Grid Utilities

! Extract the square coordinates
: with-square-coordinates ( square -- x y square )
    [ posx>> ] keep
    [ posy>> ] keep ;

: square-coordinates ( square -- x y )
    with-square-coordinates drop ;

! Check if a pair (x,y) matches a square
: coordinates=? ( square x y -- bool )
    [ square-coordinates ] 2dip
    swap [ = ] dip
    swap [ = ] dip and ;

: find-square ( x y -- square )
    [ coordinates=? ] 2curry grid get
    swap
    filter ;

: container=? ( square name -- bool )
    swap container>> at* nip ;

: find-square-by-container ( name -- square )
    [ container=? ] curry
    grid get swap
    filter ;

: find-square-by-coordinate ( n -- squares )
    grid get swap filter ; inline

! Find all squares that have a certain x or y
: find-square-by-y ( y -- squares )
    [ swap posy>> = ] curry
    find-square-by-coordinate ;

: find-square-by-x ( x -- squares )
    [ swap posx>> = ] curry
    find-square-by-coordinate ;

: set-square-key ( square val key -- )
    pick container>> set-at drop ;

: remove-square-key ( square key -- )
    swap container>> delete-at ;

: get-square-key ( square key -- val )
    swap container>> at* drop ;

: center-square ( -- x )
    grid-size get 2 / ;

: offset ( vector2 -- vector2' )
    [ x>> center-square + ] keep
    y>> center-square +
    Vector2 <struct-boa> ;

: middle-square ( n -- n' )
    grid-size get / 2 / floor
    grid-size get * ;

! Player
: find-player-square ( -- square )
    "player" find-square-by-container first ;

: player-vector ( -- vector )
    find-player-square
    [ posx>> ] keep
    posy>> Vector2 <struct-boa> ;

: draw-player ( -- )
    player-vector offset
    20.0 RED draw-circle-v ;

: setup-player ( -- )
    t "player"
    game-width middle-square
    game-height find-square first container>>
    set-at ;
    
! Movement Words

! Square2 Doesnt exist stay
! Square2 occupied with same tag Stay
! Else move to square2
DEFER: opposite-direction

: change-former ( square tag -- )
    dup first [ second opposite-direction ] dip
    set-square-key ;

: change-later ( square tag -- )
    dup first pick swap get-square-key
    opposite-direction [ first ] dip
    swap set-square-key ;

:: ?change-direction ( square square2 tag -- )
    square2 tag first get-square-key
    tag second opposite-direction equal?
    [ square tag change-former
      square2 tag change-later ] when ;

:: square-decision ( tag square square2 -- )
    square2 tag first container=?
    [ square square2 tag ?change-direction ]
    [ square2 tag second tag first set-square-key
      square tag first remove-square-key ] if ;

: pick-square ( tag square square2 -- ) 
    dup empty?
    [ 3drop ]
    [ first square-decision ] if ;

: up-square ( x y -- square )
    grid-size get - find-square  ;

: down-square ( x y -- square )
    grid-size get + find-square ;

: left-square ( x y -- square )
    [ grid-size get - ] dip find-square  ;

: right-square ( x y -- square )
    [ grid-size get + ] dip find-square ;

: which-square ( x y direction -- square' )
    {
        { "up"    [ up-square    ] }
        { "down"  [ down-square  ] }
        { "left"  [ left-square  ] }
        { "right" [ right-square ] }
    } case ;

: move-square ( tag square direction -- )
    [ dup square-coordinates ] dip
    which-square
    pick-square ;

: process-input ( keypair -- result/bool )
    dup first ! Get the key
    enum>number is-key-down
    [ second ] [ drop "" ] if ; 

: player-inputs ( -- inputs )
    { 
        { KEY_W "up"    }
        { KEY_S "down"  }
        { KEY_A "left"  }
        { KEY_D "right"  }
    } ;

: attempt-to-move ( direction -- )
    { "player" t } find-player-square rot move-square ;

: check-input ( -- )
    player-inputs
    [ process-input dup
      "" equal?
      [ drop ]
      [ attempt-to-move ] if 
    ] each ; 

! AI Entities
: enemy-vector ( square -- vector )
    [ posx>> ] keep
    posy>> Vector2 <struct-boa> ;

: draw-enemy ( vector -- )
    offset 20.0 BLUE draw-circle-v ;

: enemies ( -- squarelst )
    "enemy" find-square-by-container ;

: draw-enemies ( -- )
    enemies
    [ enemy-vector draw-enemy ] each ;

: enemy-direction ( square -- direction )
    container>> "enemy" swap at ;

: opposite-direction ( direction -- direction )
    {
        { "up"    [ "down" ] }
        { "down"  [ "up" ] }
        { "left"  [ "right" ] }
        { "right" [ "left" ] }
        [ drop f ]
    } case ;

: flip-direction ( square direction -- )
    opposite-direction "enemy" set-square-key ;

: check-enemy-direction ( square -- )
    dup enemy-direction
    [ dup square-coordinates ] dip
    which-square { } equal?
    [ dup enemy-direction flip-direction ]
    [ drop ] if ;
    
: move-enemy ( square -- )
    [ check-enemy-direction ] keep
    [ enemy-direction ] keep
    [ { "enemy" } swap suffix ] dip
    over second move-square ;

: move-enemies ( -- )
    enemies
    [ move-enemy ] each ;

: directions ( -- directions )
    { "up" "down" "left" "right" } ;

: grid-enemy-map ( n -- n' )
    grid-size get / 1 - random
    grid-size get * ;

: grid-height ( -- height )
    game-height grid-enemy-map ;

: grid-width ( -- width )
    game-width grid-enemy-map ;

! Difficulty
SYMBOL: difficulty
: set-difficulty ( n -- )
    difficulty set ;

: increase-difficulty ( -- )
    difficulty get
    1 + difficulty set ;

: reset-difficulty ( -- )
    0 difficulty set ;

! Enemies
: setup-enemy ( n -- n' )
    grid-width grid-height find-square first
    directions random "enemy" set-square-key
    dup 0 =
    [ ] [ 1 - setup-enemy ] if ; recursive

: setup-enemies ( -- )
    difficulty get setup-enemy drop ;

: game-over-text ( -- )
    "Press Space to Continue \nEscape to Exit"
    40 get-screen-height 2 /
    30 BLACK draw-text ;
! States (End, Restart, Start)
: draw-game-over ( -- )
    begin-drawing
    clear-window
    game-over-text
    end-drawing ;

DEFER: game-loop
DEFER: setup

: game-over-input ( -- )
    {
        { KEY_SPACE "space" }
    }
    [ process-input
      "space" equal?
      [ reset-difficulty setup game-loop ] when ] each ;

: game-over-screen ( -- )
    [ draw-game-over
     game-over-input window-should-close not ] loop ;

! Collisions

: detect-collision ( -- )
    find-player-square
    enemies    
    member?
    [ game-over-screen ] when ;

! Textures and scenery
SYMBOL: textures
: setup-textures ( -- )
    { "ground.png" "sidewalk.png" "end.png" "door.png" }
    [ dup load-image load-texture-from-image
      [ { } swap suffix ] dip suffix ] 
    map
    textures set ;

: get-textures ( key -- texture )
    textures get at ;

: draw-ground ( -- )
    grid get
    [ square-coordinates [ "ground.png" get-textures ] 2dip
      RAYWHITE draw-texture ] each ;

: draw-sidewalks ( -- )
    0 find-square-by-x
    game-width find-square-by-x append
    [ square-coordinates [ "sidewalk.png" get-textures ] 2dip
      RAYWHITE draw-texture ] each ;

SYMBOL: max-level

: draw-ending-door ( -- )
    "door.png" get-textures game-width middle-square 0
    RAYWHITE draw-texture ;

: draw-winning-end ( -- )
    difficulty get max-level get =
    [ 0 find-square-by-y
      [ square-coordinates [ "end.png" get-textures ] 2dip
        RAYWHITE draw-texture ] each  
    draw-ending-door ] when ;

: draw-level-num ( -- )
    difficulty get number>string
    10 10 20 RED draw-text ;

: draw-game-won-text ( -- )
    "You reached the\nPoet Society!\nSpace to play again."
    40 get-screen-height 2 /
    30 BLACK draw-text ;

: draw-game-won ( -- )
    begin-drawing
    clear-window
    draw-grid
    draw-ground
    draw-game-won-text
    end-drawing ;

: game-won ( -- )
    [ draw-game-won game-over-input
      window-should-close not ] loop ;

: render ( -- )
    begin-drawing
    clear-window
    draw-grid
    draw-ground
    draw-sidewalks
    draw-winning-end
    draw-player
    draw-enemies
    draw-level-num
    end-drawing ;

: setup ( -- )
    setup-grid
    setup-grid-squares
    setup-player
    setup-enemies ;

: ?next-screen ( -- )
    find-player-square
    posy>> 0 =
    [ difficulty get max-level get =
      [ game-won ]
      [ increase-difficulty setup game-loop ] if
    ] when ;

: game-loop ( -- )
    [ check-input render move-enemies
      detect-collision ?next-screen
      window-should-close not ] loop ;

: draw-difficulty-box ( -- )
    "Press 1, 2 or 3 to select\n
    (1) 3 Levels\n
    (2) 5 Levels\n
    (3) 10 Levels\n"
    40 40
    30 BLACK draw-text ;

: render-difficulty-screen ( -- )
    begin-drawing
    clear-window
    draw-difficulty-box
    end-drawing ;

: difficulties ( -- n )
    { { "one" 3 } { "two" 5 } { "three" 10 } } ;

: check-difficulty-input ( -- )
    {
        { KEY_ONE "one" }
        { KEY_TWO "two" }
        { KEY_THREE "three" }
    } [ process-input dup
        "" equal?
        [ drop ]
        [ difficulties at max-level set ]
        if ] each ;

: choose-difficulty ( -- )
    [ render-difficulty-screen
      check-difficulty-input
      max-level get number? not ] loop ;
    
! These only need to be initialized once
: pre-setup ( -- )
    setup-textures
    choose-difficulty
    reset-difficulty ;

: reset-max-level ( -- )
    f max-level set ;

: main ( -- )
    make-window
    pre-setup
    setup
    game-loop
    reset-max-level ! While developing you'll want this
    close-window ;
    
MAIN: main
