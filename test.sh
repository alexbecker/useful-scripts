# USAGE: test.sh test_program test_data
# Runs test_program on the the inputs in the test_data file.
# Reports any output which differs from the expected output.
# test_data file format:
# 	The character '#' begins a comment.
#	Excluding comments, the file consists of blocks of the form
# 	INPUT
# 	;
#	DESIRED OUTPUT
#	seperated by a blank line. The file must end with a blank line as well.
#	NOTE: Currently the input and output cannot contain the character ';'.

cat $2 | $(dirname $0)/test.awk test_program="$1"
