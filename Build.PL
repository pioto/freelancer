use warnings;
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Freelancer',
    requires => {
        'CGI::Application' => 0,
        'CGI::Application::Plugin::Redirect' => 0,
        'CGI::Application::Plugin::Session' => 0,
        'CGI::Application::Plugin::TT' => 0,
        'Exception::Class' => 0,
        'Exception::SEH' => 0,
        'File::ShareDir' => 0,
        'File::Spec' => 0,
    },
    share_dir => 'share',
);

$build->create_build_script;
