#!/usr/bin/env perl

use warnings;
use strict;

use XML::Simple;
use CGI;
use Try::Tiny;
use Data::Dumper;

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Accounting::API;

#open STDERR, '>>', "/dev/null";

my $q = new CGI;

my $xml  = $q->param( 'xml' );
my $auth = $q->param( 'auth' );
my ( $data, $data_out );
my ( $bad_xml, $result ) = ( 0, "" );

my $auth_ok = ( $auth eq 'B4BP9VM5E8GPjVC9nuHg' ) ? 1 : 0;

if ( $auth_ok )
  {
    try
    {
        $data = XMLin( $q->param( 'xml' ) );
    }
    catch
    {
        $result  = "Bad XML";
        $bad_xml = 1;
    };

    if ( !$bad_xml )
      {
        my $action = $data->{action} || "";
        delete $data->{action};

        my $arguments = { map { $_ => $data->{$_} }
                            keys %$data };
        my $accounting =
          Accounting::API->new( procedure => $action,
                                arguments => $arguments );
        $result = $accounting->do;

      }

    print "content-type: text/xml\n\n";
    print "<result>$result</result>";
  }
else
  {
    print "content-type: text/xml\n\n";
    print "<result>0</result>";
  }

exit 1;

