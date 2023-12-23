#!/usr/bin/env bash	

count=0
echo > out.log

while true
do
	./buggy.sh &> out.log
	if [[ $? -ne 0 ]]; then
		cat out.log
		echo "failed after $count times"
		break
	fi
	((count++))

done
