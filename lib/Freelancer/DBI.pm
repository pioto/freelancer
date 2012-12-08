use warnings;
use strict;

package Freelancer::DBI;

=head1 NAME

Freelancer::DBI - DBI interface for the Freelancer system.

=head1 SYNOPSIS

  # when the request begins:
  Freelancer::DBI->config(%{$self->{_config}{db}});

  # get an instance of the singleton:
  my $fdbi = Freelancer::DBI->new();

=head1 DESCRIPTION

This module contains all of the database configuration and access code,
to be used by other objects elsewhere in the Freelancer system. It
should be configured initially with the ->config() method.

=cut

use base 'Ima::DBI';

=head1 QUERIES

The following queries are available:

=cut

=head2 get_user_by_email

Given an email address, returns all information about the corresponding
user.

=cut

__PACKAGE__->set_sql('get_user_by_email', <<"END", 'freelancer');
SELECT * FROM Users WHERE email = ?
END

=head2 insert_user

Given all information for a user, insert them into the database. Takes
these parameters, in order:

=over

=item email

=item first_name

=item last_name

=item biz_name

=item biz_desc

=item phone

=item addr_id

=item password

=back

=cut

__PACKAGE__->set_sql('insert_user', <<"END", 'freelancer');
INSERT INTO Users
  (email, first_name, last_name, biz_name, biz_desc, phone, addr_id, password)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
END

=head2 get_pw_crypt

Given a user_id, returns the password crypt.

=cut

__PACKAGE__->set_sql('get_pw_crypt', <<"END", 'freelancer');
SELECT password FROM Users WHERE user_id = ?
END

=head2 set_pw_crypt

Given a new password crypt and a user_id, set the new password crypt for
that user_id.

=cut

__PACKAGE__->set_sql('set_pw_crypt', <<"END", 'freelancer');
UPDATE Users SET password = ? WHERE user_id = ?
END

=head2 insert_address

Given all information for a address, insert it into the database. Takes
these parameters, in order:

=over

=item addr1

=item addr2

=item city

=item state

=item zip

=item country_code

=back

=cut

__PACKAGE__->set_sql('insert_address', <<"END", 'freelancer');
INSERT INTO Addresses
  (addr1, addr2, city, state, zip, country_code)
VALUES (?, ?, ?, ?, ?, ?)
END

=head2 get_address

Given an addr_id, returns all information about the corresponding
address.

=cut

__PACKAGE__->set_sql('get_address', <<"END", 'freelancer');
SELECT * FROM Addresses WHERE addr_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('max_cust_id', <<"END", 'freelancer');
SELECT MAX(cust_id) FROM Customers;
END

# TODO: docs
__PACKAGE__->set_sql('insert_customer', <<"END", 'freelancer');
INSERT INTO Customers
  (cust_id, user_id, first_name, last_name, cust_since, email, phone, company, addr_id)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
END

# TODO: docs
__PACKAGE__->set_sql('list_customers', <<"END", 'freelancer');
SELECT * FROM Customers WHERE user_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('load_customer', <<"END", 'freelancer');
SELECT * FROM Customers WHERE user_id = ? AND cust_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('insert_service', <<"END", 'freelancer');
INSERT INTO Services
  (user_id, serv_name, serv_desc, unit, price_perunit)
VALUES (?, ?, ?, ?, ?)
END

# TODO: docs
__PACKAGE__->set_sql('list_services', <<"END", 'freelancer');
SELECT * FROM Services WHERE user_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('load_service', <<"END", 'freelancer');
SELECT * FROM Services WHERE serv_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('insert_given_service', <<"END", 'freelancer');
INSERT INTO Given_Services
  (serv_id, cust_id, date, amount, invoice_id)
VALUES (?, ?, ?, ?, ?, ?)
END

# TODO: docs
__PACKAGE__->set_sql('list_given_services', <<"END", 'freelancer');
SELECT * FROM Given_Services WHERE cust_id = ?
END

# TODO: docs
__PACKAGE__->set_sql('load_given_service', <<"END", 'freelancer');
SELECT * FROM Given_Services WHERE serv_id = ? AND cust_id = ? AND date = ?
END

#### ^^^^ INSERT MORE QUERIES HERE ^^^^ ####

#### INTERNAL GOO ####

=head1 CLASS METHODS

In addition to all of the class methods provided by Ima::DBI, the
following class methods are available:

=cut

use Carp;

my %DB_TYPES = (
    sqlite => 'SQLite',
    mysql => 'mysql',
);

=head2 new

Return a new instance of a Freelancer::DBI object.

Must have called L<configure>() first.

=cut

sub new {
    my $class = shift;

    return bless {}, $class;
}

=head2 configure

Given a "flat" hash of configuration parameters, set up the initial
database connection settings. Takes the following keys:

=over

=item type

The type of the database. Either C<mysql>, or C<sqlite>.

=item name

The name of the database. For SQLite, this is the full path to the
database file.

=item username

The username to connect with. For SQLite, this may be omitted.

=item password

The password to connect with. For SQLite, this may be omitted.

=item host

The host to connect to, for MySQL.

=item port

The port to connect to, for MySQL.

=back

=cut

sub configure {
    my $class = shift;
    my %args = @_;

    $class->set_db('freelancer', $class->_dsn(%args), $args{username},
        $args{password}, {
            Callbacks => {
                connected => \&_connected,
            },
        });
}

## _connected
#
# Callback called when a connection is made to the database. Sets
# pragmas and the like to enforce SQL rules more strictly in SQLite and
# MySQL.
sub _connected {
    my $dbh = shift;

    my $driver = lc($dbh->{Driver}{Name});
    if ($driver eq 'sqlite') {
        # enforce foreign keys
        $dbh->do('PRAGMA foreign_keys = ON');
    } elsif ($driver eq 'mysql') {
        # strictly enforce SQL stuff
        $dbh->do('SET SESSION sql_mode = STRICT_ALL_TABLES');
    }

    return;
}

## _dsn
#
# Given type, etc parameters for configure(), figure out the correct DBI
# C<dsn> string.
sub _dsn {
    my $class = shift;
    my %args = @_;

    my $dsn;
    if ($args{type} eq 'mysql') {
        $dsn = "DBI:mysql:database=$args{name}";
        $dsn .= ";host=$args{host}" if $args{host};
        $dsn .= ";port=$args{port}" if $args{port};
    } elsif ($args{type} eq 'sqlite') {
        $dsn = "DBI:SQLite:dbname=$args{name}";
    } else {
        croak "Unknown db type: $args{type}";
    }
    return $dsn;
}

=head1 SEE ALSO

=over

=item L<Ima::DBI>

=item L<DBI>

=back

=cut

1;
