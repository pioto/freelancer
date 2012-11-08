use warnings;
use strict;

package Freelancer::WebApp;

use File::Spec;

use base 'CGI::Application';
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::TT;

my $BASE_DIR = '/usr/home/mikekelly/git/infsci-2710-invoices';

sub setup {
    my $self = shift;
    $self->tt_include_path(File::Spec->catfile($BASE_DIR, 'templates'));
    $self->mode_param(
        path_info => 1,
    );
    $self->run_modes(
        login => 'do_login',
    );
}

sub do_login {
    my $self = shift;
    $self->tt_process('login');
}
