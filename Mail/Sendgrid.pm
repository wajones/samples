package Mail::Sendgrid;

use strict;
use warnings;

use feature ":5.10";
use feature "switch";

use lib "/u/apps/leads2/current";
use lib "/u/apps/leads2/current/admin";

use SmtpApiHeader;
use Try::Tiny;
use Net::SMTP;
use MIME::Entity;
use Mouse;
use Data::Dumper;

has 'user' =>
  ( is => 'ro', required => 1, default => 'transactional@insuranceagents.com' );
has 'password' => ( is => 'ro', required => 1, lazy_build => 1 );
has 'server'   => ( is => 'ro', required => 1, lazy_build => 1 );
has 'header'   => ( is => 'rw', required => 0, default    => 'Miscellaneous' );
has 'from' =>
  ( is => 'rw', required => 1, default => 'support@insuranceagents.com' );
has 'to'           => ( is => 'rw', required => 0 );
has 'bcc'          => ( is => 'rw', required => 0, predicate => 'has_bcc' );
has 'subject'      => ( is => 'rw', required => 0 );
has 'html_content' => ( is => 'rw', required => 0 );
has 'text_content' => ( is => 'rw', required => 0 );
has 'success'      => ( is => 'rw', required => 0 );

sub _build_password
  {
    my $self = shift;

    my $pass = "";

    given ( $self->user )
    {
        when ( /transactional/ ) { $pass = 'simple2011'; }
        when ( /aoconnor/ )      { $pass = 'simple2011'; }
    }

    return $pass;
  }

sub _build_server
  {
    return 'smtp.sendgrid.net';
  }

sub send
  {
    my ( $self, $params ) = @_;

    $self->header( $params->{header} )   if ( defined( $params->{header} ) );
    $self->from( $params->{from} )       if ( defined( $params->{from} ) );
    $self->to( $params->{to} )           if ( defined( $params->{to} ) );
    $self->bcc( $params->{bcc} )         if ( defined( $params->{bcc} ) );
    $self->subject( $params->{subject} ) if ( defined( $params->{subject} ) );
    $self->html_content( $params->{html_content} )
      if ( defined( $params->{html_content} ) );
    $self->text_content( $params->{text_content} )
      if ( defined( $params->{text_content} ) );

    my $hdr = SmtpApiHeader->new;
    $hdr->setCategory( $self->header );
    $hdr->setUniqueArgs( { lead_id => $params->{lead_id} || 1,
                           agent_id => $params->{agent_id} || 100, } );

    my $email = MIME::Entity->build( From     => $self->from,
                                     To       => $self->to,
                                     Subject  => $self->subject,
                                     Type     => 'multipart/alternative',
                                     Encoding => '-SUGGEST' );
    $email->head->add( "X-SMTPAPI", $hdr->asJSON );
    $email->attach( Type     => 'text/plain',
                    Encoding => '-SUGGEST',
                    Data     => $self->text_content );
    $email->attach( Type     => 'text/html',
                    Encoding => '-SUGGEST',
                    Data     => $self->html_content );

    my $success = 1;

    try
    {
        my $smtp = Net::SMTP->new( $self->server,
                                   Port    => 25,
                                   Timeout => 20,
                                   Hello   => 'insuranceagents.com' );

        $smtp->auth( $self->user, $self->password );
        $smtp->mail( $self->from );
        $smtp->to( $self->to );
        $smtp->bcc( $self->bcc ) if ( $self->has_bcc );
        $smtp->data( $email->stringify );
        $smtp->quit;
    }
    catch
    {
        $success = 0;
    };

    $self->success( $success );
    return $success;
  }

1;
