#!/usr/bin/awk -f
BEGIN {
	reading_input = 1;
	input = "";
	test_count = 0;
}

/#/ {
	# skip comments
	next;
}

/;/ {
	# run test_program and read its output
	cmd = "echo \"" input "\" | " test_program;
	actual_output = "";
	while ( (cmd | getline line) > 0 ) {
		actual_output = actual_output line "\n";
	}
	close(cmd);

	# stop reading and reset input
	reading_input = 0;
	input = "";

	next;
}

// {
	if (reading_input) {
		# read input
		input = input $0 "\n";
	} else if (NF == 0) {
		# print results of last test
		if (actual_output == desired_output) {
			printf("%d. Pass\n", test_count++);
		} else {
			printf("%d. Fail\n", test_count++);
			printf("Desired:\n%sActual:\n%sLengths: %d, %d\n", desired_output, actual_output, length(desired_output), length(actual_output)); 
		}

		# start reading input again, reset desired_output
		reading_input = 1;
		desired_output = "";
	} else {
		# read desired_output
		desired_output = desired_output $0 "\n";
	}
}
