#!/bin/perl6

class LogActions {
    method TOP($/) {
        say "TOP matched: $/";
        $/.make: {
            ip => ~$<ip>,
            timestamp => ~$<timestamp>,
        }
    }

    method ip($/) {
        say "IP matched: $<ip>";
        $/.make: ~$<ip>;
    }

    method timestamp($/) {
        say "Timestamp matched: $<timestamp>";
        $/.make: ~$<timestamp>;
    }
}

grammar LogGrammar {
    rule TOP {
        ^ <ip> \s+ .*? \s+ <timestamp> [.*]?
    }

    # IP addresses delimited by '.' and have 4 sets of 1-3 decimal digits
    token ip {
        \d ** {1..3} % '.'
    }

    # Timestamps in the format: [17/May/2015:10:05:46 +0000]
    token timestamp {
        '[' \d ** 2 '/' <[A..Za..z]> ** 3 '/' \d ** 4 ':' \d ** 2 ':' \d ** 2 ':' \d ** 2 ' ' <[-+]> \d ** 4 ']'
    }
}

sub MAIN(Str $log-file) {

    # function expects an input argument (name of log file)
    die "Usage $*PROGRAM_NAME <log-file-path>" unless $log-file;

    # create a variable to hold the contents of the input file
    my $log-content = slurp($log-file);

    # instantiate the grammar and action defined above
    my $log-grammar = LogGrammar.new;
    my $log-actions = LogActions.new;

    # create a hash for the IP addresses and timestamps
    my %ip-addresses;
    my %timestamps;

    # iterate through each entry in the log file
    for $log-content.lines -> $entry {
        say "Processing entry: $entry";

        # handle errors
        try {
            my $results = $log-grammar.parse($entry, :actions($log-actions));

            if $results {
                my $parsed-entry = $results.made;
                say "Parsed entry: ", $parsed-entry;
                %ip-addresses{$parsed-entry<ip>}++;
                %timestamps{$parsed-entry<timestamp>}++;
            } else {
                say "No match for entry: $entry";
            }
        }

        CATCH {
            warn "Error parsing the log entry: $_ ";
        }
    }

    # display the number of unique IP addresses and timestamps
    say "The number of unique IP addresses: ", %ip-addresses.keys.elems;
    say "The number of unique timestamps: ", %timestamps.keys.elems;
}

