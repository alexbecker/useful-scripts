#!/bin/bash
# accepts flag -l to include mixed case letters, -s to include a symbol

echo -n "Master Password: "
stty -echo	# turns off echo
read master_pwd
stty echo	# turns on echo
echo		# generates newline

echo -n "Service Name: "
read name

hash=$(echo $master_pwd $name | sha256sum)
length=12		# length of password generated
result=${hash:0:$length}

for flag in $@
	do
	if [ "$flag" == "-l" ]
		then while [[ $result =~ ^[^A-Z]*$ ]]
			do
			if [[ $result =~ ^[^a-z]*$ ]]
				then length=`expr $length + 1`
					 result=${hash:0:$length}
				else index=`expr index "$result" '[a-z]'`
					 result=$(echo $result | sed 's/\([a-z]\)/\U\1/')
			fi
		done
		while [[ $result =~ ^[^a-z]*$ ]]
			do length=`expr $length + 1`
			   result=${hash:0:$length}
		done
	fi
	if [ "$flag" == "-s" ]
		then result+="*"
	fi
done

echo $result
