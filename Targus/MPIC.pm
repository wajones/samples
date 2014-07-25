package Targus::MPIC;

use warnings;
use strict;
use LWP::UserAgent;
use XML::Simple;
use URI::Escape;
use Data::Dumper;
use Mouse;

use lib "/u/apps/leads2/current";
use Leads::DB;

has ua  => ( is => 'ro', required => 1, lazy_build => 1 );
has url => ( is => 'ro', required => 1, lazy_build => 1 );
has leadId        => ( is => 'ro', required => 1 );
has firstName     => ( is => 'ro', required => 1 );
has middleName    => ( is => 'ro', required => 1, default => '' );
has lastName      => ( is => 'ro', required => 1 );
has streetAddress => ( is => 'ro', required => 1 );
has city          => ( is => 'ro', required => 1 );
has state         => ( is => 'ro', required => 1 );
has zip           => ( is => 'ro', required => 1 );
has phone         => ( is => 'rw', required => 1 );
has email         => ( is => 'ro', required => 1 );
has ip                => ( is => 'ro' );
has response          => ( is => 'rw' );
has db                => ( is => 'ro', lazy_build => 1 );
has xml               => ( is => 'rw', lazy_build => 1 );
has successful        => ( is => 'rw', default => 0 );
has emailValidation   => ( is => 'rw' );
has emailReason       => ( is => 'rw' );
has emailRepository   => ( is => 'rw' );
has emailScore        => ( is => 'rw' );
has phoneScore        => ( is => 'rw' );
has phoneValidation   => ( is => 'rw' );
has phoneTZ           => ( is => 'rw' );
has phoneDST          => ( is => 'rw' );
has phoneState        => ( is => 'rw' );
has phoneMobile       => ( is => 'rw' );
has phoneDAConnected  => ( is => 'rw' );
has ipValidation      => ( is => 'rw' );
has ipCountry         => ( is => 'rw' );
has ipState           => ( is => 'rw' );
has addressState      => ( is => 'rw' );
has addressCMRA       => ( is => 'rw' );
has addressVacancy    => ( is => 'rw' );
has addressRBDI       => ( is => 'rw' );
has addressScore      => ( is => 'rw' );
has addressPrison     => ( is => 'rw' );
has addressValidation => ( is => 'rw' );
has addressDPVConfirm => ( is => 'rw' );
has addressUSPSType   => ( is => 'rw' );

sub _build_ua
  {
    my $ua = LWP::UserAgent->new();
    $ua->timeout( 5 );

    return $ua;
  }

sub _build_url
  {
    return 'https://webgwy.targusinfo.com/access/query';
  }

sub _build_db
  {
    return Leads::DB->new();
  }

sub _build_xml
  {
    my $self = shift;

    my $phone = $self->phone;
    $phone =~ s/^1//g;
    $phone =~ s/\D//g;
    $self->phone( $phone );

    my $data;
    $data->{Names}{Name} = [ { type     => 'C',
                               'First'  => [ $self->firstName ],
                               'Middle' => [ $self->middleName ],
                               'Last'   => [ $self->lastName ],
                             } ];
    $data->{Addresses}{Address} = [
                 { 'score' => 1,
                   'appends' =>
                     'validation,dpvconfirm,uspstype,rbdi,vacancy,cmra,prison',
                   'Street' => [ $self->streetAddress ],
                   'City'   => [ $self->city ],
                   'ST'     => [ $self->state ],
                   'Postal' => [ $self->zip ],
                 } ];
    $data->{Phones}{Phone} = [
                        { score   => 1,
                          appends => 'validation,mobile,tz,dst,st,daconnected',
                          content => $self->phone,
                        } ];
    $data->{eMailAddresses}{eMail} = [
                                   { score   => 1,
                                     appends => 'validation,reason,repository',
                                     content => $self->email,
                                   } ];
    $data->{IPAddresses}{IPAddress} = [ { appends => 'validation,country,ST',
                                          content => $self->ip
                                        } ];

    my $xml = XML::Simple->new->XMLout( $data, RootName => 'Contact' );

    return $xml;
  }

sub send
  {
    my $self = shift;

    my $query_params = { 875 => $self->xml };
    my $query_string = join(
        '&',
        map {
                'key' 
              . $_ . '='
              . uri_escape( $query_params->{$_} )
          } keys( %$query_params ) );

    my $credentials = { svcid    => '9212807307',
                        username => 'CyberTech',
                        password => 'K93vCq',
                        elems    => '3226' };

    my $credential_string =
      join( '&', map { $_ . '=' . $credentials->{$_} }
              keys( %{$credentials} ) );

    my $data = join( '&', $credential_string, $query_string );

    my $ua  = $self->ua;
    my $url = $self->url . '?' . $data;

    my $response = $ua->get( $url );
    if ( $response->is_success )
      {
        my $data = XML::Simple->new->XMLin( $response->decoded_content );
        my $received_xml = $data->{response}{result}{value};
        $self->response( $received_xml );
        $self->successful( 1 );
      }
    else
      {
        $self->response( $response->status_line );
        $self->successful( 0 );
      }

    $self->parseResponse;
    $self->insertRecord;

    return $self->successful;
  }

sub parseResponse
  {
    my $self = shift;

    my $response_data = XML::Simple->new->XMLin( $self->response );
    $self->emailValidation(
                          $response_data->{eMailAddresses}{eMail}{validation} );
    $self->emailReason( $response_data->{eMailAddresses}{eMail}{reason} );
    $self->emailRepository(
                          $response_data->{eMailAddresses}{eMail}{repository} );
    $self->emailScore( $response_data->{eMailAddresses}{eMail}{score} );
    $self->phoneScore( $response_data->{Phones}{Phone}{score} );
    $self->phoneValidation( $response_data->{Phones}{Phone}{validation} );
    $self->phoneTZ( $response_data->{Phones}{Phone}{tz} );
    $self->phoneDST( $response_data->{Phones}{Phone}{dst} );
    $self->phoneState( $response_data->{Phones}{Phone}{st} );
    $self->phoneMobile( $response_data->{Phones}{Phone}{mobile} );
    $self->phoneDAConnected( $response_data->{Phones}{Phone}{DAConnected} );
    $self->ipValidation( $response_data->{IPAddresses}{IPAddress}{validation} );
    $self->ipCountry( $response_data->{IPAddresses}{IPAddress}{country} );
    $self->ipState( $response_data->{IPAddresses}{IPAddress}{st} );
    $self->addressState( $response_data->{Addresses}{Address}{ST} );
    $self->addressCMRA( $response_data->{Addresses}{Address}{CMRA} );
    $self->addressVacancy( $response_data->{Addresses}{Address}{vacancy} );
    $self->addressRBDI( $response_data->{Addresses}{Address}{RBDI} );
    $self->addressScore( $response_data->{Addresses}{Address}{score} );
    $self->addressPrison( $response_data->{Addresses}{Address}{prison} );
    $self->addressValidation($response_data->{Addresses}{Address}{validation} );
    $self->addressDPVConfirm($response_data->{Addresses}{Address}{DPVConfirm} );
    $self->addressUSPSType( $response_data->{Addresses}{Address}{USPSType} );
  }

sub insertRecord
  {
    my $self = shift;

    my $db = $self->db;
    $db->sqlInsert( "targus_mpic_scoring",
                    {  lead_id            => $self->leadId,
                       successful         => $self->successful,
                       address_score      => $self->addressScore,
                       phone_score        => $self->phoneScore,
                       email_score        => $self->emailScore,
                       address_validation => $self->addressValidation,
                       address_DPVConfirm => $self->addressDPVConfirm,
                       address_USPSType   => $self->addressUSPSType,
                       address_RBDI       => $self->addressRBDI,
                       address_vacancy    => $self->addressVacancy,
                       address_CMRA       => $self->addressCMRA,
                       address_prison     => $self->addressPrison,
                       phone_validation   => $self->phoneValidation,
                       phone_mobile       => $self->phoneMobile,
                       phone_tz           => $self->phoneTZ,
                       phone_dst          => $self->phoneDST,
                       phone_state        => $self->phoneState,
                       phone_DAConnected  => $self->phoneDAConnected,
                       email_validation   => $self->emailValidation,
                       email_reason       => $self->emailReason,
                       email_repository   => $self->emailRepository,
                       ip_validation      => $self->ipValidation,
                       ip_country         => $self->ipCountry,
                       ip_state           => $self->ipState,
                    } );
  }

sub getAddressScore
  {
    my $self = shift;
    return $self->addressScore;
  }

sub getEmailScore
  {
    my $self = shift;
    return $self->emailScore;
  }

sub getPhoneScore
  {
    my $self = shift;
    return $self->phoneScore;
  }

sub emailFails
  {
    my $self = shift;

    my $return = ( $self->emailScore <= 30 ) ? 1 : 0;
    return $return;
  }

sub phoneFails
  {
    my $self = shift;

    my $return = ( $self->phoneScore <= 30 ) ? 1 : 0;
    return $return;
  }

1;
