INCLUDE Irvine32.inc

NUM_COLS = 120
NUM_ROWS = 30
.data
    
;Column Center Formula : (Number of Columns - Length of String)/2
;Row Center Formula : Number of Rows / 2

    inputBuffer byte 20 dup(0)
    welcomeMsg byte "Pacman",0
    menuMsg byte "1. Start Game",0
    menuMsg2 byte "2. Select Level",0
    menuMsg3 byte "3. Instructions",0
    menuMsg4 byte "4. High Scores",0
    menuMsg5 byte "5. Exit",0
    colCenter byte 0
    rowCenter byte 0

.code
main PROC
    
    ;Initialize screen

    call Clrscr

    ;Welcome Screen

    call WelcomeScreen

    ;Reset Screen after delay
    
    mov eax, 5000
    call Delay
    call Clrscr

    ;Display Menu
    call MenuScreen
    

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

END main

