package Util::API::GetStats;

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Mouse;

use Leads::DB;
use CGI;
use JSON;
use Data::Dumper;

has 'start_date' => ( is => 'ro', required => 1 );
has 'end_date'   => ( is => 'ro', required => 1 );

has 'dbh' => ( is => 'rw', lazy_build => 1 );

sub _build_dbh
  {
    my $self = shift;
    my $dbh  = Leads::DB->new( 'leads' );
  }

sub getLeadSalesSingleDay
  {
    my $self = shift;

    my $stats = {};

    if ( $self->start_date eq $self->end_date )
      {
        my $start = $self->start_date . " 00:00:00";
        my $end   = $self->start_date . " 23:59:59";

        my $lead_stats =
          $self->dbh->sqlSelectAllHashrefArray(
                                   "count(*) as value, hour(sale_time) as date",
                                   "lead_sales",
                                   "sale_time between '$start' and '$end'",
                                   "group by hour(sale_time)" );
        $stats = encode_json $lead_stats;
      }

    return $stats;
  }

sub getLeadSalesMultipleDay
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $lead_stats = $self->dbh->sqlSelectAllHashrefArray(
        "count(*) as value, 
         date_format(sale_time, '%m/%d/%Y') as date",
        "lead_sales",
        "sale_time between '$start' and '$end'",
        "group by date(sale_time)" );
    $stats = encode_json $lead_stats;

    return $stats;
  }

sub getLeadStats
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $leads_generated = $self->dbh->sqlCount(
        "lead_master",
        "received between '$start' and '$end' and
         status not like '%bad%'" );
    my $lead_sales = $self->dbh->sqlCount( "lead_sales",
                                      "sale_time between '$start' and '$end'" );
    my $sales_per_lead = $lead_sales / $leads_generated;
    $sales_per_lead = sprintf( "%.2f", $sales_per_lead );

    my $array;
    push @$array, { name => 'Leads',      value => $leads_generated };
    push @$array, { name => 'Sales',      value => $lead_sales };
    push @$array, { name => 'Sales/Lead', value => $sales_per_lead };

    $stats = encode_json $array;

    return $stats;
  }

sub getLeadsByTypePercentage
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $leads_generated = $self->dbh->sqlCount(
        "lead_master",
        "received between '$start' and '$end' and
         status not like '%bad%'" );
    my $lead_stats = $self->dbh->sqlSelectAllHashrefArray(
        "count(*) as value,
         lt.name as name",
        "lead_master lm, lead_types lt",
        "lm.lead_type_id = lt.id and
         lm.received between '$start' and '$end'",
        "group by lt.name" );
    @$lead_stats = map {
        {  name  => ucfirst( $_->{name} ),
           value => sprintf( "%.2f", $_->{value} * 100 / $leads_generated ) }
    } @$lead_stats;

    $stats = encode_json $lead_stats;

    return $stats;
  }

sub getLeadsByType
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $lead_stats = $self->dbh->sqlSelectAllHashrefArray(
        "count(*) as value,
         lt.name as name",
        "lead_master lm, lead_types lt",
        "lm.lead_type_id = lt.id and
         lm.received between '$start' and '$end'",
        "group by lt.name" );
    @$lead_stats =
      map { { name => ucfirst( $_->{name} ), value => $_->{value} } }
      @$lead_stats;

    $stats = encode_json $lead_stats;

    return $stats;
  }

sub getAgentSignupsSingleDay
  {
    my $self = shift;

    my $stats = {};

    if ( $self->start_date eq $self->end_date )
      {
        my $start = $self->start_date . " 00:00:00";
        my $end   = $self->end_date . " 23:59:59";
		
        my $agent_signups =
          $self->dbh->sqlSelectAllHashrefArray(
                               "count(*) as value, hour(created_stamp) as date",
                               "agents",
                               "created_stamp between '$start' and '$end'",
                               "group by hour(created_stamp)" );
		foreach my $hour ( 0..23 )
		  {
			next if grep { defined $_->{date} && $_->{date} == $hour } @$agent_signups;
			push @$agent_signups, { date => $hour, value => 0, };
		  }

		$agent_signups = [ sort { $a->{date} <=> $b->{date} } @$agent_signups ];
        $stats = encode_json $agent_signups;
      }

    return $stats;
  }

sub getAgentSignupsMultipleDay
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $agent_stats = $self->dbh->sqlSelectAllHashrefArray(
        "ifnull(count(*), 0) as value, 
         date_format(created_stamp, '%m/%d/%Y') as date",
        "agents",
        "created_stamp between '$start' and '$end'",
        "group by date(created_stamp)" );
    $stats = encode_json $agent_stats;

    return $stats;
  }

sub getAgentProfilesSingleDay
  {
    my $self = shift;

    my $stats = {};

    if ( $self->start_date eq $self->end_date )
      {
        my $start = $self->start_date . " 00:00:00";
        my $end   = $self->end_date . " 23:59:59";

        my $agent_signups =
          $self->dbh->sqlSelectAllHashrefArray(
                               "count(*) as value, hour(created_stamp) as date",
                               "agent_filter_set",
                               "created_stamp between '$start' and '$end'",
                               "group by hour(created_stamp)" );

        $stats = encode_json $agent_signups;
      }

    return $stats;
  }

sub getAgentProfilesMultipleDay
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $agent_stats = $self->dbh->sqlSelectAllHashrefArray(
        "count(*) as value, 
         date_format(created_stamp, '%m/%d/%Y') as date",
        "agent_filter_set",
        "created_stamp between '$start' and '$end'",
        "group by date(created_stamp)" );
    $stats = encode_json $agent_stats;

    return $stats;
  }

sub getAgentZipsSingleDay
  {
    my $self = shift;

    my $stats = {};

    if ( $self->start_date eq $self->end_date )
      {
        my $start = $self->start_date . " 00:00:00";
        my $end   = $self->end_date . " 23:59:59";

        my $agent_signups =
          $self->dbh->sqlSelectAllHashrefArray(
                               "count(*) as value, hour(created_stamp) as date",
                               "agent_filter_zip",
                               "created_stamp between '$start' and '$end'",
                               "group by hour(created_stamp)" );

        $stats = encode_json $agent_signups;
      }

    return $stats;
  }

sub getAgentZipsMultipleDay
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

        my $agent_zips = 0;
    $self->dbh->sqlDo( "create temporary table tmp_agent_profiles 
                        select id from agent_filter_set where created_stamp 
                        between '$start' and '$end'" );
    $agent_zips = $self->dbh->sqlSelect( "count(*) as value,
                                          date_format(afz.created_stamp, '%m/%d/%Y') as date", 
                                         "agent_filter_zip afz inner join 
                                          tmp_agent_profiles tap 
                                          on afz.filter_set_id = tap.id",
                                         "group by date(afz.created_stamp)" );
    $self->dbh->sqlDo( "drop temporary table tmp_agent_profiles" );

    my $agent_stats = $self->dbh->sqlSelectAllHashrefArray(
        "count(*) as value, 
         date_format(created_stamp, '%m/%d/%Y') as date",
        "agent_filter_zip",
        "created_stamp between '$start' and '$end'",
        "group by date(created_stamp)" );
    $stats = encode_json $agent_stats;

    return $stats;
  }

sub getAgentStats
  {
    my $self = shift;

    my $stats = {};
    my $start = $self->start_date . " 00:00:00";
    my $end   = $self->end_date . " 23:59:59";

    my $agent_signups = $self->dbh->sqlCount( "agents",
                                  "created_stamp between '$start' and '$end'" );
    my $agent_profiles = $self->dbh->sqlCount( "agent_filter_set",
                                  "created_stamp between '$start' and '$end'" );
    my $agent_zips = 0;
    $self->dbh->sqlDo( "create temporary table tmp_agent_profiles 
                        select id from agent_filter_set where created_stamp 
                        between '$start' and '$end'" );
    $agent_zips = $self->dbh->sqlSelect( "count(*)", 
                                         "agent_filter_zip afz inner join 
                                          tmp_agent_profiles tap 
                                          on afz.filter_set_id = tap.id" );
    $self->dbh->sqlDo( "drop temporary table tmp_agent_profiles" );

    my $array;
    push @$array, { name => 'Signups',   value => $agent_signups };
    push @$array, { name => 'Profiles',  value => $agent_profiles };
    push @$array, { name => 'Zip Codes', value => $agent_zips };

    $stats = encode_json $array;

    return $stats;
  }

1;

