package Agents::Select;

use strict;
use warnings;
use Mouse;

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Leads::DB;
use Leads::Utils;
use Log::ProcessLog;
use Data::Dumper;

has 'zip'                => ( is => 'ro', required   => 1 );
has 'leadTypeId'         => ( is => 'ro', required   => 1 );
has 'leadId'             => ( is => 'ro', required   => 1 );
has 'type'               => ( is => 'ro', required   => 1, default => 'ping' );
has 'affiliateId'        => ( is => 'ro', required   => 1 );
has 'duplicateLeadId'    => ( is => 'ro', required   => 1, default => 0 );
has 'daysSinceDuplicate' => ( is => 'ro', required   => 1, default => 365 );
has 'limit'              => ( is => 'ro', required   => 0 );
has 'dbh'                => ( is => 'rw', lazy_build => 1 );
has 'state'              => ( is => 'rw', lazy_build => 1 );
has 'stateFilter'        => ( is => 'rw', lazy_build => 1 );
has 'log'                => ( is => 'rw', lazy_build => 1 );
has 'currentAgentList'   => ( is => 'rw', required   => 0 );
has 'excludePeople'      => ( is => 'ro', required   => 0 );
has 'agentsPulled' => ( is => 'rw' );
has 'agentsOnHold' => ( is => 'rw' );
has 'agentsPaused' => ( is => 'rw' );

#has 'agentList' => ( is =>'rw', lazy_build => 1 );

sub _build_dbh
  {
    my $self = shift;
    my $dbh  = Leads::DB->new( 'leads' );

    return $dbh;
  }

sub _build_state
  {
    my $self   = shift;
    my $_state = 'XX';
    my $_zip   = $self->zip;

    if ( length $_zip == 5 )
      {
        my $_tmp_state =
          $self->dbh->sqlSelect( 'state', 'zip_codes', "zip = '$_zip'" );
        $_state =
          ( defined $_tmp_state && $_tmp_state =~ /[A-Z]{2}/ )
          ? $_tmp_state
          : $_state;
      }

    return $_state;
  }

sub _build_stateFilter
  {
    my $self        = shift;
    my $_leadTypeId = $self->leadTypeId;

    my $filter = $self->dbh->sqlSelect(
        'id',
        'filter_types',
        "filter = 'state'
		 and lead_type_id = '$_leadTypeId'
		 and active = 'Y'" );

    return $filter;
  }

sub _build_log
  {
    my $self = shift;

    my $leadId = $self->leadId;
    my $type   = $self->type;

    my $log = Log::ProcessLog->new( typeId => $leadId,
                                    type   => $type );

    return $log;
  }

sub agentList
  {
    my $self              = shift;
    my $_currentAgentList = [];

    if ( $self->state ne 'XX' )
      {
        $self->_getInitialAgents;
        $self->_refineAgentList;

        my $_agents = $self->currentAgentList;

        foreach ( @$_agents )
          {
            my $msg = "Selected by lead type id and zip code";
            $self->log->write(
                   { entry => $msg, agentId => $_->{agent_id}, commit => 1, } );
          }

        my $_exclusions = $self->_applySourceFilters;
        $_exclusions ||= [];

        if ( scalar @$_exclusions > 0 )
          {
            @$_currentAgentList = grep {
                my $people_id = $_->{people_id};
                not grep { $_ eq $people_id } @$_exclusions
            } @$_agents;
          }
        else
          {
            $_currentAgentList = $_agents;
          }

        $self->currentAgentList( $_currentAgentList );

        $self->_checkHoldStatus;
        $self->_checkPauseWeekends;
        $self->_getAgentPreferences;

        #        $self->_getAgentSales;
        $self->_calculateExpectedRevenue;
      }
    else
      {
        $self->currentAgentList( $_currentAgentList );
      }

    $self->dbh->sqlInsert( "agents_pulled_summary",
                           {  lead_id         => $self->leadId,
                              lead_type_id    => $self->leadTypeId,
                              type            => $self->type,
                              zip             => $self->zip,
                              state           => $self->state,
                              number_pulled   => $self->agentsPulled,
                              number_on_hold  => $self->agentsOnHold,
                              number_weekends => $self->agentsPaused,
                           } );

    return $self->currentAgentList;
  }

sub _getInitialAgents
  {
    my $self             = shift;
    my $_exclusions      = 0;
    my $_duplicateLeadId = $self->duplicateLeadId;
    my $_filterId        = $self->stateFilter;
    my $_state           = $self->state;
    my $_limit = ( defined $self->limit ) ? "limit " . $self->limit : '';

    my $_exclusionList = $self->excludePeople || 0;

    #    my $_exclusionList = join ',', @{ $self->excludePeople }
    #      if ( $self->excludePeople );

    if (    $self->daysSinceDuplicate >= 30
         && $self->daysSinceDuplicate <= 90
         && $_duplicateLeadId > 0 )
      {
        my $_sold_to =
          $self->dbh->sqlSelectColArrayref( 'people_id', 'lead_sales',
                                            "lead_id = '$_duplicateLeadId'" );
        $_exclusions = ( scalar @$_sold_to ) ? join ',', @$_sold_to : 0;
      }

    $_exclusions = $_exclusions . ',' . $_exclusionList
      if ( length $_exclusionList > 0 );

    my $_agents = $self->dbh->sqlSelectAllHashrefArray(
        "af.people_id, af.filter_set_id, a.id as agent_id, a.license,
         afs.price as quote_price, ifnull(r.rev_expt_multiplier, 1) as revenue_expectation_multiplier,
         a.balance, a.promo_balance_available as promo_balance, ifnull(a.invoiceable, 0) as invoiceable,
         a.status, ifnull(a.max_invoice_amount, 0) as max_invoice_amount,
         a.company_id as company, ifnull(ar.active, 0) as rebill_on, ifnull(r.total_leads,0) as leads_sold,
         ifnull(afs.max_per_day, 10) as max_per_day,
         ifnull(afs.max_per_week, -1) as max_per_week, ifnull(afs.max_per_month, -1) as max_per_month,
         ifnull(afs.xclusive, 0) as exclusive",
        "agent_filter af
		   INNER JOIN agent_filter_set afs ON ( afs.id = af.filter_set_id AND afs.hold = 0 )
		   INNER JOIN agents a ON (a.people_id = af.people_id)
       LEFT JOIN revenue_expectation_multiplier r ON (r.people_id=a.people_id)
       LEFT JOIN agent_rebill ar ON (a.id = ar.agent_id)",
        "filter_id = '$_filterId' 
		 and value = '$_state' 
		 and operator = 'eq'
		 and a.status = 'Active' 
		 and af.people_id not in ( $_exclusions ) $_limit" );

    $self->currentAgentList( $_agents );
    return $_agents;
  }

sub _applySourceFilters
  {
    my $self = shift;

    my $_affiliate_id = $self->affiliateId;
    my $_leadTypeId   = $self->leadTypeId;
    my $_agentList    = $self->currentAgentList;

    my $_peopleIds = [ map { $_->{people_id} } @$_agentList ];
    my $_peopleList = join ',', @$_peopleIds;
    $_peopleList ||= 0;

    my $_exclusions = $self->dbh->sqlSelectColArrayref(
        'people_id', 'agent_source_filters',
        "affiliate_id = '$_affiliate_id' and lead_type_id = '$_leadTypeId'
           and people_id in ( $_peopleList )" );

    my $people_ids = ( scalar $_exclusions > 0 ) ? join ',', @$_exclusions : 0;
    $people_ids ||= 0;

    my $_agent_ids;
    $_agent_ids =
      $self->dbh->sqlSelectColArrayref( 'id', 'agents',
                                        "people_id in ( $people_ids )" )
      if ( $people_ids ne '0' );
    $_agent_ids ||= [];

    my $lead_type =
      $self->dbh->sqlSelect( 'name', 'lead_types', "id = $_leadTypeId" );
    foreach ( @$_agent_ids )
      {
        my $msg =
          "Excluded from purchasing $lead_type leads from Affiliate $_affiliate_id";
        $self->log->write( { entry => $msg, agentId => $_, commit => 1, } );
      }

    return $_exclusions;
  }

sub _refineAgentList
  {
    my $self              = shift;
    my $_currentAgentList = $self->currentAgentList;

    return if ( scalar @$_currentAgentList == 0 );

    my ( $_filterList, $_peopleList );
    my $_agentList = [];

    my $_zipCodeList = $self->_getZipCodeList;

    foreach my $_item ( @$_currentAgentList )
      {
        push @$_filterList, $_item->{filter_set_id};
        push @$_peopleList, $_item->{people_id};
      }

    my $_filters = join ',', @$_filterList;
    my $_people  = join ',', @$_peopleList;

    my $_count = $self->dbh->sqlSelectAllHashrefArray(
        'people_id, count(*) as number',
        'agent_filter_zip',
        "filter_set_id in ( $_filters )
		     and people_id in ( $_people )
		     and zip_code in ( $_zipCodeList )",
        'group by people_id' );

    foreach my $_agent ( @$_currentAgentList )
      {
        if (grep {
                ( $_->{people_id} == $_agent->{people_id} )
                  && $_->{number}
            } @$_count )
          {
            push @$_agentList, $_agent;
            next;
          }

        push @$_agentList, $_agent
          unless (
            $self->dbh->sqlCount(
                'agent_filter_zip',
                "filter_set_id = '$_agent->{filter_set_id}'
                                 and people_id = '$_agent->{people_id}'" ) );
      }

    $self->agentsPulled( scalar @$_agentList );
    $self->currentAgentList( $_agentList );
  }

sub _getZipCodeList
  {
    my $self    = shift;
    my $_radius = 10;
    my $_zip    = $self->zip;
    my $_state  = $self->state;
    my $_zipCodeList;

    if ( $_zip =~ /\d{5}/ )
      {
        if ( -e "/var/lock/zipcode_radius" )
          {
            my ( $_lat, $_lon, $_state ) =
              $self->dbh->sqlSelect( "lat, lon, state",
                                     "zip_codes",
                                     "zip = '$_zip'" );
            my $_zipList =
              $self->dbh->sqlSelectAll(
                "zip, ( 3959 * acos( cos( radians( '$_lat' ) ) * cos( radians( lat ) ) * cos( radians( lon ) - radians( '$_lon' ) ) + sin( radians( '$_lat' ) ) * sin( radians( lat ) ) ) ) AS distance",
                "zip_codes",
                "state = '$_state' HAVING distance <= $_radius ORDER BY distance"
              );
            my @_zipCodeList = map { $_->[ 0 ] } @$_zipList;
            my $_zipCodeList = join ',', @_zipCodeList;
          }
        else
          {
            $_zipCodeList = $_zip;
          }
      }
    else
      {
        $_zipCodeList = "0";
      }

    return $_zipCodeList;
  }

sub _checkHoldStatus
  {
    my $self       = shift;
    my $_agentList = $self->currentAgentList;

    return if ( scalar @$_agentList == 0 );

    my $_peopleIds = [ map { $_->{people_id} } @$_agentList ];
    my $_peopleList = join ',', @$_peopleIds;

    my $_onHold = $self->dbh->sqlSelectAllHashrefArray(
        'a.id as agent_id, a.people_id',
        'agents a left join preferences p on a.people_id = p.people_id',
        "a.people_id in ( $_peopleList )
                                                            and p.preference_type = 'hold'
                                                            and p.preference_setting = 'on'"
                                                      );
    my %_tmp;
    @_tmp{@$_peopleIds} = ();
    foreach ( @$_onHold )
      {
        delete $_tmp{ $_->{people_id} };
        my $msg = "On hold";
        $self->log->write(
                    { agentId => $_->{agent_id}, entry => $msg, commit => 1 } );
      }

    my $_newAgentList = [];

    foreach my $_people_id ( sort { $a <=> $b } keys %_tmp )
      {
        foreach ( @$_agentList )
          {
            push @$_newAgentList, $_ if ( $_->{people_id} == $_people_id );
          }
      }

    $self->agentsOnHold( scalar @$_onHold );
    $self->currentAgentList( $_newAgentList );
  }

sub _checkPauseWeekends
  {
    my $self = shift;

    return unless ( isWeekend() );

    my $_agentList = $self->currentAgentList;

    return if ( scalar @$_agentList == 0 );

    my $_peopleIds = [ map { $_->{people_id} } @$_agentList ];
    my $_peopleList = join ',', @$_peopleIds;

    my $_paused_weekends = $self->dbh->sqlSelectAllHashrefArray(
        'a.id as agent_id, a.people_id',
        'agents a left join preferences p on a.people_id = p.people_id',
        "a.people_id in ( $_peopleList )
                                                            and p.preference_type = 'pause_weekends'
                                                            and p.preference_setting = 'on'" 
                                                      );

    my $_paused_sunday = [];

    if ( isSunday() )
      {
        $_paused_sunday = $self->dbh->sqlSelectAllHashrefArray(
        'a.id as agent_id, a.people_id',
        'agents a left join preferences p on a.people_id = p.people_id',
        "a.people_id in ( $_peopleList )
                                                            and p.preference_type = 'pause_sunday'
                                                            and p.preference_setting = 'on'" 
                                                      );
      }

    my %_tmp;
    @_tmp{@$_peopleIds} = ();
    foreach ( @$_paused_weekends, @$_paused_sunday )
      {
        delete $_tmp{ $_->{people_id} };
        my $msg = "Weekends paused";
        $self->log->write(
                    { agentId => $_->{agent_id}, entry => $msg, commit => 1 } );
      }

    my $_newAgentList = [];

    foreach my $_people_id ( sort { $a <=> $b } keys %_tmp )
      {
        foreach ( @$_agentList )
          {
            push @$_newAgentList, $_ if ( $_->{people_id} == $_people_id );
          }
      }

    $self->agentsPaused( scalar @$_paused_weekends + scalar @$_paused_sunday );
    $self->currentAgentList( $_newAgentList );
  }

sub _getAgentPreferences
  {
    my $self = shift;

    my $_agentList = $self->currentAgentList;

    return if ( scalar @$_agentList == 0 );

    foreach my $_agent ( @$_agentList )
      {
        my $_preferences = $self->dbh->sqlSelectAllHashref(
            "preference_type",
            "preference_type, ifnull(preference_setting, -1) as preference_setting",
            "preferences",
            "people_id = '$_agent->{people_id}'
            and preference_type in ('hour_max_amt', 'day_max_amt', 'week_max_amt', 'year_max_amt')"
                                                          );
        foreach ( qw/hour_max_amt day_max_amt week_max_amt month_max_amt/ )
          {
            $_preferences->{$_}{preference_setting} = -1
              unless ( defined $_preferences->{$_}{preference_setting}
                       && $_preferences->{$_}{preference_setting} =~ /\d+/ );
            $_agent->{$_} = $_preferences->{$_}{preference_setting};
          }
      }

    $self->currentAgentList( $_agentList );
  }

sub _getAgentSales
  {
    my $self = shift;

    my $_agentList = $self->currentAgentList;

    return if ( scalar @$_agentList == 0 );

    foreach my $_agent ( @$_agentList )
      {
        my $_pingsActive = $self->dbh->sqlCount(
            "ping_offers",
            "people_id = '$_agent->{people_id}'
                                                   and active = 'Y'" );

        $_agent->{account_sales_hour} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and sale_time >= 
                                                                 date_sub( now(), interval 1 hour)"
                                                            );
        $_agent->{account_sales_day} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and sale_time >= date(now())"
                                                           );
        $_agent->{account_sales_week} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and YEAR(sale_time) >= YEAR(now())
                                                                 and YEARWEEK(sale_time) >= YEARWEEK(now())"
                                                            );
        $_agent->{account_sales_month} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and YEAR(sale_time) >= YEAR(now())
                                                                 and MONTH(sale_time) >= MONTH(now())"
                                                             );
        $_agent->{filterset_sales_day} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and sale_time >= date(now())"
                                                             );
        $_agent->{filterset_sales_week} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and YEAR(sale_time) >= YEAR(now())
                                                                 and YEARWEEK(sale_time) >= YEARWEEK(now())"
                                                              );
        $_agent->{filterset_sales_month} = $self->dbh->sqlCount(
            "lead_sales",
            "people_id = '$_agent->{people_id}'
                                                                 and YEAR(sale_time) >= YEAR(now())
                                                                 and MONTH(sale_time) >= MONTH(now())"
                                                               );

        $_pingsActive ||= 0;

        foreach (
            qw/account_sales_hour account_sales_day account_sales_week account_sales_month
            filterset_sales_day filterset_sales_week filterset_sales_month/ )
          {
            $_agent->{$_} ||= 0;
            $_agent->{$_} += $_pingsActive;
          }
      }

    $self->currentAgentList( $_agentList );
  }

sub _calculateExpectedRevenue
  {
    my $self = shift;

    my $_agentList = $self->currentAgentList;

    return if ( scalar @$_agentList == 0 );

    my $_newAgentList = [];

    foreach my $_agent ( @$_agentList )
      {
        if (    defined $_agent->{revenue_expectation_multiplier}
             && $_agent->{revenue_expectation_multiplier} >= 0
             && defined $_agent->{quote_price}
             && $_agent->{quote_price} >= 0 )
          {
            $_agent->{leads_sold} ||= 10;
            $_agent->{expected_revenue} =
              ( $_agent->{leads_sold} >= 10 )
              ? $_agent->{quote_price} *
              $_agent->{revenue_expectation_multiplier}
              : $_agent->{quote_price};
            push @$_newAgentList, $_agent;
          }
        elsif ( defined $_agent->{quote_price}
                && $_agent->{quote_price} >= 0 )
          {
            $_agent->{revenue_expectation_multiplier} = 1;
            $_agent->{leads_sold} ||= 10;
            $_agent->{expected_revenue} = $_agent->{quote_price};
            push @$_newAgentList, $_agent;
          }
        else
          {
            my $msg = Dumper( $_agent );
            sendEmail( 'bjones@insuranceagents.com',
                       'bjones@insuranceagents.com',
                       'Missing quote price and expected revenue', $msg );
          }
      }

    $self->currentAgentList( $_newAgentList );
  }

1;
