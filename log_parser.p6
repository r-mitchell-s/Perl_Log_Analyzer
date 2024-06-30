#!/bin/perl6

# action methods are triggered when the rule/token of the same name is matched
class LogActions {

	# when any ip address matches, call this method to create a hash of IPs
	method TOP($/) {

		# the make method attaches a piece of data to the match object (in this case a hash)
		$/.make: {

			# hash key is the , the value is the coerced string of the matched IP address
			ip => ~$<ip>,
			timestamp => ~$<timestamp>,
		}
	}
	
	# whenever an ip is matched, it gets attached to the match object (and used in TOP)
	method ip($/) {
		$/.make: $<ip>;
	}

	# whenever a timestamp is matched, attach to the match object
	method timestamp($/) {
		$/.make: $<timestamp>;
	}
}

# grammar declaration, defines what patterns in the logfile will get matched
grammar LogGrammar {
	
	# TOP matches any series of characters that starts with an IP address
	rule TOP {
	[.*]? <ip> \s* '-' \s* '-' \s* <timestamp> [.*]?
	}

	# IP addresses delimited by '.' and have 4 sets of 1-3 decimal digits. IP token used in TOP 
	token ip {
		[ <[0..9]> ** {1..3} ] ** 4 % '.'
	}

	# matching timestamps by 
	token timestamp { 
		'[' \d ** 2 '/' <[A..Za..z]> ** 3 '/' \d ** 4 ':' \d ** 2 ':' \d ** 2 ':' \d ** 2 ' ' <[-+]> \d ** 4 ']'
	}
}

# subroutine definition for parsing of logfile passed in as argument
sub MAIN(Str $log-file) {

	# function expects an input argument (name of log file)
	die "Usage $*PROGRAM_NAME <log-file-path>" unless $log-file;

	# create a variable to hold the contents of the input file
	my $log-content = slurp($log-file);

	# instantiate the grammar and action defined above
	my $log-grammar = LogGrammar.new;
	my $log-actions = LogActions.new;

	# create a hash for the IP addresses
	my %ip-addresses;
	my %timestamps;

	# iterate through each entry in the log file
	for $log-content.lines -> $entry {
		
		# handle errors, printing a parsing warning if the following fails
		try {
			my $results = $log-grammar.parse($entry, :actions($log-actions));
		
			# if parsed successfully, the line's IP address is added to the hash	
			if $results {
				my $parsed-entry = $results.made;
				%ip-addresses{$parsed-entry<ip>}++;
				%timestamps{$parsed-entry<timestamp>}++;
			}
		}
	
		CATCH {
			warn "Error parsing the log entry: $_ ";
		}
	}
	
	#display the number of unique IP addresses
	say "The number of unique IP addresses: ", %ip-addresses.keys.elems; 
	for %ip-addresses.keys -> $key {
		say $key;
	}

	# display the timestamps that have been parsed
	say "The number of unique timestamps: ", %timestamps.keys.elems;
	for %timestamps.keys -> $key {
		say $key;
	}
}
