#!/usr/bin/perl

use strict;
use XML::Simple;
use LWP::Simple; 
use LWP::UserAgent;


#PRTG login
my $username = "<USER ACCOUNT>";
my $password = '<PASSWORD>';
my $prtg_url = "https://prtg.company.com";


our %FORM;
my $foundsomething = 0;

print "Content-type:text/html\r\n\r\n";
HTTPinput();

##$FORM{search} = "vm1234"; #Debugging


if (length $FORM{search} < 4) { print "Keep Typing"; exit(0);}
if ($FORM{search}) {HTTPsearch($FORM{search}); exit;}


#Script has not been called with any thing
print "Error of the worse type.";
exit(0);








sub HTTPsearch() { 

	my  $query = $_[0];

	my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
	#Encode the password into a hash
	my $response = $ua->get($prtg_url."/api/getpasshash.htm?username=$username\&password=$password");

	if ( $response->is_success ) {
    		#print $response->decoded_content;
	} else {
		die $response->status_line;
	}
	my $passhash = $response->decoded_content;

	#Get a list of every device in XML format. Only want the device name. 
	my $response2 = $ua->get($prtg_url."/api/table.xml?content=devices\&output=xml\&columns=device\&count=10000\&username=$username\&passhash=$passhash");
	my $xml = new XML::Simple;
	my $data;

	if ( $response2->is_success ) {
		#print $response2->decoded_content;
		$data = $xml->XMLin($response2->decoded_content);
	} else {
		die $response2->status_line;
	}

	#print Dumper($data);
	#print $data->{item}->[0]->{device};
	
	#Loop over the device names and return any that match the query
	for my $item ( @{ $data->{item} } ) {
	  #print "$item->{device}\n";
	  my $device = $item->{device}; 
          if ($device =~ m/$query/i) { print $device."<br>\n"; $foundsomething = 1; }

	}

       if (!$foundsomething) { print "Nothing found in PRTG\n"; }



}


#Parse the GET input from the URL. Fills out the $FORM hash.
sub HTTPinput {

        my ($buffer, @pairs, $pair, $name, $value);
        # Read in text
        $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

        if ($ENV{'REQUEST_METHOD'} eq "GET") {
                $buffer = $ENV{'QUERY_STRING'};
        }

        # Split information into name/value pairs
        @pairs = split(/&/, $buffer);

        foreach $pair (@pairs) {
           ($name, $value) = split(/=/, $pair);
           $value =~ tr/+/ /;
           $value =~ s/%(..)/pack("C", hex($1))/eg;
           $FORM{$name} = $value;
        }

}; #end sub HTTPinput


