use warnings;
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Freelancer',
    requires => {
        'Authen::Passphrase' => 0,
        'Authen::Passphrase::BlowfishCrypt' => 0,
        'CGI::Application' => 0,
        'CGI::Application::Plugin::Redirect' => 0,
        'CGI::Application::Plugin::Session' => 0,
        'CGI::Application::Plugin::TT' => 0,
        'DBI' => 0,
        'Exception::Class' => 0,
        'Exception::SEH' => 0,
        'File::ShareDir' => 0,
        'File::Spec' => 0,
        'FindBin' => 0,
        'Getopt::Long' => '2.33',
        'Pod::Usage' => 0,
        'Term::Prompt' => 0,
        'YAML' => 0,
    },
    recommends => {
        'DBD::SQLite' => 0,
        #'DBD::mysql' => 0,
    },
    share_dir => 'share',
);

$build->create_build_script;
