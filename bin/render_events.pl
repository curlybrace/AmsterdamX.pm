#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say);

use Data::Dumper;
use Text::Haml;
use IO::All;

use Template;

use YAML qw(LoadFile);

my $event_ref = LoadFile('new_event.yaml');

my %event     = %$event_ref;

my $month     = $event_ref->{ month };
my $daynum    = $event_ref->{ daynum };
my $year      = $event_ref->{ year };
my $space     = "  ";

my $text =<<END;
%h2 Upcoming Events
%div
  %h3 $month $daynum, $year
  %ol
END

my $talks_string;
for my $key ( keys %{$event_ref->{ talks }} ) {
    my $talk    = $event_ref->{ talks }->{ $key };
    my $talk_detail;
    my $speaker;
    my $title;
    if( $talk ) {
        $speaker    = $talk->{ speaker };
        $title      = $talk->{ title };
        my $detail  = $talk->{ detail };
        if( ref $detail ) {
            my @detail  = @{$talk->{ detail }};

            for( my $j = 0; $j <= $#detail; $j++ ) {
                my $line = $detail[ $j ];
                $talk_detail .= "      %p $line";
                if( $j != $#detail ) {
                    $talk_detail .= "\n";
                }
            }
        } else {
                $talk_detail .= "      %p $detail\n";
        }
    } else {
        last;
    }

    my $this_talk =<<END;
    %li
      %h4
        %span $speaker
        :: $title
$talk_detail
END

    $talks_string .= $this_talk;
}

$text .= $talks_string;

my $events_haml = io('events.haml')->slurp();
$events_haml = $text.$events_haml;
io('events.haml')->write( $events_haml );

my $haml = Text::Haml->new( encoding => '');
my $events = $haml->render_file('events.haml');

my $text_for_events_tt =<<END;
[% WRAPPER root.tt %]
    <h1>Events</h1>
$events
[% END %]
END

io('events.tt')->write( $text_for_events_tt );

my $template_name;
my $rendered_text;

## Render index.tt

my $tt = Template->new ();

$template_name = "index.tt";

$tt->process( $template_name,
              $event_ref,
              '../generated/index.html' ) || die $tt->error()."\n";
