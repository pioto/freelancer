use warnings;
use strict;

package Freelancer::WebApp;

use Exception::SEH;
use File::Spec;

use base 'CGI::Application';
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::TT;

use Freelancer::User;

my $BASE_DIR = '/usr/home/mikekelly/git/infsci-2710-invoices';

sub setup {
    my $self = shift;
    $self->tt_include_path(File::Spec->catfile($BASE_DIR, 'templates'));
    $self->mode_param(
        path_info => 1,
    );
    $self->start_mode('home');
    $self->run_modes(
        home => 'do_home',
        login => 'do_login',
    );
}

sub do_home {
    my $self = shift;

    unless ($self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    $self->tt_process('home');
}

sub do_login {
    my $self = shift;
    my $q = $self->query;

    my $username = $q->param('username');
    my $password = $q->param('password');
    my $error;
    if ($username && $password) {
        try {
            my $user = Freelancer::User->authenticate(
                email => $username,
                password => $password,
            );
            $self->session->param(user => $user);
            return $self->redirect($q->url);
        } catch ($e) {
            $error = $e;
        }
    }

    $self->tt_process('login', {error => $error});
}
