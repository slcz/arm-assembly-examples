#
#
#
# Sieve of Eratosthenes
#

#define __ASSEMBLY__

#include <asm/unistd.h>
#define O_ACCMODE       00000003
#define O_RDONLY        00000000
#define O_WRONLY        00000001
#define O_RDWR          00000002

#define MAX (1073741824)
#define BMAP (134217728)

.bss

.balign 4
bitmap: . = . + BMAP
number: . = . + 16

#define OS(x) mov r7, $__NR_ ## x; swi #0

.text
#
# Bit map operation
# R0: starting index
# R12: base address of the bitmap
#
set:
	mov r1, r0, lsr #5
	ldr r2, [r12, r1, lsl #2]
	and r0, r0, #0x1F
	rsb r0, r0, #31
	mov r3, #1
	orr r2, r2, r3, lsl r0
	str r2, [r12, r1, lsl #2]
	mov pc, lr

find:
	mov r1, r0, lsr #5
	ldr r2, [r12, r1, lsl #2]
	and r3, r0, #0x1F
	mov r1, #1
	mov r1, r1, lsl r3
	sub r1, r1, #1
	mov r1, r1, ror r3
	orr r2, r2, r1
	bic r0, r0, #31
1:
	mvn r2, r2
	clz r3, r2
	add r0, r0, r3
	cmp r3, #32
	movne pc, lr
	cmp r0, #MAX
	moveq pc, lr
	ldr r2, [r12, r0, lsr #3]
	b 1b

# RETURN: R0 MODULU, R1 QUOTIENT
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

display_number:
	push {lr}
	mov r3, #1
	ldr r6, =number
	add r6, r6, #10
	mov r1, #'\n'
	strb r1, [r6, #-1]!

1:
	mov r1, #10
	bl divide
	add r2, r0, #'0'
	strb r2, [r6, #-1]!
	add r3, r3, #1
	mov r0, r1
	cmp r0, #0
	bne 1b

	mov r1, r6
	mov r2, r3
	mov r0, #1
	OS(write)

	pop {pc}

.globl _start
_start:
	ldr r12, =bitmap
	mov r4, #2
2:
	cmp r4, #MAX
	bhs 2f	
	mov r0, r4
	bl display_number
	mov r0, r4
1:
	add r0, r0, r4
	cmp r0, #MAX
	bhs 3f
	mov r5, r0
	bl  set
	mov r0, r5
	b 1b
3:
	mov r0, r4
	add r0, r0, #1
	bl  find
	mov r4, r0
	b 2b
2:
	mov r0, #0
	OS(exit)
