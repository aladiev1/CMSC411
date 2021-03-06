.data
	; CMSC 411
	; Jamal Savoy
	; Andrew Olean
	; Anna Aladiev
	; Kwame Robertson
	; Kevin Miller

	;Input angle for sin and cos
	; Common angles:
	;	4 * PI = 0x41490FDB
	;	2 * PI = 0x40c90fdb
	;	PI	   = 0x40490fdb
	;	PI / 2 = 0x3fc90fdb
	;	PI / 3 = 0x3f860a92
		; These two are broken for some reason. The rest work
		;	PI / 4 = 0x3f490fdb
		;	PI / 6 = 0x3F060A92
	;	0	   = 0x40c90fdb
	; 	2PI / 3= 0x40060A92
	;	5PI / 6 = 0x40278D36
	;	3PI / 4 = 0x4016CBE4
	;   7PI / 4 = 0x40AFEDDF
	;	5PI / 4 = 0x407B53D1
	;	11PI / 6 = 0x40B84E88
	; Table of reciprocals of factorial values. Precomputed to avoid the need for division and for performance considerations
	recipFactorialTable: .word  0x3f800000, 0x3f800000, 0x3f000000, 0x3e2aaaab, 0x3d2aaaab, 0x3c088889, 0x3ab60b61, 0x39500d01, 0x37d00d01, 0x3638ef1d, 0x3493f27e, 0x32d7322b, 0x310f76c7, 0x2f309231, 0x2d49cba5, 0x2b573f9f, 0x29573f9f, 0x274a963c, 0x253413c3, 0x2317a4da, 0x20f2a15d, 0x1eb8dc78, 0x1c8671cb, 0x1a3b0da1, 0x17f96781, 0x159f9e67, 0x13447430, 0x10e8d58e, 0xe850c51, 0xc12cfcc, 0x99c9963, 0x721a697, 0x4a1a697, 0x21cc093, 0x24e204, 0x10dc6, 0x77e, 0x34, 0x1, 0x0
	
	NUM_TERMS_IN_FACTORIAL_TABLE: .word 0x28

	ANGLE: .word 0x40490fdb

	; This value should be in IEEE 754 format
	; 40C00000 = 6
	EXPONENTIAL_PARAMETER: .word 0x40C00000

.text
.global _main

_main:
	
	LDR r0, =ANGLE
	LDR r0, [r0]
    BL Sin
    ; Store result of sin in r8 and s8
    MOV r8, r1
    FMSR s8, r8

	LDR r0, =ANGLE
	LDR r0, [r0]
    BL Cos
    ; Store result of cos in r9 and s9
    MOV r9, r1
    FMSR s9, r9

	LDR r0, =EXPONENTIAL_PARAMETER
	LDR r0, [r0]
    BL Exponential
    ; Store result of the exponential function in r7 and s7
    MOV r7, r1
    FMSR s7, r7

	LDR r0, =ANGLE
	LDR r0, [r0]
    BL Sinh
    ; Store result of the sinh function in r6 and s6
    MOV r6, r1
    FMSR s6, r6

	LDR r0, =ANGLE
	LDR r0, [r0]
    BL Cosh
    ; Store result of the cosh function in r5 and s5
    MOV r5, r1
    FMSR s5, r5

	; tan(x) = sin(x) / cos(x)
	; Not checking for division by 0 here since FDVIS will just produce Infinity. Some value with all 1's in the exponent
	FDIVS s10, s8, s9

	; tanh(x) = sinh(x) / cosh(x)
	; Store in s4
	FDIVS s4, s6, s5

    B _exit					;exit


; Only differences between the exponential function and sin/cos are the starting position and the increment amount for the factorial table
Exponential:
	; Preserve registers and make sure LR doesn't get corrupted when we make our calls to _MUL and pow
	STMDB SP!, { R3-R9, LR }

	; r3 = Angle to compute
	; Storing in r3 since pow and _MUL require r0 and r1 for the input parameters
	MOV r3, r0

	; r4 = current exponent/Index in factorial table
	MOV r4, #0
	; r5 = Current offset in factorial table. Could just multiply the current index by 4, but I don't feel like doing another multiply
	; Easier to just add 4 every loop iteration
	MOV r5, #0

	; r6 = Number of terms in factorial table. This will be our loop controller. Iterate as long as r4 is < r6
	LDR r6, =NUM_TERMS_IN_FACTORIAL_TABLE
	LDR r6, [r6]

	; r8 = pointer to factorial table
	LDR r8, =recipFactorialTable

	; r7 = flag to determine whether we add or subtract. 0 corresponds to add. 1 corresponds to subtract
	MOV r7, #0
	; s2 = Accumulator. Will keep a running sum of our approximation. Set it to r7 since it's 0 anyway and we want to add first
	FMSR s2, r7

EXPONENTIAL_APPROXIMATION_LOOP:

	; r9 = Current recriprocal factorial value
	ldr r9,[r8, r5]

	; r0 = Current angle. r1 = current exponent
	MOV r0, r3
	MOV r1, r4
	BL Pow

	; Move the result of the pow function into r0 to prepare for _MUL
	MOV r0, r2
	MOV r1, r9
	BL _MUL

	; Set up floating point registers to add
	FMSR s0, r2

	FADDS s2, s2, s0

EXPONENTIAL_PREPARE_NEXT_TERM:

	; Exponential does not skip any indices, so increment by 1 and 4
	ADD r4, r4, #1
	ADD r5, r5, #4
	CMP r4, r6
	BLT EXPONENTIAL_APPROXIMATION_LOOP

FINISHED_EXPONENTIAL_APPROXIMATION:

	FMRS r1, s2
	LDMIA SP!, { R3-R9, PC }

; Sin function approximation using taylor series
; Input: r0 = angle in IEEE 754 format
; Output: r1

Sin:
	; Preserve registers and make sure LR doesn't get corrupted when we make our calls to _MUL and pow
	STMDB SP!, { R3-R9, LR }

	; r3 = Angle to compute
	; Storing in r3 since pow and _MUL require r0 and r1 for the input parameters
	MOV r3, r0

	; r4 = current exponent/Index in factorial table
	MOV r4, #1
	; r5 = Current offset in factorial table. Could just multiply the current index by 4, but I don't feel like doing another multiply
	; Easier to just add 4 every loop iteration
	MOV r5, #4

	; r6 = Number of terms in factorial table. This will be our loop controller. Iterate as long as r4 is < r6
	LDR r6, =NUM_TERMS_IN_FACTORIAL_TABLE
	LDR r6, [r6]

	; r8 = pointer to factorial table
	LDR r8, =recipFactorialTable

	; r7 = flag to determine whether we add or subtract. 0 corresponds to add. 1 corresponds to subtract
	MOV r7, #0
	; s2 = Accumulator. Will keep a running sum of our approximation. Set it to r7 since it's 0 anyway and we want to add first
	FMSR s2, r7

SIN_APPROXIMATION_LOOP:

	; r9 = Current recriprocal factorial value
	ldr r9,[r8, r5]

	; r0 = Current angle. r1 = current exponent
	MOV r0, r3
	MOV r1, r4
	BL Pow

	; Move the result of the pow function into r0 to prepare for _MUL
	MOV r0, r2
	MOV r1, r9
	BL _MUL

	; Set up floating point registers to add
	FMSR s0, r2

	CMP r7, #0
	BNE SIN_SUB_TERM

SIN_ADD_TERM:
	FADDS s2, s2, s0
	B SIN_PREPARE_NEXT_TERM

SIN_SUB_TERM:
	FSUBS s2, s2, s0

SIN_PREPARE_NEXT_TERM:
	; Flip the flag so we perform the opposite arithmetic operation in the next iteration
	EOR r7, r7, #1
	; Skip an index in the table every iteration, so increment by 8 instead of 4
	ADD r4, r4, #2
	ADD r5, r5, #8
	CMP r4, r6
	BLT SIN_APPROXIMATION_LOOP

FINISHED_SIN_APPROXIMATION:

	FMRS r1, s2
	LDMIA SP!, { R3-R9, PC }


; Only differences between the sinh and sin functions is sinh does not alternate addition and subtraction
Sinh:
	; Preserve registers and make sure LR doesn't get corrupted when we make our calls to _MUL and pow
	STMDB SP!, { R3-R9, LR }

	; r3 = Angle to compute
	; Storing in r3 since pow and _MUL require r0 and r1 for the input parameters
	MOV r3, r0

	; r4 = current exponent/Index in factorial table
	MOV r4, #1
	; r5 = Current offset in factorial table. Could just multiply the current index by 4, but I don't feel like doing another multiply
	; Easier to just add 4 every loop iteration
	MOV r5, #4

	; r6 = Number of terms in factorial table. This will be our loop controller. Iterate as long as r4 is < r6
	LDR r6, =NUM_TERMS_IN_FACTORIAL_TABLE
	LDR r6, [r6]

	; r8 = pointer to factorial table
	LDR r8, =recipFactorialTable

	; r7 = flag to determine whether we add or subtract. 0 corresponds to add. 1 corresponds to subtract
	MOV r7, #0
	; s2 = Accumulator. Will keep a running sum of our approximation. Set it to r7 since it's 0 anyway and we want to add first
	FMSR s2, r7

SINH_APPROXIMATION_LOOP:

	; r9 = Current recriprocal factorial value
	ldr r9,[r8, r5]

	; r0 = Current angle. r1 = current exponent
	MOV r0, r3
	MOV r1, r4
	BL Pow

	; Move the result of the pow function into r0 to prepare for _MUL
	MOV r0, r2
	MOV r1, r9
	BL _MUL

	; Set up floating point registers to add
	FMSR s0, r2

	FADDS s2, s2, s0

SINH_PREPARE_NEXT_TERM:

	; Sinh skips the same as sin does
	ADD r4, r4, #2
	ADD r5, r5, #8
	CMP r4, r6
	BLT SINH_APPROXIMATION_LOOP

FINISHED_SINH_APPROXIMATION:

	FMRS r1, s2
	LDMIA SP!, { R3-R9, PC }


; Input: r0 = angle in IEEE 754 format
; Output: r1
Cos:
; Preserve registers and make sure LR doesn't get corrupted when we make our calls to _MUL and pow
	STMDB SP!, { R3-R9, LR }

	; r3 = Angle to compute
	; Storing in r3 since pow and _MUL require r0 and r1 for the input parameters
	MOV r3, r0

	; r4 = current exponent/Index in factorial table
	MOV r4, #0
	; r5 = Current offset in factorial table. Could just multiply the current index by 4, but I don't feel like doing another multiply
	; Easier to just add 4 every loop iteration
	MOV r5, #0

	; r6 = Number of terms in factorial table. This will be our loop controller. Iterate as long as r4 is < r6
	LDR r6, =NUM_TERMS_IN_FACTORIAL_TABLE
	LDR r6, [r6]

	; r8 = pointer to factorial table
	LDR r8, =recipFactorialTable

	; r7 = flag to determine whether we add or subtract. 0 corresponds to add. 1 corresponds to subtract
	MOV r7, #0
	; s2 = Accumulator. Will keep a running sum of our approximation. Set it to r7 since it's 0 anyway and we want to add first
	FMSR s2, r7

COS_APPROXIMATION_LOOP:

	; r9 = Current recriprocal factorial value
	ldr r9,[r8, r5]

	; r0 = Current angle. r1 = current exponent
	MOV r0, r3
	MOV r1, r4
	BL Pow

	; Move the result of the pow function into r0 to prepare for _MUL
	MOV r0, r2
	MOV r1, r9
	BL _MUL

	; Set up floating point registers to add
	FMSR s0, r2

	CMP r7, #0
	BNE COS_SUB_TERM

COS_ADD_TERM:
	FADDS s2, s2, s0
	B COS_PREPARE_NEXT_TERM

COS_SUB_TERM:
	FSUBS s2, s2, s0

COS_PREPARE_NEXT_TERM:
	; Flip the flag so we perform the opposite arithmetic operation in the next iteration
	EOR r7, r7, #1
	; Skip an index in the table every iteration, so increment by 8 instead of 4
	ADD r4, r4, #2
	ADD r5, r5, #8
	CMP r4, r6
	BLT COS_APPROXIMATION_LOOP

FINISHED_COS_APPROXIMATION:

	FMRS r1, s2
	LDMIA SP!, { R3-R9, PC }


; Only differences between the cosh and cos functions is cosh does not alternate addition and subtraction
Cosh:
	; Preserve registers and make sure LR doesn't get corrupted when we make our calls to _MUL and pow
	STMDB SP!, { R3-R9, LR }

	; r3 = Angle to compute
	; Storing in r3 since pow and _MUL require r0 and r1 for the input parameters
	MOV r3, r0

	; r4 = current exponent/Index in factorial table
	MOV r4, #0
	; r5 = Current offset in factorial table. Could just multiply the current index by 4, but I don't feel like doing another multiply
	; Easier to just add 4 every loop iteration
	MOV r5, #0

	; r6 = Number of terms in factorial table. This will be our loop controller. Iterate as long as r4 is < r6
	LDR r6, =NUM_TERMS_IN_FACTORIAL_TABLE
	LDR r6, [r6]

	; r8 = pointer to factorial table
	LDR r8, =recipFactorialTable

	; r7 = flag to determine whether we add or subtract. 0 corresponds to add. 1 corresponds to subtract
	MOV r7, #0
	; s2 = Accumulator. Will keep a running sum of our approximation. Set it to r7 since it's 0 anyway and we want to add first
	FMSR s2, r7

COSH_APPROXIMATION_LOOP:

	; r9 = Current recriprocal factorial value
	ldr r9,[r8, r5]

	; r0 = Current angle. r1 = current exponent
	MOV r0, r3
	MOV r1, r4
	BL Pow

	; Move the result of the pow function into r0 to prepare for _MUL
	MOV r0, r2
	MOV r1, r9
	BL _MUL

	; Set up floating point registers to add
	FMSR s0, r2

	FADDS s2, s2, s0

COSH_PREPARE_NEXT_TERM:

	; Cosh skips the same as sin does
	ADD r4, r4, #2
	ADD r5, r5, #8
	CMP r4, r6
	BLT COSH_APPROXIMATION_LOOP

FINISHED_COSH_APPROXIMATION:

	FMRS r1, s2
	LDMIA SP!, { R3-R9, PC }
	
; r0 = base
; r1 = exponent
; r2 = output
; Currently only handles non-negative exponents since this is all we need.
; Negative exponents will be treated as if there were 0. Fractional exponents are also not handled
Pow:
	STMDB SP!, { R3-R9, LR }
	CMP r1, #0x0
	; Treat negative exponents as if they were 0
	BLE ZERO_EXPONENT

	MOV r3, r0
	MOV r2, r0

	; If exponent is 1 then do not do any multiplies
	CMP r1, #1
	BEQ FINISHED_POW

POW_LOOP:

	MOV r4, r1
	; Multiply r2 by itself as long as we have a postive exponent
	; _MUL takes its input values in r0 and r1
	; r2 is our running product. r1 will load the original base from the stack
	MOV r0, r2
	MOV r1, r3
	
	;MOV r9, lr
	BL _MUL
	;MOV lr, r9

	MOV r1, r4
	; Keep multiplying as long as exponent is greater than 0
	SUB r1, r1, #1
	CMP r1, #1
	BGT POW_LOOP
	B FINISHED_POW

ZERO_EXPONENT:
	; Exponent of 0 gives a result of 1
	MOV r2, #0x3F800000
	
FINISHED_POW:
	LDMIA SP!, { R3-R9, PC } ; loading into PC returns out of subroutine
	;MOV PC, lr    			;return
	
;Multiplication subroutine
;Modified this a bit to take inputs in r0 and r1 instead of hardcoding to INPUT_FLOAT1 and INPUT_FLOAT2
;input: r0 = input 1, r1 = input 2
;output: r2
_MUL:
	STMDB SP!, { R3-R9, LR }

	;first get two inputs     
	
	;LDR r0,[r0]
	;LDR	r1, [r1]
	
	;;get exponents, check if either input is zero
	;;ieee, zero is represented with zero in exponent field
	;;no need to check mantissa for zero because the input is normalized
	
	LDR r3, =0x7F800000	;used to get exponent field
	MOV r4, #0
	
	AND r2, r3, r0			; get exponent 1
	AND r3, r3, r1			; get exponent 2

	CMP r2, r4 				; check if zero
	BEQ MULT_ZERO
	CMP r3, r4 				; check if zero
	BEQ MULT_ZERO

	;;temp use r4 for '127'
	mov r4, #0x3F800000
	
	SUB r2, r2, r4			; get rid of bias on exponent 1
	SUB r3, r3, r4			; get rid of bias on exponent 2		
		
	ADD r2,r2,r3			; add exponents together
	ADD r2, r2, r4 			; give bias back
	
	;;r4 and r3 empty 
	
	;;get the mantissas
	
	LDR r3, =0x7FFFFF 

	AND r4, r1 , r3	; get mantissa 2
	AND r3, r0 , r3	; get mantissa 1
	
	mov r5, #0x00800000
	ORR r3, r3, r5			;add leading 1 to mantissa 1
	ORR r4, r4, r5			;add leading 1 to mantissa 2


	MOV r6, #0				;result of multiplication will be in r6
	MOV r7, #0				
	MOV r8, #1				
	
	;;multiply
	
	MOV r5, r4				; r5 (input 2 mantissa)
	B	MULTIPLY_LOOP		; goto multiply loop 
	
	;mant 1 is in r3
	;mant 2 is r5
	;keep ans in r6

MULTIPLY_LOOP: 
	MOV r7, #1
	AND r7, r7, r5 			;get last bit of second number
	CMP r7, #1
	BNE MULT_CONT
	ADD r6, r6, r3 			;add first number to accumulated sum if 1
	B MULT_CONT
MULT_CONT:
	MOV r5, r5, LSR #1 		;shift second number right
	CMP r5, #0 				;check if zero 
	BEQ OUT_OF_LOOPY
	MOV r6, r6, LSR #1 		;shift answer right if not done
	B MULTIPLY_LOOP

OUT_OF_LOOPY:
	;;normalize the result										
	LDR r5, =0x00FFFFFF		;used to check if more than 24 bits in result
	MOV r8, #1
	MOV r9, #0x800000
	CMP r6, r5
	BGT MULT_NORMALIZER
	B MULT_NORMALIZER_DONE

MULT_NORMALIZER:		
	;shift right 1	
	MOV r6, r6, lsr #1		; shift ansright
	ADD r2, r2, r9			;add 'one' to exponent
	CMP r6, r5				; if r6 > 24 bits
	BGT MULT_NORMALIZER		;do again
							;else
	B MULT_NORMALIZER_DONE	;done normalizing
	;;at this point, mantissa is in r6 and r7, with 15 bits in r7

MULT_NORMALIZER_DONE:		
	;; prepare mantissa for final answer
	LDR r7, =0x7FFFFF 		;remove leading one from mantissa
	AND r6,r6,r7					
	B 	MULT_GET_THE_SIGN	;go to next step 

MULT_GET_THE_SIGN:
	LDR r8, =0x80000000 	;used to get the sign
	AND r4, r0, r8			; get input 1 sign bit
	AND r5, r1, r8			; get input 2 sign bit
	EOR	r3, r4, r5			; answer positive if signs are same, negative if different
	
	B MULT_ASSEMBLE 		; assemble parts of answer

MULT_ASSEMBLE:
	ORR r3, r3, r2			;or sign and exponent together
	ORR	r3, r3, r6			;put the mantissa in
	B MULT_DONE

MULT_ZERO:
	MOV r3, #0 				;answer is zero, special case

MULT_DONE:
    MOV r2, r3

    LDMIA SP!, { R3-R9, PC } ; loading into PC returns out of subroutine
    ;MOV PC, lr    			;return

;;exit program 
_exit:
    swi     0x11        	;invoke syscall exit