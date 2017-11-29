.data

.text
start:
		
		mov		r0, #0
		mov		r2, #2 ; number a
		mov		r3, #4 ; number b
		
		;		a*b will be stored in R5
		
		;		call multiply
		
		cmp		r2, #0
		cmpne	r3, #0
		blne		Multiply
		
		mov		r10, r5 ; move multiply answer to r10
		mov		r5, #0	; reset multiply reg
		
		;		c! will be stored in R8
		
		;call	factorial
		
		mov		r3, #5	;number to factorial
		cmp		r3, #0
		cmpne	r3, #1
		moveq	r8, #1
		blne		Factorial
		mov		r3,r8
		
		
end:
		
Pow:
startExponent:

	mov pc, lr
		
Multiply:
loop:
		add		r6, r6, #1
		add		r5, r5, r3
		cmp		r6, r2
		bne		loop
		blt		Multiply
		mov		r6,#0 ; reset counter at end
		mov		pc, lr
		
		
		
Factorial:
		mov		r2,r3 ; decrement for factorial
		
loop2:
		sub		r2,r2,#1
		bl		Multiply
		mov		r3,r5
		mov		r5,#0
		cmp		r2,#1
		bne		loop2
		blt		Factorial
		bx		lr
