use warnings;
use strict;

package Freelancer::WebApp;

use Exception::SEH;
use File::ShareDir qw(dist_dir);
use File::Spec;
use FindBin;
use YAML qw(LoadFile);

use base 'CGI::Application';
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::TT;

use Freelancer::User;

my $BASE_DIR = dist_dir('Freelancer');

sub setup {
    my $self = shift;

    $self->tt_include_path(File::Spec->catfile($BASE_DIR, 'templates'));

    $self->_load_config();

    $self->mode_param(
        path_info => 1,
    );
    $self->start_mode('home');
    $self->run_modes(
        home => 'do_home',
        login => 'do_login',
        logout => 'do_logout',

        'user' => 'do_user',
        'change_password' => 'do_change_password',
    );
}

sub _load_config {
    my $self = shift;

    my $config_file = File::Spec->catfile($FindBin::Bin, 'config.yaml');

    $self->{_config} = LoadFile($config_file);

    Freelancer::DBI->configure(%{$self->{_config}{db}});
}

sub do_home {
    my $self = shift;
    my $q = $self->query;

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

sub do_logout {
    my $self = shift;
    my $q = $self->query;

    $self->session->delete();
    $self->session->flush();

    $self->redirect($q->url);
}

sub do_user {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    unless ($self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    $self->tt_process('user');
}

sub do_change_password {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    unless ($self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    if ($q->param('change_password')) {
        try {
            my $user = $self->session->param('user');
            $user->change_password(
                old_password => $q->param('old_password'),
                new_password => $q->param('new_password'),
                new_password2 => $q->param('new_password2'),
            );
            return $self->redirect($q->url.'/user');
        } catch ($e) {
            $error = $e;
        }
    }

    $self->tt_process('change_password', {error => $error});
}
