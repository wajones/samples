package Util::API::GetLead;

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Mouse;
use Leads::DB;
use XML::Simple;
use Data::Dumper;

has 'lead_id'      => ( is => 'rw', required => 0 );
has 'affiliate_id' => ( is => 'rw', required => 0 );
has 'lead_type'    => ( is => 'rw', required => 0 );
has 'lead_hash'    => ( is => 'rw', required => 0 );
has 'user_hash'    => ( is => 'rw', required => 0 );
has 'sale_hash'    => ( is => 'rw', required => 0 );
has 'return_hash'  => ( is => 'rw', required => 1, default => 0 );
has 'email'        => ( is => 'rw', required => 0 );

has 'dbh' => ( is => 'rw', lazy_build => 1 );

sub _build_dbh
  {
    my $self = shift;
    my $dbh  = Leads::DB->new( 'leads' );
  }

sub getLead
  {
    my $self = shift;
    my ( $lead, $output );

    if ( $self->lead_id && $self->lead_id =~ /\d+/ )
      {
        $lead = $self->dbh->getLead( $self->lead_id );
        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = "<lead></lead>";
          }
      }
    elsif ( $self->lead_hash && $self->lead_hash =~ /[a-z0-9]+/ )
      {
        my $hash = $self->lead_hash;
        $hash = $self->dbh->sqlQuote( $hash );
        my $lead_id =
          $self->dbh->sqlSelect( "lead_id", "lead_master", "hash = $hash" );
        my $lead = $self->dbh->getLead( $lead_id );
        if ( $lead && ref $lead eq 'HASH' )
          {
            $lead->{lead_token} = $self->lead_hash if ( $self->return_hash );
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = "<lead></lead>";
          }
      }
    elsif ( $self->sale_hash && $self->sale_hash =~ /[a-z0-9]+/ )
      {
        my $lead_id = $self->dbh->sqlSelect( "lead_id", "lead_hash_lu",
                                             "hash = '$self->sale_hash'" );
        my $lead = $self->dbh->getLead( $self->lead_id );

        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = "<lead></lead>";
          }
      }
    elsif ( $self->user_hash && $self->user_hash =~ /[a-z0-9]+/ )
      {
        my $lead_id = $self->dbh->sqlSelect( "lead_id", "lead_hash_lu",
                                             "hash = '$self->user_hash'" );
        my $lead = $self->dbh->getLead( $self->lead_id );

        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = "<lead></lead>";
          }
      }
    else
      {
        $output = "<lead></lead>";
      }
    $output;
  }

sub getLeadWithTokenFromID
  {
    my $self = shift;
    my ( $lead, $output );

    if ( $self->lead_id && $self->lead_id =~ /\d+/ )
      {
        $lead = $self->dbh->getLead( $self->lead_id );
        if ( $lead && ref $lead eq 'HASH' )
          {
            my $lead_id = $self->lead_id;
            $lead->{lead_token} =
              $self->dbh->sqlSelect( "hash",
                                     "lead_master",
                                     "lead_id=$lead_id" );

            my $source;
            my $aff_id = $self->dbh->sqlSelect( "affiliate_id",
                                                "lead_master",
                                                "lead_id=$lead_id" );
            if ( $aff_id == 93155 )
              {
                $source = "IA";
              }
            else
              {
                my $count = $self->dbh->sqlCount( "ping_lead_lu",
                                                  "lead_id=$lead_id" );
                if ( $count )
                  {
                    $source = "Inbound";
                  }
                else
                  {
                    $source = "Affiliate";
                  }
              }

            $lead->{source} = $source || "Affiliate";

            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = "<lead></lead>";
          }
      }
  }

sub getLeadMasterData
  {
    my $self = shift;
    my ( $lead, $output );

    if ( $self->lead_id && $self->lead_id =~ /\d+/ )
      {
        my $quoted_id = $self->dbh->sqlQuote( $self->lead_id );
        $lead = $self->dbh->sqlSelectHashref( "*", "lead_master",
                                              "lead_id = $quoted_id" );
        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'lead_master' );
          }
        else
          {
            $output = "<lead_master></lead_master>";
          }
      }
    else
      {
        $output = "<lead_master></lead_master>";
      }
    $output;
  }

sub getLeadSaleData
  {
    my $self = shift;
    my ( $lead, $output );

    if ( $self->lead_id && $self->lead_id =~ /\d+/ )
      {
        my $quoted_id = $self->dbh->sqlQuote( $self->lead_id );
        $lead = $self->dbh->sqlSelectAllHashrefArray( "*", "lead_sales",
                                                      "lead_id = $quoted_id" );
        if ( $lead && ref $lead eq 'ARRAY' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'sales' );
            $output =~ s/(\<\/?)anon(\>)/$1sale$2/g;
          }
        else
          {
            $output = "<sales></sales>";
          }
      }
    else
      {
        $output = "<sales></sales>";
      }
    $output;
  }

sub getLeadSaleAgentData
  {
    my $self = shift;
    my ( $agents, $output );

    if ( $self->lead_hash && $self->lead_hash =~ /[a-z0-9]+/ )
      {
        my $quoted_id = $self->dbh->sqlQuote( $self->lead_hash );
        $agents = $self->dbh->sqlSelectAllHashrefArray(
           "distinct(ag.id) as agent_id,
            ag.people_id as people_id,
            concat(ucase(mid(p.first_name, 1, 1)), lcase(mid(p.first_name,2))) as fname,
            concat(ucase(mid(p.last_name, 1, 1)), lcase(mid(p.last_name, 2))) as lname,
            com.id as company_id,
            com.name as company_name,
            ph.area_code,
            ph.number,
            ph.ext,
            lm.lead_type_id as type,
            lm.received as date,
            lm.lead_id,
            lm.zip",
           "lead_sales ls 
            left join people p on p.id = ls.people_id
            left join phone ph on ph.people_id = ls.people_id
            left join agents ag on ag.people_id = ls.people_id
            left join insurance_companies_new com on com.id = ag.company_id
            left join lead_master lm on ls.lead_id = lm.lead_id
            left join lead_quotes lq on ls.lead_id = lq.lead_id 
              and lq.people_id = ag.people_id",
           "lm.hash = $quoted_id and
            ph.phone_type in (3,7) order by lq.updated_at desc" );

        if ( $agents && ref $agents eq 'ARRAY' )
          {
            my %seen;
            my @unique = grep { !$seen{ $_->{people_id} }++ } @$agents;
            $output = XML::Simple->new()
              ->XMLout( \@unique, NoAttr => 1, RootName => 'agents' );
            $output =~ s/(\<\/?)anon(\>)/$1agent$2/g;
          }
        else
          {
            $output = "<agents></agents>";
          }
      }
    else
      {
        $output = "<agents></agents>";
      }
    $output;
  }

sub getLeadAffiliateData
  {
    my $self = shift;
    my ( $lead, $output );

    if ( $self->lead_id && $self->lead_id =~ /\d+/ )
      {
        my $quoted_id = $self->dbh->sqlQuote( $self->lead_id );
        $lead = $self->dbh->sqlSelectHashref( "affiliate_id", "lead_master",
                                              "lead_id = $quoted_id" );
        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()
              ->XMLout( $lead, NoAttr => 1, RootName => 'affiliate' );
          }
        else
          {
            $output = "<affiliate></affiliate>";
          }
      }
    else
      {
        $output = "<affiliate></affiliate>";
      }
    $output;
  }

sub getLeadSalesFromHash
  {
    my $self = shift;
    my $hash = $self->lead_hash;
    my $output;

    if ( $hash && $hash =~ /[a_zA-Z0-9]+/ )
      {
        my $sales = $self->dbh->sqlSelectAllHashrefArray(
           "ls.people_id,
            CONCAT( UCASE( MID( p.first_name, 1, 1 ) ) , LCASE( MID( p.first_name, 2 ) ) ) AS fname,
            CONCAT( UCASE( MID( p.last_name, 1, 1 ) ) , LCASE( MID( p.last_name, 2 ) ) ) AS lname,
            com.id as company_id,
            com.name as company_name,
            ph.area_code,
            ph.number,
            ph.ext,
            lm.lead_type_id as type,
            lm.zip",
            "lead_sales ls 
            LEFT JOIN people p ON p.id=ls.people_id 
            LEFT JOIN phone ph ON ph.people_id=ls.people_id 
            LEFT JOIN agents ag ON ag.people_id=ls.people_id 
            LEFT JOIN insurance_companies com ON com.id=ag.company_id 
            LEFT JOIN lead_master lm ON ls.lead_id=lm.lead_id",
            "lm.hash='$hash'
            AND ph.phone_type in ( 3, 7 )" );
        
        if ( $sales && ref $sales eq 'ARRAY' )
          {
            $output = XML::Simple->new()->XMLout( $sales, NoAttr => 1, RootName => 'sales' );
          }
        else
          {
            $output = '<sales></sales>';
          }
      }
    else
      {
        $output = '<sales></sales>';
      }
    $output =~ s/\<(\/?)anon>/<$1sale>/g;
    $output;
  }

sub getLeadCoverageFromHash
  {
    my $self = shift;
    my $hash = $self->lead_hash;
    my $output;

    if ( $hash && $hash =~ /[a_zA-Z0-9]+/ )
      {
        my $coverage = $self->dbh->sqlSelectHashref(
         "DISTINCT la.coverage as coverage",
         "lead_auto la
          LEFT JOIN lead_master lm ON la.lead_id=lm.lead_id",
         "lm.hash='$hash'" );

        if ( $coverage && $coverage =~ /[A-Za-z0-9]/ )
          {
            $output = XML::Simple->new()->XMLout( $coverage, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = '<lead></lead>';
          }
      }
    else
      {
        $output = '<lead></lead>';
      }
    $output;
  }

sub getHealthInfoFromHash
  {
    my $self = shift;
    my $hash = $self->lead_hash;
    my $output;

    if ( $hash && $hash =~ /[a_zA-Z0-9]+/ )
      {
        my $lead = $self->dbh->sqlSelectHashref(
         "distinct lm.lead_type_id as lead_type_id,
                          la.dob as dob,
                          la.gender as gender,
                          la.smoker as smoker,
                          lm.zip as zip,
                          lh.plan as plan",
          "lead_record_applicant la 
          LEFT JOIN lead_master lm ON la.lead_id=lm.lead_id 
          LEFT JOIN lead_health lh ON lh.lead_id=lm.lead_id",
          "lm.hash='$hash'" );

        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = '<lead></lead>';
          }
      }
    else
      {
        $output = '<lead></lead>';
      }
    $output;
  }

sub getLeadTypeAndZipFromHash
  {
    my $self = shift;
    my $hash = $self->lead_hash;
    my $output;

    if ( $hash && $hash =~ /[A-Za-z0-9]+/ )
      {
        my $lead = $self->dbh->sqlSelectHashref( "lead_type_id, zip",
                                                 "lead_master",
                                                 "hash = '$hash'",
                                                 "order by lead_id desc limit 1" );
        if ( $lead && ref $lead eq 'HASH' )
          {
            $output = XML::Simple->new()->XMLout( $lead, NoAttr => 1, RootName => 'lead' );
          }
        else
          {
            $output = '<lead></lead>';
          }
        }
      else
        {
          $output = '<lead></lead>';
        }

        $output;
      }
      
sub getPartners
  {
    my $self = shift;
    my $output;

    my $partners = $self->dbh->sqlSelectAllHashrefArray( "people_id",
                                             "post_partner_to_people" );
    $output = XML::Simple->new()->XMLout( $partners, RootName => 'partners' );

    $output =~ s/\<anon /\<partner /g;
    $output;
  }

sub checkUnsubscribeStatus
  {
    my $self = shift;

    my $email = $self->email;
    my $status = $self->dbh->sqlCount( "marketing_email_unsubscribe",
                                       "email = '$email'" );
    my $output = ( $status > 0 ) ? "Yes" : "No";
    $output = "<unsubscribed>$output</unsubscribed>";

    $output;
  }

1;
__END__

=head1 Stuff to do:


my $lead = Util::API::GetLead->new(lead_id => "numerical lead id");
print $lead->getLead;
print $lead->getLeadMasterData;
print $lead->getLeadSaleData;

=cut
