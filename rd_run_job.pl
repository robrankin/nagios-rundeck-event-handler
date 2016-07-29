#!/usr/bin/env perl

use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use JSON::XS;
use Switch;

# nagios exit codes
use constant EXIT_OK       => 0;
use constant EXIT_WARNING  => 1;
use constant EXIT_CRITICAL => 2;
use constant EXIT_UNKNOWN  => 3;

my $debug               = undef;
my $state               = $ARGV[0];
my $statetype           = $ARGV[1];
my $attemptnum          = $ARGV[2];
my $username            = $ARGV[3];
my $password            = $ARGV[4];
my $rundeck             = $ARGV[5];
my $jobid               = $ARGV[6];
my $filter              = $ARGV[7];
my $logLevel            = $ARGV[8];
my $serviceOuputEnabled = $ARGV[9];
my $serviceOuput        = $ARGV[10];
my $argString           = $ARGV[11];
my $asUser              = $ARGV[12];

my $rd_auth_url      = $rundeck . '/j_security_check';
my %rd_auth_headers  = ( 'Content-Type' => 'application/x-ww-form-urlencoded' );
my %rd_auth_body     = ( 'j_username' => $username, 'j_password' => $password );
my $rd_run_url       = $rundeck . "/api/1/job/$jobid/run";
my %rd_run_headers   = ( 'Content-Type' => 'application/json' );

my $coder     = JSON::XS->new->ascii->pretty->allow_nonref;
my $useragent = LWP::UserAgent->new(
  cookie_jar    => HTTP::Cookies->new,
);
my $valid_service_output = '';


###
### Main
###

if ( $serviceOuputEnabled ) {
  my $valid_service_output = check_service_output ( '$serviceOuput' );
}


if ($state eq "CRITICAL") {
  if ($debug) { print "State: CRITICAL\n"; }
  if ( ($statetype eq "SOFT" && $attemptnum >= 3) || ($statetype eq "HARD") || ($valid_service_output) ) {
    if ($debug) { print "Type: $statetype Num: $attemptnum\n"; }
    my $rd_auth_response = web_request ('auth', 'POST', $rd_auth_url, \%rd_auth_body, \%rd_auth_headers );
    # Whackjob RunDeck API returns HTTP 200 on successfully FAILING auth. http://rundeck.org/2.6.6/api/index.html#password-authentication
    if ( $rd_auth_response->request()->uri() =~ m#/user/error# || $rd_auth_response->request()->uri() =~ m#/user/login# ) {
      print "RunDeck Auth Failed\n"; exit EXIT_CRITICAL;
    }
    my $rd_run_body = build_rundeck_body ( $argString, $logLevel, $asUser, $filter );
    my $rd_run_response = web_request ('run', 'POST', $rd_run_url, $rd_run_body, \%rd_run_headers );
    if ( ! $rd_run_response->is_success ) { print "RunDeck Run Request Failed\n"; exit EXIT_CRITICAL; }
  }
}


###
### Subs
###

sub build_rundeck_body {
  my ($argString, $logLevel, $asUser, $filter) = @_;

  my $rundeck_body->{'argString'} = $argString;
     $rundeck_body->{'logLevel'}  = $logLevel;
     $rundeck_body->{'asUser'}    = $asUser;
     $rundeck_body->{'filter'}    = $filter;

  my $json_body = encode_json $rundeck_body;

  return $json_body;
}

sub check_service_output {

  switch ($serviceOuput) {
    case  /Socket timeout/	{ $valid_service_output = 1 }
  	else		                { $valid_service_output = 0 }
  }

  return $valid_service_output;
}


sub web_request {
  my ($type, $method, $url, $body, $headers) = @_;
  my $response = '';

  if ($type eq "auth") {
    $useragent->requests_redirectable ( ['GET', 'HEAD', 'POST']  );
    $useragent->default_header ( 'Content-Type' => $headers->{'Content-Type'} );
    $response = $useragent->post( $url, $body );
  } elsif ($type eq "run") {
    my $request = HTTP::Request->new($method => $url);
    $request->content_type( $headers->{'Content-Type'} );
    $request->content($body);
    $response = $useragent->request($request);
  }

  return $response;
}
