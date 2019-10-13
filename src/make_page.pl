#!/usr/bin/perl

binmode STDOUT, ":encoding(utf8)";

use strict;
use warnings;

use utf8::all;
use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Cwd qw( abs_path );
use File::Basename;
use List::Util qw( shuffle );


my $server = 'https://gateway.marvel.com';
my $apikey = 'bae9b6b8113ef19c40ac5df9fd928775';
my $url = '/v1/public/characters';
my $parms = '?apikey='.$apikey;

my $path = dirname(abs_path($0));
my $tpl = $path.'/template_body.html';
$tpl = `cat $tpl`;

my $full = $path.'/template_header.html';
$full = `cat $full`;

# Lista todos os personagens disponíveis. Não tem a Agente Carter! :-(
# list_all_characters();

my @heros = ('captain america', 'black widow', 'daredevil');

foreach my $hero(@heros) {
    my $call = $server.$url.$parms.'&name='.$hero;
    my $rows = JSON->new->utf8->decode(goCall($call));
    
    foreach my $row(@{$rows->{data}->{results}}) {

        my $tpl2 = "";
        (my $tpl = $tpl) =~ s/\<\%character\%\>/$row->{name}/gmi;
        my $t = $row->{thumbnail}->{path}.'.'.$row->{thumbnail}->{extension};
        $tpl =~ s/\<\%thumbnail\%\>/$t/gmi;
        my $qtd = $row->{stories}->{available};
        my @idx = shuffle 0..$qtd;
        my $tot = 1;
        my $cur = 1;
        while($tot < 6 && $cur < $qtd) {
            my $call2 = $server.'/v1/public/stories'.$parms.'&characters='.$row->{id}.'&orderBy=id&limit=1&offset='.$idx[$cur];
            my $story = JSON->new->utf8->decode(goCall($call2));
            my $descrp = $story->{data}->{results}[0]->{description};
            if($descrp && $descrp ne '') {
                $descrp .= '<br>';
                $tot++;
                $tpl2 .= '
                <p>
                    <strong>'.$story->{data}->{results}[0]->{title}.'</strong><br>'.$descrp.'
                    URL: <a href="'.$story->{data}->{results}[0]->{resourceURI}.'?apikey='.$apikey.'">'.$story->{data}->{results}[0]->{resourceURI}.'</a>
                </p>            
                ';
            }
            $cur++;
        }
        $tpl =~ s/\<\%stories\%\>/$tpl2/gmi;
        $full .= $tpl;
    }
}

$full .= `cat $path/template_footer.html`;
open(my $fh, '>', 'index.html');
print $fh $full;
close($fh);

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
