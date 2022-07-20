org 100h

.data

FirstOperandMessage db 'Enter first operand: '
SecondOperandMessage db 'Enter second operand: '
EnterOperatorMessage db 'Enter operator: '  
OperatorMessageError db ' Unknown operator.',13,10


Operand1 db 0
Operand2 db 0
Operator db '$'

ResultDigit db 0

OP1string db '$$$'
OP2string db '$$$'
ResultString db '$$$$$'
                                     
                                         
.code   

START:

GetFirstOperand:
    mov bp,0     
    
    lea si, FirstOperandMessage
    mov cx, 21
    mov ah, 0Eh
    call Write  
                 
    mov dl, 10  
    mov bl, 0 
    jmp ScanNumber


GetSecondOperand:
    mov bp,1
    mov Operand1, bl

    lea si, SecondOperandMessage
    mov cx, 22
    mov ah, 0Eh
    call Write
    
    jmp ScanNumber


GetOperator:
    mov bp,65535 
    
    mov Operand2, bl  
    
    ShowMessage:
    lea si, EnterOperatorMessage
    mov cx, 16
    mov ah, 0Eh
    call Write
    
    MOV AH,1
    INT 21H 

    cmp AL, 2BH
    je Sum 
    cmp AL, 2DH
    je Subt
    cmp AL, 2AH
    je Mult 
    cmp AL, 2FH
    je Divd
    
    lea si, OperatorMessageError
    mov cx, 20
    mov ah, 0Eh
    call Write
    jmp ShowMessage
    
    
    
    

jmp START

ScanNumber:
    mov ah, 01h
    int 21h
    cmp al, 13   ; Check if user pressed ENTER KEY
    je  Resume                     
      
    mov ah, 0  
    sub al, 48   ; ASCII to DECIMAL
    mov cl, al
    mov al, bl   ; Store the previous value in AL
    
    mul dl       ; multiply the previous value with 10

    add al, cl   ; previous value + new value ( after previous value is multiplyed with 10 )
    mov bl, al

    jmp ScanNumber  

Resume:
    call NewLine
    cmp bp,0
    je GetSecondOperand
    cmp bp,1
    je  GetOperator
    cmp bp,65535
    je  GetFirstOperand

Write: lodsb
    int 10h
    loop Write

    mov dl, 10  
    mov bl, 0
ret    

NewLine:
    mov dx,13
    mov ah,2
    int 21h  
    mov dx,10
    mov ah,2
    int 21h
ret    

Sum:
    lea si, operator
    mov [si], '+' 
    call SetOperands
    
    ;al=op1, bl=op2
    add ax, bx
    
    lea si, ResultString
    call NumberToString
    
    call FillASCIILcd
    
Subt:
    lea si, operator
    mov [si], '-'      
    call SetOperands
    
    ;al=op1, bl=op2
    sub ax, bx
    
    lea si, ResultString
    call NumberToString
    
    call FillASCIILcd   
    
Mult:            
    lea si, operator
    mov [si], '*'
    call SetOperands
    
    ;al=op1, bl=op2
    mul bx
    
    lea si, ResultString
    call NumberToString
       
    call FillASCIILcd
    
Divd:            
    lea si, operator
    mov [si], '/'
    call SetOperands
    
    ;al=op1, bl=op2
    div bl
    
    lea si, ResultString
    call NumberToString
       
    call FillASCIILcd    
    
ret


SetOperands:
    mov ah,0
    mov al,operand1
    mov si,offset OP1string
    call NumberToString 
   
    mov ah,0
    mov al,operand2
    mov si,offset OP2string
    call NumberToString 
    
    mov ah,0
    mov bh,0
    mov al, Operand1
    mov bl, Operand2
    
ret

;PARAMETERS : AX = NUMBER TO CONVERT.
;             SI = POINTING WHERE TO STORE STRING.

NumberToString proc 
  mov ResultDigit, 0
  call dollars ;FILL STRING WITH $.
  mov  bx, 10  ;DIGITS ARE EXTRACTED DIVIDING BY 10.
  mov  cx, 0   ;COUNTER FOR EXTRACTED DIGITS.
cycle1:       
  mov  dx, 0   ;NECESSARY TO DIVIDE BY BX.
  div  bx      ;DX:AX / 10 = AX:QUOTIENT DX:REMAINDER.
  push dx      ;PRESERVE DIGIT EXTRACTED FOR LATER.
  inc  cx      ;INCREASE COUNTER FOR EVERY DIGIT EXTRACTED.
  inc ResultDigit
  cmp  ax, 0   ;IF NUMBER IS
  jne  cycle1  ;NOT ZERO, LOOP. 
;NOW RETRIEVE PUSHED DIGITS.
cycle2:
  pop  dx       
  ADD  dl, "0"  ;CONVERT DIGIT TO CHARACTER.
  mov  [si], dl
  inc  si
  loop cycle2  

  ret
NumberToString endp 

proc dollars                 
  mov  cx, 5
  mov  di, si
dollars_loop:      
  mov  bl, '$'
  mov  [ di ], bl
  inc  di
  loop dollars_loop

  ret
endp           

FillASCIILcd:
    mov ch,0
    mov dx,2040h	; first row on lcd
    mov si,offset OP1string
    mov cx,3 

lcdOp1:
	MOV AL,[si] 
	cmp al,'$'
	je Continue
	out DX,AL
	INC SI
	INC DX

	LOOP lcdOp1

Continue:

mov al,Operator
inc dx
out dx,al

mov si, offset OP2string
add dx,2                

mov cx,3
lcdOp2:
	MOV AL, [SI]
	cmp al,'$'
	je Continue2
	out DX,AL
	INC SI
	INC DX

	LOOP lcdOp2
	
Continue2:
mov al,'='
inc dx
out dx,al

mov si, offset ResultString
add dx,2
mov ch,0
mov cl,ResultDigit
lcdResult:
	MOV AL, [SI]
	cmp al,'$'
	je NextOne
	out DX,AL
	INC SI
	INC DX

	LOOP lcdResult
	
NextOne:
jmp Resume