#!/bin/sh
file_count=0
dir_count=0
for item in *
do 
	if [ -d "$item" ]
	then
	 	dir_count=$((dir_count+1))
	elif [ -f "$item" ]
	then
	 	file_count=$((file_count+1))
	else
		echo "$item X"
	fi
done
echo "파일 수: $file_count"
echo "디렉토리 수: $dir_count"
exit 0
