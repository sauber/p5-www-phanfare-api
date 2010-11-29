use Test::More qw(no_plan);
BEGIN { use_ok "WWW::Phanfare::API"};
require_ok( 'WWW::Phanfare::API' );

my $api = new WWW::Phanfare::API;
$api->_authentication;
#diag("Target uid is " . $api->target_uid);
ok( $api->target_uid > 0, "Target uid is " . $api->target_uid );
