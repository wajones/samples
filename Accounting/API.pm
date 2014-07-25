package Accounting::API;

use strict;
use warnings;

use feature ":5.10";
use feature "switch";

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use Leads::DB;
use Mouse;
use Try::Tiny;
use Data::Dumper;

has 'procedure' => ( is => 'ro', required   => 1 );
has 'arguments' => ( is => 'ro', required   => 1 );
has 'result'    => ( is => 'rw', required   => 1, default => 0 );
has 'dbh'       => ( is => 'ro', lazy_build => 1 );

sub _build_dbh
  {
    my $self = shift;
    my $dbh  = Leads::DB->new( 'leads' );

    return $dbh;
  }

sub _addPromoCredit
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $self->arguments->{amount_available} ||= 0;
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.addPromoCredit',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{amount_available} );
      }

    $self->result( $result );

    return $result;
  }

sub _affiliatePaymentMade
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{affiliate_id}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.affiliatePaymentMade',
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{notes} );
      }

    $self->result( $result );

    return $result;
  }

sub _affiliatePaymentReceived
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{affiliate_id}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.affiliatePaymentReceived',
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{notes} );
      }

    $self->result( $result );

    return $result;
  }

sub _applyInactivityFee
  {
    my $self   = shift;
    my $result = 0;

    if ( $self->arguments->{agent_id} )
      {
        $self->arguments->{fee}   ||= 20;
        $self->arguments->{notes} ||= '';

        $result =
          $self->dbh->sqlCallProcedure( 'accounting.applyInactivityFee',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{fee},
                                        $self->arguments->{notes} );
      }

    $self->result( $result );

    return $result;
  }

sub _agentEmailPurchase
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.agentEmailPurchase',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{notes} );
      }

    $self->result( $result );

    return $result;
  }

sub _agentPaymentReceived
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
	my $entry_date = $self->dbh->sqlSelect( "select now()" );
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.agentPaymentReceived',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{notes},
					$entry_date );
      }

    $self->result( $result );

    return $result;
  }

sub _cashBalanceAdjustment
  {
    my $self   = shift;
    my $result = 0;
warn Dumper($self->arguments);
    if (    $self->arguments->{id}
         && $self->arguments->{account_type}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.cashBalanceAdjustment',
                                        $self->arguments->{id},
                                        $self->arguments->{account_type},
                                        $self->arguments->{amount},
                                        $self->arguments->{notes} );
      }

    $self->result( $result );

    return $result;
  }

sub _closeAccount
  {
    my $self   = shift;
    my $result = 0;

    if ( $self->arguments->{agent_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.closeAccount',
                                        $self->arguments->{agent_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _closeAccountRefund
  {
    my $self   = shift;
    my $result = 0;

    if ( $self->arguments->{agent_id} )
      {
        if ( $self->arguments->{amount} )
          {
            $result =
              $self->dbh->sqlCallProcedure( 'accounting.closeAccountRefund',
                                            $self->arguments->{agent_id},
                                            $self->arguments->{amount} );
          }
        else
          {
            $result =
              $self->dbh->sqlCallProcedure( 'accounting.closeAccount',
                                            $self->arguments->{agent_id} );
          }
      }

    $self->result( $result );

    return $result;
  }

sub _creditAgent
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{agent_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.creditAgent',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{agent_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _creditCardFund
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount}
         && $self->arguments->{transaction_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.creditCardFund',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{transaction_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _creditCardRefund
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount}
         && $self->arguments->{transaction_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.creditCardRefund',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount},
                                        $self->arguments->{transaction_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _duplicateReversal
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{affiliate_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.duplicateReversal',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{affiliate_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadPurchase
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{affiliate_id}
         && $self->arguments->{amount} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadPurchase',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{amount} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadRefund
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{agent_id}
         && $self->arguments->{affiliate_id} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadRefund',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{agent_id},
                                        $self->arguments->{affiliate_id} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadReturn
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{affiliate_id} )
      {
        $self->arguments->{description} ||= "";
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadReturn',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{description} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadReturnByDate
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{affiliate_id} )
      {
        $self->arguments->{description} ||= "";
        if ( !defined $self->arguments->{date} )
          {
            my $entry_date = $self->dbh->sqlSelect( "select now()" );
            $self->arguments->{date} = $entry_date;
          }

        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadReturnByDate',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{description},
                                        $self->arguments->{date} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadSale
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadSale',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount} );
      }

    $self->result( $result );

    return $result;
  }

sub _leadSaleByDate
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{lead_id}
         && $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        if ( !defined $self->arguments->{date} )
          {
            my $entry_date = $self->dbh->sqlSelect( "select now()" );
            $self->arguments->{date} = $entry_date;
          }

        $result =
          $self->dbh->sqlCallProcedure( 'accounting.leadSaleByDate',
                                        $self->arguments->{lead_id},
                                        $self->arguments->{affiliate_id},
                                        $self->arguments->{description},
                                        $self->arguments->{date} );
      }

    $self->result( $result );

    return $result;
  }

sub _moveMoney
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_from}
         && $self->arguments->{agent_to}
         && $self->arguments->{amount} )
      {
        $self->arguments->{notes} ||= '';
        $self->arguments->{notes} .=
          " Moved $self->arguments->{amount} from $self->arguments->{agent_from} to $self->arguments->{agent_to}.";
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.cashBalanceAdjustment',
                                        $self->arguments->{agent_from},
                                        'Agent',
                                        -$self->arguments->{amount},
                                        $self->arguments->{notes} );
        if ( $result )
          {
            $result =
              $self->dbh->sqlCallProcedure( 'accounting.cashBalanceAdjustment',
                                            $self->arguments->{agent_to},
                                            'Agent',
                                            $self->arguments->{amount},
                                            $self->arguments->{notes} );

            if ( !$result )
              {
                $result =
                  $self->dbh->sqlCallProcedure(
                           'accounting.cashBalanceAdjustment',
                           $self->arguments->{agent_from},
                           'Agent',
                           $self->arguments->{amount},
                           'Correction to previous move money -- routine failed'
                  );

              }
          }
      }
    $self->result( $result );

    return $result;
  }

sub _removePromoCredit
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.removePromoCredit',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount} );
      }

    $self->result( $result );

    return $result;
  }

sub _sellBulkLeads
  {
    my $self   = shift;
    my $result = 0;

    if (    $self->arguments->{agent_id}
         && $self->arguments->{amount} )
      {
        $result =
          $self->dbh->sqlCallProcedure( 'accounting.sellBulkLeads',
                                        $self->arguments->{agent_id},
                                        $self->arguments->{amount} );
      }

    $self->result( $result );

    return $result;
  }

sub do
  {
    my $self = shift;

    given ( $self->procedure )
    {
        when ( "addPromoCredit" ) { $self->_addPromoCredit; }
        when ( "affiliatePaymentMade" )
        {
            $self->_affiliatePaymentMade;
        }
        when ( "affiliatePaymentReceived" )
        {
            $self->_affiliatePaymentReceived;
        }
        when ( "agentEmailPurchase" )
        {
            $self->_agentEmailPurchase;
        }
        when ( "agentPaymentReceived" )
        {
            $self->_agentPaymentReceived;
        }
        when ( "cashBalanceAdjustment" )
        {
            $self->_cashBalanceAdjustment;
        }
	when ( "closeAccount" )      { $self->_closeAccount; }
	when ( "closeAccountRefund" ) { $self->_closeAccountRefund;}
        when ( "creditAgent" )       { $self->_creditAgent; }
        when ( "creditCardFund" )    { $self->_creditCardFund; }
        when ( "creditCardRefund" )  { $self->_creditCardRefund; }
        when ( "duplicateReversal" ) { $self->_duplicateReversal; }
        when ( "leadPurchase" )      { $self->_leadPurchase; }
        when ( "leadRefund" )        { $self->_leadRefund; }
        when ( "leadReturn" )        { $self->_leadReturn; }
        when ( "leadReturnByDate" )  { $self->_leadReturnByDate; }
        when ( "moveMoney" )         { $self->_moveMoney; }
        when ( "removePromoCredit" ) { $self->_removePromoCredit; }
        when ( "sellBulkLeads" )     { $self->_sellBulkLeads; }
    }

    return $self->result;
  }

1;

