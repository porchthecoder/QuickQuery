#!/usr/bin/perl

use strict;
use Infoblox;
#use Data::Dumper;

$| = 1;

our %FORM;

##The Infoblox perl module needs to be update after every Infoblox upgrade. 
## Browse to following URL to get tar.gz file to download
## Under /root/
## wget https://<URL of grid master>/api/dist/CPAN/authors/id/INFOBLOX/Infoblox-xxxxxx
## extract
## cd Infoblox-xxxxxxx/
## perl Makefile.PL
## make
## make install

#HTTPsearchinfoblox("VM1234");
#exit;

print "Content-type:text/html\r\n\r\n";
HTTPinput();
#$FORM{search}="Gentoo"; #Testing


if (length $FORM{search} < 4) { print "Keep Typing"; exit(0);}
if ($FORM{search}) {HTTPsearchinfoblox($FORM{search}); exit;}



#Script has not been called with any thing
print "Error of the worse type.";
exit(0);




sub HTTPsearchinfoblox() {

	my $q = $_[0];
#	my $q = lc($_[0]); #Infobox \i regex does not seem to work. It's case sensitive in it's search. 

	my $itemsfound = 0;
	

	# Create a session to the Infoblox appliance
	my $SESSION = Infoblox::Session->new(
   		master  => "<GRID MASTER IP>",
		username => "<USERNAME>",
		password => '<PASSWORD>'
        
	);

	if ($SESSION->status_code()) {
    		my $result = $SESSION->status_code();
    		my $response = $SESSION->status_detail();
    		print "Error: $response ($result)\n";
	} else {
    #		print "Connection established\n";
    #		print "Server Version: ".$SESSION->server_version()."\n";
	}

	###Search A and TXT records, and anything else we can find. 

 	#Searching for all A records under "domain.com" from the Infoblox appliance.
 	#my @retrieved_objs = $SESSION->search(
     	#	object => "Infoblox::DNS::Record::A",
        #		name   => ".*$q.*" );
 	#unless (@retrieved_objs) {
     	#	die("Search DNS record A failed: ",
        #	$SESSION->status_code() . ":" . $SESSION->status_detail());
 	#}

print " "; #Sending a little data every now and then seems to stop timeout issues. 

	 my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DNS::AllRecords",
     		zone   => 'info.sys',
     		name   => ".*$q.*",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print $nameout->type() . ": -- ". $nameout->name() ."<BR>\n";
		$itemsfound = 1;
	}


	###################Search CNAME

print " ";
 	# search DNS CNAME record with canonical name "cname.domain.com" of default view
 	my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DNS::Record::CNAME",
     		canonical => ".*$q.*",
		#view   => "default",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print "CNAME: " . $nameout->canonical() . " -- " . $nameout->name() . "<BR>\n";
		$itemsfound = 1;
	}

print " ";

	###################Search DHCP Fingerprint
 	my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DHCP::Lease",
     		fingerprint => ".*$q.*",
		#view   => "default",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print "DHCP FINGERPRINT: " .$nameout->client_hostname() . " -- " . $nameout->ip_address() . " -- " .  $nameout->fingerprint() . "<BR>\n";
		$itemsfound = 1;
	}
	
print " ";

	#################Search DHCP IP
 	my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DHCP::Lease",
     		ip_address => "$q",
		#view   => "default",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print "DHCP IP ADDRESS: " .$nameout->ip_address() . " -- " .  $nameout->client_hostname() . "<BR>\n";
		$itemsfound = 1;
	}
	
print " ";

	################Search DHCP hostname
 	my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DHCP::Lease",
     		client_hostname => ".*$q.*",
		#view   => "default",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print "DHCP HOSTNAME: " .$nameout->ip_address() . " -- " .  $nameout->client_hostname() . "<BR>\n";
		$itemsfound = 1;
	}
	
	
print " ";

	###################Search PTR

 	my @retrieved_objs = $SESSION->search(
     		object => "Infoblox::DNS::Record::PTR",
     		ptrdname => ".*$q.*",
		#view   => "default",
 	);


 	foreach (@retrieved_objs) {
  		my $nameout = $_;
  		print "PTR: " . $nameout->ptrdname() . " -- " . $nameout->ipv4addr() . "<BR>\n";
		$itemsfound = 1;
	}

	if (!$itemsfound) { print "Nothing found in InfoBlox\n"; }

} #end sub HTTPsearchinfoblox


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




