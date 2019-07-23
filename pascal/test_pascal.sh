#!/bin/bash

declare -a files
files=(a t0 t1 t2 t3 t4 t5 t6 t7 t8 t10 t11 t12 t13 gcd arithtest t14)

for file in ${files[@]}
do
	echo "Checking ${file}.pas file"
	../compilator <"files/${file}.pas"
	../reference/komp <"files/${file}.pas" &> /dev/null
	sed -e "s/;.*$//" output.asm > output_without_comments.asm
	DIFF=$(diff -EZb my_output.asm output_without_comments.asm)
	if [ $? -eq 0 ]; then
		echo "OK"
	else
		echo "${DIFF}"
		if [ "${file}" == "t14" ]; then
			continue
		fi
		VM_RESULT=$(../reference/vm output.asm)
		MY_RESULT=$(../reference/vm my_output.asm)
		if [ "${VM_RESULT}" != "" ]; then
			echo "${VM_RESULT}"
			printf "== \n"
			echo "${MY_RESULT}"
		fi
	fi
	printf "\n"
done
