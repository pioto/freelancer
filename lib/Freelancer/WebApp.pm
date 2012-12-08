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

use Freelancer::Address;
use Freelancer::Customer;
use Freelancer::GivenService;
use Freelancer::Invoice;
use Freelancer::Payment;
use Freelancer::Service;
use Freelancer::User;

use Freelancer::Reports;

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

        'create_invoice' => 'do_create_invoice',
        'invoices' => 'do_invoices',
        'invoice' => 'do_invoice',
        'print_invoice' => 'do_print_invoice',

        'add_charges' => 'do_add_charges',
        'add_payment' => 'do_add_payment',

        'best_selling_services' => 'do_best_selling_services',
        'sales_by_zip' => 'do_sales_by_zip',

        set_client_personal_info => 'do_set_client_personal_info',
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
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    $self->tt_process('user', {
            user => $user,
        });
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
            my %addr_args;
            $addr_args{$_} = $q->param($_) foreach (qw(addr1 addr2 city
                state zip country_code));
            my $addr = Freelancer::Address->new(
                %addr_args,
            );

            my %cust_args;
            $cust_args{$_} = $q->param($_) foreach (qw(first_name last_name
                cust_since email phone company));
            my $customer = Freelancer::Customer->new(
                user => $user,
                address => $addr,
                %cust_args,
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
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer, $services);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );

        $services = Freelancer::Service->list(
            user => $user,
        );

        if ($q->param('given_service')) {
            my $service = Freelancer::Service->load(
                id => $q->param('serv_id'),
            );
            my $serv_given = Freelancer::GivenService->new(
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
            services => $services,
        });
}

sub do_create_invoice {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
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

        if ($q->param('create_invoice')) {
            my $invoice = Freelancer::Invoice->new(
                user => $user,
                customer => $customer,
                issue_date => $q->param('issue_date'),
                due_date => $q->param('due_date'),
                #status => $q->param('status'),
                status => 'new',
            );

            return $self->redirect($q->url.'/invoice?cust_id='.$customer->id
                .'&invoice_id='.$invoice->id);
        }
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('create_invoice', {
            error => $error,
            customer => $customer,
        });
}

sub do_invoices {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    my ($customer, $invoices);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
        $invoices = Freelancer::Invoice->list(
            user => $user,
            customer => $customer,
        );
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('invoices', {
            error => $error,
            customer => $customer,
            invoices => $invoices,
        });
}

sub do_invoice {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer, $invoice, $given_services);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
        $invoice = Freelancer::Invoice->load(
            user => $user,
            customer => $customer,
            id => $q->param('invoice_id'),
        );
        $given_services = Freelancer::GivenService->list(
            customer => $customer,
            invoice => $invoice,
        );
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('invoice', {
            error => $error,
            customer => $customer,
            invoice => $invoice,
            given_services => $given_services,
        });
}

sub do_add_charges {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer, $invoice, $given_services);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
        $invoice = Freelancer::Invoice->load(
            user => $user,
            customer => $customer,
            id => $q->param('invoice_id'),
        );
        $given_services = Freelancer::GivenService->list(
            customer => $customer,
            invoice => undef,
        );

        if ($q->param('add_charges')) {
            foreach my $serv_date ($q->param('serv_date')) {
                my ($serv_id, $date) = split /\|/, $serv_date, 2;
                my $service = Freelancer::Service->load(id => $serv_id);
                my $given_service = Freelancer::GivenService->load(
                    service => $service,
                    customer => $customer,
                    date => $date,
                );
                $given_service->add_to_invoice(invoice => $invoice);
            }

            return $self->redirect($q->url.'/invoice?cust_id='.$customer->id
                .'&invoice_id='.$invoice->id);
        }
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('add_charges', {
            error => $error,
            customer => $customer,
            invoice => $invoice,
            given_services => $given_services,
        });
}

sub do_add_payment {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer, $invoice);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
        $invoice = Freelancer::Invoice->load(
            user => $user,
            customer => $customer,
            id => $q->param('invoice_id'),
        );

        if ($q->param('add_payment')) {
            my $payment = Freelancer::Payment->new(
                user => $user,
                customer => $customer,
                invoice => $invoice,
                pay_date => $q->param('pay_date'),
                amount => $q->param('amount'),
                method => $q->param('method'),
            );

            return $self->redirect($q->url.'/invoice?cust_id='.$customer->id
                .'&invoice_id='.$invoice->id);
        }
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('add_payment', {
            error => $error,
            customer => $customer,
            invoice => $invoice,
        });
}

sub do_print_invoice {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer, $invoice, $given_services);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );
        $invoice = Freelancer::Invoice->load(
            user => $user,
            customer => $customer,
            id => $q->param('invoice_id'),
        );
        $given_services = Freelancer::GivenService->list(
            customer => $customer,
            invoice => $invoice,
        );
        $invoice->set_status(status => 'sent');
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('print_invoice', {
            error => $error,
            user => $user,
            customer => $customer,
            invoice => $invoice,
            given_services => $given_services,
        });
}

sub do_best_selling_services {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    my $best_selling_services;
    try {
        $best_selling_services = Freelancer::Reports->best_selling_services(user => $user);
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('best_selling_services', {
            error => $error,
            best_selling_services => $best_selling_services,
        });
}

sub do_sales_by_zip {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    my $error;
    my $sales_by_zip;
    try {
        $sales_by_zip = Freelancer::Reports->sales_by_zip(user => $user);
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('sales_by_zip', {
            error => $error,
            sales_by_zip => $sales_by_zip,
        });
}

sub do_set_client_personal_info {
    my $self = shift;
    my $q = $self->query;

    # Login Required
    my $user;
    unless ($user = $self->session->param('user')) {
        return $self->redirect($q->url.'/login');
    }

    # need to be given a customer to do this for, too
    my $error;
    my ($customer);
    try {
        $customer = Freelancer::Customer->load(
            user => $user,
            id => $q->param('cust_id'),
        );

        if ($q->param('set_client_personal_info')) {
            $customer->set_client_personal_info(
                family => $q->param('family'),
                children => $q->param('children'),
                birthday => $q->param('birthday'),
                notes => $q->param('notes'),
            );

            return $self->redirect($q->url.'/customer?cust_id='.$customer->id)
        }
    } catch ($e) {
        $error = $e;
    }

    $self->tt_process('set_client_personal_info', {
            error => $error,
            customer => $customer,
        });
}
