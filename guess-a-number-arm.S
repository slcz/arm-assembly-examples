
#define __ASSEMBLY__

#include <asm/unistd.h>
#define O_ACCMODE       00000003
#define O_RDONLY        00000000
#define O_WRONLY        00000001
#define O_RDWR          00000002

.data
randomfilepath:
	.asciz "/dev/urandom"
prompt:
	.asciz "guess a number from 0 to 99: "
	.set prompt_size, .-prompt
prompttoohigh:
	.asciz "too high\n"
	.set prompthigh_size, .-prompttoohigh
prompttoolow:
	.asciz "too low\n"
	.set promptlow_size, .-prompttoolow
promptequal:
	.asciz "correct\n"
	.set promptequal_size, .-promptequal
.bss
.balign 4
randomdata: . = . + 4
numberbuf:  . = . + 80 

.text

.globl divide
divide:
	mov r2, #0
1:
	cmp  r0, r1
	bcc  1f
	sub  r0, r0, r1
	add  r2, r2, #1
	b    1b
1:
	mov  r1, r2
	mov pc, lr

.globl atoi
atoi:
	mov r1, #0
	ldr r2, =numberbuf
1:
	ldrb r3, [r2], #1
	cmp r3, #'0'
	blo 1f
	cmp r3, #'9'
	bhi 1f
	sub r3, r3, #'0'
	add r1, r1, r1, lsl #2
	add r1, r3, r1, lsl #1
	b 1b
1:
	mov r0, r1
	mov pc, lr

#define OS(x) mov r7, $__NR_ ## x; swi #0

.globl _start

_start:
	ldr r0, =randomfilepath
	ldr r1, =O_RDWR 
	OS(open)

	mov r4, r0
	ldr r1, =randomdata
	mov r2, #4
	OS(read)

	mov r0, r4
	OS(close)

1:
	ldr r0, =randomdata
	ldrb r0, [r0]

	/* random number from 0 to 99 */
	mov r1, #100
	bl divide
	mov r8, r0

1:
	mov r0, #1
	ldr r1, =prompt
	mov r2, #prompt_size
	OS(write)

	mov r0, #0
	ldr r1, =numberbuf
	mov r2, #80
	OS(read)
	bl  atoi

	mov r6, r0
	cmp r0, r8
	ldrhi r1, =prompttoohigh
	ldrhi r2, =prompthigh_size
	ldrlo r1, =prompttoolow
	ldrlo r2, =promptlow_size
	ldreq r1, =promptequal
	ldreq r2, =promptequal_size
	mov r0, #1
	OS(write)

	cmp r6, r8
	bne 1b

	mov r0, #0
	OS(exit)
