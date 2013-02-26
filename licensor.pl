#!/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use File::Find;
use File::Basename;
use FileHandle;
use Data::Dumper;
use Getopt::Long;
use Cwd;
use File::Glob ':globally';
use Licenses;

# Application configuration and state storage
my $app = {};

# Defaults
$app->{'options'}->{'directory'}  = getcwd;
$app->{'options'}->{'license'}    = 'mit';
$app->{'options'}->{'user'}       = $ENV{'USER'};
$app->{'options'}->{'date'}       = (localtime(time))[5] + 1900;
$app->{'options'}->{'about'}      = "This is an open-source software";
$app->{'state'}->{'license_stub'} = "NON EXISTANT";
$app->{'state'}->{'app_dir'}      = dirname($0);

# Command line options
my $correct_usage = GetOptions (
    'directory=s' => \$app->{'options'}->{'directory'},
    'license=s' => \$app->{'options'}->{'license'},
    'about=s' => \$app->{'options'}->{'about'},
    'user=s' => \$app->{'options'}->{'user'},
    'date=s' => \$app->{'options'}->{'date'},
  );

setup_licenses($app);
setup_filetype_comment_mapping($app);

print "Applying '"
      . $app->{'licenses'}->{$app->{'options'}->{'license'}}->{'pretty_name'}
      . "' license to files in '"
      . $app->{'options'}->{'directory'}
      . "' directory\n\n";

print "Copyright: Copyright (C) "
      . $app->{'options'}->{'date'}
      . " " . $app->{'options'}->{'user'}
      . "\n\n";

print "About: " . $app->{'options'}->{'about'}
      . "\n\n";

print "Stub:\n-----\n"
      . $app->{'licenses'}->{$app->{'options'}->{'license'}}->{'header_stub'}
      . "\n-----\n";

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

  return unless -f $name;

  my($filename, $directories, $suffix) = fileparse($file, qr/\.[^.]*/);

  if (exists $app->{'filetype_comments'}->{$suffix}) {
    my $rh = new FileHandle ($name);
    my @contents = <$rh>;

    print "Handling... $filename - $directories - $suffix\n";

    if ((defined $contents[0]) && ($contents[0] =~ /^\s*#!/)) {
      print "   ... has #! line\n";
    }
  }
  else {
    print "[ALERT] Don't know how to comment in file with '$suffix' extension\n";
  }
}

sub setup_licenses {
  my ($app) = @_;

  my $licenses = new Licenses;
  $licenses->get_licenses($app);

  print "[INFO] Imported "
        . join (', ', keys %{$app->{'licenses'}})
        . " licenses\n";
}

sub setup_filetype_comment_mapping {
  my ($app) = @_;

  $app->{'filetype_comments'} = {
    '.pl'       => '#',
    '.rb'       => '#',
    '.erb'      => ['<!--', '-->'],
    '.html'     => ['<!--', '-->'],
    '.css'      => ['/*', '*/'],
    '.coffee'   => '#',
    '.js'       => '//',
    '.scss'     => '//',
    '.v'        => '//',
    '.sv'       => '//',
    '.vr'       => '//'
  };
}
