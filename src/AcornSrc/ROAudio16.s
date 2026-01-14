	.text

	.global init_audio_16
	.global close_audio_16

/*	EXPORT lin_val
	EXPORT lin_val2
        EXPORT render_buffer_len_in_samples
	EXPORT print_render_time

	IMPORT xm_run
	IMPORT xm_buffers
	IMPORT data_out
	IMPORT data_wp
	IMPORT ulaw_tbl*/

#define buffer_size_in_samples  208 //440 //880 //652 //500 //440// 512

#define XOS_Sound_Configure     &60140
#define XOS_Sound_Stereo        &60142

#define Sound_Mode              &40144
#define Sound_LinearHandler     &40145
#define Sound_SampleRate        &40146



#define VOICE_BASE        0
#define VOICE_POS         4      //22:10
#define VOICE_INC         8
#define VOICE_END        12
#define VOICE_LOOP_START 16
#define VOICE_LOOP_END   20
#define VOICE_VOL_L      24
#define VOICE_VOL_R      28
#define VOICE_FLAGS      32

#define FLAGS_LOOP       1
#define FLAGS_BIDIR      2
#define FLAGS_16BIT    &10
#define FLAGS_REVERSE  &20
#define FLAGS_STOPPED  &40
#define FLAGS_RAMPING  &80

sound_config_data:
	.word 0,0,0,0,0

linlog_p:
	.word 0

old_sample_rate:
	.word 0
old_linear_handler:
	.word 0
old_linear_param:
	.word 0
target_sample_rate:
	.word 20833*1024
//	DCD 44100*1024
//	DCD 50000*1024

lin_val2:
	.word 0

//r0 = player state
init_audio_16:
	STMDB sp!, {r4-r12, lr}
	STR r0, lin_val2
//	STR r0, [sp, #-4]!

	//Have we got 16 bit sound?
	MOV r0, #0
	SWI Sound_Mode
	CMP r0, #1
	BNE sound_init_8bit
	B sound_init_8bit

	MOV r1, #buffer_size_in_samples
	MOV r0, #2
	MOV r2, #40 //10us - 25 kHz at 4 voices
	MOV r3, #0
	MOV r4, #0
	SWI XOS_Sound_Configure
        //Save old config
	ADR r5, sound_config_data
	STMIA r5, {r0-r4}


	//Search for 25000 Hz (or nearest sample rate)
	MOV r0, #0
	SWI Sound_SampleRate
	MOV r9, r1 //Number of sample rates
	MOV r7, #1 //best match
	MOV r8, #&40000000 //best diff
        MOV r1, #1

sample_rate_loop:
	MOV r0, #2
        SWI Sound_SampleRate //Get sample rate
	LDR r3, target_sample_rate
	SUBS r2, r2, r3
        RSBMI r2, r2, #0  //r2 = absolute diff
	CMP r2, r8 //less than best?
	MOVCC r8, r2
	MOVCC r7, r1

	ADD r1, r1, #1
	CMP r1, r9
	BLS sample_rate_loop

	//Set sample rate
        MOV r0, #3
	MOV r1, r7
	SWI Sound_SampleRate
	STR r1, old_sample_rate

	//Set linear handler
	MOV r0, #1
	LDR r1, linear_handler_fill_p
//	LDR r2, [sp], #4
	LDR r2, lin_val2
	SWI Sound_LinearHandler
	STR r1, old_linear_handler
	STR r2, old_linear_param


	MOV r0, #0

	LDMIA sp!, {r4-r12, pc}


linear_handler_fill_p:
	.word linear_handler_fill


sound_init_8bit:
	MOV r1, #buffer_size_in_samples
	MOV r0, #8
	MOV r2, #48 //24 //24us - 41 kHz
//	MOV r3, #0
	ADRL r3, channel_handler_header
	MOV r4, #0
	SWI XOS_Sound_Configure
        //Save old config
	ADR r5, sound_config_data
	STMIA r5, {r0-r4}
	LDR r0, [r3, #8]
	STR r0, linlog_p

	MOV r0, #1
	MOV r1, #127
	RSB r1, r1, #0
	SWI XOS_Sound_Stereo
	MOV r0, #2
	MOV r1, #127
	RSB r1, r1, #0
	SWI XOS_Sound_Stereo
	MOV r0, #3
	MOV r1, #127
	RSB r1, r1, #0
	SWI XOS_Sound_Stereo
	MOV r0, #4
	MOV r1, #127
	RSB r1, r1, #0
	SWI XOS_Sound_Stereo
	MOV r0, #5
	MOV r1, #127
	SWI XOS_Sound_Stereo
	MOV r0, #6
	MOV r1, #127
	SWI XOS_Sound_Stereo
	MOV r0, #7
	MOV r1, #127
	SWI XOS_Sound_Stereo
	MOV r0, #8
	MOV r1, #127
	SWI XOS_Sound_Stereo

	MOV r0, #0
	LDMIA sp!, {r4-r12, pc}



close_audio_16:
	STMDB sp!, {r4-r12, lr}

	MOV r0, #0
	SWI Sound_Mode
	CMP r0, #1
	BNE sound_close_8bit
	B sound_close_8bit


        //Restore old handler
	MOV r0, #1
	LDR r1, old_linear_handler
	LDR r2, old_linear_param
	SWI Sound_LinearHandler

	//Restore old sample rate
	MOV r0, #3
	LDR r1, old_sample_rate
	SWI Sound_SampleRate

sound_close_8bit:
	ADR r0, sound_config_data
	LDMIA r0, {r0-r4}
	SWI XOS_Sound_Configure

	LDMIA sp!, {r4-r12, pc}



channel_handler_header:
	.word channel_handler_fill,0,0,0

ulaw_tbl_p:
	.word ulaw_tbl

channel_handler_fill:
	STMDB sp!, {r0-r12, lr}

	MOV r11, #&3200000
	STR r0, [r11, #&4c] //latch timer
	LDRB r0, [r11, #&40]
	LDRB r0, [r11, #&40]
	LDRB r2, [r11, #&44]
	ORR r0, r0, r2, LSL #8
	STR r0, render_time


	//r10 = DMA buffer end (+1)
	//r11 = DMA buffer inc
	//r12 = DMA buffer base
	MOV r1, r12
	//LDR r6, linlog_p
	LDR r6, ulaw_tbl_p
//	LDR r6, [r6]

        LDR r0, lin_val2

	//r0 = state
	//r1 = pointer to buffer

	LDR r0, buffer_read_idx
	LDR r2, buffer_write_idx
	CMP r0, r2
	BEQ linear_handler_zero_fill_8

	LDR r11, render_buffer_len_in_samples
	MOV r7, r11
	MOV r14, #buffer_size_in_samples

linear_handler_copy_fill_2_8:
	LDR r10, buffer_read_offset
	LDR r0, buffer_read_idx
        AND r0, r0, #3
	MOV r0, r0, LSL #13 //r2 = offset into xm_buffers
        LDR r3, xm_buffers_p
	ADD r12, r3, r0     //read pointer
	ADD r12, r12, r10, LSL #3

	SUB r9, r11, r10   //samples remaining in buffer
        CMP r9, r14    //clamp to remaining out buffer size
	MOVCS r9, r14
	MOV r8, r9
	ADD r10, r10, r9 //Update read offset
	STR r10, buffer_read_offset

linear_handler_copy_fill_8:
	LDMIA r12!, {r0, r2}
	MOV r0, r0, LSL #(16+2)-12
	MOV r0, r0, LSR #(16+2)
        LDR r0, [r6, r0, LSL #2]
	MOV r2, r2, LSL #(16+2)-12
	MOV r2, r2, LSR #(16+2)
        LDR r2, [r6, r2, LSL #2]
//	MOV r0, #0
// 	MOV r2, #0
	STR r0, [r1], #4
	STR r2, [r1], #4

	SUBS r9, r9, #1
	BNE linear_handler_copy_fill_8

	CMP r10, r7 //This buffer over?
	BCC linear_handler_no_buffer_over_8

	MOV r0, #0
	STR r0, buffer_read_offset
	LDR r0, buffer_read_idx
	ADD r0, r0, #1
	STR r0, buffer_read_idx

linear_handler_no_buffer_over_8:
	SUBS r14, r14, r8
	BLS linear_handler_skip_this_fill  //Generic update

	//More to do...
	B linear_handler_copy_fill_2_8


data_out_p:
	.word data_out
data_wp_p:
	.word data_wp

linear_handler_zero_fill_8:
	MOV r2, #0
	MOV r14, #buffer_size_in_samples

linear_handler_zero_fill_loop_8:
	STR r2, [r1], #4
	STR r2, [r1], #4
	SUBS r14, r14, #1
	BNE linear_handler_zero_fill_loop_8


	//Generic update
	B linear_handler_try_fill


lin_val:
	.word 0

render_buffer_len_in_samples:
	.word 216 //255 BPM
//	DCD 405 //136 BPM
//        DCD 441 //125 BPM
//	DCD 573 //96 BPM
buffer_read_idx:
	.word 0
buffer_read_offset:
	.word 0
buffer_write_idx:
	.word 0

xm_buffers_p:
	.word xm_buffers


render_time:
	.word 0

linear_handler_fill:
	STMDB sp!, {r0-r12, lr}

	MOV r11, #&3200000
	STR r0, [r11, #&4c] //latch timer
	LDRB r0, [r11, #&40]
	LDRB r0, [r11, #&40]
	LDRB r2, [r11, #&44]
	ORR r0, r0, r2, LSL #8
	STR r0, render_time


        LDR r0, lin_val2

	//r0 = state
	//r1 = pointer to buffer

	LDR r0, buffer_read_idx
	LDR r2, buffer_write_idx
	CMP r0, r2
	BEQ linear_handler_zero_fill

	LDR r11, render_buffer_len_in_samples
	MOV r7, r11
	MOV r14, #buffer_size_in_samples

linear_handler_copy_fill_2:
	LDR r10, buffer_read_offset
	LDR r0, buffer_read_idx
        AND r0, r0, #3
	MOV r0, r0, LSL #13 //r2 = offset into xm_buffers
        LDR r3, xm_buffers_p
	ADD r12, r3, r0     //read pointer
	ADD r12, r12, r10, LSL #3

	SUB r9, r11, r10   //samples remaining in buffer
        CMP r9, r14    //clamp to remaining out buffer size
	MOVCS r9, r14
	MOV r8, r9
	ADD r10, r10, r9 //Update read offset
	STR r10, buffer_read_offset

linear_handler_copy_fill:
	LDMIA r12!, {r0, r2}
	MOV r0, r0, ASR #8+4//+1
	MOV r2, r2, ASR #8+4//+1
	MOV r0, r0, LSL #16
	MOV r2, r2, LSL #16
	ORR r0, r2, r0, LSR #16

//	LDR r0, [r12], #4
	STR r0, [r1], #4
	SUBS r9, r9, #1
	BNE linear_handler_copy_fill

	CMP r10, r7 //This buffer over?
	BCC linear_handler_no_buffer_over

	MOV r0, #0
	STR r0, buffer_read_offset
	LDR r0, buffer_read_idx
	ADD r0, r0, #1
	STR r0, buffer_read_idx

linear_handler_no_buffer_over:
	SUBS r14, r14, r8
	BLS linear_handler_skip_this_fill

	//More to do...
	B linear_handler_copy_fill_2



linear_handler_zero_fill:
	MOV r2, #0
	MOV r14, #buffer_size_in_samples

linear_handler_zero_fill_loop:
	STR r2, [r1], #4
	SUBS r14, r14, #1
	BNE linear_handler_zero_fill_loop

linear_handler_skip_this_fill:
linear_handler_try_fill:
	LDR r0, buffer_read_idx
	LDR r2, buffer_write_idx
	SUB r3, r2, r0
	CMP r3, #4
	BCS linear_handler_skip_update

        AND r2, r2, #3
	MOV r2, r2, LSL #13 //r2 = offset into xm_buffers
        LDR r3, xm_buffers_p
	ADD r1, r3, r2      //write pointer


	//Do initial clear
	MOV r2, #0
	MOV r3, #0
	MOV r4, #0
	MOV r5, #0
	MOV r6, r1
	LDR r7, render_buffer_len_in_samples //buffer_size_in_samples

linear_handler_zero_loop:
	STMIA r6!, {r2, r3}
	//STR r2, [r6], #4
	SUBS r7, r7, #1
	BNE linear_handler_zero_loop


	STR r1, [sp, #-4]!
	//ADD r0, r0, #12*32
	LDR r0, lin_val2
	MOV r10, #32 //16
//	MOV r10, #9
//	ADD r0, r0, #1*36


linear_handler_sample_loop:
	//LDR r2, [r0, #VOICE_VOL_L] //Voice on?
	//CMP r2, #0
	//BEQ linear_handler_skip_voice

	LDR r11, [r0, #VOICE_FLAGS]
	TST r11, #FLAGS_STOPPED
	BNE linear_handler_skip_voice

	LDR r3, [r0, #VOICE_BASE]
	LDR r4, [r0, #VOICE_POS]
	LDR r5, [r0, #VOICE_INC]
	LDR r6, [r0, #VOICE_END]
//	LDR r9, [r0, #VOICE_FLAGS]
//
//	LDR r11, data_out_p
//	LDR r12, data_wp_p
//	LDR r8, [r12]
//	ADD r8, r8, #1
//	STR r8, [r12]
//	CMP r8, #512
//	STRCC r9, [r11, r8, LSL #2]

	LDR r9, [r0, #VOICE_VOL_L]
	LDR r1, [r0, #VOICE_VOL_R]
	LDR r12, [sp] //Temp buffer
	//MOV r12, r1
	LDR r14, render_buffer_len_in_samples //buffer_size_in_samples

	CMP r5, #&10000000
	LDR r8, [r5]

	TST r11, #FLAGS_RAMPING
	BIC r11, r11, #FLAGS_RAMPING
	STR r11, [r0, #VOICE_FLAGS]
	BNE voice_ramping

do_real_mix:
        TST r11, #FLAGS_16BIT
	BNE linear_handler_mix_16
	TST r11, #FLAGS_REVERSE
	BNE linear_handler_mix_reverse

linear_handler_mix:
	LDR r8, [r12]
	ADD r7, r3, r4, LSR #10
	//LDRSB r7, [r7]
	LDRB r7, [r7]
	MOV r7, r7, LSL #24
	MOV r7, r7, ASR #24
	ADD r4, r4, r5
	MOV r7, r7, LSL #8

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #4+1
	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BCS linear_handler_sample_over

linear_handler_sample_cont:
	SUBS r14, r14, #1
	BNE linear_handler_mix

	STR r4, [r0, #VOICE_POS]

linear_handler_skip_voice:

	ADD r0, r0, #36
	SUBS r10, r10, #1
	BNE linear_handler_sample_loop


	LDR r1, [sp], #4

//	//Mirror in both channels (temp)
//        MOV r12, r1
//	LDR r14, render_buffer_len_in_samples
//
//linear_handler_mirror_loop
//	LDR r8, [r12]
//	MOV r8, r8, LSL #16
//	ORR r8, r8, r8, LSR #16
 //	STR r8, [r12], #4
 //
//	SUBS r14, r14, #1
//	BNE linear_handler_mirror_loop


	LDR r2, buffer_write_idx
	ADD r2, r2, #1
	STR r2, buffer_write_idx

	//BL xm_run

	B linear_handler_try_fill

linear_handler_skip_update:

	MOV r12, #&3200000
	STR r0, [r12, #&4c] //latch timer
	LDRB r0, [r12, #&40]
	LDRB r0, [r12, #&40]
	LDRB r1, [r12, #&44]
	ORR r0, r0, r1, LSL #8
	LDR r1, render_time
	SUBS r0, r1, r0
	ADDCC r0, r0, #&20
	ADDCC r0, r0, #&4e00
	LDR r1, last_render_time
	ADD r0, r0, r1
	STR r0, last_render_time

	LDR r1, render_time_time
 	SUBS r1, r1, #1
	STRNE r1, render_time_time
	BNE no_update_render_time

 	MOV r1, #100
	STR r1, render_time_time

  	STR r0, print_render_time
	MOV r0, #0
	STR r0, last_render_time

no_update_render_time:
	LDMIA sp!, {r0-r12, pc}


last_render_time:
	.word 0
print_render_time:
	.word 0
render_time_time:
	.word 100




linear_handler_mix_reverse:
	LDR r8, [r12]
	ADD r7, r3, r4, LSR #10
//	LDRSB r7, [r7]
	LDRB r7, [r7]
	MOV r7, r7, LSL #24
	MOV r7, r7, ASR #24
	SUB r4, r4, r5
	MOV r7, r7, LSL #8

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #4+1

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BLS linear_handler_sample_over

linear_handler_sample_cont_reverse:
	SUBS r14, r14, #1
	BNE linear_handler_mix_reverse

	STR r4, [r0, #VOICE_POS]

	B linear_handler_skip_voice



linear_handler_sample_over:
	TST r11, #FLAGS_BIDIR
	BNE linear_handler_sample_over_bidir

	TST r11, #FLAGS_LOOP
        BEQ linear_handler_sample_really_over

	//Loop
        LDR r6, [r0, #VOICE_LOOP_START]
	ADD r4, r4, r6
	LDR r6, [r0, #VOICE_LOOP_END]
	SUB r4, r4, r6
	STR r6, [r0, #VOICE_END]
	STR r4, [r0, #VOICE_POS]
//        LDR r8, [r0, #VOICE_LOOP_START]
//	ADD r3, r3, r8
//	STR r3, [r0, #VOICE_BASE]
//	MOV r8, #0
//	STR r8, [r0, #VOICE_LOOP_START]
	B linear_handler_sample_cont

linear_handler_sample_over_bidir:
	TST r11, #FLAGS_REVERSE
	EOR r11, r11, #FLAGS_REVERSE
	ADDNE r4, r4, r5 //bring back in range of loop
	SUBEQ r4, r4, r5
	STR r4, [r0, #VOICE_POS]
	STRB r11, [r0, #VOICE_FLAGS]
        LDRNE r6, [r0, #VOICE_LOOP_END]
        LDREQ r6, [r0, #VOICE_LOOP_START]
	STR r6, [r0, #VOICE_END]

	BEQ linear_handler_sample_cont_reverse
	B linear_handler_sample_cont

linear_handler_sample_really_over:
	STR r4, [r0, #VOICE_POS]
	//MOV r2, #0
	//STR r2, [r0, #VOICE_VOL]
	ORR r11, r11, #FLAGS_STOPPED
	STR r11, [r0, #VOICE_FLAGS]


	B linear_handler_skip_voice



linear_handler_mix_16:
	TST r11, #FLAGS_REVERSE
	BNE linear_handler_mix_16_reverse

linear_handler_mix_16_loop:
	LDR r8, [r12]
	MOV r7, r4, LSR #10
	LDR r7, [r3, r7, LSL #1]
	ADD r4, r4, r5
	MOV r7, r7, LSL #16
	MOV r7, r7, ASR #16

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #8+4+1

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4


	CMP r4, r6
	BCS linear_handler_sample_over_16

linear_handler_sample_cont_16:
	SUBS r14, r14, #1
	BNE linear_handler_mix_16_loop

	STR r4, [r0, #VOICE_POS]

	B linear_handler_skip_voice


linear_handler_mix_16_reverse:
	LDR r8, [r12]
	MOV r7, r4, LSR #10
	LDR r7, [r3, r7, LSL #1]
	SUB r4, r4, r5
	MOV r7, r7, LSL #16
	MOV r7, r7, ASR #16

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #8+4+1
//	STR r8, [r12], #4

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BLS linear_handler_sample_over_16

linear_handler_sample_cont_16_reverse:
	SUBS r14, r14, #1
	BNE linear_handler_mix_16_reverse

	STR r4, [r0, #VOICE_POS]

	B linear_handler_skip_voice


linear_handler_sample_over_16:
	TST r11, #FLAGS_BIDIR
	BNE linear_handler_sample_over_16_bidir
	TST r11, #FLAGS_LOOP
        BEQ linear_handler_sample_really_over

	//Loop
        LDR r6, [r0, #VOICE_LOOP_START]
	ADD r4, r4, r6
	LDR r6, [r0, #VOICE_LOOP_END]
	SUB r4, r4, r6
	STR r6, [r0, #VOICE_END]
	STR r4, [r0, #VOICE_POS]
//	SUB r4, r4, r6
//	STR r4, [r0, #VOICE_POS]
//	LDR r6, [r0, #VOICE_LOOP_END]
//	STR r6, [r0, #VOICE_END]
//        LDR r8, [r0, #VOICE_LOOP_START]
//	ADD r3, r3, r8
//	STR r3, [r0, #VOICE_BASE]
//	MOV r8, #0
//	STR r8, [r0, #VOICE_LOOP_START]
	B linear_handler_sample_cont_16

linear_handler_sample_over_16_bidir:
	TST r11, #FLAGS_REVERSE
	EOR r11, r11, #FLAGS_REVERSE
	ADDNE r4, r4, r5 //bring back in range of loop
	SUBEQ r4, r4, r5
	STR r4, [r0, #VOICE_POS]
	STRB r11, [r0, #VOICE_FLAGS]
        LDRNE r6, [r0, #VOICE_LOOP_END]
        LDREQ r6, [r0, #VOICE_LOOP_START]
	STR r6, [r0, #VOICE_END]

	BEQ linear_handler_sample_cont_16_reverse
	B linear_handler_sample_cont_16



//Ramping mix routines (for voice start)
//Fast ramp over 16 samples
voice_ramping:
	MOV r14, #16

        TST r11, #FLAGS_16BIT
	BNE linear_handler_mix_16_ramp
	TST r11, #FLAGS_REVERSE
	BNE linear_handler_mix_reverse_ramp

//r0=voice pointer
//r1=right vol
//r3=sample base
//r4=sample pos
//r5=sample inc
//r6=sample end
//r7=sample data
//r8=temp (sample buffer data)
//r9=left vol
//r10=sample count
//r11=flags
//r12=sample buffer addr
linear_handler_mix_ramp:
	LDR r8, [r12]
	ADD r7, r3, r4, LSR #10
//	LDRSB r7, [r7]
	LDRB r7, [r7]
	MOV r7, r7, LSL #24
	MOV r7, r7, ASR #24
	ADD r4, r4, r5
	MOV r7, r7, LSL #8

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #4+1

	RSB r2, r14, #16
	MUL r2, r9, r2
	MOV r2, r2, LSR #4
	MLA r8, r2, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	RSB r2, r14, #16
	MUL r2, r1, r2
	MOV r2, r2, LSR #4
	MLA r8, r2, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BCS linear_handler_sample_over_ramp

linear_handler_sample_cont_ramp:
	SUBS r14, r14, #1
	BNE linear_handler_mix_ramp

	LDR r14, render_buffer_len_in_samples //buffer_size_in_samples
	SUB r14, r14, #16
	B do_real_mix




linear_handler_mix_reverse_ramp:
	LDR r8, [r12]
	ADD r7, r3, r4, LSR #10
//	LDRSB r7, [r7]
	LDRB r7, [r7]
	MOV r7, r7, LSL #24
	MOV r7, r7, ASR #24
	SUB r4, r4, r5
	MOV r7, r7, LSL #8

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #4+1

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BLS linear_handler_sample_over_ramp

linear_handler_sample_cont_reverse_ramp:
	SUBS r14, r14, #1
	BNE linear_handler_mix_reverse_ramp

	LDR r14, render_buffer_len_in_samples //buffer_size_in_samples
	SUB r14, r14, #16
	B do_real_mix




linear_handler_sample_over_ramp:
	TST r11, #FLAGS_BIDIR
	BNE linear_handler_sample_over_bidir_ramp

	TST r11, #FLAGS_LOOP
        BEQ linear_handler_sample_really_over

	//Loop
        LDR r6, [r0, #VOICE_LOOP_START]
	ADD r4, r4, r6
	LDR r6, [r0, #VOICE_LOOP_END]
	SUB r4, r4, r6
	STR r6, [r0, #VOICE_END]
	STR r4, [r0, #VOICE_POS]
//        LDR r8, [r0, #VOICE_LOOP_START]
//	ADD r3, r3, r8
//	STR r3, [r0, #VOICE_BASE]
//	MOV r8, #0
//	STR r8, [r0, #VOICE_LOOP_START]
	B linear_handler_sample_cont_ramp

linear_handler_sample_over_bidir_ramp:
	TST r11, #FLAGS_REVERSE
	EOR r11, r11, #FLAGS_REVERSE
	ADDNE r4, r4, r5 //bring back in range of loop
	SUBEQ r4, r4, r5
	STR r4, [r0, #VOICE_POS]
	STRB r11, [r0, #VOICE_FLAGS]
        LDRNE r6, [r0, #VOICE_LOOP_END]
        LDREQ r6, [r0, #VOICE_LOOP_START]
	STR r6, [r0, #VOICE_END]

	BEQ linear_handler_sample_cont_reverse_ramp
	B linear_handler_sample_cont_ramp




linear_handler_mix_16_ramp:
	TST r11, #FLAGS_REVERSE
	BNE linear_handler_mix_16_reverse_ramp

linear_handler_mix_16_loop_ramp:
	LDR r8, [r12]
	MOV r7, r4, LSR #10
	LDR r7, [r3, r7, LSL #1]
	ADD r4, r4, r5
	MOV r7, r7, LSL #16
	MOV r7, r7, ASR #16

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #8+4+1

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4


	CMP r4, r6
	BCS linear_handler_sample_over_16_ramp

linear_handler_sample_cont_16_ramp:
	SUBS r14, r14, #1
	BNE linear_handler_mix_16_loop_ramp

	LDR r14, render_buffer_len_in_samples //buffer_size_in_samples
	SUB r14, r14, #16
	B do_real_mix


linear_handler_mix_16_reverse_ramp:
	LDR r8, [r12]
	MOV r7, r4, LSR #10
	LDR r7, [r3, r7, LSL #1]
	SUB r4, r4, r5
	MOV r7, r7, LSL #16
	MOV r7, r7, ASR #16

//	MUL r7, r9, r7
//	ADD r8, r8, r7, ASR #8+4+1
//	STR r8, [r12], #4

	MLA r8, r9, r7, r8
	STR r8, [r12], #4

	LDR r8, [r12]
	MLA r8, r1, r7, r8
	STR r8, [r12], #4

	CMP r4, r6
	BLS linear_handler_sample_over_16_ramp

linear_handler_sample_cont_16_reverse_ramp:
	SUBS r14, r14, #1
	BNE linear_handler_mix_16_reverse_ramp

	LDR r14, render_buffer_len_in_samples //buffer_size_in_samples
	SUB r14, r14, #16
	B do_real_mix


linear_handler_sample_over_16_ramp:
	TST r11, #FLAGS_BIDIR
	BNE linear_handler_sample_over_16_bidir_ramp
	TST r11, #FLAGS_LOOP
        BEQ linear_handler_sample_really_over

	//Loop
        LDR r6, [r0, #VOICE_LOOP_START]
	ADD r4, r4, r6
	LDR r6, [r0, #VOICE_LOOP_END]
	SUB r4, r4, r6
	STR r6, [r0, #VOICE_END]
	STR r4, [r0, #VOICE_POS]
//	SUB r4, r4, r6
//	STR r4, [r0, #VOICE_POS]
//	LDR r6, [r0, #VOICE_LOOP_END]
//	STR r6, [r0, #VOICE_END]
//        LDR r8, [r0, #VOICE_LOOP_START]
//	ADD r3, r3, r8
//	STR r3, [r0, #VOICE_BASE]
//	MOV r8, #0
//	STR r8, [r0, #VOICE_LOOP_START]
	B linear_handler_sample_cont_16_ramp

linear_handler_sample_over_16_bidir_ramp:
	TST r11, #FLAGS_REVERSE
	EOR r11, r11, #FLAGS_REVERSE
	ADDNE r4, r4, r5 //bring back in range of loop
	SUBEQ r4, r4, r5
	STR r4, [r0, #VOICE_POS]
	STRB r11, [r0, #VOICE_FLAGS]
        LDRNE r6, [r0, #VOICE_LOOP_END]
        LDREQ r6, [r0, #VOICE_LOOP_START]
	STR r6, [r0, #VOICE_END]

	BEQ linear_handler_sample_cont_16_reverse_ramp
	B linear_handler_sample_cont_16_ramp

