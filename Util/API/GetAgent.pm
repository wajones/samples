package Util::API::GetAgent;

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Mouse;
use Leads::DB;
use XML::Simple;
use Data::Dumper;

has 'agent_id' => ( is => 'rw', required => 1, default => 0 );
has 'lead_id'  => ( is => 'rw', required => 0 );
has 'hash'     => ( is => 'rw', required => 0 );

has 'dbh' => ( is => 'rw', lazy_build => 1 );

sub _build_dbh
  {
    my $self = shift;
    my $dbh = Leads::DB->new( 'leads' );
  }

sub getAgentInfo
  {
    my $self = shift;
    my ( $agent_id, $output );

    if ( $self->agent_id && $self->agent_id > 0 )
      {
        $agent_id = $self->agent_id;
        my $agent = $self->dbh->sqlSelectHashref( 
          "ag.id as agent_id,
           ag.people_id as people_id,
           concat(ucase(mid(p.first_name, 1, 1)), lcase(mid(p.first_name,2))) as fname,
           concat(ucase(mid(p.last_name, 1, 1)), lcase(mid(p.last_name, 2))) as lname,
           com.id as company_id,
           com.name as company_name,
           ph.area_code,
           ph.number,
           ph.ext",
          "agents ag 
           left join people p on p.id = ag.people_id
           left join phone ph on ph.people_id = p.id
           left join insurance_companies_new com on com.id = ag.company_id",
          "ag.id = $agent_id" );

        $agent->{lead_id} = $self->lead_id if ( $self->lead_id );

        if ( $agent && ref $agent eq 'HASH' )
          {
            $output = XML::Simple->new()->XMLout( $agent, NoAttr => 1, RootName => 'agent' );
          }
        else
          {
            $output = '<agent></agent>';
          }
      }
    else
      {
        $output = '<agent></agent>';
      }
  $output;
}

1;

