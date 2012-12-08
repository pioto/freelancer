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

1;
