package Log::ProcessLog;

use strict;
use warnings;

use feature ":5.10";
use feature "switch";

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Mouse;
use Try::Tiny;
use Leads::DB;
use Data::Dumper;

has 'typeId' => ( is => 'rw', required => 1 );
has 'type'   => ( is => 'rw', required => 1 );
has 'entry' => ( is        => 'rw',
                 required  => 0,
                 clearer   => 'clear_entry',
                 predicate => 'has_entry' );
has 'agentId' => ( is        => 'rw',
                   required  => 0,
                   clearer   => 'clear_agentId',
                   predicate => 'has_agentId' );
has 'filterId' => ( is        => 'rw',
                    required  => 0,
                    clearer   => 'clear_filterId',
                    predicate => 'has_filterId' );
has 'action' => ( is        => 'rw',
                  required  => 0,
                  clearer   => 'clear_action',
                  predicate => 'has_action' );
has 'dbh' => ( is => 'rw', lazy_build => 1 );
has 'category' => ( is        => 'rw',
                    required  => 0,
                    clearer   => 'clear_category',
                    predicate => 'has_category' );

sub _build_dbh
  {
    my $self = shift;
    my $dbh  = Leads::DB->new( 'leads' );

    return $dbh;
  }

sub assignCategory
  {
    my $self     = shift;
    my $category = 'Misc';

    given ( $self->entry )
    {
        when ( /zip code/i )      { $category = "Selection"; }
        when ( /excluded/i)       { $category = "Exclusion"; }
        when ( /filter_id/i )     { $category = "Filters"; }
        when ( /hold/i )          { $category = "Hold"; }
        when ( /paused/i )        { $category = "Hold"; }
        when ( /inactive/i )      { $category = "Hold"; }
        when ( /blocked/i )       { $category = "Distribution"; }
        when ( /distribution/i )  { $category = "Distribution"; }
        when ( /current/i )       { $category = "Distribution"; }
        when ( /reached/i )       { $category = "Distribution"; }
        when ( /limited/i )       { $category = "Distribution"; }
        when ( /dropped/i )       { $category = "Distribution"; }
        when ( /requested/i )     { $category = "Distribution"; }
        when ( /balance/i )       { $category = "Money"; }
        when ( /rebill/i )        { $category = "Money"; }
        when ( /round-robin/i )   { $category = "Sale"; }
        when ( /backup/i )        { $category = "Sale"; }
        when ( /retrying/i )      { $category = "Sale"; }
        when ( /bidder/i )        { $category = "Sale"; }
        when ( /retrying/i )      { $category = "Sale"; }
        when ( /RESERVED/i )      { $category = "Sale"; }
        when ( /SOLD/i )          { $category = "Sale"; }
        when ( /Attempting/i )    { $category = "Sale"; }
        when ( /No agents/i )     { $category = "Sale"; }
        when ( /Posting/i )       { $category = "Posting"; }
        when ( /Duplicate/i )     { $category = "Posting"; }
        when ( /rejected/i )      { $category = "Posting"; }
        when ( /stop/i )          { $category = "Posting"; }
        when ( /successful/i )    { $category = "Posting"; }
        when ( /returned/i )      { $category = "Posting"; }
        when ( /not supported/i ) { $category = "Posting"; }
    }

    $self->category( $category );
    return $category;
  }

sub write
  {
    my ( $self, $p ) = @_;

    $self->clear_entry;
    $self->clear_agentId;
    $self->clear_filterId;
    $self->clear_action;
    $self->clear_category;

    $self->entry( $p->{entry} )       if exists( $p->{entry} );
    $self->agentId( $p->{agentId} )   if exists( $p->{agentId} );
    $self->filterId( $p->{filterId} ) if exists( $p->{filterId} );
    $self->action( $p->{action} )     if exists( $p->{action} );
    $self->assignCategory             if exists( $p->{entry} );
    $self->_write                     if ( $p->{commit} );
  }

sub commit
  {
    my $self;

    $self->_write;
  }

sub _write
  {
    my $self = shift;
    $self->assignCategory;

    try
    {
        $self->dbh->sqlInsert( "process_log_detail",
                               {  type      => $self->type,
                                  type_id   => $self->typeId,
                                  agent_id  => $self->agentId,
                                  filter_id => $self->filterId,
                                  action    => $self->action,
                                  message   => $self->entry,
                                  category  => $self->category,
                               } );
    }
    catch
    {
        sleep 1;
        $self->commit;
    }
  }

1;

