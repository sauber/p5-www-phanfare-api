# Authenticate
# Create new album
# Upload image to new album
# Delete image from album
# Delete album

use strict;
use warnings;

use Test::More;

# Make sure we have the auth values to perform a test
#
my %config;
eval {
  use Config::General;
  use File::HomeDir;
  use WWW::Phanfare::API;

  my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
  %config = Config::General->new( $rcfile )->getall;
  die unless $config{api_key} and $config{private_key}
         and $config{email_address} and $config{password};
};
plan skip_all => $@ if $@;

# Create agent
#
my $api = new_ok ( 'WWW::Phanfare::API' => [
  api_key     => $config{api_key},
  private_key => $config{private_key},
] );

# Login
#
my $session = $api->Authenticate(
  email_address => $config{email_address},
  password      => $config{password},
);
ok ( $session->{'stat'} eq 'ok',  'Could not authenticate: ' . ( $session->{code_value} || '' ) );
ok ( $session->{session}{uid},  'Could not get target_uid: ' . ( $session->{code_value} || '' ) );
my $target_uid = $session->{session}{uid};

# Create New Album
#
my $album = $api->NewAlbum(
  target_uid => $target_uid,
);
ok ( $album->{'stat'} eq 'ok',  'Could not create new album: ' . ( $album->{code_value} || '' ) );
ok ( $album->{album}{album_id},  'Could not get album_id: ' . ( $album->{code_value} || '' ) );
my $album_id = $album->{album}{album_id};
ok ( $album->{album}{sections}{section}{section_id},  'Could not get section_id: ' . ( $album->{code_value} || '' ) );
my $section_id = $album->{album}{sections}{section}{section_id};

# Upload an image to newly created album
#
my $image = $api->NewImage(
  target_uid => $target_uid,
  album_id => $album_id,
  section_id => $section_id,
  filename => 't/testimage.png',
  caption => 'WWW::Phanfare::API Test Image',
  hidden => 1,
);
ok ( $image->{'stat'} eq 'ok',  'Could not upload new image ' . ( $image->{code_value} || '' ) );
ok ( $image->{imageinfo}{image_id},  'Could not get image_id: ' . ( $image->{code_value} || '' ) );
my $image_id = $image->{imageinfo}{image_id};

# Delete Image
#
my $del_image = $api->DeleteImage(
  target_uid => $target_uid,
  album_id => $album_id,
  section_id => $section_id,
  image_id => $image_id,
);
ok ( $del_image->{'stat'} eq 'ok',  'Could not delete image ' . ( $del_image->{code_value} || '' ) );

# Delete Album
#
my $del_album = $api->DeleteAlbum(
  target_uid => $target_uid,
  album_id => $album_id,
);
ok ( $del_album->{'stat'} eq 'ok',  'Could not delete album ' . ( $del_album->{code_value} || '' ) );

done_testing();
