# Wiktor Lazarski --03/01/2020
# rgb_interpolation.asm -- draws smoothly shadowed rectangle using bilinear interpolation in MARS Bitmap Display.
# Inputs :  width of rectangle, height of rectangle, 4 colors of each pixel
# Output :  colored pixel of a rectangle in a heap address range 
	
	.data
	
	.eqv	FRAME_WIDTH 1024	#bitmap display width
	
	#masks used to extract values of particular color specified in the input
	.eqv	RED_BIT_MASK 0xFF0000	
	.eqv	GREEN_BIT_MASK 0x00FF00
	.eqv	BLUE_BIT_MASK 0x0000FF

#--------------------------------------------------------------------------------------------------------

	#reads single integer and stores it in $v0
	.macro read_int()	
	li	$v0, 5
	syscall
	.end_macro
	
#--------------------------------------------------------------------------------------------------------
	
	#allocates memory for pixels of bitmap (registers used $a0, $v0)
	.macro pixel_alloc(%w, %h)	
	#pixel_to_alloc = ((height-1) * frame_width + width) * 4
	subiu	$a0, %h, 1
	li	$t0, FRAME_WIDTH
	multu	$a0, $t2
	mflo	$a0	#moves the result of multiplication 
	addu	$a0, $a0, %w
	sll	$a0, $a0, 2   #multiply result by 4 (sizeof(pixel) == 4)
	
	li	$v0, 9	#call allocation 
	syscall
	.end_macro

#--------------------------------------------------------------------------------------------------------
	
	#performs computation of how color should change according to X axis 		
	.macro interpolation_along_x(%left_col, %right_col)
	sub	$t3, $s0, $t1
	sll	$t3, $t3, 16
	div	$t3, $s0
	mflo	$t3
	mult	%left_col, $t3
	mflo	$t3
	srl	$t3, $t3, 16
	
	move	$t4, $t1
	sll	$t4, $t4, 16
	div	$t4, $s0
	mflo	$t4
	mult	%right_col, $t4
	mflo	$t4
	srl	$t4, $t4, 16
	
	add	$t3, $t3, $t4
	.end_macro
	
#--------------------------------------------------------------------------------------------------------
	
	#performs computation of how color should change according to Y axis and outputs final color of pixel
	.macro interpolation_along_y(%r1_val, %r2_val)
	move	$t3, $t0
	sll	$t3, $t3, 16
	div	$t3, $s1
	mflo	$t3
	mult	$t3, %r1_val
	mflo	$t3
	srl	$t3, $t3, 16
	
	sub	$t4, $s1, $t0
	sll	$t4, $t4, 16
	div	$t4, $s1
	mflo	$t4
	mult	$t4, %r2_val
	mflo	$t4
	srl	$t4, $t4, 16
	
	add	$t3, $t3, $t4
	.end_macro
	

	.text
#============================== MAIN ==========================================
main:
#============================= READING INPUTS AND ALLOCATING ==================
	read_int()		#reads width
	move	$s0, $v0	#hold width of rectangle
		
	read_int()		#reads height
	move	$s1, $v0
	
	pixel_alloc($s0, $s1)	#allocate memory on heap
	move	$s2, $v0	#$s2 points now to allocated heap
	
	#color reading
	read_int()		#reads 1st color
	move	$s3, $v0
	read_int()		#reads 2nd color
	move	$s4, $v0
	read_int()		#reads 3rd color
	move	$s5, $v0
	read_int()		#reads 4rd color
	move	$s6, $v0
	
#=================== DRAWING RECTANGLE ==========================================
	li	$t0, 0		#row counter
next_row:
	bge	$t0, $s1, terminate
	addiu	$t0, $t0, 1		#inc row counter
	li	$t1, 0		#col counter
draw_line:
	bgt	$t1, $s0, apply_stride
	sll	$t2, $t1, 2		#mult col cnt * 4
	addu	$t2, $t2, $s2		#addr of pixel to be drawn
	
	xor	$t8, $t8, $t8
	xor	$t9, $t9, $t9
	#compute color
	#interpolation along X axis
	#compute f(R1) of blue
	andi	$t6, $s5, BLUE_BIT_MASK
	andi	$t7, $s6, BLUE_BIT_MASK	
	interpolation_along_x($t6, $t7)	#output blue value color in $t3
	move	$t8, $t3
	
	#compute f(R2) of blue
	andi	$t6, $s3, BLUE_BIT_MASK
	andi	$t7, $s4, BLUE_BIT_MASK	
	interpolation_along_x($t6, $t7)	#output blue value color in $t3
	move	$t9, $t3
	
	#interpolation along Y axis of blue
	interpolation_along_y($t8, $t9)
	move	$s7, $t3
	
	#compute f(R1) of green
	andi	$t6, $s5, GREEN_BIT_MASK
	andi	$t7, $s6, GREEN_BIT_MASK	
	srl	$t6, $t6, 8
	srl	$t7, $t7, 8
	interpolation_along_x($t6, $t7)	#output green value color in $t3
	move	$t8, $t3
	
	#compute f(R2) of green
	andi	$t6, $s3, GREEN_BIT_MASK
	andi	$t7, $s4, GREEN_BIT_MASK	
	srl	$t6, $t6, 8
	srl	$t7, $t7, 8
	interpolation_along_x($t6, $t7)	#output green value color in $t3
	move	$t9, $t3
	
	#interpolation along Y axis of green
	interpolation_along_y($t8, $t9)
	sll	$t3, $t3, 8
	addu	$s7, $s7, $t3
	
	#compute f(R1) of red
	andi	$t6, $s5, RED_BIT_MASK
	andi	$t7, $s6, RED_BIT_MASK	
	srl	$t6, $t6, 16
	srl	$t7, $t7, 16
	interpolation_along_x($t6, $t7)	#output red value color in $t3
	move	$t8, $t3
	
	#compute f(R2) of red
	andi	$t6, $s3, RED_BIT_MASK
	andi	$t7, $s4, RED_BIT_MASK	
	srl	$t6, $t6, 16
	srl	$t7, $t7, 16
	interpolation_along_x($t6, $t7)	#output red value color in $t3
	move	$t9, $t3
	
	#interpolation along Y axis of red
	interpolation_along_y($t8, $t9)
	sll	$t3, $t3, 16
	addu	$s7, $s7, $t3
	
	sw	$s7, ($t2)		#save pixel color on heap
	
	addiu	$t1, $t1, 1		#inc col counter
	b	draw_line
	
apply_stride:
	li	$t2, FRAME_WIDTH
	sll	$t2, $t2, 2
	addu	$s2, $s2, $t2		#move main ptr to next row
	b	next_row

terminate:
	li	$v0, 10
	syscall
