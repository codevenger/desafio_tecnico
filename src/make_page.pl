#!/usr/bin/perl


use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;

my $server = 'https://gateway.marvel.com';
my $apikey = 'bae9b6b8113ef19c40ac5df9fd928775';
my $call = $server.'/v1/public/characters?apikey='.$apikey;

my $ua = new LWP::UserAgent;
my $request = HTTP::Request->new(GET => $call);
$request->referer("http://localhost");
my $response = $ua->request($request);

 if($response->is_success){
     print $response->content;
 } elsif($response->is_error) {
     print "Erro ao executar consulta em ".$call.": ".$response->message."\n";
 }
 
 
 
 
 
