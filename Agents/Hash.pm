package Agents::Hash;

use strict;
use warnings;
use Mouse;
use Sort::Key qw(keysort nkeysort);

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Leads::DB;
use Leads::Utils;
use Data::Dumper;

has 'agentList' => ( is => 'ro', required   => 1 );
has 'keyField'  => ( is => 'rw', required   => 1 );
has 'sortOrder' => ( is => 'ro', required   => 1, default => 'asc' );
has 'sortType'  => ( is => 'ro', required   => 1, default => 'numeric' );
has 'keyList'   => ( is => 'ro', lazy_build => 1 );
has 'agentHash' => ( is => 'rw' );
has 'error'     => ( is => 'rw' );

sub _build_keyList
  {
    my $self = shift;
    my @keys;
    while ( <DATA> )
      {
        chomp;
        push @keys, $_;
      }

    my $re = join '|',
      map { quotemeta } sort { length( $b ) <=> length( $a ) } @keys;
    $re = qr/$re/;

    return $re;
  }

sub sortIt
  {
    my $self = shift;

    my $list      = $self->agentList;
    my $key       = $self->keyField;
    my $re        = $self->keyList;
    my $sortType  = $self->sortType;
    my $sortOrder = $self->sortOrder;
    my $valid     = 1;
    my $error     = undef;
    my $ret       = $list;

    if ( $key !~ m/$re/ig )
      {
        $valid = 0;
        $error = "Invalid key field given";
      }

    if ( $valid )
      {
        if ( ref $list eq 'ARRAY' )
          {
            my $hash;
            my $sortedList;

            if ( $sortType =~ /^num/ig && $sortOrder =~ /^asc/ig )
              {
                $sortedList = [ nkeysort { $_->{$key} } @$list ];
              }
            elsif ( $sortType =~ /^num/ig && $sortOrder =~ /^desc/ig )
              {
                $sortedList = [ reverse nkeysort { $_->{$key} } @$list ];
              }
            elsif ( $sortType =~ /^asc/ig && $sortOrder =~ /^asc/ig )
              {
                $sortedList = [ keysort { $_->{$key} } @$list ];
              }
            elsif ( $sortType =~ /^asc/ig && $sortOrder =~ /^desc/ig )
              {
                $sortedList = [ reverse keysort { $_->{$key} } @$list ];
              }
            else
              {
                $sortedList = $list;
              }
            $ret = $sortedList;
          }
        else
          {
            $error = "agentList is not an array";
          }
      }

    $self->error( $error );
    $self->agentHash( $ret );
    return $ret;
  }

sub hashIt
  {
    my $self = shift;

    my $list = $self->agentHash;
    my $key = $self->keyField;
    my $re = $self->keyList;
    my $ret = $list;
    my $valid = 1;
    my $error = undef;

    if ( $key !~ m/$re/ig )
      {
        $valid = 0;
        $error = "Invalid key field given";
      }

    if ( $valid )
      {
        if ( ref $list eq 'ARRAY' )
          {
            print Dumper($list);
            $ret = { map { $_->{$key} => $_ } @$list };
            print Dumper($ret);
          }
        else
          {
            $error = "agentList is not at an array";
          }
      }

    $self->error( $error );
    $self->agentHash( $ret );
    return $ret;
  }

1;

__DATA__
company_id
people_id
invoiceable
license
promo_balance
balance
filter_set_id
agent_id
quote_price
max_invoice_amount
