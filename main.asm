INCLUDE Irvine32.inc
INCLUDE macros.inc
INCLUDELIb winmm.lib

;Column Center Formula : (Number of Columns - Length of String)/2
;Row Center Formula : Number of Rows / 2
NUM_COLS = 120
NUM_ROWS = 30

;----------------------------------------
; Gameplay Constants
;----------------------------------------
TICK_MS       = 25              ; One game tick
PLAYER_TICKS  = 4               ; Pacman moves one column every 4 ticks (100 ms)
                                ; Rows take twice as long since console cells are twice as tall
FRIGHT_TICKS  = 280             ; Power pellet lasts 7 seconds
MAX_GHOSTS    = 5
MAX_SCORES    = 5
NAME_LEN      = 16              ; Bytes per high score name (including null)

DIR_UP    = 0
DIR_DOWN  = 1
DIR_LEFT  = 2
DIR_RIGHT = 3
DIR_NONE  = 4

START_X      = 2                ; Pacman start position
START_Y      = 2
HOUSE_LEFT   = 57               ; Ghost house interior
HOUSE_RIGHT  = 66
HOUSE_TOP    = 12
HOUSE_BOTTOM = 16
HOUSE_EXIT_X = 62               ; Ghosts head here to leave the house
HOUSE_EXIT_Y = 10

FRIGHT_COLOR = white + (blue * 16)

TITLE MASM PlaySound

PlaySound PROTO,
pszSoundName:PTR BYTE,
hmod:DWORD,
fdwSound:DWORD

.data

;----------------------------------------
; Music Constants
;----------------------------------------
musicIntro     db "pacman_beginning.wav", 0
musicChomp     db "pacman_chomp.wav", 0
musicDeath     db "pacman_death.wav", 0
musicFruit     db "pacman_eatfruit.wav", 0
musicEatGhost  db "pacman_eatghost.wav", 0

; Sound Flags
SND_FILENAME   DWORD 00020001h  ; Sound file name flag (played asynchronously)
SND_ASYNC      DWORD 00000001h  ; Asynchronous flag
SND_LOOP       DWORD 00000008h  ; Loop flag
SND_FLAGS      DWORD 20009h     ; Combined flags (SND_FILENAME OR SND_ASYNC OR SND_LOOP)

;----------------------------------------
; File Constants
;----------------------------------------
fileName       db "highscores.dat", 0

;----------------------------------------
; Game Constants
;----------------------------------------
; Ghost speeds for different levels (ms per column)
L1_Speed       DWORD 150
L2_Speed       DWORD 125
L3_Speed       DWORD 100

ghostsPerLevel db 2, 3, 5       ; Level 1: G1-G2, Level 2: G1-G3, Level 3: G1-G5
chaseChance    db 60, 75, 90    ; % of moves where a ghost heads straight for Pacman
levelTables    DWORD OFFSET level1, OFFSET level2, OFFSET level3

; Characters for game elements
wall           db "#"
coin           db "."
powerPellet    db "O"
space          db " "
pacman         db "X"

; Ghost Symbols
G1             DB "!"
G2             DB "@"
G3             DB "$"
G4             DB "%"
G5             DB "&"

ghostColors    db lightRed, lightMagenta, lightCyan, lightGreen, brown

;----------------------------------------
; Grid and Buffer Definitions
;----------------------------------------
grid            db NUM_COLS * NUM_ROWS dup(0)    ; Grid to store the maze
welcomeMsg      db "Pacman", 0                   ; Welcome message
menuMsg         db "1. Start Game", 0            ; Menu option 1
altMenuMsg     db  "1. Resume Game", 0           ; Alternative menu option when paused
menuMsg2        db "2. Select Level", 0          ; Menu option 2
menuMsg3        db "3. Instructions", 0          ; Menu option 3
menuMsg4        db "4. High Scores", 0           ; Menu option 4
menuMsg5        db "5. Exit -> Any Key", 0       ; Menu option 5
highScoresMsg   db "High Scores", 0              ; High Scores title
noScoresMsg     db "No high scores yet.", 0
levelPrompt     db "Select starting level (1-3): ", 0
gameOverMsg     db "GAME OVER", 0
winMsg          db "YOU WIN!", 0
finalScoreMsg   db "Final score: ", 0
newHighMsg      db "New high score! Enter your name: ", 0
defaultName     db "Player", 0
titleMsg        db "Pacman (MASM)", 0

readyMsg        db " READY! "
READY_LEN = ($ - readyMsg)
pausedMsg       db " PAUSED - P to resume, Esc for menu "
PAUSED_LEN = ($ - pausedMsg)

; HUD drawn over the top border; digits are filled in by DrawHud
hudBuf          db " SCORE "
hudScore        db "000000"
                db "   LIVES "
hudLives        db "0"
                db "   LEVEL "
hudLevel        db "0", " "
HUD_LEN = ($ - hudBuf)

; Centering positions
colCenter      db 0
rowCenter      db 0

; Game State Data
lives          db 3                            ; Player lives
score          dd 0                            ; Player score
pelletsLeft    dd 0                            ; Pellets left on this level
frightTimer    dd 0                            ; Ticks of power pellet left
chompCooldown  db 0                            ; Keeps the chomp sound from restarting every step
ghostTicks     dd 6                            ; Ticks per ghost column move for this level
numGhosts      db 2                            ; Ghosts active on this level

; Player movement and state
nameInputBuffer DB 20 dup(0)                   ; Buffer for player name input

playerDirection    db DIR_NONE                 ; Current direction
nextDirection      db DIR_NONE                 ; Direction queued by the last key press
playerTimer        db 1                        ; Ticks until Pacman's next step

dirDX          SBYTE 0, 0, -1, 1               ; Up, Down, Left, Right
dirDY          SBYTE -1, 1, 0, 0

;----------------------------------------
; Ghosts' Status and Movement
;----------------------------------------
ghostX        db MAX_GHOSTS dup(0)
ghostY        db MAX_GHOSTS dup(0)
ghostDir      db MAX_GHOSTS dup(DIR_UP)
ghostState    db MAX_GHOSTS dup(0)            ; 0 = chasing, 1 = frightened
ghostTimer    db MAX_GHOSTS dup(1)            ; Ticks until the ghost's next step
candDirs      db 4 dup(0)                     ; Scratch list of directions a ghost can take
targetX       db 0                            ; Scratch target for ghost pathing
targetY       db 0

levelIndicator db 1                           ; Current level
startLevel     db 1                           ; Level chosen in Select Level
GameStateHandler db 0                         ; 1 while a game is paused in the menu

;----------------------------------------
; Player Position and Status
;----------------------------------------
xPos           db START_X                      ; Player X position
yPos           db START_Y                      ; Player Y position

;----------------------------------------
; Ghost Positions (Initial)
;----------------------------------------
ghostSpawnX    DB 58, 60, 62, 64, 62
ghostSpawnY    DB 15, 15, 15, 15, 13

;----------------------------------------
; Console Output
;----------------------------------------
consoleOut     DWORD 0
cursorInfo     CONSOLE_CURSOR_INFO <25, 0>
cellCoord      COORD <0, 0>
charsWritten   DWORD 0
charBuf        db NUM_COLS dup(0)
attrBuf        WORD NUM_COLS dup(0)

;----------------------------------------
; High Scores (saved to fileName as one block)
;----------------------------------------
hsNames        db MAX_SCORES * NAME_LEN dup(0)
hsScores       DWORD MAX_SCORES dup(0)
HS_SIZE = ($ - hsNames)

;----------------------------------------
; Maze Level 1
;----------------------------------------
maze1    db "------------------------------------------------------------------------------------------------------------------------", 0
maze2    db "|O................#####..........................................................................#####................O|", 0
maze3    db "|.................#####..........................................................................#####.................|", 0
maze4    db "|.................#####..........................................................................#####.................|", 0
maze5    db "|.................#####..........................................................................#####.................|", 0
maze6    db "|.................#####..........................................................................#####.................|", 0
maze7    db "|......................................................................................................................|", 0
maze8    db "|......................................................................................................................|", 0
maze9    db "|..................##............................##.......................##........................##.................|", 0
maze10   db "|..................##.##########################.##.......................##.######################.##.................|", 0
maze11   db "|..................##............................##.......................##........................##.................|", 0
maze12   db "|......................................................................................................................|", 0
maze13   db "|......................................................##          ##..................................................|", 0
maze14   db "|......................................................##          ##..................................................|", 0
maze15   db "|......................................................##          ##..................................................|", 0
maze16   db "|......................................................##          ##..................................................|", 0
maze17   db "|......................................................##          ##..................................................|", 0
maze18   db "|......................................................##############..................................................|", 0
maze19   db "|......................................................................................................................|", 0
maze20   db "|..................##............................##.......................##........................##.................|", 0
maze21   db "|..................##.##########################.##.......................##.######################.##.................|", 0
maze22   db "|..................##............................##.......................##........................##.................|", 0
maze23   db "|.............................................................#........................................................|", 0
maze24   db "|.............................................................#........................................................|", 0
maze25   db "|.................#####.......................................#.............................#####......................|", 0
maze26   db "|.................#####.......................................#.............................#####......................|", 0
maze27   db "|.................#####.......................................#.............................#####......................|", 0
maze28   db "|.................#####.......................................#.............................#####......................|", 0
maze29   db "|O................#####.....................................................................#####.....................O|", 0
maze30   db "------------------------------------------------------------------------------------------------------------------------", 0

level1 DWORD OFFSET maze1, OFFSET maze2, OFFSET maze3, OFFSET maze4, OFFSET maze5, OFFSET maze6, OFFSET maze7, OFFSET maze8, OFFSET maze9, OFFSET maze10, OFFSET maze11, OFFSET maze12, OFFSET maze13, OFFSET maze14, OFFSET maze15, OFFSET maze16, OFFSET maze17, OFFSET maze18, OFFSET maze19, OFFSET maze20, OFFSET maze21, OFFSET maze22, OFFSET maze23, OFFSET maze24, OFFSET maze25, OFFSET maze26, OFFSET maze27, OFFSET maze28, OFFSET maze29, OFFSET maze30

;----------------------------------------
; Maze Level 2
;----------------------------------------
L2maze1 db "------------------------------------------------------------------------------------------------------------------------", 0
L2maze2 db "|O....................................................................................................................O|", 0
L2maze3 db "|......................................................................................................................|", 0
L2maze4 db "|...#####################.....#####################..................#####################.....#####################...|", 0
L2maze5 db "|......................................................................................................................|", 0
L2maze6 db "|......................................................................................................................|", 0
L2maze7 db "|.........###############################......................................###############################.........|", 0
L2maze8 db "|......................................................................................................................|", 0
L2maze9 db "|......................................................................................................................|", 0
L2maze10 db "|...###############.....#######################..........................#######################.....###############...|", 0
L2maze11 db "|......................................................................................................................|", 0
L2maze12 db "|......................................................................................................................|", 0
L2maze13 db "|.......#...........................................#..##          ##..........................................#.......|", 0
L2maze14 db "|.......#.....................#.....................#..##          ##....................#.....................#.......|", 0
L2maze15 db "|.......#.....................#.....................#..##          ##....................#.....................#.......|", 0
L2maze16 db "|.......#.....................#.....................#..##          ##....................#.....................#.......|", 0
L2maze17 db "|.......#.....................#.....................#..##          ##....................#.....................#.......|", 0
L2maze18 db "|.......#...........................................#..##############..........................................#.......|", 0
L2maze19 db "|......................................................................................................................|", 0
L2maze20 db "|......................................................................................................................|", 0
L2maze21 db "|...###############.....#######################..........................#######################.....###############...|", 0
L2maze22 db "|......................................................................................................................|", 0
L2maze23 db "|......................................................................................................................|", 0
L2maze24 db "|.........###############################......................................###############################.........|", 0
L2maze25 db "|......................................................................................................................|", 0
L2maze26 db "|......................................................................................................................|", 0
L2maze27 db "|...#####################.....#####################..................#####################.....#####################...|", 0
L2maze28 db "|......................................................................................................................|", 0
L2maze29 db "|O....................................................................................................................O|", 0
L2maze30 db "------------------------------------------------------------------------------------------------------------------------", 0

level2 DWORD OFFSET L2maze1, OFFSET L2maze2, OFFSET L2maze3, OFFSET L2maze4, OFFSET L2maze5, OFFSET L2maze6, OFFSET L2maze7, OFFSET L2maze8, OFFSET L2maze9, OFFSET L2maze10
       DWORD OFFSET L2maze11, OFFSET L2maze12, OFFSET L2maze13, OFFSET L2maze14, OFFSET L2maze15, OFFSET L2maze16, OFFSET L2maze17, OFFSET L2maze18, OFFSET L2maze19, OFFSET L2maze20
       DWORD OFFSET L2maze21, OFFSET L2maze22, OFFSET L2maze23, OFFSET L2maze24, OFFSET L2maze25, OFFSET L2maze26, OFFSET L2maze27, OFFSET L2maze28, OFFSET L2maze29, OFFSET L2maze30

;----------------------------------------
; Maze Level 3
;----------------------------------------
L3maze1 db "------------------------------------------------------------------------------------------------------------------------", 0
L3maze2 db "|O....................................................................................................................O|", 0
L3maze3 db "|..########...#############...###############..............................###############...#############...########..|", 0
L3maze4 db "|..########...#############...###############..............................###############...#############...########..|", 0
L3maze5 db "|..########...................###############..............................###############...................########..|", 0
L3maze6 db "|......................................................................................................................|", 0
L3maze7 db "|......................................................................................................................|", 0
L3maze8 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze9 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze10 db "|..####.......................#####..................................................#####.......................####..|", 0
L3maze11 db "|..####.......................#####..................................................#####.......................####..|", 0
L3maze12 db "|..####...#############.......#####...###########.......................##########...#####.......#############...####..|", 0
L3maze13 db "|..####...#############.......#####...###########......##          ##..###########...#####.......#############...####..|", 0
L3maze14 db "|..####.......................#####...###########......##          ##..###########...#####.......................####..|", 0
L3maze15 db "|......................................................##          ##..................................................|", 0
L3maze16 db "|.................#########............................##          ##........................#########.................|", 0
L3maze17 db "|..############...#########...........#############....##          ##.############...........#########...############..|", 0
L3maze18 db "|..############...#########...........#############....##############.############...........#########...############..|", 0
L3maze19 db "|.................#########...........#############..................#############...........#########.................|", 0
L3maze20 db "|......................................................................................................................|", 0
L3maze21 db "|..####.......................#####..................................................#####.......................####..|", 0
L3maze22 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze23 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze24 db "|..####.......................#####..................................................#####.......................####..|", 0
L3maze25 db "|..####.......................#####..................................................#####.......................####..|", 0
L3maze26 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze27 db "|..####...#################...#####...#############..................#############...#####...#################...####..|", 0
L3maze28 db "|.........#################...........#############..................#############...........#################.........|", 0
L3maze29 db "|O....................................................................................................................O|", 0
L3maze30 db "------------------------------------------------------------------------------------------------------------------------", 0

level3 DWORD OFFSET L3maze1, OFFSET L3maze2, OFFSET L3maze3, OFFSET L3maze4, OFFSET L3maze5, OFFSET L3maze6, OFFSET L3maze7, OFFSET L3maze8, OFFSET L3maze9, OFFSET L3maze10
       DWORD OFFSET L3maze11, OFFSET L3maze12, OFFSET L3maze13, OFFSET L3maze14, OFFSET L3maze15, OFFSET L3maze16, OFFSET L3maze17, OFFSET L3maze18, OFFSET L3maze19, OFFSET L3maze20
       DWORD OFFSET L3maze21, OFFSET L3maze22, OFFSET L3maze23, OFFSET L3maze24, OFFSET L3maze25, OFFSET L3maze26, OFFSET L3maze27, OFFSET L3maze28, OFFSET L3maze29, OFFSET L3maze30

.code
main PROC

    ;Initialize the console
    call Randomize
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov consoleOut, eax
    INVOKE SetConsoleTitle, ADDR titleMsg
    call HideCursor
    call LoadHighScores
    call Clrscr

    ;Welcome Screen
    call displayWelcome

Menu:
    call Clrscr
    call displayMenu
    call ReadChar
    cmp al, '1'
    je StartGame
    cmp al, '2'
    je SelectLevel
    cmp al, '3'
    je Instructions
    cmp al, '4'
    je HighScores
    jmp ExitGame ; 5 or any other key

StartGame:
    cmp GameStateHandler, 1
    je ResumeGame
    call NewGame
    jmp PlayGame

ResumeGame:
    call DrawLevel

PlayGame:
    call GameLoop               ; EAX = 0 paused, 1 game over, 2 won
    cmp eax, 0
    je Menu
    mov GameStateHandler, 0
    call GameOverScreen
    call RecordHighScore
    jmp Menu

SelectLevel:
    call Clrscr
    mov dl, 45
    mov dh, rowCenter
    call GoToXY
    mov edx, offset levelPrompt
    call WriteString
ReadLevel:
    call ReadChar
    cmp al, '1'
    jb ReadLevel
    cmp al, '3'
    ja ReadLevel
    sub al, '0'
    mov startLevel, al
    mov GameStateHandler, 0
    call NewGame
    jmp PlayGame

Instructions:
    call Clrscr
    call displayInstructions
    jmp Menu

HighScores:
    call ShowHighScores
    jmp Menu

ExitGame:
    INVOKE PlaySound, 0, 0, 0
    call Clrscr
    exit
main ENDP

;---------------------------------------
;Welcome Screen Proc
;---------------------------------------
displayWelcome PROC

    ;Play Intro Music
    INVOKE PlaySound, OFFSET musicIntro, 0, SND_FLAGS

    ;Perform calculations to find center
    mov eax, NUM_COLS
    sub eax, 7 ; Length of "Pacman"
    mov edx, 0
    mov ecx, 2
    div ecx
    mov colCenter, al
    mov eax, NUM_ROWS
    mov edx, 0
    mov ecx, 2
    div ecx
    mov rowCenter, al

    ;Move cursor to the center of the screen and display screen
    mov dl, colCenter
    mov dh, rowCenter
    call GoToXY

    mov eax, yellow
    call SetTextColor

    mov edx, offset welcomeMsg
    call WriteString
    call crlf

    mov eax, white
    call SetTextColor

    mov dl, colCenter
    sub dl, 10
    mov dh, 29
    call GoToXY
    call WaitMsg

    call Clrscr
    ret
displayWelcome ENDP
;---------------------------------------
;Display Instructions Proc
;---------------------------------------
displayInstructions PROC
    LOCAL tempCol:BYTE
    LOCAL tempRow:BYTE

    ; Find center column
    mov eax, NUM_COLS
    sub eax, 60         ; Width of the instructions block
    xor edx, edx
    mov ecx, 2
    div ecx
    mov tempCol, al

    ; Adjust row center up by 5
    movzx eax, rowCenter
    sub eax, 5
    mov tempRow, al

    mov dl, tempCol
    mov dh, tempRow
    call GoToXY
    mov eax, yellow
    call SetTextColor
    mwrite "Instructions"
    mov eax, white
    call SetTextColor

    mov dl, tempCol
    mov dh, tempRow
    add dh, 2
    call GoToXY
    mwrite "Move with the arrow keys or W A S D."
    mov dl, tempCol
    mov dh, tempRow
    add dh, 3
    call GoToXY
    mwrite "Eat every dot (10) to clear the level. There are 3 levels."
    mov dl, tempCol
    mov dh, tempRow
    add dh, 4
    call GoToXY
    mwrite "Power pellets O (50) turn the ghosts blue for 7 seconds:"
    mov dl, tempCol
    mov dh, tempRow
    add dh, 5
    call GoToXY
    mwrite "eat a blue ghost for 200. Any other ghost costs a life."
    mov dl, tempCol
    mov dh, tempRow
    add dh, 6
    call GoToXY
    mwrite "P pauses. Esc returns to the menu, where you can resume."

    ; Wait message two lines below
    mov dl, tempCol
    mov dh, tempRow
    add dh, 8
    call GoToXY
    call WaitMsg
    call Clrscr
    ret
displayInstructions ENDP


;---------------------------------------
;Menu Screen Proc
;---------------------------------------
displayMenu PROC
    LOCAL tempCol:BYTE
    LOCAL tempRow:BYTE

    mov eax, NUM_COLS
    sub eax, 13 ; Length of "1. Start Game"
    sub eax, 5  ; Adjust
    mov ecx, 2
    xor edx, edx
    div ecx
    mov tempCol, al

    movzx eax, rowCenter
    sub eax, 2
    mov tempRow, al

    ; Menu Line 1 (Resume when a game is paused)
    mov dl, tempCol
    mov dh, tempRow
    call GoToXY
    mov edx, offset menuMsg
    cmp GameStateHandler, 1
    jne ShowLine1
    mov edx, offset altMenuMsg
ShowLine1:
    call writestring

    ; Menu Line 2
    mov dl, tempCol
    mov dh, tempRow
    add dh, 1
    call GoToXY
    mov edx, offset menuMsg2
    call writestring

    ; Menu Line 3
    mov dl, tempCol
    mov dh, tempRow
    add dh, 2
    call GoToXY
    mov edx, offset menuMsg3
    call writestring

    ; Menu Line 4
    mov dl, tempCol
    mov dh, tempRow
    add dh, 3
    call GoToXY
    mov edx, offset menuMsg4
    call writestring

    ; Menu Line 5
    mov dl, tempCol
    mov dh, tempRow
    add dh, 4
    call GoToXY
    mov edx, offset menuMsg5
    call writestring

    ret
displayMenu ENDP

;---------------------------------------
;Game Setup
;---------------------------------------
NewGame PROC
    INVOKE PlaySound, 0, 0, 0
    mov score, 0
    mov lives, 3
    mov al, startLevel
    mov levelIndicator, al
    call LoadLevel
    call ResetPositions
    mov GameStateHandler, 1
    call DrawLevel
    call ShowReady
    ret
NewGame ENDP

;---------------------------------------
; LoadLevel
; Copies the current level's maze into grid. Dots are kept only on
; odd rows and columns so the open mazes don't take minutes to clear.
;---------------------------------------
LoadLevel PROC USES eax ebx ecx edx esi edi
    movzx ebx, levelIndicator
    dec ebx
    mov al, ghostsPerLevel[ebx]
    mov numGhosts, al
    mov eax, L1_Speed[ebx*4]
    xor edx, edx
    mov ecx, TICK_MS
    div ecx
    mov ghostTicks, eax
    mov esi, levelTables[ebx*4]

    mov pelletsLeft, 0
    xor edi, edi                ; grid index
    xor ecx, ecx                ; row
RowLoop:
    mov ebx, [esi + ecx*4]      ; maze line for this row
    xor edx, edx                ; column
ColLoop:
    mov al, [ebx + edx]
    cmp al, '.'
    jne NotDot
    test dl, 1
    jz Blank
    test cl, 1
    jz Blank
    inc pelletsLeft
    jmp Store
Blank:
    mov al, ' '
    jmp Store
NotDot:
    cmp al, 'O'
    jne Store
    inc pelletsLeft
Store:
    mov grid[edi], al
    inc edi
    inc edx
    cmp edx, NUM_COLS
    jb ColLoop
    inc ecx
    cmp ecx, NUM_ROWS
    jb RowLoop
    ret
LoadLevel ENDP

;---------------------------------------
; ResetPositions
; Puts Pacman and the ghosts back at their starting spots.
; Ghosts leave the house one second apart.
;---------------------------------------
ResetPositions PROC USES eax esi
    mov xPos, START_X
    mov yPos, START_Y
    mov playerDirection, DIR_NONE
    mov nextDirection, DIR_NONE
    mov playerTimer, 1
    mov frightTimer, 0

    xor esi, esi
GhostLoop:
    mov al, ghostSpawnX[esi]
    mov ghostX[esi], al
    mov al, ghostSpawnY[esi]
    mov ghostY[esi], al
    mov ghostDir[esi], DIR_UP
    mov ghostState[esi], 0
    mov eax, esi
    imul eax, 40
    add eax, ghostTicks
    mov ghostTimer[esi], al
    inc esi
    cmp esi, MAX_GHOSTS
    jb GhostLoop
    ret
ResetPositions ENDP

;---------------------------------------
; GameLoop
; Returns EAX = 0 if the player went back to the menu,
; 1 on game over, 2 when all three levels are cleared.
;---------------------------------------
GameLoop PROC
TickLoop:
    mov eax, TICK_MS
    call Delay

    call HandleInput
    cmp al, 1
    jne Continue
    mov eax, 0
    ret

Continue:
    dec playerTimer
    jnz SkipPlayer
    call MovePlayer
    call CheckCollisions
SkipPlayer:
    call MoveGhosts
    call CheckCollisions
    call UpdateTimers
    call DrawEntities

    cmp lives, 0
    jne StillAlive
    mov eax, 1
    ret

StillAlive:
    cmp pelletsLeft, 0
    jne TickLoop

    ; Level cleared
    cmp levelIndicator, 3
    jb NextLevel
    mov eax, 2
    ret

NextLevel:
    inc levelIndicator
    call LoadLevel
    call ResetPositions
    call DrawLevel
    call ShowReady
    jmp TickLoop
GameLoop ENDP

;---------------------------------------
; HandleInput
; Drains pending key presses. Returns AL = 1 if the player
; wants to go back to the menu, otherwise 0.
;---------------------------------------
HandleInput PROC USES ebx ecx edx
    mov cl, 0
KeyLoop:
    call ReadKey                ; ZF = 1 if no key (clobbers EBX)
    jz Done

    cmp dx, VK_UP
    je SetUp
    cmp dx, VK_DOWN
    je SetDown
    cmp dx, VK_LEFT
    je SetLeft
    cmp dx, VK_RIGHT
    je SetRight
    cmp dx, VK_ESCAPE
    je WantMenu

    or al, 20h                  ; lowercase letters
    cmp al, 'w'
    je SetUp
    cmp al, 's'
    je SetDown
    cmp al, 'a'
    je SetLeft
    cmp al, 'd'
    je SetRight
    cmp al, 'p'
    je PauseKey
    jmp KeyLoop

SetUp:
    mov nextDirection, DIR_UP
    jmp KeyLoop
SetDown:
    mov nextDirection, DIR_DOWN
    jmp KeyLoop
SetLeft:
    mov nextDirection, DIR_LEFT
    jmp KeyLoop
SetRight:
    mov nextDirection, DIR_RIGHT
    jmp KeyLoop
PauseKey:
    call PauseGame
    cmp al, 1
    je WantMenu
    jmp KeyLoop
WantMenu:
    mov cl, 1
Done:
    mov al, cl
    ret
HandleInput ENDP

;---------------------------------------
; PauseGame
; Waits for P (resume) or Esc (menu). Returns AL = 1 for Esc.
;---------------------------------------
PauseGame PROC USES ecx edx esi
    mov esi, OFFSET pausedMsg
    mov ecx, PAUSED_LEN
    call ShowBanner
WaitKey:
    call ReadChar
    cmp al, 27
    je ToMenu
    or al, 20h
    cmp al, 'p'
    jne WaitKey
    mov cl, 0
    jmp Restore
ToMenu:
    mov cl, 1
Restore:
    mov dh, NUM_ROWS - 1
    call DrawRow
    mov al, cl
    ret
PauseGame ENDP

;---------------------------------------
; MovePlayer
; Turns into the queued direction if it's open, otherwise keeps
; going until a wall.
;---------------------------------------
MovePlayer PROC USES eax ebx edx
    mov playerTimer, 1              ; retry next tick if blocked

    movzx ebx, nextDirection
    cmp ebx, DIR_NONE
    je TryCurrent
    mov dl, xPos
    mov dh, yPos
    call StepFrom
    call IsWall
    test eax, eax
    jnz TryCurrent
    mov playerDirection, bl

TryCurrent:
    movzx ebx, playerDirection
    cmp ebx, DIR_NONE
    je Done
    mov dl, xPos
    mov dh, yPos
    call StepFrom
    call IsWall
    test eax, eax
    jnz Done

    push edx
    mov dl, xPos
    mov dh, yPos
    call DrawCell                   ; erase Pacman's old spot
    pop edx
    mov xPos, dl
    mov yPos, dh
    call EatAt

    mov playerTimer, PLAYER_TICKS
    cmp ebx, DIR_LEFT
    jae Done
    mov playerTimer, PLAYER_TICKS * 2
Done:
    ret
MovePlayer ENDP

;---------------------------------------
; EatAt
; Scores whatever is under Pacman.
;---------------------------------------
EatAt PROC USES eax ebx ecx edx
    mov dl, xPos
    mov dh, yPos
    call GridIndex
    mov ebx, eax
    mov al, grid[ebx]
    cmp al, '.'
    je Pellet
    cmp al, 'O'
    je Power
    ret

Pellet:
    mov grid[ebx], ' '
    add score, 10
    dec pelletsLeft
    cmp chompCooldown, 0
    jne UpdateHud
    INVOKE PlaySound, OFFSET musicChomp, 0, SND_FILENAME
    mov chompCooldown, 16
    jmp UpdateHud

Power:
    mov grid[ebx], ' '
    add score, 50
    dec pelletsLeft
    INVOKE PlaySound, OFFSET musicFruit, 0, SND_FILENAME
    mov chompCooldown, 16
    call FrightenGhosts

UpdateHud:
    call DrawHud
    ret
EatAt ENDP

;---------------------------------------
; FrightenGhosts
; Turns every ghost blue and reverses it.
;---------------------------------------
FrightenGhosts PROC USES esi
    mov frightTimer, FRIGHT_TICKS
    xor esi, esi
FLoop:
    mov ghostState[esi], 1
    xor ghostDir[esi], 1
    inc esi
    cmp esi, MAX_GHOSTS
    jb FLoop
    ret
FrightenGhosts ENDP

;---------------------------------------
; UpdateTimers
;---------------------------------------
UpdateTimers PROC USES esi
    cmp chompCooldown, 0
    je CheckFright
    dec chompCooldown
CheckFright:
    cmp frightTimer, 0
    je Done
    dec frightTimer
    jnz Done
    xor esi, esi
CalmLoop:
    mov ghostState[esi], 0
    inc esi
    cmp esi, MAX_GHOSTS
    jb CalmLoop
Done:
    ret
UpdateTimers ENDP

;---------------------------------------
; MoveGhosts
; Steps every ghost whose timer has run out.
;---------------------------------------
MoveGhosts PROC USES eax ebx edx esi
    xor esi, esi
GhostLoop:
    movzx eax, numGhosts
    cmp esi, eax
    jae Done

    dec ghostTimer[esi]
    jnz NextGhost

    call ChooseGhostDir             ; BL = direction
    mov ghostDir[esi], bl
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    call StepFrom
    call IsWall
    test eax, eax
    jnz ResetTimer

    push edx
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    call DrawCell                   ; erase the ghost's old spot
    pop edx
    mov ghostX[esi], dl
    mov ghostY[esi], dh

ResetTimer:
    mov eax, ghostTicks
    cmp bl, DIR_LEFT
    jae Horizontal
    shl eax, 1                      ; rows take twice as long
Horizontal:
    cmp ghostState[esi], 1
    jne SetTimer
    shl eax, 1                      ; frightened ghosts are slower
SetTimer:
    mov ghostTimer[esi], al

NextGhost:
    inc esi
    jmp GhostLoop
Done:
    ret
MoveGhosts ENDP

;---------------------------------------
; ChooseGhostDir
; Receives: ESI = ghost index
; Returns:  BL = direction
; Ghosts never reverse unless they're stuck. Inside the house they
; head for the exit, frightened ghosts wander, and otherwise they
; chase Pacman chaseChance% of the time.
;---------------------------------------
ChooseGhostDir PROC USES eax ecx edx edi
    LOCAL bestDist:DWORD, bestDir:BYTE

    ; Collect open directions, excluding a U-turn
    xor edi, edi
    xor ebx, ebx
CandLoop:
    movzx eax, ghostDir[esi]
    xor eax, 1
    cmp ebx, eax
    je NextCand
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    call StepFrom
    call IsWall
    test eax, eax
    jnz NextCand
    mov candDirs[edi], bl
    inc edi
NextCand:
    inc ebx
    cmp ebx, 4
    jb CandLoop

    test edi, edi
    jnz HaveCands
    movzx ebx, ghostDir[esi]        ; dead end: turn around
    xor ebx, 1
    ret

HaveCands:
    ; Inside the house: head for the exit
    mov al, ghostX[esi]
    cmp al, HOUSE_LEFT
    jb Outside
    cmp al, HOUSE_RIGHT
    ja Outside
    mov al, ghostY[esi]
    cmp al, HOUSE_TOP
    jb Outside
    cmp al, HOUSE_BOTTOM
    ja Outside
    mov targetX, HOUSE_EXIT_X
    mov targetY, HOUSE_EXIT_Y
    jmp Greedy

Outside:
    cmp ghostState[esi], 1
    je Wander
    mov eax, 100
    call RandomRange
    movzx ecx, levelIndicator
    cmp al, chaseChance[ecx - 1]
    jae Wander
    mov al, xPos
    mov targetX, al
    mov al, yPos
    mov targetY, al
    jmp Greedy

Wander:
    mov eax, edi
    call RandomRange
    movzx ebx, candDirs[eax]
    ret

Greedy:
    mov bestDist, 0FFFFh
    xor ecx, ecx
GreedyLoop:
    movzx ebx, candDirs[ecx]
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    call StepFrom
    call DistanceToTarget
    cmp eax, bestDist
    jae NotBetter
    mov bestDist, eax
    mov bestDir, bl
NotBetter:
    inc ecx
    cmp ecx, edi
    jb GreedyLoop
    movzx ebx, bestDir
    ret
ChooseGhostDir ENDP

;---------------------------------------
; DistanceToTarget
; Receives: DL, DH = position
; Returns:  EAX = |x - targetX| + |y - targetY|
;---------------------------------------
DistanceToTarget PROC USES ebx ecx
    movzx eax, dl
    movzx ecx, targetX
    sub eax, ecx
    jns PosX
    neg eax
PosX:
    movzx ebx, dh
    movzx ecx, targetY
    sub ebx, ecx
    jns PosY
    neg ebx
PosY:
    add eax, ebx
    ret
DistanceToTarget ENDP

;---------------------------------------
; CheckCollisions
; Eats frightened ghosts, otherwise costs a life.
;---------------------------------------
CheckCollisions PROC USES eax ecx edx esi
    xor esi, esi
CLoop:
    movzx eax, numGhosts
    cmp esi, eax
    jae Done
    mov al, ghostX[esi]
    cmp al, xPos
    jne NextGhost
    mov al, ghostY[esi]
    cmp al, yPos
    jne NextGhost

    cmp ghostState[esi], 1
    jne Caught
    add score, 200
    INVOKE PlaySound, OFFSET musicEatGhost, 0, SND_FILENAME
    mov al, ghostSpawnX[esi]
    mov ghostX[esi], al
    mov al, ghostSpawnY[esi]
    mov ghostY[esi], al
    mov ghostDir[esi], DIR_UP
    mov ghostState[esi], 0
    mov eax, ghostTicks
    shl eax, 2
    mov ghostTimer[esi], al
    call DrawHud
    jmp NextGhost

Caught:
    call PlayerDied
    jmp Done

NextGhost:
    inc esi
    jmp CLoop
Done:
    ret
CheckCollisions ENDP

;---------------------------------------
; PlayerDied
;---------------------------------------
PlayerDied PROC
    INVOKE PlaySound, OFFSET musicDeath, 0, SND_FILENAME
    dec lives
    call DrawHud
    mov eax, 1500
    call Delay
    call EraseEntities
    cmp lives, 0
    je Done
    call ResetPositions
    call DrawEntities
    call ShowReady
Done:
    ret
PlayerDied ENDP

;---------------------------------------
; Grid helpers
;---------------------------------------
; GridIndex: DL = x, DH = y. Returns EAX = index into grid.
GridIndex PROC USES ecx
    movzx eax, dh
    imul eax, NUM_COLS
    movzx ecx, dl
    add eax, ecx
    ret
GridIndex ENDP

; IsWall: DL = x, DH = y. Returns EAX = 1 for a wall, else 0.
IsWall PROC
    call GridIndex
    mov al, grid[eax]
    cmp al, '#'
    je Yes
    cmp al, '|'
    je Yes
    cmp al, '-'
    je Yes
    mov eax, 0
    ret
Yes:
    mov eax, 1
    ret
IsWall ENDP

; StepFrom: DL = x, DH = y, BL = direction. Returns the next cell in DL, DH.
StepFrom PROC USES eax ebx
    movzx ebx, bl
    mov al, dirDX[ebx]
    add dl, al
    mov al, dirDY[ebx]
    add dh, al
    ret
StepFrom ENDP

;---------------------------------------
;Draw Functions
; Everything in the playfield is written with WriteConsoleOutput*,
; which doesn't move the cursor, so drawing the bottom-right cell
; never scrolls the window.
;---------------------------------------

; CellColor: AL = maze character. Returns AH = attribute.
CellColor PROC
    mov ah, lightGray
    cmp al, '#'
    je Block
    cmp al, '|'
    je Block
    cmp al, '-'
    je Block
    cmp al, 'O'
    jne Done
    mov ah, white
    ret
Block:
    mov ah, lightBlue
Done:
    ret
CellColor ENDP

; PutChar: DL = x, DH = y, AL = character, AH = attribute
PutChar PROC USES eax ecx edx
    mov charBuf[0], al
    movzx cx, ah
    mov attrBuf[0], cx
    movzx cx, dl
    mov cellCoord.X, cx
    movzx cx, dh
    mov cellCoord.Y, cx
    INVOKE WriteConsoleOutputCharacter, consoleOut, ADDR charBuf, 1, cellCoord, ADDR charsWritten
    INVOKE WriteConsoleOutputAttribute, consoleOut, ADDR attrBuf, 1, cellCoord, ADDR charsWritten
    ret
PutChar ENDP

; PutString: DL = x, DH = y, ESI = text, ECX = length, AH = attribute
PutString PROC USES eax ebx ecx edx
    mov ebx, ecx
    movzx ax, ah
FillAttr:
    mov attrBuf[ecx*2 - 2], ax
    loop FillAttr
    movzx cx, dl
    mov cellCoord.X, cx
    movzx cx, dh
    mov cellCoord.Y, cx
    INVOKE WriteConsoleOutputCharacter, consoleOut, esi, ebx, cellCoord, ADDR charsWritten
    INVOKE WriteConsoleOutputAttribute, consoleOut, ADDR attrBuf, ebx, cellCoord, ADDR charsWritten
    ret
PutString ENDP

; DrawCell: DL = x, DH = y. Redraws the maze character there.
DrawCell PROC USES eax
    call GridIndex
    mov al, grid[eax]
    call CellColor
    call PutChar
    ret
DrawCell ENDP

; DrawRow: DH = row
DrawRow PROC USES eax ecx edx esi
    movzx eax, dh
    imul eax, NUM_COLS
    lea esi, grid[eax]
    xor ecx, ecx
RowLoop:
    mov al, [esi + ecx]
    call CellColor
    movzx ax, ah
    mov attrBuf[ecx*2], ax
    inc ecx
    cmp ecx, NUM_COLS
    jb RowLoop
    mov cellCoord.X, 0
    movzx cx, dh
    mov cellCoord.Y, cx
    INVOKE WriteConsoleOutputCharacter, consoleOut, esi, NUM_COLS, cellCoord, ADDR charsWritten
    INVOKE WriteConsoleOutputAttribute, consoleOut, ADDR attrBuf, NUM_COLS, cellCoord, ADDR charsWritten
    ret
DrawRow ENDP

; DrawLevel: whole maze, HUD, Pacman and ghosts
DrawLevel PROC USES edx
    call Clrscr
    mov dh, 0
DrawLoop:
    call DrawRow
    inc dh
    cmp dh, NUM_ROWS
    jb DrawLoop
    call DrawHud
    call DrawEntities
    ret
DrawLevel ENDP

; DrawHud: score, lives and level over the top border
DrawHud PROC USES eax ebx ecx edx esi
    mov eax, score
    mov ebx, 10
    mov ecx, 6
    mov esi, OFFSET hudScore + 5
Digit:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [esi], dl
    dec esi
    loop Digit

    mov al, lives
    add al, '0'
    mov hudLives, al
    mov al, levelIndicator
    add al, '0'
    mov hudLevel, al

    mov dl, 4
    mov dh, 0
    mov esi, OFFSET hudBuf
    mov ecx, HUD_LEN
    mov ah, yellow
    call PutString
    ret
DrawHud ENDP

; ShowBanner: ESI = text, ECX = length. Centered on the bottom border.
ShowBanner PROC USES eax edx
    mov eax, NUM_COLS
    sub eax, ecx
    shr eax, 1
    mov dl, al
    mov dh, NUM_ROWS - 1
    mov ah, black + (yellow * 16)
    call PutString
    ret
ShowBanner ENDP

; ShowReady: "READY!" for a moment before play starts
ShowReady PROC USES eax ecx edx esi
    mov esi, OFFSET readyMsg
    mov ecx, READY_LEN
    call ShowBanner
    mov eax, 1500
    call Delay
    mov dh, NUM_ROWS - 1
    call DrawRow
    ret
ShowReady ENDP

DrawPacman PROC USES eax edx
    mov dl, xPos
    mov dh, yPos
    mov al, pacman
    mov ah, yellow
    call PutChar
    ret
DrawPacman ENDP

; DrawGhost: ESI = ghost index
DrawGhost PROC USES eax edx
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    mov al, G1[esi]
    mov ah, ghostColors[esi]
    cmp ghostState[esi], 1
    jne Draw
    mov ah, FRIGHT_COLOR
Draw:
    call PutChar
    ret
DrawGhost ENDP

; DrawEntities: Pacman, then ghosts on top
DrawEntities PROC USES eax esi
    call DrawPacman
    xor esi, esi
GLoop:
    movzx eax, numGhosts
    cmp esi, eax
    jae Done
    call DrawGhost
    inc esi
    jmp GLoop
Done:
    ret
DrawEntities ENDP

; EraseEntities: restore the maze under Pacman and every ghost
EraseEntities PROC USES eax edx esi
    mov dl, xPos
    mov dh, yPos
    call DrawCell
    xor esi, esi
ELoop:
    movzx eax, numGhosts
    cmp esi, eax
    jae Done
    mov dl, ghostX[esi]
    mov dh, ghostY[esi]
    call DrawCell
    inc esi
    jmp ELoop
Done:
    ret
EraseEntities ENDP

;---------------------------------------
; Cursor helpers
;---------------------------------------
HideCursor PROC USES eax ecx edx
    mov cursorInfo.bVisible, 0
    INVOKE SetConsoleCursorInfo, consoleOut, ADDR cursorInfo
    ret
HideCursor ENDP

ShowCursor PROC USES eax ecx edx
    mov cursorInfo.bVisible, 1
    INVOKE SetConsoleCursorInfo, consoleOut, ADDR cursorInfo
    ret
ShowCursor ENDP

;---------------------------------------
; GameOverScreen
; Receives: EAX = 1 for game over, 2 for a win
;---------------------------------------
GameOverScreen PROC USES eax edx
    push eax
    INVOKE PlaySound, 0, 0, 0
    call Clrscr
    pop eax

    mov dl, 55
    mov dh, rowCenter
    sub dh, 2
    call GoToXY
    mov edx, OFFSET gameOverMsg
    cmp eax, 2
    jne ShowTitle
    mov edx, OFFSET winMsg
ShowTitle:
    mov eax, yellow
    call SetTextColor
    call WriteString
    mov eax, white
    call SetTextColor

    mov dl, 52
    mov dh, rowCenter
    call GoToXY
    mov edx, OFFSET finalScoreMsg
    call WriteString
    mov eax, score
    call WriteDec

    mov dl, 45
    mov dh, rowCenter
    add dh, 3
    call GoToXY
    call WaitMsg
    ret
GameOverScreen ENDP

;---------------------------------------
; High Scores
; Top MAX_SCORES names and scores, kept sorted and saved to fileName.
;---------------------------------------
LoadHighScores PROC USES eax ecx edx
    mov edx, OFFSET fileName
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je Done
    push eax
    mov edx, OFFSET hsNames
    mov ecx, HS_SIZE
    call ReadFromFile
    pop eax
    call CloseFile
Done:
    ret
LoadHighScores ENDP

SaveHighScores PROC USES eax ecx edx
    mov edx, OFFSET fileName
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je Done
    push eax
    mov edx, OFFSET hsNames
    mov ecx, HS_SIZE
    call WriteToFile
    pop eax
    call CloseFile
Done:
    ret
SaveHighScores ENDP

; RecordHighScore: asks for a name if score makes the table
RecordHighScore PROC USES eax ebx ecx edx esi edi
    mov eax, score
    test eax, eax
    jz Done
    cmp eax, hsScores[(MAX_SCORES - 1) * 4]
    jbe Done

    call Clrscr
    mov dl, 35
    mov dh, rowCenter
    call GoToXY
    mov edx, OFFSET newHighMsg
    call WriteString

    cld
    mov edi, OFFSET nameInputBuffer
    mov ecx, SIZEOF nameInputBuffer
    xor al, al
    rep stosb

    call ShowCursor
    mov edx, OFFSET nameInputBuffer
    mov ecx, NAME_LEN
    call ReadString
    call HideCursor
    test eax, eax
    jnz HaveName
    INVOKE Str_copy, ADDR defaultName, ADDR nameInputBuffer
HaveName:
    mov nameInputBuffer[NAME_LEN - 1], 0

    ; Find the slot
    xor esi, esi
    mov eax, score
FindSlot:
    cmp eax, hsScores[esi*4]
    ja Found
    inc esi
    jmp FindSlot
Found:
    ; Shift lower entries down one place
    mov ebx, MAX_SCORES - 1
Shift:
    cmp ebx, esi
    jbe Insert
    mov eax, hsScores[ebx*4 - 4]
    mov hsScores[ebx*4], eax
    push esi
    mov eax, ebx
    dec eax
    imul eax, NAME_LEN
    lea esi, hsNames[eax]
    mov eax, ebx
    imul eax, NAME_LEN
    lea edi, hsNames[eax]
    mov ecx, NAME_LEN
    rep movsb
    pop esi
    dec ebx
    jmp Shift

Insert:
    mov eax, score
    mov hsScores[esi*4], eax
    mov eax, esi
    imul eax, NAME_LEN
    lea edi, hsNames[eax]
    mov esi, OFFSET nameInputBuffer
    mov ecx, NAME_LEN
    rep movsb

    call SaveHighScores
    call ShowHighScores
Done:
    ret
RecordHighScore ENDP

ShowHighScores PROC USES eax ecx edx esi
    call Clrscr
    mov dl, 54
    mov dh, 8
    call GoToXY
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET highScoresMsg
    call WriteString
    mov eax, white
    call SetTextColor

    cmp hsScores[0], 0
    jne ListScores
    mov dl, 50
    mov dh, 10
    call GoToXY
    mov edx, OFFSET noScoresMsg
    call WriteString
    jmp WaitForKey

ListScores:
    xor esi, esi
ScoreLoop:
    cmp hsScores[esi*4], 0
    je WaitForKey
    mov dl, 48
    mov eax, esi
    add al, 10
    mov dh, al
    call GoToXY
    mov eax, esi
    inc eax
    call WriteDec
    mwrite ". "
    mov eax, esi
    imul eax, NAME_LEN
    lea edx, hsNames[eax]
    call WriteString
    mov dl, 68
    mov eax, esi
    add al, 10
    mov dh, al
    call GoToXY
    mov eax, hsScores[esi*4]
    call WriteDec
    inc esi
    cmp esi, MAX_SCORES
    jb ScoreLoop

WaitForKey:
    mov dl, 45
    mov dh, 18
    call GoToXY
    call WaitMsg
    ret
ShowHighScores ENDP

END main
