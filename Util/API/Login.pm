package Util::API;

use Moose;
use Leads::DB;
has 'key' => (is => 'rw', required => 1);
has 'db_data' => (is => 'rw', lazy_build => 1);

sub _build_db_data {
  my $self = shift;
  my $db = Leads::DB->new();
  my $quoted_key = $db->sqlQuote($self->key);
  $db->sqlSelectHashref(
  "api_keys.*, affiliates.people_id",
  "api_keys 
   INNER JOIN affiliates ON (api_keys.affiliate_id=affiliates.id)",
  "api_keys.production_key LIKE $quoted_key OR
   api_keys.testing_key    LIKE $quoted_key");
}

sub is_active {
  my $self = shift();
  ($self->is_valid && $self->db_data->{is_active} eq '1') || 0;
}

sub is_testing {
  my $self = shift();
  ($self->is_valid && $self->db_data->{testing_key} eq $self->key) || 0;
}

sub is_production {
  my $self = shift();
  ($self->is_valid && $self->db_data->{production_key} eq $self->key) || 0;
}

sub is_valid {
  defined(shift()->db_data) || 0;
}

sub affiliate_id {
  my $self = shift();
  $self->is_valid && $self->db_data->{affiliate_id};
}

sub people_id {
  my $self = shift();
  $self->is_valid && $self->db_data->{people_id};
}

1;
__END__
=head1 Stuff to do:


my $apikey = Util::API->new(key => "user's crap");
return unless $api_key->is_active();
do_testing_stuff if $api_key->is_testing();
do_production_stuff if $api_key->is_production;

=cut