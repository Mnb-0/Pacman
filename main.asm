INCLUDE Irvine32.inc

.data
    msg BYTE "Hello World!", 0

.code
main PROC
    call Clrscr
    mov edx, OFFSET msg
    call WriteString
    call Crlf
    exit
main ENDP

END main
