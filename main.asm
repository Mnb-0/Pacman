INCLUDE Irvine32.inc
.data
    
    welcomeMsg byte "Pacman",0
    inputBuffer byte 20 dup(0)

.code
main PROC
    
;---------Welcome Screen---------------
    ;Initialize screen
    call Clrscr

    ;Move cursor to the center of the screen and display screen
    mov dl, 56
    mov dh,15
    call GoToXY

    mov eax, yellow
    call SetTextColor

    mov edx, offset welcomeMsg
    call writestring
    call crlf

    mov eax, white
    call SetTextColor

    mov eax, 5000
    call Delay

    call Clrscr

;---------------------------------------
    exit
main ENDP

END main

