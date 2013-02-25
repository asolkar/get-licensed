#!/bin/env perl

use strict;
use warnings;
use File::Find;
use FileHandle;
use Data::Dumper;
use Getopt::Long;
use Cwd;

# Application configuration and state storage
my $app = {};

# Defaults
$app->{'options'}->{'directory'} = getcwd;
$app->{'options'}->{'license'} = 'mit';

# Command line options
my $correct_usage = GetOptions (
  'directory=s' => \$app->{'options'}->{'directory'},
  'license=s' => \$app->{'options'}->{'license'});

setup_license_pretty_names($app);
setup_filetype_comment_mapping($app);

print "Applying '"
      . $app->{'license_pretty_names'}->{$app->{'options'}->{'license'}}
      . "' license to files in '"
      . $app->{'options'}->{'directory'}
      ."' directory\n";

#
# Subroutines
#
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
