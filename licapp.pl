#!/bin/env perl

use strict;
use warnings;
use File::Find;
use File::Basename;
use FileHandle;
use Data::Dumper;
use Getopt::Long;
use Cwd;

# Application configuration and state storage
my $app = {};

# Defaults
$app->{'options'}->{'directory'} = getcwd;
$app->{'options'}->{'license'} = 'mit';
$app->{'options'}->{'user'} = $ENV{'USER'};
$app->{'options'}->{'date'} = (localtime(time))[5] + 1900;
$app->{'options'}->{'about'} = "This is an open-source software";
$app->{'state'}->{'license_stub'} = "NON EXISTANT";
$app->{'state'}->{'app_dir'} = dirname($0);

# Command line options
my $correct_usage = GetOptions (
    'directory=s' => \$app->{'options'}->{'directory'},
    'license=s' => \$app->{'options'}->{'license'},
    'about=s' => \$app->{'options'}->{'about'},
    'user=s' => \$app->{'options'}->{'user'},
    'date=s' => \$app->{'options'}->{'date'},
  );

setup_license_pretty_names($app);
setup_filetype_comment_mapping($app);
setup_license_stub($app);

print "Applying '"
      . $app->{'license_pretty_names'}->{$app->{'options'}->{'license'}}
      . "' license to files in '"
      . $app->{'options'}->{'directory'}
      . "' directory\n\n";

print "Copyright: Copyright (C) "
      . $app->{'options'}->{'date'}
      . " " . $app->{'options'}->{'user'}
      . "\n\n";

print "About: " . $app->{'options'}->{'about'}
      . "\n\n";

print "Stub:\n-----\n$app->{'state'}->{'license_stub'}\n-----\n";

find (sub {
    find_files($app, ${File::Find::name}, $_)
  }, $app->{'options'}->{'directory'});

#
# Subroutines
#
sub find_files {
  my ($app, $file, $name) = @_;

  #
  # Opportunity to filter any file types befrore any processing starts
  #
  handle_files ($app, $file, $name);
}

sub handle_files {
  my ($app, $file, $name) = @_;

  my $rh = new FileHandle ($name);
  my @contents = <$rh>;

  print "Handling... $file\n";

  if ((defined $contents[0]) && ($contents[0] =~ /^\s*#!/)) {
    print "   ... has #! line\n";
  }
}

sub setup_license_stub {
  my ($app) = @_;
  my $header_file = $app->{'state'}->{'app_dir'}
                    ."/licenses/"
                    . $app->{'options'}->{'license'} . ".header";

  if (-e $header_file) {
    my $rh = new FileHandle ($header_file);
    $app->{'state'}->{'license_stub'} = do {local $/; <$rh>};

    $app->{'state'}->{'license_stub'} =~
      s/###DESCRIPTION###/$app->{'options'}->{'about'}/;
    $app->{'state'}->{'license_stub'} =~
      s/###DATE###/$app->{'options'}->{'date'}/;
    $app->{'state'}->{'license_stub'} =~
      s/###NAME###/$app->{'options'}->{'user'}/;
  }
  else {
    warn "[WARN] License Header '$header_file' does not exist";
  }
}

sub setup_license_pretty_names {
  my ($app) = @_;

  $app->{'license_pretty_names'} = {
    'mit' => 'MIT',
    'gpl_v1' => 'GPL v1',
    'gpl_v2' => 'GPL v2',
    'gpl_v3' => 'GPL v3',
    'apache_v2' => 'Apache v2',
    'apache_v1' => 'Apache v1'
  };
}

sub setup_filetype_comment_mapping {
  my ($app) = @_;

  $app->{'filetype_commants'} = {
    '.pl'       => '#',
    '.rb'       => '#',
    '.erb'      => ['<!--', '-->'],
    '.html'     => ['<!--', '-->'],
    '.v'        => '//',
    '.sv'       => '//',
    '.vr'       => '//'
  };
}
