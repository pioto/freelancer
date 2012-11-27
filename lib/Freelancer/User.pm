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
      biz_name => "Bob's Bots",
      biz_desc => "Bob's Bots is the best buyer of robots in"
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

use Authen::Passphrase;
use Authen::Passphrase::BlowfishCrypt;
use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Exception::Class (
    'Freelancer::User::Error' => {},

    'Freelancer::User::Error::Exists' => {
        isa => 'Freelancer::User::Error',
    },

    'Freelancer::User::Error::InvalidUserOrPassword' => {
        isa => 'Freelancer::User::Error',
    },
);

# 'cost' setting to use for bcrypt
use constant BLOWFISH_COST => 8;

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(user_id email first_name last_name biz_name
biz_desc phone address);

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

=item biz_name

The name of the user's business.

=item biz_desc

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

    my $self = bless \%args, $class;
    $self->{password} = $self->_hash_password($self->{password});

    my $fdbi = Freelancer::DBI->new();
    try {
        my $sth = $fdbi->sql_insert_user();
        $sth->execute(@{$self}{qw(email first_name last_name biz_name
            biz_desc phone address password)});

        $self->{user_id} = $fdbi->db_freelancer()->last_insert_id(undef, undef, undef, undef);

        $fdbi->commit();
    } catch (Freelancer::User::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return $self;
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

    my $fdbi = Freelancer::DBI->new();
    # fetch the user from the database:
    my $user_info;
    try {
        my $sth = $fdbi->sql_get_user_by_email();
        $sth->execute($args{email});
        $user_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($user_info) {
            Freelancer::User::Error::InvalidUserOrPassword->throw("Username not found");
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::User::Error->throw("Duplicates for $args{email}?");
        }

        $class->_check_password($args{password}, $user_info->{password})
            or Freelancer::User::Error::InvalidUserOrPassword->throw("Invalid password");
    } catch (Freelancer::User::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    my %o;
    $o{$_} = $user_info->{$_} foreach (@OBJ_ATTRS);
    my $self = bless \%o, $class;
    return $self;
}

=head1 OBJECT METHODS

These object methods are provided:

=cut

# NOTE: these currently assume this object is "non-lazy", meaning that
# the 'new' and 'authenticate' methods will fully populate the object.

=head2 id

Return the user's unique ID (user_id).

=cut

sub id { $_[0]{user_id} }

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

=head2 biz_name

Return the user's business' name.

=cut

sub biz_name { $_[0]{biz_name} }

=head2 biz_desc

Return a description of the user's business.

=cut

sub biz_desc { $_[0]{biz_desc} }

=head2 phone

Return the user's business' phone number.

=cut

sub phone { $_[0]{phone} }

=head2 address

Return the user's business' mailing address.

=cut

sub address { $_[0]{address} }

## _check_password
#
# Checks that the given password matches the given password crypt.
sub _check_password {
    my $class_or_object = shift;
    my ($password, $crypt) = @_;

    my $ppr = Authen::Passphrase->from_rfc2307($crypt);
    return $ppr->match($password);
}

## _hash_password
#
# Given a passphrase, return its crypted hash.
sub _hash_password {
    my $class_or_object = shift;
    my ($password) = @_;

    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
        cost => BLOWFISH_COST, salt_random => 1,
        passphrase => $password);
    return $ppr->as_rfc2307;
}

1;
