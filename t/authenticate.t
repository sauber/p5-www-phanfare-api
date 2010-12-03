# If a .phanfarerc file exist, use it for authentication test
# File format:
#   api_key xxx
#   private_key yyy
#   email_address my@email
#   password zzz
#


use Test::More qw(no_plan);

eval 'use File::HomeDir';
plan skip_all => 'File::HomeDir required' if $@;

eval 'use Config::General';
plan skip_all => 'Config::General required' if $@;

my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
my $conf;
SKIP: {
  skip 'Cannot read $rcfile', 1, unless -r $rcfile;

  $conf = new_ok( Config::General => [ $rcfile ] );
}
exit unless $conf;


my %config = $conf->getall;
ok( $config{api_key}, 'api_key not found in .phanfarerc file' );
ok( $config{private_key}, 'private_key not found in .phanfarerc file' );
plan skip_all => 'Cannot test authentiction without api_key and private_key'
  unless $config{api_key} and $config{private_key};

BEGIN { use_ok "WWW::Phanfare::API"};
require_ok( 'WWW::Phanfare::API' );
my $api = new WWW::Phanfare::API->new(
  api_key     => $config{api_key},
  private_key => $config{private_key},
);
ok ( $api, 'Could not create WWW::Phanfare::API object' );
plan skip_all => 'Could not create WWW::Phanfare::API object' unless $api;
#diag( $api );

# Make XML::Simple object
#
my $xml;
eval 'use XML::Simple';
if ( $@ ) {
  fail('XML::Simple required');
} else {
  $xml = new XML::Simple;
  ok ( $xml, 'xml object' );
}

# Test anonymous login
#
my $anon = $api->AuthenticateGuest();
ok( $anon );

# Check for valid response
# 
SKIP: {
  skip 'XML::Simple required', 2, unless $xml and $anon;

  my $ref = $xml->XMLin( $anon );
  ok( ref $ref, 'XML response not parsing');
  ok( $ref->{'stat'} eq 'ok', "Response stat not ok: $anon" );
}

# Test user login when email_address and password is defined in .phanfarerc
#
my $user;
SKIP: {
  skip 'Cannot test authentiction without email_address and password', 1,
    unless $config{email_address} and $config{password};

  $user = $api->Authenticate(
    email_address => $config{email_address},
    password      => $config{password},
  );

  ok ( $user );
};

# Check for valid response
#
SKIP: {
  skip 'XML::Simple required', 2, unless $xml and $user;

  $ref = $xml->XMLin( $user );
  ok( ref $ref, 'XML response not parsing');
  ok( $ref->{'stat'} eq 'ok', "Response stat not ok: $user" );
  ok( $ref->{session}{uid} > 0, 'No target_uid in response' );
};
