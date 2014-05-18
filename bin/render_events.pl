#!/usr/bin/env perl

use strict;
use warnings;

use IO::All;
use Text::Haml;

my ($filename) = @ARGV
    or die "$0 <file.html>\n";

my $haml     = Text::Haml->new;
my $template = io($filename)->slurp;
my $output   = $haml->render($template);

print << "_END";
[% WRAPPER root.tt %]
    <h1>Events</h1>
$output
[% END %]
_END

