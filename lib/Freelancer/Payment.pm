use warnings;
use strict;

package Freelancer::Payment;

# TODO: POD

use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Exception::Class (
    'Freelancer::Payment::Error' => {},

    'Freelancer::Payment::Error::NotFound' => {
        isa => 'Freelancer::Payment::Error',
        fields => [qw(id)],
    },
);

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(payment_num invoice_id pay_date amount method);

# TODO: POD
sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    my $fdbi = Freelancer::DBI->new();
    try {
        # add them to the db
        my $insert_sth = $fdbi->sql_insert_payment();
        $insert_sth->execute(
            $args{invoice}->id, @{$self}{qw(pay_date amount method)}
        );

        $self->{payment_num} = $fdbi->db_freelancer()->last_insert_id(undef,
            undef, undef, undef);

        $fdbi->commit();
    } catch (Freelancer::Payment::Error $e) {
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
        my $sth;
        $sth = $fdbi->sql_list_payments();
        $sth->execute($args{invoice}->id);

        while (my $serv_info = $sth->fetchrow_hashref('NAME_lc')) {
            my $obj = $class->_load($serv_info);
            push @r, $obj;
        }
    } catch (Freelancer::Payment::Error $e) {
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
        my $sth = $fdbi->sql_load_payment();
        $sth->execute($args{id});

        $serv_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($serv_info) {
            Freelancer::Payment::Error::NotFound->throw(
                error => 'Payment not found',
                id => $args{id},
            );
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::Payment::Error->throw("Duplicates for "
                .$args{service}->id." ".$args{customer}->id." $args{date}?");
        }
    } catch (Freelancer::Payment::Error $e) {
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
sub id { $_[0]{payment_num} }

# TODO: POD
foreach my $attr (@OBJ_ATTRS) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

1;
