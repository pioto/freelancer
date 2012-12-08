use warnings;
use strict;

package Freelancer::Reports;

use Freelancer::DBI;

use Freelancer::Service;

sub best_selling_services {
    my $class = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new();
    my $sth = $fdbi->sql_best_selling_services();
    $sth->execute($args{user}->id);

    my @r;
    while (my ($serv_id, $amt) = $sth->fetch()) {
        push @r, {
            service => Freelancer::Service->load(id => $serv_id),
            amt => $amt
        };
    }

    return \@r;
}

sub sales_by_zip {
    my $class = shift;
    my %args = @_;

    my $fdbi = Freelancer::DBI->new;
    my $sth = $fbi->sales_by_zip;
    $sth->execute($args{user}->id);

    my @r;
    while (my ($zip, $sales) = $sth->fetch()) {
        push @r, {
            zip => $zip,
            sales => $sales,
        };
    }

    return \@r;
}

1;
