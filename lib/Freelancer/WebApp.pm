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

        'customers' => 'do_customers',
        'customer' => 'do_customer',
        'add_customer' => 'do_add_customer',

        'services' => 'do_services',
        'add_service' => 'do_add_service',

        'given_service' => 'do_given_service',
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
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    if ($q->param('change_password')) {
        try {
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

sub do_customers {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $customers;
    my $error;
    try {
        $customers = Freelancer::Customer->list(user => $user);
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('customers', {
            error => $error,
            customers => $customers,
        });
}

sub do_customer {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $customer;
    my $error;
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('customer', {
            error => $error,
            customer => $customer,
        });
}

sub do_add_customer {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    if ($q->param('add_customer')) {
        try {
            my %args;
            $args{$_} = $q->param($_) foreach (qw(first_name last_name
                cust_since email phone street_address state zip company));
            my $customer = Freelancer::Customer->new(
                user => $user,
                %args,
            );

            return $self->redirect($q->url.'/customer?cust_id='.$customer->id);
        } catch ($e) {
            $error = $e;
        }
    }

    $self->tt_process('add_customer', {error => $error});
}

sub do_services {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $services;
    my $error;
    try {
        $services = Freelancer::Service->list(user => $user);
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('services', {
            error => $error,
            services => $services,
        });
}

sub do_add_service {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    if ($q->param('add_service')) {
        try {
            my %args;
            $args{$_} = $q->param($_) foreach (qw(serv_name serv_desc
                unit price_perunit));
            Freelancer::Service->new(
                user => $user,
                %args,
            );

            return $self->redirect($q->url.'/services');
        } catch ($e) {
            $error = $e;
        }
    }

    $self->tt_process('add_service', {error => $error});
}

sub do_given_service {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    if ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my $customer;
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );

        if ($q->param('given_service')) {
            my $service = Freelancer::Service->load(
                id => $q->param('serv_id'),
            );
            my $serv_given = Freelancer::ServiceGiven->new(
                customer => $customer,
                service => $service,
                date => $q->param('date'),
                amount => $q->param('amount'),
            );

            return $self->redirect($q->url.'/customer?cust_id='.$customer->id);
        }
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('given_service', {
            error => $error,
            customer => $customer,
        });
}
