package Licenses::MPL2;

sub new {
  return bless {
    'name' => 'mpl2',
    'pretty_name' => 'MPL 2',
    'header' => qq {
Copyright (C) ###DATE### ###NAME###

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
}
  }, shift;
}

1;
