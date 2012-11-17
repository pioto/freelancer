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