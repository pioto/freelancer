use warnings;
use strict;

package Freelancer::Service;

# TODO: POD

use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Exception::Class (
    'Freelancer::Service::Error' => {},

    'Freelancer::Service::Error::NotFound' => {
        isa => 'Freelancer::Service::Error',
        fields => [qw(id)],
    },
);

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(serv_id serv_name serv_desc user_id unit
price_perunit);

# TODO: POD
sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    my $fdbi = Freelancer::DBI->new();
    try {
        # add them to the db
        my $insert_sth = $fdbi->sql_insert_service();
        $insert_sth->execute(
            $args{user}->id, @{$self}{qw(serv_name serv_desc unit price_perunit)}
        );

        $self->{serv_id} = $fdbi->db_freelancer()->last_insert_id(undef,
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
        my $sth = $fdbi->sql_list_services();
        $sth->execute($args{user}->id);

        while (my $serv_info = $sth->fetchrow_hashref('NAME_lc')) {
            my $obj = $class->_load($serv_info);
            push @r, $obj;
        }
    } catch (Freelancer::Service::Error $e) {
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
    my $serv_info;
    try {
        my $sth = $fdbi->sql_load_service();
        $sth->execute($args{id});

        $serv_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($serv_info) {
            Freelancer::Service::Error::NotFound->throw(
                error => 'Service not found',
                id => $args{id},
            );
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::Service::Error->throw("Duplicates for $args{id}?");
        }
    } catch (Freelancer::Service::Error $e) {
        die $e;
    } catch ($e) {
        die $e;
    }

    return $class->_load($serv_info);
}

sub _load {
    my $class = shift;
    my ($serv_info) = @_;

    my %o;
    $o{$_} = $serv_info->{$_} foreach (@OBJ_ATTRS);
    my $self = bless \%o, $class;
    return $self;
}

# TODO: POD
sub id { $_[0]{serv_id} }

foreach my $attr (@OBJ_ATTRS) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

1;
