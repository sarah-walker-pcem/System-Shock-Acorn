	.text

	.global eventv_handler
	.global key_state

//R0 = 11
//R1 = 0 for key up, 1 for key down
//R2 = key number
//R3 = keyboard driver ID

key_state_p:
	.word key_state

eventv_handler:
	CMP	r0, #11
	MOVNES	pc, lr   // not us
	CMP	r2, #128
	MOVCS	pc, lr   // sanity check

	STR 	r0, [sp, #-4]!
	LDR	r0, key_state_p
	STRB	r1, [r0, r2]
	LDR	r0, [sp], #4

	MOVS	pc, lr