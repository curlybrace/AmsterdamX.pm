#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use DDP;

use Template;
use JSON;
use Net::Twitter;
use YAML qw(LoadFile);
use LWP::UserAgent;
use HTTP::Request;
use Term::ReadPassword;
use IO::Prompt::Tiny 'prompt';

use Email::Simple;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP;

use utf8;

my ($conf_file) = @ARGV
    or die "Usage: perl send_email_and_tweets.pl <config.yaml>\n";

# Read event details
my $event_ref = LoadFile('templates/new_event.yaml');

my ( $month, $daynum ) = @{$event_ref}{qw<month daynum>};

# Sending email code

# Read email configuration from a YAML file
my $conf     = LoadFile($conf_file);
my $password = $conf->{'password'} || read_password('Email pass: ');

my ( $username, $host, $to, $from, $port ) =
    @{$conf}{qw<username host to from port>};

# sending email part

my %options = (
    1 => [
        'announcement.tt',
        "Amsterdam eXpats Perl Mongers $month meeting ($month $daynum, 18:30)",
    ],

    2 => [ 'reminder.tt', "[REMINDER] $month $daynum: AmsterdamX.pm" ],
    3 => [ 'teaser.tt',   '' ],
);

my $option = -1;
while ( $option < 0 || $option > 3 ) {
    print "What kind of email you would like to send?\n"
        . "0. Exit\n"
        . "1. Announcement\n"
        . "2. Reminder\n"
        . "3. Teaser\n";
    $option = prompt( 'Pick 0-3:', '0' );
}

$option or print "Exiting.\n", exit;

my ( $template_name, $subject ) = @{ $options{$option} };

my $email_body;

my $tt = Template->new();
$tt->process(
    "templates/email_templates/$template_name",
    $event_ref,
    \$email_body,
    binmode => ':utf8',
) or die $tt->error();

my $transport = Email::Sender::Transport::SMTP->new({
    host          => $host,
    port          => $port,
    ssl           => 1,
    sasl_username => $username,
    sasl_password => $password,
    debug         => 1
});

my $email = Email::Simple->create(
    header => [
        To             => $to,
        From           => $from,
        Subject        => $subject,
        'Content-Type' => "text/plain; charset=utf-8",
    ],
    body   => $email_body,
);

sendmail( $email, { transport => $transport } );

# Code for sending tweet

my $yes_or_no = prompt('Do you wanna send a tweet as well? (y/n)', 'n' );

$yes_or_no =~ /^[Yy]$/
    or exit;

my $nt = Net::Twitter->new(
    traits              => ['API::RESTv1_1'],
    consumer_key        => $conf->{'consumer_key'},
    consumer_secret     => $conf->{'consumer_secret'},
    access_token        => $conf->{'access_token'},
    access_token_secret => $conf->{'access_token_secret'},
);

my $result = $nt->update(
    sprintf 'Next AmsterdamX.pm meetup announced! %s. See you there! :)',
            get_shorten_url()
);

sub get_shorten_url {
    my $uri  = 'https://www.googleapis.com/urlshortener/v1/url';
    my $json = to_json({ longUrl => 'http://amsterdamx.pm.org/#new_event' });
    my $req  = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content($json);

    my $lwp      = LWP::UserAgent->new;
    my $response = $lwp->request($req);

    $response->is_success
        or die $response->status_line;

    my $result = from_json( $response->decoded_content );
    return $result->{'id'};
}
