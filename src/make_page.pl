#!/usr/bin/perl


use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use List::Util qw( shuffle );

my $server = 'https://gateway.marvel.com';
my $apikey = 'bae9b6b8113ef19c40ac5df9fd928775';
my $url = '/v1/public/characters';
my $parms = '?apikey='.$apikey;

# Lista todos os personagens disponíveis. Não tem a Agente Carter! :-(
# list_all_characters();

my @heros = ('captain america', 'black widow', 'daredevil');

foreach my $hero(@heros) {
    my $call = $server.$url.$parms.'&name='.$hero;
    my $rows = JSON->new->utf8->decode(goCall($call));
    foreach my $row(@{$rows->{data}->{results}}) {
        my $qtd = $row->{stories}->{available};
        print "Nome: ".$row->{name}."\n";
        print "Código: ".$row->{id}."\n";
        print "Qtd. estórias: ".$qtd.".\n";
        print "Escolhidas:\n";
        my @idx = shuffle 0..$qtd;
        for(my $f=1; $f < 6; $f++) {
            my $call2 = $server.'/v1/public/stories'.$parms.'&characters='.$row->{id}.'&orderBy=id&limit=1&offset='.$idx[$f];
            my $story = JSON->new->utf8->decode(goCall($call2));
            print $idx[$f].': '.$story->{data}->{results}[0]->{title}.": ".$story->{data}->{results}[0]->{resourceURI}."\n";
        }
        print "\n";
    }
}


exit;



my $call = $server.$url.$parms;

my $ua = new LWP::UserAgent;
my $request = HTTP::Request->new(GET => $call);
$request->referer("http://localhost");
my $response = $ua->request($request);

 if($response->is_success) {
    my $heros = JSON->new->utf8->decode($response->content);

    print $heros->{data}->{total}." rows\n";
    foreach my $line(@{$heros->{data}->{results}}) {
        #Results from this particular query have a "Key" and a "Value"
        print $line->{name} . "\n";
    }
 } elsif($response->is_error) {
     print "Erro ao executar consulta em ".$server.$url.": ".$response->message."\n";
 }
 
 
sub count_characters {


}
 
sub goCall {
    my ($call) = @_;
    
    my $ua = new LWP::UserAgent;
    my $request = HTTP::Request->new(GET => $call);
    $request->referer("http://localhost");
    my $response = $ua->request($request);

    if($response->is_success) {
        return $response->content;
    } elsif($response->is_error) {
        print "Erro ao executar consulta em ".$server.$url.": ".$response->message."\n";
        exit -1;
    }   
}
 
sub list_all_characters {
    $parms .= '&orderBy=name&limit=100';
    my $call = $server.$url.$parms;
   
    my $rows = JSON->new->utf8->decode(goCall($call));
    my $rv = $rows->{data}->{total};
    print $rv." rows:\n\n";
    
    for(my $f=0; $f<=$rv; $f+=100) {
        $rows = JSON->new->utf8->decode(goCall($call.'&offset='.$f));
        foreach my $row(@{$rows->{data}->{results}}) {
            print $row->{name} . "\n";
        }
    }
    
 }
