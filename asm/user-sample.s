.set noreorder
.set noat
.globl __start
.section text

__start:
.text
	li      $a0, 0x80400000
    li      $a1, 0x80500000
    li      $a2, 0x80600000
    li      $a3, 40000
	addiu   $t0,$t0,1
	addiu   $s1,$s1,2
	addiu   $s2,$s2,30
    # // a0 -> a
    # // a1 -> b
    # // a2 -> c
    # // a3 -> n
    # // v0 -> #移位计数器
	# // t0 = 1
	# // s1 = 2
	# // s2 = 30
	# //   s3
    # // t1 -> i #减法结果
    # // t2 -> #a右移结果
    # // t3 -> #b右移结果
	# // t4 移位计数器
	# // t5 -> A 
	# // t6 -> B
	# // t7 尾数清零版本
	# // v1 -> #留位计数器
	   
loop1:
    lw      $t5,0($a0)#40000
    lw      $t6,0($a1)#50000
	or      $t7,$t5,$0#
	sub		$t1,$t5,$t6
    bgtz    $t1,begin #>0就跳转
    ori   $zero, $zero, 0 # nop
	sw		$t5,($a2)
	beq     $0,$0,store
	ori   $zero, $zero, 0 # nop
	
begin:    #先拆分
	beq     $t0,$t6,loop2 #b == 1
	ori   $zero, $zero, 0 # nop
	
right:
	sll $t2,$t5,1
    sll $t3,$t6,1
	mul $v1,$v1,$s1 #111
	addiu $v1,$v1,1
	addiu $t4,$t4,2 #cnt*2
	addiu $v0,$v0,1 #cnt
	bne $t3,$t0,right #不 = 1
	ori   $zero, $zero, 0 # nop
loop2:
	mul $t7,$t2,$t4 #A无尾
	and $t2,$t2,$s2 #去1
	mul $t3,$t6,$v0 #B*n
	sub $t3,$t3,$t7 #前余项
	and $t7,$t5,$v1 #后余项
	add $t7,$t7,$t3
	bne $t7,$t6,loop2end
	ori   $zero, $zero, 0 # nop
	and $t7,$t7,$0 #等于0就清空
loop2end:
	sw $t7,0($a2)
store:
	addiu $a0,$a0,4 #A+
	addiu $a3,$a3,-4 #C-
	addiu $a1,$a1,4	#B+
	and $v0,$v0,$0
	and $t4,$t4,$0
	and $v1,$v1,$0
	bne $a3,$0,loop1
	ori   $zero, $zero, 0 # nop
	
	jr    $ra
    ori   $zero, $zero, 0 # nop
	