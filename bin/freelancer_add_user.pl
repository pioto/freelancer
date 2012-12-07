#!/usr/bin/env perl

=head1 NAME

freelancer_add_user.pl - add a new user to the freelancer system

=head1 SYNOPSIS

  freelancer_add_user.pl CONFIG_FILE

  CONFIG_FILE is the full path to a config.yaml file for the instance of
  Freelancer to add the user to.

=cut

use warnings;
use strict;

use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use Term::Prompt qw(prompt);
use YAML qw(LoadFile);

use Freelancer::DBI;
use Freelancer::Address;
use Freelancer::User;

my %O;
GetOptions(\%O)
    or pod2usage(2);

# load DB conf
my $config_file = shift
    or pod2usage("Need a CONFIG_FILE");
my $conf = LoadFile($config_file);
Freelancer::DBI->configure(%{$conf->{db}});

# get params for new user
my (%new_args, %new_addr_args);

$new_args{email} = prompt('x', 'Email:', '', '');
$new_args{first_name} = prompt('x', 'First Name:', '', '');
$new_args{last_name} = prompt('x', 'Last Name:', '', '');
$new_args{biz_name} = prompt('X', 'Business Name:', '', '') || undef;
$new_args{biz_desc} = prompt('X', 'Business Description:', '', '') || undef;
$new_args{phone} = prompt('x', 'Phone Number:', '', '');

$new_addr_args{addr1} = prompt('x', 'Street Address (1/2):', '', '');
$new_addr_args{addr2} = prompt('X', 'Street Address (2/2):', '', '');
$new_addr_args{city} = prompt('x', 'City:', '', '');
$new_addr_args{state} = prompt('x', 'State:', '', '');
$new_addr_args{zip} = prompt('x', 'ZIP:', '', '');
$new_addr_args{country_code} = prompt('x', 'Country Code:', '', 'USA');

$new_args{password} = prompt('p', 'Password:', '', '');

print "\n\n";

my $new_addr = Freelancer::Address->new(
    %new_addr_args,
);
$new_args{address} = $new_addr,

my $new_user = Freelancer::User->new(
    %new_args,
);

printf "Successfully added %s (%s)\n", $new_user->email(), $new_user->id();
