package Dancer2::Plugin::Passphrase::Hashed;
use strict;
use warnings;
use MIME::Base64 qw(encode_base64);

sub new {
    my $class = shift;
    my @args  = @_;
    return bless { @args == 1 ? %{$args[0]} : @args }, $class;
}

sub rfc2307     { $_[0]->{'rfc2307'}   || undef        }
sub scheme      { $_[0]->{'scheme'}    || undef        }
sub algorithm   { $_[0]->{'algorithm'} || undef        }
sub cost        { $_[0]->{'cost'}      || undef        }
sub plaintext   { $_[0]->{'plaintext'} || undef        }
sub salt_raw    { $_[0]->{'salt'}      || undef        }
sub hash_raw    { $_[0]->{'hash'}      || undef        }
sub salt_hex    { unpack 'H*', $_[0]->{'salt'}         }
sub hash_hex    { unpack 'H*', $_[0]->{'hash'}         }
sub salt_base64 { encode_base64( $_[0]->{'salt'}, '' ) }
sub hash_base64 { encode_base64( $_[0]->{'hash'}, '' ) }

1;
