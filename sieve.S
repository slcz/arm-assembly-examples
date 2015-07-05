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

#if 0
#define MAX    (131072)
#define STAGE1 (262144)
#define STAGE2 (131072)

#define BMAP   (16384)
#else
#define MAX    (262144)
#define STAGE1 (524288)
#define STAGE2 (262144)

#define BMAP   (32768)

#endif

.bss

.balign 4
stage1: . = . + STAGE1
bitmap: . = . + BMAP
bmap2:  . = . + BMAP
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
	cmp r0, r11
	moveq pc, lr
	ldr r2, [r12, r0, lsr #3]
	b 1b

# RETURN: R0 MODULU, R1 QUOTIENT
divide:
	cmp r0,  #0
	moveq pc, lr
	clz r10, r0
	mov r2,  #0
	mov r3,  r2

	rsb r10, r10, #31
1:
	mov r9, r0, lsr r10
	and r9, r9, #1
	orr r2, r9, r2, lsl #1
	cmp r2, r1
	mov r9, #1
	subhs r2, r2, r1
	orrhs r3, r3, r9, lsl r10

	cmp r10, #0
	sub r10, r10, #1
	bne 1b

	mov r0, r2
	mov r1, r3
	moveq pc, lr

display_number:
	push {r6, lr}
	mov r7, #1
	ldr r6, =number
	add r6, r6, #10
	mov r1, #'\n'
	strb r1, [r6, #-1]!

1:
	mov r1, #10
	bl divide
	add r2, r0, #'0'
	strb r2, [r6, #-1]!
	add r7, r7, #1
	mov r0, r1
	cmp r0, #0
	bne 1b

	mov r1, r6
	mov r2, r7
	mov r0, #1
	OS(write)

	pop {r6, pc}

sieve1:
	push {lr}
2:
	cmp r4, r11
	bhs 2f	
	mov r0, r4
	strh r4, [r8], #2
	mov r0, r4
1:
	add r0, r0, r4
	cmp r0, r11
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
	pop {pc}

sieve2:
	push {lr}
	mov r6, r4
3:
	mov r4, r6
	ldrh r5, [r8], #2
	cmp r5, #0
	beq 1f
	mov r0, r4
	mov r1, r5
	bl divide
	mov r4, #0
	subs  r4, r4, r0
	addlt r4, r4, r5
2:
	cmp r4, r11
	bge 3b
	mov r0, r4
	bl  set
	add r4, r4, r5
	b 2b

1:
	mov r4, r6
	mov r0, #0
1:
	bl  find
	cmp r0, r11
	bge 1f

	mov r6, r0
#if 0
	add r0, r0, r4
	bl  display_number
#endif

	add r0, r6, #1
	cmp r0, r11
	blt 1b
1:
	pop {pc}

.globl _start
_start:
	ldr r12, =bitmap
	ldr r8,  =stage1
	mov r4,  #2
	mov r11, #MAX
	bl  sieve1
# R8 / 2 number of primes in sqrt(n)
	ldr r8, =stage1
	mov r4, #MAX

2:
	mov r0, r4
	mov r0, r0, lsr #24
	mov r0, r0, lsl #24
	cmp r0, r4
	bleq display_number
	# memset(bmap2, 0)
	ldr r12, =bmap2
	mov r0, #0
	mov r1, r0
	mov r2, r0
	mov r3, r0
	mov r5, #BMAP
1:
	stmia r12!,{r0-r3}
	stmia r12!,{r0-r3}
	stmia r12!,{r0-r3}
	stmia r12!,{r0-r3}
	subs r5, r5, #64
	bne  1b

	ldr r12, =bmap2
	mov r11, #STAGE2
	ldr r8,  =stage1
	bl sieve2
	adds r4, r4, #STAGE2
	bcc 2b

	OS(exit)
