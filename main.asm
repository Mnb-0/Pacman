INCLUDE Irvine32.inc
INCLUDE macros.inc
INCLUDELIb winmm.lib

;Column Center Formula : (Number of Columns - Length of String)/2
;Row Center Formula : Number of Rows / 2
;2623 -> 2663-> 2 blocks then 6 blocks then 6 blocks then 3 blocks
NUM_COLS = 120
NUM_ROWS = 30



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
tempMusic      db " ", 0

; Sound Flags
SND_FILENAME   DWORD 00020001h  ; Sound file name flag
SND_ASYNC      DWORD 00000001h  ; Asynchronous flag
SND_LOOP       DWORD 00000008h  ; Loop flag
SND_FLAGS      DWORD 20009h     ; Combined flags (SND_FILENAME OR SND_ASYNC OR SND_LOOP)

;----------------------------------------
; File Constants
;----------------------------------------
fileName       db "highscores.txt", 0
filetemp       db "temp.txt", 0
fileHandle     HANDLE ?

;----------------------------------------
; Game Constants
;----------------------------------------
; Speeds for different levels
L1_Speed       DWORD 150
L2_Speed       DWORD 125
L3_Speed       DWORD 100

; Characters for game elements
wall           db "#"
coin           db "."
space          db " "
pacman         db "X"

; Ghost Symbols
G1             DB "!"
G2             DB "@"
G3             DB "$"
G4             DB "%"
G5             DB "&"

;----------------------------------------
; Grid and Buffer Definitions
;----------------------------------------
grid            db NUM_COLS * NUM_ROWS dup(0)    ; Grid to store the maze
inputBuffer     db 20 dup(0)                     ; Input buffer for user input
welcomeMsg      db "Pacman", 0                   ; Welcome message
menuMsg         db "1. Start Game", 0            ; Menu option 1
altMenuMsg     db  "1. Resume Game", 0           ; Alternative menu option when paused
menuMsg2        db "2. Select Level", 0          ; Menu option 2
menuMsg3        db "3. Instructions", 0          ; Menu option 3
menuMsg4        db "4. High Scores", 0           ; Menu option 4
menuMsg5        db "5. Exit -> Any Key", 0       ; Menu option 5
instructionsMsg db "Instructions: Use arrow keys to move Pacman. Eat all the dots and avoid the ghosts!", 0
highScoresMsg   db "High Scores: ", 0            ; High Scores message

; Centering positions
colCenter      db 0
rowCenter      db 0

; Game State Data
lives          db 3                            ; Player lives
score          dd 0                            ; Player score

; Player movement and state
nameInputBuffer DB 20 dup(0)                   ; Buffer for player name input
buffer         db 255 DUP(0)                   ; General buffer
scoreBuffer    db 255 DUP(0)                   ; Buffer for score input

playerDirection    db 1                        ; Movement direction (0: Down, 1: Up, 2: Left, 3: Right)
playerMovePossible db 1                        ; If player can move

; Ghosts' Movement Handlers
G1Direction   db 1
G1MovePossible db 1

G2Direction   db 1
G2MovePossible db 1

G3Direction   db 1
G3MovePossible db 1

G4Direction   db 1
G4MovePossible db 1

G5Direction   db 1
G5MovePossible db 1

;----------------------------------------
; Ghosts' Status and Movement
;----------------------------------------
G1Status      db 1                            ; Ghost 1 status
G2Status      db 1                            ; Ghost 2 status
G3Status      db 1                            ; Ghost 3 status
G4Status      db 1                            ; Ghost 4 status
G5Status      db 1                            ; Ghost 5 status

levelIndicator db 1                           ; Current level
GameStateHandler db 1                         ; Game state handler (e.g., paused, running)

;----------------------------------------
; Player Position and Status
;----------------------------------------
xPos           db 2                            ; Player X position
yPos           db 2                            ; Player Y position
playerStatus   db 1                            ; Player status (1 = alive, 0 = dead)
inputChar      db ?                            ; Last input character

;----------------------------------------
; Ghost Positions (Initial)
;----------------------------------------
; Level 1 Ghost Positions
xG1            DB 62
yG1            DB 15
xG2            DB 62
yG2            DB 15

; Level 2 Ghost Positions
xG3            DB 62
yG3            DB 15

; Level 3 Ghost Positions
xG4            DB 62
yG4            DB 15
xG5            DB 62
yG5            DB 15
        
;----------------------------------------
; Maze Level 1
;----------------------------------------
maze1  db "------------------------------------------------------------------------------------------------------------------------", 0
maze2  db "|.................#####..........................................................................#####.................|", 0
maze3  db "|.................#####..........................................................................#####.................|", 0
maze4  db "|.................#####..........................................................................#####.................|", 0
maze5  db "|.................#####..........................................................................#####.................|", 0
maze6  db "|.................#####..........................................................................#####.................|", 0
maze7  db "|......................................................................................................................|", 0
maze8  db "|......................................................................................................................|", 0
maze9  db "|..................##............................##.......................##........................##.................|", 0
maze10 db "|..................##.##########################.##.......................##.######################.##.................|", 0
maze11 db "|..................##............................##.......................##........................##.................|", 0
maze12 db "|......................................................................................................................|", 0
maze13 db "|......................................................##          ##..................................................|", 0
maze14 db "|......................................................##          ##..................................................|", 0
maze15 db "|......................................................##          ##..................................................|", 0
maze16 db "|......................................................##          ##..................................................|", 0
maze17 db "|......................................................##          ##..................................................|", 0
maze18 db "|......................................................##############..................................................|", 0
maze19 db "|......................................................................................................................|", 0
maze20 db "|..................##............................##.......................##........................##.................|", 0
maze21 db "|..................##.##########################.##.......................##.######################.##.................|", 0
maze22 db "|..................##............................##.......................##........................##.................|", 0
maze23 db "|.............................................................#........................................................|", 0
maze24 db "|.............................................................#........................................................|", 0
maze25 db "|.................#####.......................................#.............................#####......................|", 0
maze26 db "|.................#####.......................................#.............................#####......................|", 0
maze27 db "|.................#####.......................................#.............................#####......................|", 0
maze28 db "|.................#####.......................................#.............................#####......................|", 0
maze29 db "|.................#####.....................................................................#####......................|", 0
maze30 db "------------------------------------------------------------------------------------------------------------------------", 0


level1 DWORD OFFSET maze1, OFFSET maze2, OFFSET maze3, OFFSET maze4, OFFSET maze5, OFFSET maze6, OFFSET maze7, OFFSET maze8, OFFSET maze9, OFFSET maze10, OFFSET maze11, OFFSET maze12, OFFSET maze13, OFFSET maze14, OFFSET maze15, OFFSET maze16, OFFSET maze17, OFFSET maze18, OFFSET maze19, OFFSET maze20, OFFSET maze21, OFFSET maze22, OFFSET maze23, OFFSET maze24, OFFSET maze25, OFFSET maze26, OFFSET maze27, OFFSET maze28, OFFSET maze29, OFFSET maze30

.code
main PROC
    
    ;Initialize the console
    call Clrscr

    ;Welcome Screen
    call displayWelcome

Menu:
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
    cmp al, '5'
    jmp ExitGame
    jmp Menu ; fallback

StartGame:
    call Clrscr
    call CreateLevel1
    call readchar
    ;call GameLoop
    call ClrScr
    jmp Menu

SelectLevel:
    ; Future implementation
    jmp Menu

Instructions:
    call Clrscr
    call displayInstructions
    jmp Menu

HighScores:
    ; Future implementation
    jmp Menu




    ExitGame:

    call Clrscr
    exit
main ENDP
temp proc
        ;Initialize screen
    call Clrscr

    ;Welcome Screen
    call displayWelcome

    ;Wait msg for debugging
    

    ;Reset Screen after delay
    call Clrscr

    ;Display Menu
    call displayMenu

    ;Draw Maze
    call CreateLevel1


    ;Stop Music
    INVOKE PlaySound, 0, 0, 0
temp endp
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

    ;mov eax, 3000 ;Set to 1 second for debugging, change to 3 later
    ;call Delay

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
    sub eax, 13         ; Length of "Instructions"
    sub eax, 5          ; Adjust
    xor edx, edx
    mov ecx, 2
    div ecx
    mov tempCol, al

    ; Adjust row center up by 2
    movzx eax, rowCenter
    sub eax, 2
    mov tempRow, al

    ; Move cursor to calculated center
    mov dl, tempCol
    mov dh, tempRow
    call GoToXY

    ; Print instructions
    call Crlf
    mwrite "Instructions: Use arrow keys to move Pacman. Eat all the dots and avoid the ghosts!"

    ; Wait message two lines below
    mov dl, 0
    mov dh, tempRow
    add dh, 2
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

    ; Menu Line 1
    mov dl, tempCol
    mov dh, tempRow
    call GoToXY
    mov edx, offset menuMsg
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
;Menu Selection Proc
;--------------------------------------
;---------------------------------------
;Create Level 1
;---------------------------------------
CreateLevel1 PROC
    ; Reset cursor to top-left
    mov edx, 0
    call GoToXY
    call Clrscr

    mov ecx, 30               ; Number of rows
    mov esi, OFFSET level1    ; Address of the maze array

print_loop:
    lodsd                     ; Load DWORD [esi] into eax, increment esi by 4
    mov edx, eax              ; edx = offset to maze line
    call WriteString
    call Crlf
    loop print_loop

    ret
CreateLevel1 ENDP

;---------------------------------------
;Draw Functions
;---------------------------------------

DrawBlock PROC

DrawBlock ENDP

DrawPellet PROC

DrawPellet ENDP

DrawGhost PROC
DrawGhost ENDP

DrawPacman PROC
DrawPacman ENDP

END main