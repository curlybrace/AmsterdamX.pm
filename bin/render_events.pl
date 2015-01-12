#!/usr/bin/env perl

use strict;
use warnings;

use DDP;
use YAML qw(LoadFile);
use IO::All;
use Template;
use Text::Haml;

print "Reading new event...\n";
my $event_ref = LoadFile('new_event.yaml');

my ( $month, $daynum, $year ) = @{$event_ref}{qw<month daynum year>};

my $text =<<END;
%h2 Upcoming Events
%div
  %h3 $month $daynum, $year
  %ol
END

my $talks_string;
foreach my $talk ( @{ $event_ref->{'talks'} } ) {
    my $speaker = $talk->{'speaker'};
    my $title   = $talk->{'title'};
    my $details = join "\n", map "        %p $_", @{ $talk->{'details'} };
    my $talk    = <<END;
    %li
      %h4
        %span $speaker
        :: $title
$details
END

    $talks_string .= $talk;
}

( $text . $talks_string . io('events.haml')->slurp ) > io('events.haml');

my $haml   = Text::Haml->new( encoding => '' );
my $events = $haml->render_file('events.haml');

my $text_for_events_tt = <<END;
[% WRAPPER root.tt %]
    <h1>Events</h1>
$events
[% END %]
END

$text_for_events_tt > io('events.tt');

## Render index.tt

my $tt = Template->new();
$tt->process(
    'index.tt',
    $event_ref,
    '../generated/index.html',
) or die $tt->error;
