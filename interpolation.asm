# Wiktor Lazarski -- 14/01/2020
# interpolation.asm -- draws smoothly shadowed rectangle in MARS Bitmap Display.
# Inputs :  width of rectangle, height of rectangle, 4 colors of each pixel
# Output :  colored pixel of a rectangle in a heap address range 

	.data
heap_addr:	.word 0		#stores address to the begging of heap memory map
alloc_bites:	.word 0		#stores value of currently allocated bites

#interpolation parameters for each color
rgb_xgains:	.word 0, 0, 0
rgb_ygains:	.word 0, 0, 0
rgb_gains_diff:	.word 0, 0, 0

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

	#check correctness of the input
	.macro check_input(%input)
	blt	%input, $zero, terminate
	.end_macro

#########################################################################################################

	.text 
#============================== MAIN ==========================================
main:
#============================= READING INPUTS AND ALLOCATING BITES ============
	read_int()		#reads width
	move	$s0, $v0	#hold width of rectangle
	check_input($s0)
		
	read_int()		#reads height
	move	$s1, $v0
	check_input($s1)
	
	#check if additional allocation of memory is needed
	la	$t0, alloc_bites
	lw	$t1, ($t0)
	#bites_needed = ((rect_height-1) * frame_width + rect_width) * 4
	subiu	$t0, $s1, 1
	li	$t2, FRAME_WIDTH
	multu	$t0, $t2
	mflo	$t0	#moves the result of multiplication 
	addu	$t0, $t0, $s0
	sll	$t0, $t0, 2   #multiply result by 4 (sizeof(pixel) == 4)
	
	bge	$t1, $t0, skip_allocation
	subu	$a0, $t0, $t1
	li	$v0, 9
	syscall		#allocate remaining bites
	
	la	$t1, alloc_bites	
	sw	$t0, ($t1)		#save value of currently allocated bites
	
	la	$t0, heap_addr	#save ptr to the beggining of heap memory map
	lw	$t1, ($t0)	
	bnez	$t1, skip_allocation
	sw	$v0, ($t0)
	
skip_allocation:
	#restore register to point at the beggining of heap memory map
	la	$t0, heap_addr
	lw	$s2, ($t0)
	
	#color reading
	read_int()		#reads 1st color
	move	$s3, $v0
	check_input($s3)
	
	read_int()		#reads 2nd color
	move	$s4, $v0
	check_input($s4)
	
	read_int()		#reads 3rd color
	move	$s5, $v0
	check_input($s5)
	
	read_int()		#reads 4rd color
	move	$s6, $v0
	check_input($s6)

#=================== COMPUTE COLOR GAINS ========================================
	#Blue color gains
	andi	$a0, $s3, BLUE_BIT_MASK
	andi	$a1, $s4, BLUE_BIT_MASK
	andi	$a2, $s5, BLUE_BIT_MASK
	andi	$a3, $s6, BLUE_BIT_MASK
	jal	compute_gains
	la	$t0, rgb_xgains
	la	$t1, rgb_ygains
	la	$t2, rgb_gains_diff
	sw	$v0, ($t0)
	sw	$v1, ($t1)
	sw	$a0, ($t2)
	
	#Green color gains
	andi	$a0, $s3, GREEN_BIT_MASK
	srl	$a0, $a0, 8
	andi	$a1, $s4, GREEN_BIT_MASK
	srl	$a1, $a1, 8
	andi	$a2, $s5, GREEN_BIT_MASK
	srl	$a2, $a2, 8
	andi	$a3, $s6, GREEN_BIT_MASK
	srl	$a3, $a3, 8
	jal	compute_gains
	sw	$v0, 4($t0)
	sw	$v1, 4($t1)
	sw	$a0, 4($t2)
	
	#Red color gains
	andi	$a0, $s3, RED_BIT_MASK
	srl	$a0, $a0, 16
	andi	$a1, $s4, RED_BIT_MASK
	srl	$a1, $a1, 16
	andi	$a2, $s5, RED_BIT_MASK
	srl	$a2, $a2, 16
	andi	$a3, $s6, RED_BIT_MASK
	srl	$a3, $a3, 16
	jal	compute_gains
	sw	$v0, 8($t0)
	sw	$v1, 8($t1)
	sw	$a0, 8($t2)
	
#=================== DRAWING RECTANGLE ==========================================
	#blue parameters
	andi	$t4, $s3, BLUE_BIT_MASK	#previous in col pixel blue color
	sll	$t4, $t4, 16		#representing color as 16.16 fixed point
	move	$t5, $t4		#previous in row pixel blue color
	la	$t0, rgb_xgains	
	lw	$t3, ($t0)		#column gain
	
	#green parameters
	andi	$t6, $s3, GREEN_BIT_MASK	#previous in col pixel green color
	sll	$t6, $t6, 8		#representing color as 16.16 fixed point
	move	$t7, $t6		#previous in row pixel green color
	lw	$t8, 4($t0)		#column gain
	
	#red parameters
	andi	$s4, $s3, RED_BIT_MASK	#previous in col pixel red color
	move	$s5, $s4		#previous in row pixel red color
	lw	$s6, 8($t0)		#column gain
	
	li	$t0, 0		#row counter
next_row:
	bge	$t0, $s1, main
	addiu	$t0, $t0, 1		#inc row counter
	li	$t1, 0		#col counter
draw_line:
	bgt	$t1, $s0, apply_stride
	sll	$t2, $t1, 2		#mult col cnt * 4
	addu	$t2, $t2, $s2		#addr of pixel to be drawn
	
	#compute color and cast fixed point to integers
	srl	$t9, $t4, 16		#blue component
	
	srl	$s3, $t6, 16		
	sll	$s3, $s3, 8 		#green component
	
	add	$t9, $t9, $s3		#blue and green in a word
	
	srl	$s3, $s4, 16
	sll	$s3, $s3, 16		#red component
	
	add	$t9, $t9, $s3		#red, blue and green in a word
	
	sw	$t9, ($t2)		#save pixel color on heap
	addiu	$t1, $t1, 1		#inc col counter
	
	#update color components by current column gain
	add	$t4, $t4, $t3		#add blue col gain
	#check color ranges
	bgt	$t4, 0xFF0000, set_max_blue
	blt	$t4, 0x10000, set_min_blue
	
green_col_update:
	add	$t6, $t6, $t8		#add green col gain
	#check color ranges
	bgt	$t6, 0xFF0000, set_max_green
	blt	$t6, 0x10000, set_min_green

red_col_update:	
	add	$s4, $s4, $s6		#add red col gain
	#check color ranges
	bgt	$s4, 0xFF0000, set_max_red
	blt	$s4, 0x10000, set_min_red
	b	draw_line
	
set_max_blue:	
	li	$t4, 0xFF0000
	b	green_col_update
set_min_blue:
	li	$t4, 0x10000
	b	green_col_update
	
set_max_green:
	li	$t6, 0xFF0000
	b	red_col_update
set_min_green:
	li	$t6, 0x10000
	b	red_col_update
	
set_max_red:	
	li	$s4, 0xFF0000
	b	draw_line
set_min_red:	
	li	$s4, 0x10000
	b	draw_line
	
apply_stride:
	li	$t2, FRAME_WIDTH
	sll	$t2, $t2, 2
	addu	$s2, $s2, $t2		#move main ptr to next row
	
	#update color components by current row gain
	la	$s7, rgb_ygains	
	lw	$t9, ($s7)		#row blue gain
	add	$t4, $t5, $t9		#add blue row gain
	move	$t5, $t4
	
	lw	$t9, 4($s7)		#row green gain
	add	$t6, $t7, $t9		#add green row gain
	move	$t7, $t6
	
	lw	$t9, 8($s7)		#row red gain
	add	$s4, $s5, $t9		#add red row gain
	move	$s5, $s4
	
	#update color gains
	la	$s7, rgb_gains_diff	
	lw	$t9, ($s7)		#row blue gain
	add	$t3, $t3, $t9		#add blue row gain
	
	lw	$t9, 4($s7)		#row green gain
	add	$t8, $t8, $t9		#add green row gain
	
	lw	$t9, 8($s7)		#row red gain
	add	$s6, $s6, $t9		#add red row gain
	
	b	next_row
	
terminate:
	#exit
	li	$v0, 10
	syscall

################################################################################################################

# Funtion which computes three parameters needed for interpolation.
# Input : color1, color2, width, height
# Ouput : dcol/dx, dcol/ dy, d(dcol/dx) / dy
	.text
compute_gains:
	#create stack frame
	subiu	$sp, $sp, 32
	sw	$ra, 28($sp)
	sw	$fp, 24($sp)
	addiu	$fp, $sp, 32
	
	#upper part of an image d(col) / dx
	sub	$t3, $a1, $a0
	sll	$t3, $t3, 16
	div	$t3, $s0
	mflo	$t3		#$t3 = (col2 - col1) / width
	
	#d(col) / dy
	sub	$t4, $a2, $a0
	sll	$t4, $t4, 16
	div	$t4, $s1
	mflo	$t4		#$t4 = (col3 - col1) / height
	
	#lower part of image (d(col) / dx)
	andi	$t6, $s6, BLUE_BIT_MASK
	sub	$t5, $a3, $a2
	sll	$t5, $t5, 16
	div	$t5, $s0
	mflo	$t5		#$t5 = (col4 - col3) / width
	#gain of gains determines how column gain should change in every row iteration
	sub	$t5, $t5, $t3
	div	$t5, $s1
	mflo	$t5
	
	move	$v0, $t3
	move	$v1, $t4
	move	$a0, $t5
	
	#remove stack frame
	lw	$ra, 28($sp)
	lw	$fp, 24($fp)
	addiu	$sp, $sp, 32
	jr	$ra
