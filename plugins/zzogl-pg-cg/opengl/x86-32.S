# Copyright (C) 2005-2006 zerofrog(@gmail.com)
#
#  This Program is free software you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation either ve%rsion 2, or (at your option)
#  any later ve%rsion.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with GNU Make see the file COPYING.  If not, write to
#  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA USA.
#  http://www.gnu.org/copyleft/gpl.html
#
#
.intel_syntax

#ifdef ZEROGS_SSE2
// SSE2 extensions

// Note: pshufd 0xea <=> movdqa !!!
// What the function does is
// Interleave s1 and sd0 -> d1 (high) & sd0 (low)
// Interleave s3 and sd2 -> d3 (high) & sd2 (low)
#define punpck(op, sd0, sd2, s1, s3, d1, d3) \
	movdqa %xmm##d1, %xmm##sd0; \
	pshufd %xmm##d3, %xmm##sd2, 0xe4; \
	punpckl##op %xmm##sd0, %xmm##s1; \
	punpckh##op %xmm##d1, %xmm##s1; \
	punpckl##op %xmm##sd2, %xmm##s3; \
	punpckh##op %xmm##d3, %xmm##s3; \


// Input xmm7 == 0x0F0F0F0F 0x0F0F0F0F  0x0F0F0F0F 0x0F0F0F0F
// DATA xmm[0-3]
// This function does a 4-bits interleaving of 4 xmm registers
//
// ARG Can not put comment in the middle of the define...
// After the first por
// low 32bits (4bits packed) == 1.6 0.6 1.4 0.4  1.2 0.2 1.0 0.0
// After the second one
// low 32bits (4bits packed) == 1.7 0.7 1.5 0.5  1.3 0.3 1.1 0.1
#define punpcknb \
	movdqa	%xmm4, %xmm0; \
	pshufd	%xmm5, %xmm1, 0xe4; \
        \
	psllq	%xmm1, 4; \
	psrlq	%xmm4, 4; \
         \
	movdqa	%xmm6, %xmm7; \
	pand	%xmm0, %xmm7; \
	pandn	%xmm6, %xmm1; \
	por		%xmm0, %xmm6; \
        \
	movdqa	%xmm6, %xmm7; \
	pand	%xmm4, %xmm7; \
	pandn	%xmm6, %xmm5; \
	por		%xmm4, %xmm6; \
        \
	movdqa	%xmm1, %xmm4; \
        \
        \
	movdqa	%xmm4, %xmm2; \
	pshufd	%xmm5, %xmm3, 0xe4; \
        \
	psllq	%xmm3, 4; \
	psrlq	%xmm4, 4; \
        \
	movdqa	%xmm6, %xmm7; \
	pand	%xmm2, %xmm7; \
	pandn	%xmm6, %xmm3; \
	por		%xmm2, %xmm6; \
        \
	movdqa	%xmm6, %xmm7; \
	pand	%xmm4, %xmm7; \
	pandn	%xmm6, %xmm5; \
	por		%xmm4, %xmm6; \
        \
	movdqa	%xmm3, %xmm4; \
        \
	punpck(bw, 0, 2, 1, 3, 4, 6);\

// output
// low 32 bits 0 (4 bits packed) == 1.3  0.3  1.2  0.2    1.1  0.1  1.0  0.0
// low 32 bits 4 (4 bits packed) == 1.19 0.19 1.18 0.18   1.17 0.17 1.16 0.16
// low 32 bits 2 (4 bits packed) == 3.3  2.3  3.2  2.2    3.1  2.1  3.0  2.0
// low 32 bits 6 (4 bits packed) == 3.19 2.19 3.18 2.18   3.17 2.17 3.16 2.16


//
// swizzling
//

//
// SwizzleBlock32
//

.globl SwizzleBlock32_sse2
        .type SwizzleBlock32_sse2, @function
SwizzleBlock32_sse2:

	push		%esi
	push		%edi

    // save dst
	mov			%edi, %ecx
    // save src
	mov			%esi, %edx
    // get pitch
	mov			%edx, [%esp+4+8]
	mov			%ecx, 4

    // get WriteMask
	mov			%eax, [%esp+8+8]
	cmp			%eax, 0xffffffff
	jne			SwizzleBlock32_sse2_2

	.align 16
SwizzleBlock32_sse2_1:
	movdqa		%xmm0, [%esi]
	movdqa		%xmm4, [%esi+16]
	movdqa		%xmm1, [%esi+%edx]
	movdqa		%xmm5, [%esi+%edx+16]

    // 64bits interleave 1&0 -> 2&0
    // 64bits interleave 5&4 -> 6&4
	punpck(qdq, 0, 4, 1, 5, 2, 6)

	movntps		[%edi+16*0], %xmm0
	movntps		[%edi+16*1], %xmm2
	movntps		[%edi+16*2], %xmm4
	movntps		[%edi+16*3], %xmm6

    // update ptr
	lea			%esi, [%esi+%edx*2]
	add			%edi, 64

	dec			%ecx
	jnz			SwizzleBlock32_sse2_1

	pop			%edi
	pop			%esi

	ret			8

SwizzleBlock32_sse2_2:

    // WriteMask: 32bits to 4*32bits
	movd		%xmm7, %eax
	pshufd		%xmm7, %xmm7, 0

	.align 16
SwizzleBlock32_sse2_3:
	movdqa		%xmm0, [%esi]
	movdqa		%xmm4, [%esi+16]
	movdqa		%xmm1, [%esi+%edx]
	movdqa		%xmm5, [%esi+%edx+16]

    // 64bits interleave 1&0 -> 2&0
    // 64bits interleave 5&4 -> 6&4
	punpck(qdq, 0, 4, 1, 5, 2, 6)

    // save a mask copy
	movdqa		%xmm3, %xmm7
	pshufd		%xmm5, %xmm7, 0xe4

    // *dst & ~WriteMask
	pandn		%xmm3, [%edi+16*0]
    // *src & WriteMask
	pand		%xmm0, %xmm7
    // Final value to save
	por			%xmm0, %xmm3
	movntps		[%edi+16*0], %xmm0

	pandn		%xmm5, [%edi+16*1]
	pand		%xmm2, %xmm7
	por			%xmm2, %xmm5
	movntps		[%edi+16*1], %xmm2

	movdqa		%xmm3, %xmm7
	pshufd		%xmm5, %xmm7, 0xe4

	pandn		%xmm3, [%edi+16*2]
	pand		%xmm4, %xmm7
	por			%xmm4, %xmm3
	movntps		[%edi+16*2], %xmm4

	pandn		%xmm5, [%edi+16*3]
	pand		%xmm6, %xmm7
	por			%xmm6, %xmm5
	movntps		[%edi+16*3], %xmm6

    // update ptr
	lea			%esi, [%esi+%edx*2]
	add			%edi, 64

	dec			%ecx
	jnz			SwizzleBlock32_sse2_3

	pop			%edi
	pop			%esi

	ret			8

//
// SwizzleBlock16
//

.globl SwizzleBlock16_sse2
        .type SwizzleBlock16_sse2, @function
SwizzleBlock16_sse2:

	push		%ebx

    // srcpitch
	mov			%ebx, [%esp+4+4]
	mov			%eax, 4

	.align 16
SwizzleBlock16_sse2_1:
	movdqa		%xmm0, [%edx]
	movdqa		%xmm1, [%edx+16]
	movdqa		%xmm2, [%edx+%ebx]
	movdqa		%xmm3, [%edx+%ebx+16]

    // 16bits interleave 1&0 -> 4&0
    // 16bits interleave 3&2 -> 6&2
	punpck(wd, 0, 2, 1, 3, 4, 6)
    // 64bits interleave 2&0 -> 1&0
    // 64bits interleave 6&4 -> 5&4
	punpck(qdq, 0, 4, 2, 6, 1, 5)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm1
	movntps		[%ecx+16*2], %xmm4
	movntps		[%ecx+16*3], %xmm5

    // update ptr
	lea			%edx, [%edx+%ebx*2]
	add			%ecx, 64

	dec			%eax
	jnz			SwizzleBlock16_sse2_1

	pop			%ebx

	ret			4

//
// SwizzleBlock8
//

.globl SwizzleBlock8_sse2
        .type SwizzleBlock8_sse2, @function
SwizzleBlock8_sse2:

	push		%ebx

    // load srcpitch
	mov			%ebx, [%esp+4+4]
    // basic counter
	mov			%eax, 2

	.align 16
SwizzleBlock8_sse2_1:
	// col 0, 2

	movdqa		%xmm0, [%edx]
	movdqa		%xmm2, [%edx+%ebx]
    // update src pointer
	lea			%edx, [%edx+%ebx*2]

    // 2 3  0 1
	pshufd		%xmm1, [%edx], 0xb1
	pshufd		%xmm3, [%edx+%ebx], 0xb1
    // update src pointer
	lea			%edx, [%edx+%ebx*2]

    // 8bits interleave 1&0 -> 4&0
    // 8bits interleave 3&2 -> 6&2
	punpck(bw, 0, 2, 1, 3, 4, 6)
    // 16bits interleave 4&0 -> 1&0
    // 16bits interleave 6&2 -> 3&2
	punpck(wd, 0, 2, 4, 6, 1, 3)
    // 64bits interleave 2&0 -> 4&0
    // 64bits interleave 3&1 -> 5&1
	punpck(qdq, 0, 1, 2, 3, 4, 5)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm4
	movntps		[%ecx+16*2], %xmm1
	movntps		[%ecx+16*3], %xmm5

	// col 1, 3 (same as previous column)

    // 2 3  0 1
	pshufd		%xmm0, [%edx], 0xb1
	pshufd		%xmm2, [%edx+%ebx], 0xb1
    // update src pointer
	lea			%edx, [%edx+%ebx*2]

	movdqa		%xmm1, [%edx]
	movdqa		%xmm3, [%edx+%ebx]
    // update src pointer
	lea			%edx, [%edx+%ebx*2]

    // 8bits interleave 1&0 -> 4&0
    // 8bits interleave 3&2 -> 6&2
	punpck(bw, 0, 2, 1, 3, 4, 6)
    // 16bits interleave 4&0 -> 1&0
    // 16bits interleave 6&2 -> 3&2
	punpck(wd, 0, 2, 4, 6, 1, 3)
    // 64bits interleave 2&0 -> 4&0
    // 64bits interleave 3&1 -> 5&1
	punpck(qdq, 0, 1, 2, 3, 4, 5)

	movntps		[%ecx+16*4], %xmm0
	movntps		[%ecx+16*5], %xmm4
	movntps		[%ecx+16*6], %xmm1
	movntps		[%ecx+16*7], %xmm5

    // update dst pointer
	add			%ecx, 128

	dec			%eax
	jnz			SwizzleBlock8_sse2_1

	pop			%ebx

	ret			4

//
// SwizzleBlock4
//

.globl SwizzleBlock4_sse2
        .type SwizzleBlock4_sse2, @function
SwizzleBlock4_sse2:

	push		%ebx

    // load 4 0x0F0F0F0F
	mov         %eax, 0xf0f0f0f
	movd        %xmm7, %eax
	pshufd      %xmm7, %xmm7, 0

    // load srcpitch
	mov			%ebx, [%esp+4+4]
	mov			%eax, 2

	.align 16
SwizzleBlock4_sse2_1:
	// col 0, 2

	movdqa		%xmm0, [%edx]
	movdqa		%xmm2, [%edx+%ebx]
    //update src pointer
	lea			%edx, [%edx+%ebx*2]

	movdqa		%xmm1, [%edx]
	movdqa		%xmm3, [%edx+%ebx]
    // update src pointer
	lea			%edx, [%edx+%ebx*2]

    // - - - -  2 3 0 1
	pshuflw		%xmm1, %xmm1, 0xb1
	pshuflw		%xmm3, %xmm3, 0xb1
    // 6 7 4 5  - - - -
	pshufhw		%xmm1, %xmm1, 0xb1
	pshufhw		%xmm3, %xmm3, 0xb1

    // 4bits interleave 1&0 -> 4&0
    // 4bits interleave 3&2 -> 6&2
	punpcknb
    // 8bits interleave 4&0 -> 1&0
    // 8bits interleave 6&2 -> 3&2
	punpck(bw, 0, 2, 4, 6, 1, 3)
    // 8bits interleave 1&0 -> 4&0
    // 8bits interleave 3&2 -> 6&2
	punpck(bw, 0, 2, 1, 3, 4, 6)
    // 64bits interleave 2&0 -> 1&0
    // 64bits interleave 6&4 -> 3&4
	punpck(qdq, 0, 4, 2, 6, 1, 3)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm1
	movntps		[%ecx+16*2], %xmm4
	movntps		[%ecx+16*3], %xmm3

	// col 1, 3 (same as previous column)

	movdqa		%xmm0, [%edx]
	movdqa		%xmm2, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	movdqa		%xmm1, [%edx]
	movdqa		%xmm3, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	pshuflw		%xmm0, %xmm0, 0xb1
	pshuflw		%xmm2, %xmm2, 0xb1
	pshufhw		%xmm0, %xmm0, 0xb1
	pshufhw		%xmm2, %xmm2, 0xb1

	punpcknb
	punpck(bw, 0, 2, 4, 6, 1, 3)
	punpck(bw, 0, 2, 1, 3, 4, 6)
	punpck(qdq, 0, 4, 2, 6, 1, 3)

	movntps		[%ecx+16*4], %xmm0
	movntps		[%ecx+16*5], %xmm1
	movntps		[%ecx+16*6], %xmm4
	movntps		[%ecx+16*7], %xmm3

	add			%ecx, 128

	dec			%eax
	jnz			SwizzleBlock4_sse2_1

	pop			%ebx

	ret			4

//
// swizzling with unaligned reads
// Same functions as a above with movdqu instead of movdqa for the reads
// Movdqu is as fast as movdqa with aligned address... So do not bother, directly
// use movdqu
//

//
// SwizzleBlock32u
//

.globl SwizzleBlock32u_sse2
        .type SwizzleBlock32u_sse2, @function
SwizzleBlock32u_sse2:

	push		%esi
	push		%edi

	mov			%edi, %ecx
	mov			%esi, %edx
	mov			%edx, [%esp+4+8]
	mov			%ecx, 4

	mov			%eax, [%esp+8+8]
	cmp			%eax, 0xffffffff
	jne			SwizzleBlock32u_sse2_2

	.align 16
SwizzleBlock32u_sse2_1:
	movdqu		%xmm0, [%esi]
	movdqu		%xmm4, [%esi+16]
	movdqu		%xmm1, [%esi+%edx]
	movdqu		%xmm5, [%esi+%edx+16]

	punpck(qdq, 0, 4, 1, 5, 2, 6)

	movntps		[%edi+16*0], %xmm0
	movntps		[%edi+16*1], %xmm2
	movntps		[%edi+16*2], %xmm4
	movntps		[%edi+16*3], %xmm6

	lea			%esi, [%esi+%edx*2]
	add			%edi, 64

	dec			%ecx
	jnz			SwizzleBlock32u_sse2_1

	pop			%edi
	pop			%esi

	ret			8

SwizzleBlock32u_sse2_2:

	movd		%xmm7, %eax
	pshufd		%xmm7, %xmm7, 0

	.align 16
SwizzleBlock32u_sse2_3:
	movdqu		%xmm0, [%esi]
	movdqu		%xmm4, [%esi+16]
	movdqu		%xmm1, [%esi+%edx]
	movdqu		%xmm5, [%esi+%edx+16]

	punpck(qdq, 0, 4, 1, 5, 2, 6)

	movdqa		%xmm3, %xmm7
	pshufd		%xmm5, %xmm7, 0xe4

	pandn		%xmm3, [%edi+16*0]
	pand		%xmm0, %xmm7
	por			%xmm0, %xmm3
	movdqa		[%edi+16*0], %xmm0

	pandn		%xmm5, [%edi+16*1]
	pand		%xmm2, %xmm7
	por			%xmm2, %xmm5
	movdqa		[%edi+16*1], %xmm2

	movdqa		%xmm3, %xmm7
	pshufd		%xmm5, %xmm7, 0xe4

	pandn		%xmm3, [%edi+16*2]
	pand		%xmm4, %xmm7
	por			%xmm4, %xmm3
	movdqa		[%edi+16*2], %xmm4

	pandn		%xmm5, [%edi+16*3]
	pand		%xmm6, %xmm7
	por			%xmm6, %xmm5
	movdqa		[%edi+16*3], %xmm6

	lea			%esi, [%esi+%edx*2]
	add			%edi, 64

	dec			%ecx
	jnz			SwizzleBlock32u_sse2_3

	pop			%edi
	pop			%esi

	ret			8

//
// SwizzleBlock16u
//

.globl SwizzleBlock16u_sse2
        .type SwizzleBlock16u_sse2, @function
SwizzleBlock16u_sse2:

	push		%ebx

	mov			%ebx, [%esp+4+4]
	mov			%eax, 4

	.align 16
SwizzleBlock16u_sse2_1:
	movdqu		%xmm0, [%edx]
	movdqu		%xmm1, [%edx+16]
	movdqu		%xmm2, [%edx+%ebx]
	movdqu		%xmm3, [%edx+%ebx+16]

	punpck(wd, 0, 2, 1, 3, 4, 6)
	punpck(qdq, 0, 4, 2, 6, 1, 5)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm1
	movntps		[%ecx+16*2], %xmm4
	movntps		[%ecx+16*3], %xmm5

	lea			%edx, [%edx+%ebx*2]
	add			%ecx, 64

	dec			%eax
	jnz			SwizzleBlock16u_sse2_1

	pop			%ebx

	ret			4

//
// SwizzleBlock8u
//

.globl SwizzleBlock8u_sse2
        .type SwizzleBlock8u_sse2, @function
SwizzleBlock8u_sse2:

	push		%ebx

	mov			%ebx, [%esp+4+4]
	mov			%eax, 2

	.align 16
SwizzleBlock8u_sse2_1:
	// col 0, 2

	movdqu		%xmm0, [%edx]
	movdqu		%xmm2, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	movdqu		%xmm1, [%edx]
	movdqu		%xmm3, [%edx+%ebx]
	pshufd		%xmm1, %xmm1, 0xb1
	pshufd		%xmm3, %xmm3, 0xb1
	lea			%edx, [%edx+%ebx*2]

	punpck(bw, 0, 2, 1, 3, 4, 6)
	punpck(wd, 0, 2, 4, 6, 1, 3)
	punpck(qdq, 0, 1, 2, 3, 4, 5)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm4
	movntps		[%ecx+16*2], %xmm1
	movntps		[%ecx+16*3], %xmm5

	// col 1, 3

	movdqu		%xmm0, [%edx]
	movdqu		%xmm2, [%edx+%ebx]
	pshufd		%xmm0, %xmm0, 0xb1
	pshufd		%xmm2, %xmm2, 0xb1
	lea			%edx, [%edx+%ebx*2]

	movdqu		%xmm1, [%edx]
	movdqu		%xmm3, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	punpck(bw, 0, 2, 1, 3, 4, 6)
	punpck(wd, 0, 2, 4, 6, 1, 3)
	punpck(qdq, 0, 1, 2, 3, 4, 5)

	movntps		[%ecx+16*4], %xmm0
	movntps		[%ecx+16*5], %xmm4
	movntps		[%ecx+16*6], %xmm1
	movntps		[%ecx+16*7], %xmm5

	add			%ecx, 128

	dec			%eax
	jnz			SwizzleBlock8u_sse2_1

	pop			%ebx

	ret			4

//
// SwizzleBlock4u
//

.globl SwizzleBlock4u_sse2
        .type SwizzleBlock4u_sse2, @function
SwizzleBlock4u_sse2:

	push		%ebx

	mov         %eax, 0xf0f0f0f
	movd        %xmm7, %eax
	pshufd      %xmm7, %xmm7, 0

	mov			%ebx, [%esp+4+4]
	mov			%eax, 2

	.align 16
SwizzleBlock4u_sse2_1:
	// col 0, 2

	movdqu		%xmm0, [%edx]
	movdqu		%xmm2, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	movdqu		%xmm1, [%edx]
	movdqu		%xmm3, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	pshuflw		%xmm1, %xmm1, 0xb1
	pshuflw		%xmm3, %xmm3, 0xb1
	pshufhw		%xmm1, %xmm1, 0xb1
	pshufhw		%xmm3, %xmm3, 0xb1

	punpcknb
	punpck(bw, 0, 2, 4, 6, 1, 3)
	punpck(bw, 0, 2, 1, 3, 4, 6)
	punpck(qdq, 0, 4, 2, 6, 1, 3)

	movntps		[%ecx+16*0], %xmm0
	movntps		[%ecx+16*1], %xmm1
	movntps		[%ecx+16*2], %xmm4
	movntps		[%ecx+16*3], %xmm3

	// col 1, 3

	movdqu		%xmm0, [%edx]
	movdqu		%xmm2, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	movdqu		%xmm1, [%edx]
	movdqu		%xmm3, [%edx+%ebx]
	lea			%edx, [%edx+%ebx*2]

	pshuflw		%xmm0, %xmm0, 0xb1
	pshuflw		%xmm2, %xmm2, 0xb1
	pshufhw		%xmm0, %xmm0, 0xb1
	pshufhw		%xmm2, %xmm2, 0xb1

	punpcknb
	punpck(bw, 0, 2, 4, 6, 1, 3)
	punpck(bw, 0, 2, 1, 3, 4, 6)
	punpck(qdq, 0, 4, 2, 6, 1, 3)

	movntps		[%ecx+16*4], %xmm0
	movntps		[%ecx+16*5], %xmm1
	movntps		[%ecx+16*6], %xmm4
	movntps		[%ecx+16*7], %xmm3

	add			%ecx, 128

	dec			%eax
	jnz			SwizzleBlock4u_sse2_1

	pop			%ebx

	ret			4

#endif

#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif
