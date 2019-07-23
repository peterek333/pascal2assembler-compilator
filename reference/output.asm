
	jump.i	 #lab0
lab0:
	mul.i	#2,#3,52
	div.i	52,#4,56
	add.i	#1,56,60
	inttoreal.i	60,16
	mul.i	#2,#3,64
	inttoreal.i	64,76
	div.r	76,#4.0,68
	inttoreal.i	#1,92
	add.r	92,68,84
	mov.r	84,24
	write.r	16
	write.r	24
	mov.i	#4,40
	mov.i	#5,44
	div.i	40,44,100
	mul.i	44,40,104
	add.i	100,104,108
	mod.i	44,40,112
	add.i	108,112,116
	sub.i	44,40,120
	add.i	116,120,124
	mov.i	124,48
	write.i	48
	jg.i	48,#10,#lab1
	mov.i	#0,128
	jump.i	 #lab2
lab1:
	mov.i	#1,128
lab2:
	je.i	128,#0,#lab3
	inttoreal.i	#10,32
	jump.i	 #lab4
lab3:
	inttoreal.i	#5,32
lab4:
	write.r	32
	mov.i	#0,40
	mov.i	#1,44
	mov.i	#3,48
	and.i	44,48,132
	or.i	40,132,136
	je.i	136,#0,#lab5
	write.i	#1
	jump.i	 #lab6
lab5:
	write.i	#0
lab6:
lab8:
	jl.i	40,48,#lab9
	mov.i	#0,140
	jump.i	 #lab10
lab9:
	mov.i	#1,140
lab10:
	je.i	140,#0,#lab7
	write.i	40
	add.i	40,#1,144
	mov.i	144,40
	jump.i	 #lab8
lab7:
	inttoreal.i	#6,156
	mod.r	#5.0,156,148
	mov.r	148,16
	write.r	16
	exit