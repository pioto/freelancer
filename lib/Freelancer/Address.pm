use warnings;
use strict;

package Freelancer::Address;

=head1 NAME

Freelancer::Address - A address of the "Freelancer" system.

=head1 SYNOPSIS

  use Freelancer::Address;

  # create a new address:
  my $addr = Freelancer::Address->new(
      addr1 => '123 Main St.',
      # addr2 is optional
      city => 'Pittsburgh',
      state => 'PA',
      zip => '15203',
      country_code => 'USA',
  );

  # load a specific address:
  my $addr = Freelancer::Address->load(id => $addr_id);

  # access properties of the address:
  printf "%s\n%s %s, %s\n", $addr->addr1, $addr->city, $addr->state,
      $addr->zip;

=head1 DESCRIPTION

A Freelancer::Address is an object representing a address of the Freelancer
system. This module allows creating new addresss, and authenticating as
existing ones.

=head1 ERRORS

Errors thrown will all be subclasses of Freelancer::Address::Error.

=cut

use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Exception::Class (
    'Freelancer::Address::Error' => {},

    'Freelancer::Address::Error::Exists' => {
        isa => 'Freelancer::Address::Error',
    },

    'Freelancer::Address::Error::NotFound' => {
        isa => 'Freelancer::Address::Error',
        fields => [qw(id)],
    },
);

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(addr_id addr1 addr2 city state zip country_code);

=head1 CLASS METHODS

These class methods are provided:

=cut

=head2 new

Create a new Freelancer::Address. The parameters will be checked for
consistency and validity, and then stored in the database. The following
parameters are required:

=over

=item addr1

=item addr2

=item city

=item state

=item zip

=item country_code

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    my $fdbi = Freelancer::DBI->new();
    try {
        my $sth = $fdbi->sql_insert_address();
        $sth->execute(@{$self}{qw(addr1 addr2 city state zip country_code)});

        $self->{addr_id} = $fdbi->db_freelancer()->last_insert_id(undef, undef, undef, undef);

        $fdbi->commit();
    } catch (Freelancer::Address::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return $self;
}

=head2 load

Load an existing address. Takes the following parameters:

=over

=item id

=back

=cut

sub load {
    my $class = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new();
    # fetch the address from the database:
    my $addr_info;
    try {
        my $sth = $fdbi->sql_get_address();
        $sth->execute($args{id});
        $addr_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($addr_info) {
            Freelancer::Address::Error::NotFound->throw(
                error => 'Address not found',
                id => $args{id},
            );
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::Address::Error->throw("Duplicates for $args{id}?");
        }
    } catch (Freelancer::Address::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    my %o;
    $o{$_} = $addr_info->{$_} foreach (@OBJ_ATTRS);
    my $self = bless \%o, $class;
    return $self;
}

=head1 OBJECT METHODS

These object methods are provided:

=cut

# NOTE: these currently assume this object is "non-lazy", meaning that
# the 'new' and 'authenticate' methods will fully populate the object.

=head2 id

Return the address's unique ID (addr_id).

=cut

sub id { $_[0]{addr_id} }

sub addr1 { $_[0]{addr1} }

sub addr2 { $_[0]{addr2} }

sub city { $_[0]{city} }

sub state { $_[0]{state} }

sub zip { $_[0]{zip} }

sub country_code { $_[0]{country_code} }

1;
