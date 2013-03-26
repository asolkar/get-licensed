#!/bin/env perl

# -----
#
# Copyright (c) 2013 Mahesh Asolkar
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# -----
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use File::Find;
use File::Basename;
use File::Copy;
use FileHandle;
use File::Glob ':globally';
use Data::Dumper;
use Getopt::Long;
use Cwd;
use Licenses;

# Application configuration and state storage
my $app = {};

# Defaults
$app->{'options'}->{'directory'}  = getcwd;
$app->{'options'}->{'license'}    = 'mit';
$app->{'options'}->{'user'}       = $ENV{'USER'};
$app->{'options'}->{'date'}       = (localtime(time))[5] + 1900;
$app->{'options'}->{'about'}      = "This is an open-source software";
$app->{'options'}->{'dry'}        = 0;

$app->{'state'}->{'license_stub'} = "NON EXISTANT";
$app->{'state'}->{'app_dir'}      = dirname($0);

# Command line options
my $correct_usage = GetOptions (
    'directory=s' => \$app->{'options'}->{'directory'},
    'license=s' => \$app->{'options'}->{'license'},
    'about=s' => \$app->{'options'}->{'about'},
    'user=s' => \$app->{'options'}->{'user'},
    'date=s' => \$app->{'options'}->{'date'},
    'dry' => \$app->{'options'}->{'dry'},
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

# print Data::Dumper->Dump([$app]);

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
  return if ($file =~ /\.git\b/);

  handle_files ($app, $file, $name);
}

sub handle_files {
  my ($app, $file, $name) = @_;

  return unless -f $name;

  my($filename, $directories, $suffix) = fileparse($file, qr/\.[^.]*/);

  if (exists $app->{'filetype_comments'}->{$suffix}) {
    my $rh = FileHandle->new($name);
    my @contents = <$rh>;

    print "Handling... $filename - $directories - $suffix ----- " .
          ref($app->{'filetype_comments'}->{$suffix}) . "\n";

    my $stub = get_license_stub($app, $suffix);

    if ((defined $contents[0]) && ($contents[0] =~ /^\s*#!/)) {
      print "   ... has #! line\n";

      $contents[0] =  $contents[0] . "\n" . $stub;
    } else {
      $contents[0] =  $stub . "\n" . $contents[0];
    }

    if ($app->{'options'}->{'dry'} == 0) {
      copy($name, $name . ".get_licensed_backup") or die "Could not create backup file";

      my $wh = FileHandle->new($name, O_WRONLY);
      print $wh @contents;
    }
  }
  else {
    print "[ALERT] Don't know how to comment in file with '$suffix' extension\n";
  }
}

sub get_license_stub {
  my ($app, $suffix) = @_;

  my $stub = $app->{'licenses'}->{$app->{'options'}->{'license'}}->{'header_stub'};
  if (ref($app->{'filetype_comments'}->{$suffix}) eq '') {
    $stub =~ s/^(.)/$app->{'filetype_comments'}->{$suffix} $1/msg;
    $stub = $app->{'filetype_comments'}->{$suffix} . " -----\n" .
            "$stub\n" .
            $app->{'filetype_comments'}->{$suffix} . " -----\n";
  } elsif (ref($app->{'filetype_comments'}->{$suffix}) eq 'ARRAY') {
    $stub =~ s/^(.)/  $1/msg;
    $stub = $app->{'filetype_comments'}->{$suffix}[0] .
            " -----\n$stub\n ----- " .
            $app->{'filetype_comments'}->{$suffix}[1];
  } else {
    # not an option
  }

  $stub =~ s/\s+$//msg;

  return $stub;
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
    '.pl'         => '#',
    '.pm'         => '#',
    '.rb'         => '#',
    '.erb'        => ['<!--', '-->'],
    '.html'       => ['<!--', '-->'],
    '.css'        => ['/*', '*/'],
    '.coffee'     => '#',
    '.js'         => '//',
    '.scss'       => '//',
    '.v'          => '//',
    '.sv'         => '//',
    '.vr'         => '//',
    '.gitignore'  => '#',
    '.gitkeep'    => '#'

  };
}
