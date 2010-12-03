package WWW::Phanfare::API;

=head1 NAME

WWW::Phanfare::API - Perl wrapper for Phanfare API

=head1 VERSION

Version 0.01

=cut

use strict;
use warnings;
use Carp;
use REST::Client;
use Digest::MD5 qw(md5_hex);
use URI::Escape;

our $VERSION = '0.01';
our $site = 'http://www.phanfare.com/api/?';
our $AUTOLOAD;

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self  = { @_ };
  bless $self, $class;
  return $self;
}

# All API methods implemented as autoload functions.
#
#   $papi->Function() becomes REST::Client::GET(..."method=Function"...)
#
sub AUTOLOAD {
  my $self = shift;
  croak "$self is not an object" unless ref($self);

  my $method = $AUTOLOAD;
  $method =~ s/.*://;   # strip fully-qualified portion
  croak "method not defined" unless $method;

  # Verify keys are defined
  croak 'api_key not defined' unless $self->{api_key};
  croak 'private_key not defined' unless $self->{private_key};

  my %param = @_;
  # Build signature request string
  my $req = join '&',
    sprintf('%s=%s', 'api_key', $self->{api_key}),
    sprintf('%s=%s', 'method', $method),
    map { sprintf '%s=%s', $_, $param{$_} } keys %param;

  # Sign request string
  my $sig = md5_hex( $req . $self->{private_key} );

  # Build URL escaped request string
  $req = join '&',
    sprintf('%s=%s', 'api_key', $self->{api_key}),
    sprintf('%s=%s', 'method', $method),
    map { sprintf '%s=%s', $_, uri_escape $param{$_} } keys %param;
  $req .= sprintf '&%s=%s', 'sig', $sig;

  #warn "*** Request string: $req\n"; # XXX debug

  # Create REST agent with cookies
  unless ( $self->{_rest} ) {
    $self->{_rest} = new REST::Client;
    $self->{_rest}->getUseragent()->cookie_jar({});
  }

  # Send request
  $self->{_rest}->GET( $site . $req );

  # Receive response
  carp sprintf(
    "Return code %s: %s",
    $self->{_rest}->responseCode(),
    $self->{_rest}->responseContent()
  ) unless $self->{_rest}->responseCode() eq '200';

  # Return the XML formatted response
  return $self->{_rest}->responseContent();
}

# Make sure not caught by AUTOLOAD
sub DESTROY {}

=head1 SYNOPSIS

Create object. Developer API keys required.

    use WWW::Phanfare::API;
    my $papi = WWW::Phanfare::API->new(
      api_key     => 'xxx',
      private_key => 'yyy',
    );

Authentication with account:

    $papi->Authenticate(
       email_address => 'my@email',
       password      => 'zzz',
    )
 
Or authenticate as guest:

    $papi->AuthenticateGuest();

=head1 DESCRIPTION

Low level implementation of the Phanfare API. A developer API key is required
for using this module.

=head1 SUBROUTINES/METHODS

Refer to methods and required parameters are listed on
http://help.phanfare.com/index.php/API . api_key and private_code is only
required for the constructor and not for individual methods.

Methods return an unprocessed xml string from REST GET call.

=head2 new

Create a new API agent.

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

1;
