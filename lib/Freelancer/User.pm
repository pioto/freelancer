use warnings;
use strict;

package Freelancer::User;

=head1 NAME

Freelancer::User - A user of the "Freelancer" system.

=head1 SYNOPSIS

  use Freelancer::User;

  # create a new user:
  my $user = Freelancer::User->new(
      email => 'bob@domain.tld',
      password => '123456',
      first_name => 'Bob',
      last_name => 'Smith',
      business_name => "Bob's Bots",
      business_desc => "Bob's Bots is the best buyer of robots in"
          ." Western Pennsylvania",
      phone => '412-555-1234',
      address => "123 Main St.\nPittsburgh, PA 15203",
  );

  # attempt to authenticate as an existing user (log in)
  my $user = Freelancer::User->authenticate(
      email => 'bob',
      password => '12345',
  );

  # access properties of the user:
  printf "Hello, %s %s!\n", $user->first_name(), $user->last_name();

=head1 DESCRIPTION

A Freelancer::User is an object representing a user of the Freelancer
system. This module allows creating new users, and authenticating as
existing ones.

=head1 ERRORS

Errors thrown will all be subclasses of Freelancer::User::Error.

=cut

our $VERSION = '0.1';

use Exception::Class (
    'Freelancer::User::Error' => {},

    'Freelancer::User::Error::Exists' => {
        isa => 'Freelancer::User::Error',
    },

    'Freelancer::User::Error::InvalidUserOrPassword' => {
        isa => 'Freelancer::User::Error',
    },
);

=head1 CLASS METHODS

These class methods are provided:

=cut

=head2 new

Create a new Freelancer::User. The parameters will be checked for
consistency and validty, and then stored in the database. The following
parameters are required:

=over

=item email

The email address (also, username) for this user.

=item password

The new password for this user.

=item first_name

The user's first name.

=item last_name

The user's last name.

=item business_name

The name of the user's business.

=item business_desc

A description of the user's business.

=item phone

The user's business' phone number.

=item address

The user's business' mailing address.

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;

    Freelancer::User::Error->throw("Unimplemented");
}

=head2 authenticate

Attempt to authenticate as an existing user. Returns a new
Freelancer::User object for that user, if successful. Takes the
following parameters:

=over

=item email

The email address (also, username) for this user.

=item password

The password to try to authenticate this user with.

=back

=cut

sub authenticate {
    my $class = shift;
    my %args = @_;

    #return my $self = bless \%args, $class;

    # TODO
    Freelancer::User::Error->throw("Unimplemented");
}

=head1 OBJECT METHODS

These object methods are provided:

=cut

# NOTE: these currently assume this object is "non-lazy", meaning that
# the 'new' and 'authenticate' methods will fully populate the object.

=head2 email

Return the user's email.

=cut

sub email { $_[0]{email} }

=head2 first_name

Return the user's first name.

=cut

sub first_name { $_[0]{first_name} }

=head2 last_name

Return the user's last name.

=cut

sub last_name { $_[0]{last_name} }

=head2 business_name

Return the user's business' name.

=cut

sub business_name { $_[0]{business_name} }

=head2 business_desc

Return a description of the user's business.

=cut

sub business_desc { $_[0]{business_desc} }

=head2 phone

Return the user's business' phone number.

=cut

sub phone { $_[0]{phone} }

=head2 address

Return the user's business' mailing address.

=cut

sub address { $_[0]{address} }

1;
