package Licenses;

use Module::Pluggable instantiate => 'new', search_path => "Licenses";
use Data::Dumper;

sub new {
  return bless {}, shift;
}

sub get_licenses {
  my ($self, $app) = @_;

  foreach my $plugin ($self->plugins()) {
    my $stub = $plugin->{'header'};
    $stub =~ s/###DESCRIPTION###/$app->{'options'}->{'about'}/;
    $stub =~ s/###DATE###/$app->{'options'}->{'date'}/;
    $stub =~ s/###NAME###/$app->{'options'}->{'user'}/;

    $app->{'licenses'}->{$plugin->{'name'}} = {
      'pretty_name' => $plugin->{'pretty_name'},
      'header_stub' => $stub
    };
  }
}

1;
