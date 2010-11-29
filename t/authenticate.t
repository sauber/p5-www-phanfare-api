use Test::More qw(no_plan);
BEGIN { use_ok "WWW::Phanfare::API"};
require_ok( 'WWW::Phanfare::API' );

my $api = new WWW::Phanfare::API;
$api->readconfig;
$api->Authenticate;
ok( $api->target_uid > 0, "Target uid is " . $api->targetuid );