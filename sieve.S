#
# Sieve of Eratosthenes
# Segmented sieve, https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes#Segmented_sieve
# Running on Quad Core Raspberry PI 2, to take 60 seconds to find primes from 2 to
# 2 ^ 32 (if disable printf)
#
# Compile by: gcc sieve.S -O2 -g -o sieve -lpthread
#

#define __ASSEMBLY__

#include <asm/unistd.h>
#define O_ACCMODE       00000003
#define O_RDONLY        00000000
#define O_WRONLY        00000001
#define O_RDWR          00000002

/* THREADS = NUMBER OF CORES, LOG2STAGE2 = L1_DCACHE_SIZE * 8 */
#define THREADS (4)
#define LOG2STAGE2 (18)

#define LOG2MAX (16)
#define MAX     (1<<LOG2MAX)
/* stage 1 prime number stored in half word */
#define STAGE1  (MAX * 2)
#define STAGE2  (1<<LOG2STAGE2)
#define BMAP    (MAX / 8)
#define LOG2BMAP2 (LOG2STAGE2 - 3)
#define BMAP2   (STAGE2 / 8 * THREADS)

.data
format: .asciz "%u "

.bss

.balign 4
stage1: . = . + STAGE1
bitmap: . = . + BMAP
bmap2:  . = . + BMAP2
number: . = . + 16
thread: . = . + (THREADS * 4)

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
	push {r12, lr}
	mov r1, r0
	ldr r0, =format
	bl  printf
	pop {r12, pc}

sieve1:
	push {lr}
2:
	cmp r4, r11
	bhs 2f	
	mov r0, r4
	bl display_number
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
	mov r0, #0
	strh r0, [r8], #2
	pop {pc}

sieve2:
	push {r6, lr}
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
	add r0, r0, r4
	bl  display_number

	add r0, r6, #1
	cmp r0, r11
	blt 1b
1:
	pop {r6, pc}

partition:
	push {r4-r11,lr}
	mov r6, r0

# R8 / 2 number of primes in sqrt(n)
	ldr r8, =stage1
	mov r4, #STAGE2
	add r4, r4, r6, lsl #LOG2STAGE2
2:
#if 0
	mov r0, r4
	mov r0, r0, lsr #26
	mov r0, r0, lsl #26
	cmp r0, r4
	bleq display_number
#endif
	# memset(bmap2, 0)
	ldr r12, =bmap2
	add r12, r12, r6, lsl #LOG2BMAP2
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
	add r12, r12, r6, lsl #15
	mov r11, #STAGE2
	ldr r8,  =stage1
	bl sieve2
	adds r4, r4, #(STAGE2 * THREADS)
	bcc 2b

	pop {r4-r11,pc}

.globl main
main:
	push {r4-r11,lr}
	ldr r12, =bitmap
	ldr r8,  =stage1
	mov r4,  #2
	mov r11, #MAX
	bl  sieve1

	mov r4, #0
	ldr r5, =thread
1:
	mov r0, r5
	mov r3, r4
	mov r1, #0
	ldr r2, =partition
	bl  pthread_create

	add r5, r5, #4
	add r4, r4, #1
	cmp r4, #THREADS
	blt 1b

	mov r4, #0
	ldr r5, =thread
1:
	ldr r0, [r5], #4
	mov r1, #0
	bl pthread_join
	add r4, r4, #1
	cmp r4, #THREADS
	blt 1b

	pop {r4-r11,pc}
