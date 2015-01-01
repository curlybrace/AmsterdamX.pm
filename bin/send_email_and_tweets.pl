#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say);

use Template;

use Email::Simple;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP;

use Net::Twitter;

use YAML qw(LoadFile);

use Data::Dumper;

use LWP::UserAgent;
use HTTP::Request;

use JSON;

my $conf_file;
if( $#ARGV >= 0 ) {
    $conf_file = $ARGV[ 0 ];
} else {
    die "Usage : perl send_email_and_tweets.pl <conf_file_name>\n";
}

# Read event details
my $event_ref = LoadFile('new_event.yaml');
my $month = $event_ref->{ month };
my $daynum = $event_ref->{ daynum };

# Sending email code

# Read email configuration from a YAML file
my $conf     = LoadFile($conf_file);
my $username = $conf->{ username };
my $password = $conf->{ password };
if( !$password ) {
    print "Please enter password for the email: ";
    $password = <STDIN>;
    chomp $password;
}
my $host     = $conf->{ host };
my $to       = $conf->{ to };
my $from     = $conf->{ from };
my $port     = $conf->{ port };

# sending email part

my $email_body;
my $subject;
my $template_name;

while( 1 ) {
    print "What kind of email you would like to send?\n";
    print "1 Announcement\n";
    print "2 Reminder\n";
    print "3 Teaser\n";
    my $option = <STDIN>;
    chomp $option;

    if( $option == 1 ) {
        $template_name = "announcement.tt";
        $subject    = "Amsterdam eXpats Perl Mongers $month meeting ($month $daynum, 18:30)";
        last;
    } elsif( $option == 2 ) {
        $template_name = "reminder.tt";
        $subject    = "[REMINDER] $month $daynum: AmsterdamX.pm";
        last;
    } elsif( $option == 3 ) {
        $template_name = "teaser.tt";
        $subject    = "";
        last;
    } else {
        print "Invalid optipn\n";
    }
}

my $tt = Template->new();
$tt->process( "email_templates/".$template_name, $event_ref, \$email_body ) or die $tt->error();

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
        To      => $to,
        From    => $from,
        Subject => $subject,
    ],
    body    => $email_body,
);
sendmail($email, { transport => $transport });

## Code for sending tweet

print "Do you wanna send a tweet as well? (y/n)";
my $yes_or_no = <STDIN>;
chomp $yes_or_no;
if( $yes_or_no =~ /(n|N)/ ) {
    exit 0;
} elsif( $yes_or_no =~ /(y|Y)/ ) {
    my $consumer_key = $conf->{ consumer_key };
    my $consumer_secret = $conf->{ consumer_secret };
    my $access_token = $conf->{ access_token };
    my $access_token_secret = $conf->{ access_token_secret };

    my $nt = Net::Twitter->new(
        traits => ['API::RESTv1_1'],
        consumer_key => $consumer_key,
        consumer_secret => $consumer_secret,
        access_token => $access_token,
        access_token_secret => $access_token_secret,
        );

    my $url = get_shorten_url();
    my $result = $nt->update("Next AmsterdamX.pm meetup has been announced, check out more details here : $url. See you there! :)");
}

sub get_shorten_url {
    my $uri = 'https://www.googleapis.com/urlshortener/v1/url';
    my $json = to_json({ longUrl => "http://amsterdamx.pm.org/#new_event" });
    my $req = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $json );

    my $lwp = LWP::UserAgent->new;
    my $response = $lwp->request( $req );

    if ($response->is_success) {
        my $result = from_json( $response->decoded_content );
        return $result->{ id };
    }
    else {
        die $response->status_line;
    }
}
