
	.arm
	.align
	.text
	.global project

project:

	@r2 will be the offset
	mov r2,#0

	@address arctanTable
	ldr r0, =arctanTable

	loadAtanValue:
		@loads first elemnent in array to r3
		ldr r3,[r0, r2]

		@get next index in array
		add r2, r2, #4
		cmp r2, #124
		ble loadAtanValue

.data


arctanTable: .word 0x3F490FDB, 0x3EED6338, 0x3E7ADBB0, 0x3DFEADD5, 0x3D7FAADE, 0x3CFFEAAE, 0x3C7FFAAB, 0x3BFFFEAB, 0x3B7FFFAB, 0x3AFFFFEB, 0x3A7FFFFB, 0x39FFFFFF, 0x39800000, 0x39000000, 0x38800000, 0x38000000, 0x37800000, 0x37000000, 0x36800000, 0x36000000, 0x35800000, 0x35000000, 0x34800000, 0x34000000, 0x33800000, 0x33000000, 0x32800000, 0x32000000, 0x31800000, 0x31000000, 0x30800000, 0x30000000


.end
