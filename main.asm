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
G5             DB "^"

;----------------------------------------
; Grid and Buffer Definitions
;----------------------------------------
grid           db NUM_COLS * NUM_ROWS dup(0)   ; Grid to store the maze
inputBuffer    db 20 dup(0)                     ; Input buffer for user input
welcomeMsg     db "Pacman", 0                   ; Welcome message
menuMsg        db "1. Start Game", 0            ; Menu option 1
menuMsg2       db "2. Select Level", 0          ; Menu option 2
menuMsg3       db "3. Instructions", 0          ; Menu option 3
menuMsg4       db "4. High Scores", 0           ; Menu option 4
menuMsg5       db "5. Exit", 0                  ; Menu option 5
instructionsMsg db "Instructions: Use arrow keys to move Pacman. Eat all the dots and avoid the ghosts!", 0
highScoresMsg  db "High Scores: ", 0            ; High Scores message

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
xPos           db 0                            ; Player X position
yPos           db 0                            ; Player Y position
playerStatus   db 1                            ; Player status (1 = alive, 0 = dead)
inputChar      db ?                            ; Last input character

;----------------------------------------
; Ghost Positions (Initial)
;----------------------------------------
; Level 1 Ghost Positions
xG1            DB 10
yG1            DB 10
xG2            DB 10
yG2            DB 10

; Level 2 Ghost Positions
xG3            DB 10
yG3            DB 10

; Level 3 Ghost Positions
xG4            DB 10
yG4            DB 10
xG5            DB 10
yG5            DB 10

        
    ;----------------------------------------
    ;Maze Level 1
    ;----------------------------------------
    maze1  db "------------------------------------------------------------------------------------------------------------------------",0
    maze2  db "|.................#####..........................................................................#####.................|",0
    maze3  db "|.................#####..........................................................................#####.................|",0
    maze4  db "|.................#####..........................................................................#####.................|",0
    maze5  db "|.................#####..........................................................................#####.................|",0
    maze6  db "|.................#####..........................................................................#####.................|",0
    maze7  db "|......................................................................................................................|",0
    maze8  db "|......................................................................................................................|",0
    maze9  db "|..................##............................##.......................##........................##.................|",0
    maze10 db "|..................##.##########################.##.......................##.######################.##.................|",0
    maze11 db "|..................##............................##.......................##........................##.................|",0
    maze12 db "|......................................................................................................................|",0
    maze13 db "|......................................................##          ##..................................................|",0
    maze14 db "|......................................................##          ##..................................................|",0
    maze15 db "|......................................................##   GHOST  ##..................................................|",0
    maze16 db "|......................................................##   HOUSE  ##..................................................|",0
    maze17 db "|......................................................##          ##..................................................|",0
    maze18 db "|......................................................##############..................................................|",0
    maze19 db "|......................................................................................................................|",0
    maze20 db "|..................##............................##.......................##........................##.................|",0
    maze21 db "|..................##.##########################.##.......................##.######################.##.................|",0
    maze22 db "|..................##............................##.......................##........................##.................|",0
    maze23 db "|.............................................................#........................................................|",0
    maze24 db "|.............................................................#........................................................|",0
    maze25 db "|.................#####.......................................#.............................#####......................|",0
    maze26 db "|.................#####.......................................#.............................#####......................|",0
    maze27 db "|.................#####.......................................#.............................#####......................|",0
    maze28 db "|.................#####.......................................#.............................#####......................|",0
    maze29 db "|.................#####.....................................................................#####......................|",0
    maze30 db "------------------------------------------------------------------------------------------------------------------------",0


.code
main PROC
    
    ;Initialize screen
    call Clrscr

    ;Welcome Screen
    call displayWelcome

    ;Wait msg for debugging
    mov dl, colCenter
    sub dl, 10
    mov dh, 29
    call GoToXY
    call WaitMsg

    ;Reset Screen after delay
    call Clrscr

    ;Display Menu
    call displayMenu

    ;Draw Maze
    call CreateLevel1


    ;Stop Music
    INVOKE PlaySound, 0, 0, 0
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

    ;mov eax, 3000 ;Set to 1 second for debugging, change to 3 later
    ;call Delay
    ret
displayWelcome ENDP

;---------------------------------------
;Menu Screen Proc
;---------------------------------------
displayMenu PROC

    mov eax, NUM_COLS
    sub eax, 13 ; Length of "1. Start Game"
    sub eax, 5 ;Adjust 
    mov ecx, 2
    mov edx, 0
    div ecx
    mov colCenter, al
    ;Move row center up by 2
    movzx eax, rowCenter
    sub eax, 2
    mov rowCenter, al
    ;No need to recalculate middle row
    mov dl, colCenter
    mov dh, rowCenter
    call GoToXY
    mov edx, offset menuMsg
    call writestring
    mov dl, colCenter
    mov dh, rowCenter
    add dh,1
    call GoToXY
    mov edx, offset menuMsg2
    call writestring
    mov dl, colCenter
    mov dh, rowCenter
    add dh,2
    call GoToXY
    mov edx, offset menuMsg3
    call writestring
    mov dl, colCenter
    mov dh, rowCenter
    add dh,3
    call GoToXY
    mov edx, offset menuMsg4
    call writestring
    mov dl, colCenter
    mov dh, rowCenter
    add dh,4
    call GoToXY
    mov edx, offset menuMsg5
    call writestring
    ;Wait Msg only for temporary debugging 
    mov dl, colCenter
    mov dh, rowCenter
    add dh,5
    call GoToXY
    call WaitMsg

    ret
displayMenu ENDP

;---------------------------------------
;Menu Selection Proc

;---------------------------------------
;Create Level 1
;---------------------------------------
CreateLevel1 PROC

    mov dx, 0
    call GoToXY
    call Clrscr
    mov edx, offset maze1
    call writestring
    call crlf
    mov edx, offset maze2
    call writestring
    call crlf
    mov edx, offset maze3
    call writestring
    call crlf
    mov edx, offset maze4
    call writestring
    call crlf
    mov edx, offset maze5
    call writestring
    call crlf
    mov edx, offset maze6
    call writestring
    call crlf
    mov edx, offset maze7
    call writestring
    call crlf
    mov edx, offset maze8
    call writestring
    call crlf
    mov edx, offset maze9
    call writestring
    call crlf
    mov edx, offset maze10
    call writestring
    call crlf
    mov edx, offset maze11
    call writestring
    call crlf
    mov edx, offset maze12
    call writestring
    call crlf
    mov edx, offset maze13
    call writestring
    call crlf
    mov edx, offset maze14
    call writestring
    call crlf
    mov edx, offset maze15
    call writestring
    call crlf
    mov edx, offset maze16
    call writestring
    call crlf
    mov edx, offset maze17
    call writestring
    call crlf
    mov edx, offset maze18
    call writestring
    call crlf
    mov edx, offset maze19
    call writestring
    call crlf
    mov edx, offset maze20
    call writestring
    call crlf
    mov edx, offset maze21
    call writestring
    call crlf
    mov edx, offset maze22
    call writestring
    call crlf
    mov edx, offset maze23
    call writestring
    call crlf
    mov edx, offset maze24
    call writestring
    call crlf
    mov edx, offset maze25
    call writestring
    call crlf
    mov edx, offset maze26
    call writestring
    call crlf
    mov edx, offset maze27
    call writestring
    call crlf
    mov edx, offset maze28
    call writestring
    call crlf
    mov edx, offset maze29
    call writestring
    call crlf
    mov edx, offset maze30
    call writestring
    call crlf
    ret
CreateLevel1 ENDP   

END main

