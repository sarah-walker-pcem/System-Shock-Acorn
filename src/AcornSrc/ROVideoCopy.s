	.text

	.global video_copy_double
	.global video_copy_640x480


video_copy_double:
	STMFD	sp!, {v1-v6, ip, lr}

	MOV	lr, #200
	ADD	ip, a1, #320

video_copy_double_loop:
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}


	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	STMIA	ip!, {a3-a4, v1-v6}

	ADD	a1, a1, #320
	ADD	ip, ip, #320
	SUBS	lr, lr, #1
	BNE	video_copy_double_loop

	LDMFD	sp!, {v1-v6, ip, pc}


video_copy_640x480:
	STMFD	sp!, {v1-v6, lr}

	MOV	lr, #480

video_copy_640x480_loop:
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}

	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}
	LDMIA	a2!, {a3-a4, v1-v6}
	STMIA	a1!, {a3-a4, v1-v6}

	SUBS	lr, lr, #1
	BNE	video_copy_640x480_loop

	LDMFD	sp!, {v1-v6, pc}
