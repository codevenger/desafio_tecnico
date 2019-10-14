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

my %config;
my $apikey;
my $server;
my $dest;
my @heros;
&getConfig('/etc/marvel_developer.conf');
if($config{apikey} eq '') {
    error("Public key empty in configurarion file");
} else {
    $apikey = $config{apikey};
}
if($config{server} && $config{server} ne '') {
    $server = $config{server};
} else {
    $server = 'https://gateway.marvel.com';    
}
if($config{destination} && $config{destination} ne '') {
    $dest = $config{destination};
} else {
    $dest = '/var/www/html/index.html';    
}
if($config{heros} && $config{heros} ne '') {
    @heros = split(/,\s+/, $config{heros});
} else {
    @heros = ('captain america', 'black widow', 'daredevil');    
}
my $url = '/v1/public/characters';
my $parms = '?apikey='.$apikey;

my $path = dirname(abs_path($0));
my $tpl = $path.'/template_body.html';
$tpl = `cat $tpl`;

my $full = $path.'/template_header.html';
$full = `cat $full`;

if(! -e $dest) {
    my $from = $path.'/template_loading.html';
    `cp $from $dest`;
}

# Lista todos os personagens disponíveis. Não tem a Agente Carter e nem o Conan! :-(
# list_all_characters();

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
open(my $fh, '>', $dest) || die "Erro ao salvar os dados";
print $fh $full;
close($fh);

exit;


sub getConfig {
    my ($file) = @_;
    
    open(CONFIG, '<', $file) || die "Erro ao carregar configurações";
    
    while (<CONFIG>) {
        chomp; # no newline
        s/#.*//; # no comments
        s/^\s+//; # no leading white
        s/\s+$//; # no trailing white
        next unless length; # anything left?
        my ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value;
    }
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
        error("Erro ao executar consulta em ".$server.$url.": ".$response->message."\n");
    }   
}
 
sub list_all_characters {
    my $parms = $parms.'&orderBy=name&limit=100';
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
 
 sub error {
    my ($msg) = @_;
    print $msg;
    print "\n";
    exit -1;
 }
 
