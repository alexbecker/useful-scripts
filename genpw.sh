#!/bin/bash
# USAGE: genpw.sh [-i [-f file] | [-a] [-c] [-l length] [-s]] [-f file] service-name]
# Generates a password from a master password and a service name.
# When a service name is used for the first time, the flags used are saved in a data file (default .$0).
# OPTIONS:
#	-i	Initialize. Saves a hash of the master password in the data file.
# 	-a	Includes an alphabetic character. Overwrites any preferences in the data file.
# 	-c	Mixed case. If -c is used, -a becomes redundant. Overwrites any preferences in the data file.
#	-l	Returns a password of at least a set length. Overwrites any preferences in the data file.
#	-s	Append special character '*'. Overwrites any preferences in the data file.
#	-f	Use a specified data file. Default is ".genpw_data".

# save name of program
name=$0

# default values
initialize=false
alphabetic=false
mixed_case=false
length=12
special_char=false
data_file=".genpw_data"
store_prefs=false

# process flags
while getopts ":acil:sf:" opt; do
	case $opt in
		a)	alphabetic=true
			store_prefs=true;;
		i)
			initialize=true;;
		c)
			alphabetic=true
			mixed_case=true
			store_prefs=true;;
		l)
			length=$OPTARG
			store_prefs=true;;
		s)
			special_char=true
			store_prefs=true;;
		f)
			data_file=$OPTARG;;
		\?)
			echo "Invalid option. USAGE: genpw.sh [-i [-f file] | [-a] [-c] [-l length] [-s]] [-f file] service-name]"
			exit 1
	esac
done

# shift past flags
shift $(($OPTIND - 1))

# get service-name
service_name=$1

# get master password
echo -n "Master Password: "
stty -echo	# turns off echo
read master_pwd
stty echo	# turns on echo
echo		# generates newline

# calculate hash
master_hash=$(echo $master_pwd | sha256sum | sed 's/  -//')

# if -i flag is set, store master password
if $initialize
	then
		# warn user; this overwrites all data
		echo "WARNING: this will overwrite all saved data in $data_file"
		echo -n "Proceed? (y/N): "
		read proceed
		if [[ $proceed == "y" ]]
			then
				# create $data_file if it does not already exist
				touch $data_file
				# write to $data_file
				echo "master_hash $master_hash" > $data_file
				exit 0
			else
				# if user opts not to proceed, exit with failure
				exit 1
		fi
fi

# if -a -c -l or -s flags are set, remove any previous entry from the data file and store a new one
if $store_prefs
	then
		sed -i "/^$service_name/ d" $data_file
		echo "$service_name $alphabetic $mixed_case $length $special_char" >> $data_file
fi

# make sure master_hash is checked
unchecked=true

# loop through lines in data_file
while read line; do
	# get the line as an array
	arr=($line)

	# check master password hash
	if [[ ${arr[0]} == "master_hash" ]]
		then
			if [[ ${arr[1]} != $master_hash ]]
				then
					# if master password hash does not match, print error and exit with failure
					echo "Error: hash mismatch"
					exit 1
			fi
			unchecked=false
	fi

	# retrieve proper settings from data_file
	if [[ ${arr[0]} == $service_name ]]
		then
			alphabetic=${arr[1]}
			mixed_case=${arr[2]}
			length=${arr[3]}
			special_char=${arr[4]}
			break
	fi
done < $data_file

# if master hash has not been checked, print warning
if $unchecked
	then
		echo "Warning: master password hash not found in $data_file"
		echo "Use the -f option to specify a different data file or -i to set the master hash."
fi

# calculate hash and password
full_hash=$(echo $master_pwd $service_name | sha256sum)
password=${full_hash:0:$length}

# extend password until it contains an alphabetic character
if $alphabetic
	then while [[ $password =~ ^[^a-z]*$ ]]; do
			length=$(($length + 1))
			password=${full_hash:0:$length}
		done
fi

# convert first alphabetic character to uppercase
if $mixed_case
	then
		password=$(echo $password | sed 's/\([a-z]\)/\U\1/')

		# in case this was the only alphabetic character, get another
		while [[ $password =~ ^[^a-z]*$ ]]; do
			length=$(($length + 1))
			password=${full_hash:0:$length}
		done
fi

# add special character
if $special_char
	then
		password="$password*"
fi

echo $password
