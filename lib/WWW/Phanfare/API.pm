package WWW::Phanfare::API;

use Moose;
use MooseX::Method::Signatures;
use REST::Client;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use XML::Simple;
use Config::General;

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

has xml => (
  is => 'ro',
  isa => 'XML::Simple',
  lazy_build => 1,
);
sub _build_xml { new XML::Simple }

has rest => (
  is => 'ro',
  isa => 'REST::Client',
  lazy_build => 1,
);
sub _build_rest {
  # Create a REST client with cookies
  my $ua = new REST::Client;
  $ua->getUseragent()->cookie_jar({});
  return $ua;
}
  
has email => ( is => 'ro', isa => 'Str' );
has password => ( is => 'ro', isa => 'Str' );
has api_key => ( is => 'ro', isa => 'Str' );
has private_key => ( is => 'ro', isa => 'Str' );
has site => ( is => 'ro', isa => 'Str', default => 'http://www.phanfare.com/api/?' );
has uid => ( is => 'ro', isa => 'Str' );
has requeststring => ( is => 'ro', isa => 'Str' );

=head1 SUBROUTINES/METHODS

=head2 sign

Sign a request with private key

=cut

method sign {
  my $req = $self->requeststring;
  my $sig = md5_hex( $req . $self->private_key );
  $self->append( 'sig' => $sig );
}

=head2 append

Append key-value pairs to request string

=cut

method append( Str $key, Str $value ) {
  my $str;
  my $req = $self->requeststring;
  $str = '&' if $req;
  $str = $req . $str . sprintf "%s=%s", $key, $value;  
  $self->requeststring( $str );
}

=head2 request

Place a request to REST API

=cut

method request {
  $self->api->GET( $self->site . $self->requeststring);
  my $data = $self->xml->XMLin( $self->api->responseContent() );
  return $data;
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
