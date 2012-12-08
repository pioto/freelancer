use warnings;
use strict;

package Freelancer::Invoice;

# TODO: POD

use Exception::SEH;

our $VERSION = '0.1';

use Freelancer::DBI;

use Exception::Class (
    'Freelancer::Invoice::Error' => {},

    'Freelancer::Invoice::Error::NotFound' => {
        isa => 'Freelancer::Invoice::Error',
        fields => [qw(id)],
    },
);

# all the attributes we should keep in a new object
my @OBJ_ATTRS = qw(invoice_id user_id cust_id issue_date due_date status);

# TODO: POD
sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    my $fdbi = Freelancer::DBI->new();
    try {
        # add them to the db
        my $insert_sth = $fdbi->sql_insert_invoice();
        $insert_sth->execute(
            $args{user}->id, $args{customer}->id, @{$self}{qw(issue_date due_date status)}
        );

        $self->{invoice_id} = $fdbi->db_freelancer()->last_insert_id(undef,
            undef, undef, undef);

        $fdbi->commit();
    } catch (Freelancer::Invoice::Error $e) {
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
        if ($args{user}) {
            $sth = $fdbi->sql_list_user_invoices();
            $sth->execute($args{user}->id);
        } elsif ($args{customer}) {
            $sth = $fdbi->sql_list_cust_invoices();
            $sth->execute($args{customer}->id);
        } else {
            Freelancer::Invoice::Error->throw("Need to give either a user or customer to list for");
        }

        while (my $serv_info = $sth->fetchrow_hashref('NAME_lc')) {
            my $obj = $class->_load($serv_info);
            push @r, $obj;
        }
    } catch (Freelancer::Invoice::Error $e) {
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
        my $sth = $fdbi->sql_load_invoice();
        $sth->execute($args{id});

        $serv_info = $sth->fetchrow_hashref('NAME_lc');
        unless ($serv_info) {
            Freelancer::Invoice::Error::NotFound->throw(
                error => 'Invoice not found',
                id => $args{id},
            );
        }
        if ($sth->fetch()) {
            # something else matched??
            Freelancer::Invoice::Error->throw("Duplicates for "
                .$args{service}->id." ".$args{customer}->id." $args{date}?");
        }
    } catch (Freelancer::Invoice::Error $e) {
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
sub id { $_[0]{invoice_id} }

# TODO: POD
foreach my $attr (@OBJ_ATTRS) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

sub amount_due {
    my $self = shift;
    my $fdbi = Freelancer::DBI->new();

    my $amt;
    try {
        my $sth = $fdbi->sql_invoice_amount_due();
        $sth->execute($self->id);

        ($amt) = $sth->fetch;
    } catch ($e) {
        die $e;
    }

    return $amt;
}

sub set_status {
    my $self = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new();
    my $sth = $fdbi->sql_invoice_set_status();
    $sth->execute($args{status}, $self->id);
    $fdbi->commit();
}

1;
