#!/usr/home/mikekelly/perl5/perlbrew/perls/perl-5.16.0/bin/perl

use warnings;
use strict;

use lib '/usr/home/mikekelly/git/infsci-2710-invoices/lib';

use Freelancer::WebApp;

my $webapp = Freelancer::WebApp->new();
$webapp->run();
