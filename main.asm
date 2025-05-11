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


    grid        db  NUM_COLS * NUM_ROWS dup(0)
    inputBuffer db  20 dup(0)
    welcomeMsg  db  "Pacman",0
    menuMsg     db  "1. Start Game",0
    menuMsg2    db  "2. Select Level",0
    menuMsg3    db  "3. Instructions",0
    menuMsg4    db  "4. High Scores",0
    menuMsg5    db  "5. Exit",0
    colCenter   db  0
    rowCenter   db  0

    ;----------------------------------------
    ;Music
    ;----------------------------------------
    musicIntro db "pacman_beginning.wav",0
    musicChomp db "pacman_chomp.wav",0
    musicDeath db "pacman_death.wav",0
    musicFruit db "pacman_eatfruit.wav",0
    tempMusic db " ",0
    SND_FILENAME DWORD 00020001h
    SND_ASYNC DWORD 00000001h
    SND_LOOP DWORD 00000008h
    SND_FLAGS DWORD 20009h ;OR SND_ASYNC and SND_FILENAME and SND_LOOP

.code
main PROC
    
    ;Initialize screen

    call Clrscr

    ;Play Intro Music
    INVOKE PlaySound, OFFSET musicIntro, 0, SND_FLAGS

    ;Welcome Screen

    call WelcomeScreen

    ;Reset Screen after delay
    call Clrscr

    ;Display Menu
    call MenuScreen

    ;Draw Maze
    call CreateLevel1

    ;wait msg
    call WaitMsg

    ;Stop Music
    INVOKE PlaySound, 0, 0, 0
    exit
main ENDP

;---------------------------------------
;Welcome Screen Proc
;---------------------------------------
WelcomeScreen PROC
    
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

    mov eax, 3000 ;Set to 1 second for debugging, change to 3 later
    call Delay
    ret
WelcomeScreen ENDP

;---------------------------------------
;Menu Screen Proc
;---------------------------------------
MenuScreen PROC

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
MenuScreen ENDP

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

;---------------------------------------
;Initialize Grid
;---------------------------------------
LoadMazeToGrid PROC
    lea esi, maze1          ; Start with the first maze row, contiguous memory so dont need to change maze
    lea edi, grid           ; Point to the start of the grid
    mov ecx, NUM_ROWS * NUM_COLS       ; Loop over each row

    ret
LoadMazeToGrid ENDP


END main

