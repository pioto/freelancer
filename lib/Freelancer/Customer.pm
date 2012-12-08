use warnings;
use strict;

package Freelancer::Customer;

=head1 NAME

Freelancer::Customer - A customer for the "Freelancer" system.

=head1 SYNOPSIS

  use Freelancer::Customer;

  my $customer = Freelancer::User->new(
    user => $user,
    first_name => 'Bob',
    last_name => 'Smith',
    cust_since => '2012-12-01',
    email => 'bob@smith.com',
    phone => '412-555-1234',
    address => $address, # Freelancer::Address object
    company => 'Bob Smith Ford',
  );

  # list all customers for a Freelancer::User:
  my $customers = Freelancer::Customer->list(user => $user);

  # retrieve a specific Freelancer::User:
  my $customer = Freelancer::Customer->load(user => $user, id => $customer_id);

  # access properties of the customer:
  printf "Hello, %s %s, of %s!\n", $customer->first_name(),
    $customer->last_name(), $customer->company();

=head1 DESCRIPTION

A Freelancer::Customer is an object representing a customer of the
Freelancer system. This module allows creating new customers, and
retrieving either a list of all customers for a Freelancer::User, or a
specific customer.

=head1 ERRORS

Errors thrown will all be subclasses of Freelancer::Customer::Error.

=cut

use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Freelancer::Address;

use Exception::Class (
    'Freelancer::Customer::Error' => {},

    'Freelancer::Customer::Error::NotFound' => {
        isa => 'Freelancer::Customer::Error',
        fields => [qw(id)],
    },
);

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(cust_id user_id first_name last_name cust_since email phone company addr_id);

=head1 CLASS METHODS

These class methods are provided:

=cut

=head2 new

Create a new Freelancer::Customer. The parameters will be checked for
consistency and validity, and then stored in the database. The following
parameters are required:

=over

=item user

=item first_name

=item last_name

=item cust_since

=item email

=item phone

=item address

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    my $fdbi = Freelancer::DBI->new();
    try {
        # add them to the db
        my $insert_sth = $fdbi->sql_insert_customer();
        $insert_sth->execute(
            $args{user}->id, @{$self}{qw(first_name last_name
            cust_since email phone company)}, $args{address}->id,
        );

        $self->{cust_id} = $fdbi->db_freelancer()->last_insert_id(undef,
            undef, undef, undef);

        $fdbi->commit();
    } catch (Freelancer::Customer::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return $self;
}

# TODO: POD
sub list {
    my $class = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new();
    my @r;
    try {
        my $sth = $fdbi->sql_list_customers();
        $sth->execute($args{user}->id);

        while (my $cust_info = $sth->fetchrow_hashref('NAME_lc')) {
            my $obj = $class->_load($cust_info);
            push @r, $obj;
        }
    } catch (Freelancer::Customer::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return \@r;
}

# TODO: POD
sub load {
    my $class = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new();
    my $cust_info;
    try {
        my $sth = $fdbi->sql_load_customer();
        $sth->execute($args{user}->id, $args{id});

        $cust_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($cust_info) {
            Freelancer::Customer::Error::NotFound->throw(
                error => 'Customer not found',
                id => $args{id},
            );
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::Customer::Error->throw("Duplicates for $args{id}?");
        }
    } catch (Freelancer::Customer::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return $class->_load($cust_info);
}

sub _load {
    my $class = shift;
    my ($cust_info) = @_;

    my %o;
    $o{$_} = $cust_info->{$_} foreach (@OBJ_ATTRS);
    my $self = bless \%o, $class;
    return $self;
}

# TODO: POD
sub id { $_[0]{cust_id} }

# TODO: POD
sub first_name { $_[0]{first_name} }

# TODO: POD
sub last_name { $_[0]{last_name} }

# TODO: POD
sub cust_since { $_[0]{cust_since} }

# TODO: POD
sub email { $_[0]{email} }

# TODO: POD
sub phone { $_[0]{phone} }

# TODO: POD
sub company { $_[0]{company} }

# TODO: POD
sub address { $_[0]{address} ||= Freelancer::Address->load(id => $_[0]{addr_id}) }

sub client_personal_info {
    my $self = shift;

    my $fdbi = Freelancer::DBI->new;
    my $sth = $fdbi->sql_client_personal_info;
    $sth->execute($self->id);

    my $r = $sth->fetchrow_hashref('NAME_lc');
    # should only get 1, because we're looking up by primary key
    $sth->finish;

    return $r;
}

sub set_client_personal_info {
    my $self = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new;
    my $sth = $fdbi->sql_set_client_personal_info;
    $sth->execute($self->id, $self->{user_id}, @{$args}{qw(family
        children birthday notes)});

    $fdbi->commit();
}

1;
