TITLE Macros & String Primitives     (Proj6_covingtb.asm)

; Author: Brenden Covington
; Last Modified: 8/18/2023
; OSU email address: covingtb@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6               Due Date: 8/18/2023
; Description: This program reads 10 input integers from user that fits into a 32 bit register,
;			   converts these numbers to a SDWORD and saves them in an array, 
;			   converts them back to strings and displays them and their sums 
;			   and averages. 

INCLUDE Irvine32.inc

; MACROS -----------------------------------------------------------------------------------------------------

; name: mGetString
; Reads string input from user
; Precondition: none
; Postconditions: 	userInput byte array and userInputLength will be modified
; Receives: prompt a message for user input, string input from user, length of array, max length
; Returns: userInput = user input string
;		   userInputLength = length of the user input
mGetString MACRO prompt, string, userCount, length
	pushad

	mov		EDX, prompt
	call	WriteString
	mov		EDX, string
	mov		ECX, userCount
	call	ReadString
	mov		length, EAX

	popad
ENDM

; name: mDisplayString
; Displays string
; Precondition: none
; Postconditions: none
; Receives: dString = string to be printed			
; Returns: none
mDisplayString MACRO dString
	pushad

	mov		EDX, dString
	call	WriteString

	popad
ENDM

; Constants -----------------------------------------------------------------------------------------------------

LO_ASCII				= 48
ASCII_SPACE				= 32
MAX_USER_INPUT			= 11
NUM_LENGTH				= 10


.data

intro1					BYTE		"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures by Brenden Covington",0
intro2					BYTE		"Please provide 10 signed decimal integers small enough to fit inside a 32 bit register.",0
intro3					BYTE		"After you have finished inputting the raw numbers I will display a list of: ",0
intro4					BYTE		"The integers, their sum, and their average value. ",0
prompt					BYTE		"Please enter a signed number: ",0
numMsg					BYTE		"You entered the following numbers:",0
sumMsg					BYTE		"The sum of these numbers is: ",0
avgMsg					BYTE		"The truncated average is: ",0
farewellMsg				BYTE		"Thanks for playing! ",0
error					BYTE		"ERROR: You did not enter an signed number or your number was too big.",0
error2					BYTE		"Please try again: "
userInput				BYTE		MAX_USER_INPUT DUP(?)
userInputLength			DWORD		?
userNum					SDWORD		?
userNumsArray			SDWORD		10 DUP(?)
setNegative				DWORD		0
printString				BYTE		1 DUP(?)
avgString				BYTE		1 DUP(?)
userSum					SDWORD		0
userAverage				SDWORD		0

.code
main PROC

	mDisplayString	OFFSET intro1
	call			CrLf
	call			CrLf

	mDisplayString  OFFSET intro2
	mDisplayString  OFFSET intro3
	mDisplayString  OFFSET intro4
	call			CrLf
	call			CrLf
	
	push			OFFSET userNumsArray
	push			OFFSET setNegative
	push			OFFSET error
	push			OFFSET error2
	push			OFFSET prompt
	push			OFFSET userInput
	push			OFFSET userInputLength
	call			ReadVal
	call			CrLf

	mDisplayString	OFFSET numMsg
	call			CrLf

	push			OFFSET printString
	push			OFFSET userNumsArray
	call			DisplayNumbers
	call			CrLf
	call			CrLf

	push			OFFSET userSum
	push			OFFSET userNumsArray
	call			CalculateSum

	mDisplayString  OFFSET sumMsg

	push			OFFSET	printString
	push			userSum
	call			WriteVal
	call			CrLf
	push			OFFSET userAverage
	push			userSum
	call			CalcAverage

	mDisplayString  OFFSET avgMsg

	push			OFFSET	printString
	push			userAverage
	call			WriteVal
	call			CrLf
	call			CrLf

	mDisplayString OFFSET farewellMsg

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; name: ReadVal
; Reads integer input as string converting to integer and then storing each number into an SDWORD array
; Precondition: none
; Postconditions: userNums array will be filled with 10 SDWORD integers. setNegative & userInputLength will be changed
; Receives: [EBP + 8] for userInputLen, [EBP + 12] as userInput, [EBP + 16]	for prompt, [EBP + 20] for errorMsg, [EBP + 24] to setNegative,
;			and [EBP + 28] for userNums.
; Returns: userNums array filled with signed integers
ReadVal PROC
	push	EBP
	mov		EBP, ESP
	pushad

	mov		ECX, NUM_LENGTH
	mov		EDI, [EBP + 32]	

_prompt:
	push	ECX
	mGetString	[EBP + 16], [EBP + 12], MAX_USER_INPUT, [EBP + 8]
	push	EAX
	mov		EAX, [EBP + 8]				; set ECX as the count of userInput
	mov		ECX, EAX
	pop		EAX
	mov		ESI, [EBP + 12]				; reset userInput mem location
	mov		EBX, 0
	mov		[EBP + 24], EBX				; reset negation variable

_checkSign:
	lodsb
	cmp		AL, 45
	je		_negative
	cmp		AL, 43
	je		_positive
	jmp		_validate

_negative:
	push	EBX
	mov		EBX, 1
	mov		[EBP + 24], EBX				; modify negative to 1
	pop		EBX
	dec		ECX
	jmp		_advance

_positive:
	dec		ECX

_advance:
	cld
	lodsb
	jmp		_validate

_validate:								; validates range
	cmp		AL, 48
	jb		_tooLow
	cmp		AL, 57
	ja		_tooLow
	jmp		_repeat

_tooLow:
	mDisplayString	[EBP + 20]
	call			CrLf
	pop				ECX					; restore ECX
	mov				EBX, 0
	mov				[EDI], EBX			; reset value in destination register
	jmp				_prompt
		
_repeat:
	mov		EBX, [EDI]					; save previous added value
	push	EAX							; preserve AL
	push	EBX
	mov		EAX, EBX					
	mov		EBX, 10
	mul		EBX							; 10 * (EAX <= EBX)
	mov		[EDI], EAX
	pop		EBX
	pop		EAX
	sub		AL, LO_ASCII
	add		[EDI], AL
	dec		ECX
	cmp		ECX, 0
	ja		_advance
	push	EAX
	mov		EAX, [EBP + 24]				; if negative is set, jump to _neggate
	cmp		EAX, 1
	je		_neggate
	jmp		_continue

_neggate:
	mov		EAX, [EDI]
	neg		EAX
	mov		[EDI], EAX

_continue:
	pop		EAX
	add		EDI, 4
	pop		ECX
	dec		ECX
	cmp		ECX, 0
	jnz		_prompt

	popad
	pop		EBX
	ret		28
ReadVal ENDP


; name: WriteVal
; Displays an integer by performing ASCII conversion and displaying string number as shown in Exploration 2
; Precondition: none
; Postconditions: Sring will be modified 
; Receives: [EBP + 8] as userNums, [EBP + 12] as printString address
; Returns: none
WriteVal PROC
	push	EBP
	mov		EBP, ESP
	pushad

	mov		EDI, [EBP + 12]				; printString address
	mov		EAX, [EBP + 8]				; write number to printString

_checkSign:
	cmp		EAX, 0
	jl		_neggate
	jmp		_pushNullBit
	cld

_neggate:
	push	EAX
	mov		AL, 45
	stosb	
	mDisplayString	[EBP + 12]
	dec		EDI							; Move back to beginning of string
	pop		EAX
	neg		EAX							

_pushNullBit:
	push	0

_asciiConvert:
	mov		EDX, 0
	mov		EBX, 10
	div		EBX
	mov		ECX, EDX
	add		ECX, 48
	push	ECX
	cmp		EAX, 0
	je		_displayLoop
	jmp		_asciiConvert

_displayLoop:
	pop		EAX
	stosb
	mDisplayString	[EBP + 12]
	dec		EDI									; loop display
	cmp		EAX, 0
	je		_exitAsciiConvert
	jmp		_displayLoop

_exitAsciiConvert:
	mov				AL, ASCII_SPACE
	stosb
	mDisplayString	[EBP + 12]
	dec				EDI							; reset for next use 
	
	popad
	pop				EBP
	ret	8
WriteVal ENDP


; name: DisplayNumbers
; Loops over SDWORD numbers array and calls WriteVal to display the numbers
; Precondition: array must be filled with valid inputs
; Postconditions: none 
; Receives: [EBP + 8] SDWORD integer, [EBP + 12] string address, MAX_NUM_LENGTH as the length of the SDWORD array
; Returns: none
DisplayNumbers PROC
	push	EBP
	mov		EBP, ESP
	pushad

	mov		ESI, [EBP + 8]				; input array
	mov		EDI, [EBP + 12]				; printString
	mov		ECX, NUM_LENGTH

_printNumber:
	push	EDI
	push	[ESI]
	call	WriteVal
	add		ESI, 4
	loop	_printNumber

	popad
	pop		EBP	
	ret		12
DisplayNumbers ENDP


; name: CalculateSum
; Loops over SDWORD numbers array calculates the sum
; Precondition: Array must be filled with valid inputs
; Postconditions: sum variable will be altered
; Receives: [EBP + 12] as sum, [EBP + 8] SDWORD array, and MAX_NUM_LENGTH as array length
; Returns: sum
CalculateSum PROC
	push	EBP
	mov		EBP, ESP
	pushad

	mov		ESI, [EBP + 8]				; input array
	mov		ECX, NUM_LENGTH
	mov		EAX, 0

_sumNumbers:
	add		EAX, [ESI]
	add		ESI, 4
	loop	_sumNumbers
	mov		EBX, [EBP + 12]
	mov		[EBX], EAX

	popad
	pop		EBP
	ret		8
CalculateSum ENDP


; name: CalcAverage
; Does signed integer division on sum variable previously calculated and returns average variable
; Precondition: sum must be preexisting and holding a valid number
; Postconditions: average variable will be altered 
; Receives: [EBP + 8] for the sum, and [EBP + 12] for the average
; Returns: average of user numbers
CalcAverage PROC
	push	EBP
	mov		EBP, ESP
	pushad

	mov		ECX, NUM_LENGTH
	mov		EAX, [EBP + 8]					
	
_divide:
	mov		EBX, NUM_LENGTH
	mov		EDX, 0
	cdq
	idiv	EBX
	mov		EBX, [EBP + 12]					
	mov		[EBX], EAX

	popad
	pop		EBP
	ret		12
CalcAverage ENDP

END main
