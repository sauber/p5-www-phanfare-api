package WWW::Phanfare::API;

use Moose;
use MooseX::Method::Signatures;
use REST::Client;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use XML::Simple;
use Config::General;
use File::HomeDir;
use Carp;

=head1 NAME

WWW::Phanfare::API - Perl wrapper for Phanfare API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::Phanfare::API;

    my $phanfare = WWW::Phanfare::API->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

has _xml => (
  is => 'ro',
  isa => 'XML::Simple',
  lazy_build => 1,
);
sub _build__xml { new XML::Simple }

has _rest => (
  is => 'ro',
  isa => 'REST::Client',
  required => 1,
  lazy_build => 1,
);
sub _build__rest {
  # Create a new REST client with cookies enabled
  my $ua = new REST::Client;
  $ua->getUseragent()->cookie_jar({});
  return $ua;
}

# User Configs
has email_address => ( is => 'ro', isa => 'Str', lazy_build=>1 );
sub _build_email_address {
  _readconfig('email_address');
}

has password => ( is => 'ro', isa => 'Str', lazy_build=>1 );
sub _build_password {
  _readconfig('password');
}

has api_key => ( is => 'ro', isa => 'Str', required => 1, lazy_build => 1 );
sub _build_api_key {
  _readconfig('api_key');
}

has private_key => ( is => 'ro', isa => 'Str', required => 1, lazy_build=>1 );
sub _build_private_key {
  _readconfig('private_key');
}

has _site => ( is => 'ro', isa => 'Str', default => 'http://www.phanfare.com/api/?' );
has target_uid => ( is => 'rw', isa => 'Str' );
has _requeststring => ( is => 'rw', isa => 'Str', default=>'', clearer => '_clear__requeststring' );

has _authenticated => ( is => 'rw', isa => 'Bool' );

=head1 SUBROUTINES/METHODS

=head2 Private functions

=cut

# Read configuration options from .phanfarerc file
#
sub _readconfig {
  my $option = shift;
  # Make sure file exists
  my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
  unless ( -r $rcfile ) {
    croak "Cannot read $rcfile\n";
  }
  
  # Read config file
  my $conf = new Config::General($rcfile);
  my %config = $conf->getall;
  
  # Read each required value
  #for my $key ( qw(email password api_key private_key) ) {
  #  croak "$key not defined in $rcfile" unless $config{$key};
  #  $self->$key( $config{$key} );
  #}

  return $config{$option};
}

# Sign a request with private key
#
method _sign {
  my $req = $self->_requeststring;
  my $sig = md5_hex( $req . $self->private_key );
  $self->_append( 'sig' => $sig );
  return $self;
}

#Append key-value pairs to request string
#
method _append( Str $key, Str $value ) {
  my $str;
  my $req = $self->_requeststring;
  $str = '&' if $req;
  $req ||= ''; $str ||= '';
  $str = $req . $str . sprintf "%s=%s", $key, $value;  
  $self->_requeststring( $str );
  return $self;
}


#Place a request to REST API
#
method _request {
  # Place request
  my $rest = $self->_rest;
  $rest->GET( $self->_site . $self->_requeststring);
  $self->_clear__requeststring;

  # Verify request is succesful
  croak $rest->responseContent() unless $rest->responseCode() eq '200';

  # Convert xml data to perl data structure
  my $data = $self->_xml->XMLin( $rest->responseContent() );
  return $data;
}

########################################################################
### Authentication
########################################################################

=head2 Authentication

There are three methods of authentication.

=over

=item Authenticate - read-write account session

=item AuthenticateGuest - read-only session

=item AuthenticateToSite - read-only session to password protected site

=back

One of these methods must be called before any other method can be called.

=cut

# Call an authentication method.
#
method _authentication {
  # If email/password exist, then get read-write session
  # Otherwise guest session
  if ( $self->email_address and $self->password ) {
    $self->Authenticate;
  } else {
    $self->AuthenticateGuest;
  }
}

=head3 Authenticate

Read-write user session authentication request.

=cut

method Authenticate {
  $self->_append( 'api_key'  => $self->api_key );
  $self->_append( 'email_address'    => $self->email_address );
  $self->_append( 'password' => $self->password );
  $self->_append( 'method'   => 'Authenticate' );
  my $resp = $self->_sign->_request;
  # Read uid from response
  #warn Dumper $resp;
  $self->target_uid( $resp->{session}{uid} );
  $self->_authenticated(1);
  return $self;
}

=head3 AuthenticateGuest

Anonymous read-only authentication request

=cut

method AuthenticateGuest {
  $self->_append( 'api_key'  => $self->api_key );
  $self->_append( 'method'   => 'AuthenticateGuest' );
  $self->_sign->_request;
  $self->_authenticated(1);
  return $self;
}

########################################################################
### Albums
########################################################################

=head2 Albums

=head3 GetAlbumList

List of albums

=cut

method GetAlbumList {
  $self->_authentication unless $self->_authenticated;
  $self->rest->_append( 'api_key'  => $self->api_key );
  $self->rest->_append( 'method'   => 'GetAlbumList' );
  my $resp = $self->_sign->_request;
  # Read list of albums
  return $resp->{albums}{album};
}

=head1 AUTHOR

Soren Dossing, C<< <netcom at sauber.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-phanfare-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Phanfare-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Phanfare::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Phanfare-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Phanfare-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Phanfare-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Phanfare-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose;

1; # End of WWW::Phanfare::API
