package Dancer2::Plugin::Passphrase;

use strict;
use warnings;
use Dancer2::Plugin::Passphrase::Core;
use Dancer2::Plugin::Passphrase::Hashed;
use Dancer2::Plugin;

our $VERSION = '3.4.1';

plugin_keywords 'passphrase';

# ABSTRACT: Passphrases and Passwords as objects for Dancer2

=head1 NAME

Dancer2::Plugin::Passphrase - Passphrases and Passwords as objects for Dancer2

=head1 DEPRECATION WARNING

B<NOTE:> This module is DEPRECATED, and it is advised that you switch
to L<Dancer2::Plugin::CryptPassphrase> if possible.

=head1 SYNOPSIS

This plugin manages the hashing of passwords for Dancer2 apps, allowing 
developers to follow cryptography best practices without having to 
become a cryptography expert.

It uses the bcrypt algorithm as the default, while also supporting any
hashing function provided by L<Digest>.

=head1 USAGE

    package MyWebService;
    use Dancer2;
    use Dancer2::Plugin::Passphrase;

    post '/login' => sub {
        my $phrase = passphrase( param('my password') )->generate;

        # $phrase is now an object that contains RFC 2307 representation
        # of the hashed passphrase, along with the salt, and other metadata
        
        # You should store $phrase->rfc2307() for use later
    };

    get '/protected' => sub {
        # Retrieve $stored_rfc_2307_string, like we created above.
        # IT MUST be a valid RFC 2307 string

        if ( passphrase( param('my password') )->matches( $stored_rfc_2307 ) ) {
            # Passphrase matches!
        }
    };

    get '/generate_new_password' => sub {
        return passphrase->generate_random;
    };

=head1 NOTE

This package does no checking about how secure the password is,
minimum length or anything, including a length of 0 being valid.
You can add extra checks in your "MyWebService".

=head1 AUTO STRINGIFICATION IS REMOVED

You must use $phrase->rfc2307() to get a text string.

=head1 KEYWORDS

=head2 passphrase

Given a plaintext password, it returns a Dancer2::Plugin::Passphrase::Core
object that you can generate a new hash from, or match against a stored hash.

=cut

has algorithm => (
    is          => 'ro',
    from_config => sub { 'Bcrypt' },
);

sub passphrase {
    my ($plugin, $plaintext) = @_;

    return Dancer2::Plugin::Passphrase::Core->new(
        %{$plugin->config},
        algorithm => $plugin->algorithm,
        plaintext => $plaintext,
    );
}

1;

__END__

=head1 MAIN METHODS

=head2 generate

Generates an RFC 2307 representation of the hashed passphrase
that is suitable for storage in a database.

    my $phrase = passphrase('my passphrase')->generate;

It returns a Dancer2::Plugin::Passphrase::Hashed object.

You should store C<< $phrase->rfc_2307() >> in your database.

Accepts a hashref of options to specify what kind of hash should be 
generated. All options settable in the config file are valid.

If you specify only the algorithm, the default settings for that algorithm will be used.

A cryptographically random salt is used if salt is not defined.
Only if you specify the empty string will an empty salt be used.
This is not recommended, and should only be used to upgrade old insecure hashes.

    my $phrase = passphrase('my password')->generate(
        {
            algorithm  => $algo_name,   # override algo from config
            $algo_name => {
                # override options for this algorithm
                $opt1 => $value1,
            },
        }
    );

So for Bcrypt this might be:


    my $phrase = passphrase('my password')->generate(
        {
            algorithm => 'Bcrypt',
            Bcrypt   => {
                cost => 14,
            }
        }
    );

=head2 matches

Matches a plaintext password against a stored hash.
Returns 1 if the hash of the password matches the stored hash.
Returns undef if they don't match or if there was an error
Fail-Secure, rather than Fail-Safe.

    passphrase('my password')->matches($stored_rfc_2307_string);

$stored_rfc_2307_string B<MUST> be a valid RFC 2307 string,
as created by L<generate()|/"passphrase__generate">

An RFC 2307 string is made up of a scheme identifier, followed by a
base64 encoded string. The base64 encoded string should contain
the password hash and the salt concatenated together - in that order.

    '{'.$scheme.'}'.encode_base64($hash . $salt, '');

Where C<$scheme> can be any of the following and their unsalted variants,
which have the leading S removed. CRYPT will be Bcrypt.

    SMD5 SSHA SSHA224 SSHA256 SSHA384 SSHA512 CRYPT

A complete RFC2307 string looks like this:

    {SSHA}K3LAbIjRL5CpLzOlm3/HzS3qt/hUaGVTYWx0

This is the format created by L<generate()|/"passphrase__generate">

=head2 generate_random

Generates and returns any number of cryptographically random
characters from the url-safe base64 character set.

    my $rand_pass = passphrase->generate_random;

The passwords generated are suitable for use as
temporary passwords or one-time authentication tokens.

You can configure the length and the character set
used by passing a hashref of options.

    my $rand_pass = passphrase->generate_random({
        length  => 32,
        charset => ['a'..'z', 'A'..'Z'],
    });

=head1 ADDITIONAL METHODS

The methods are only applicable once you have called C<generate>

    passphrase( 'my password' )->generate->rfc2307; # CORRECT

    passphrase( 'my password' )->rfc2307;           # INCORRECT, Returns undef


=head2 rfc2307

Returns the rfc2307 representation from a C<Dancer2::Plugin::Passphrase> object.

    passphrase('my password')->generate->rfc2307;

=head2 scheme

Returns the scheme name from a C<Dancer2::Plugin::Passphrase> object.

This is the scheme name as used in the RFC 2307 representation

    passphrase('my password')->generate->scheme;

The scheme name can be any of the following, and will always be capitalized

    SMD5  SSHA  SSHA224  SSHA256  SSHA384  SSHA512  CRYPT
    MD5   SHA   SHA224   SHA256   SHA384   SHA512

=head2 algorithm

Returns the algorithm name from a C<Dancer2::Plugin::Passphrase> object.

The algorithm name can be anything that is accepted by C<< Digest->new($alg) >>
This includes any modules in the C<Digest::> Namespace

    passphrase('my password')->generate->algorithm;

=head2 cost

Returns the bcrypt cost from a C<Dancer2::Plugin::Passphrase> object.
Only works when using the bcrypt algorithm, returns undef for other algorithms

    passphrase('my password')->generate->cost;

=head2 salt_raw

Returns the raw salt from a C<Dancer2::Plugin::Passphrase> object.

    passphrase('my password')->generate->salt_raw;

Can be defined, but false - The empty string is technically a valid salt.

Returns C<undef> if there is no salt.

=head2 hash_raw

Returns the raw hash from a C<Dancer2::Plugin::Passphrase> object.

    passphrase('my password')->generate->hash_raw;

=head2 salt_hex

Returns the hex-encoded salt from a C<Dancer2::Plugin::Passphrase> object.

Can be defined, but false - The empty string is technically a valid salt.
Returns C<undef> if there is no salt.

    passphrase('my password')->generate->salt_hex;

=head2 hash_hex

Returns the hex-encoded hash from a C<Dancer2::Plugin::Passphrase> object.

    passphrase('my password')->generate->hash_hex;

=head2 salt_base64

Returns the base64 encoded salt from a C<Dancer2::Plugin::Passphrase> object.

Can be defined, but false - The empty string is technically a valid salt.
Returns C<undef> if there is no salt.

    passphrase('my password')->generate->salt_base64;

=head2 hash_base64

Returns the base64 encoded hash from a C<Dancer2::Plugin::Passphrase> object.

    passphrase('my password')->generate->hash_base64;

=head2 plaintext

Returns the plaintext password as originally supplied to the L<passphrase> keyword.

    passphrase('my password')->generate->plaintext;


=head1 MORE INFORMATION

=head2 Purpose

The aim of this module is to help you store new passwords in a secure manner, 
whilst still being able to verify and upgrade older passwords.

Cryptography is a vast and complex field. Many people try to roll their own 
methods for securing user data, but succeed only in coming up with 
a system that has little real security.

This plugin provides a simple way of managing that complexity, allowing 
developers to follow crypto best practice without having to become an expert.


=head2 Rationale

The module defaults to hashing passwords using the bcrypt algorithm, returning them
in RFC 2307 format.

RFC 2307 describes an encoding system for passphrase hashes, as used in the "userPassword"
attribute in LDAP databases. It encodes hashes as ASCII text, and supports several 
passphrase schemes by starting the encoding with an alphanumeric scheme identifier enclosed 
in braces.

RFC 2307 only specifies the C<MD5>, and C<SHA> schemes - however in real-world usage,
schemes that are salted are widely supported, and are thus provided by this module.

Bcrypt is an adaptive hashing algorithm that is designed to resist brute 
force attacks by including a cost (aka work factor). This cost increases 
the computational effort it takes to compute the hash.

SHA and MD5 are designed to be fast, and modern machines compute a billion 
hashes a second. With computers getting faster every day, brute forcing 
SHA hashes is a very real problem that cannot be easily solved.

Increasing the cost of generating a bcrypt hash is a trivial way to make 
brute forcing ineffective. With a low cost setting, bcrypt is just as secure 
as a more traditional SHA+salt scheme, and just as fast. Increasing the cost
as computers become more powerful keeps you one step ahead

For a more detailed description of why bcrypt is preferred, see this article: 
L<http://codahale.com/how-to-safely-store-a-password/>


=head2 Configuration

In your applications config file, you can set the default hashing algorithm,
and the default settings for every supported algorithm. Calls to
L<generate()|/"passphrase__generate"> will use the default settings
for that algorithm specified in here.

You can override these defaults when you call L<generate()|/"passphrase__generate">.

If you do no configuration at all, the default is to bcrypt with a cost of 4, and 
a strong psuedo-random salt.

    plugins:
        Passphrase:
            algorithm: Bcrypt
            cost: 8


=head2 Storage in a database

You should be storing the RFC 2307 string in your database, it's the easiest way
to use this module. You could store the C<raw_salt>, C<raw_hash>, and C<scheme>
separately, but this strongly discouraged. RFC 2307 strings are specifically
designed for storing hashed passwords, and should be used wherever possible.

The length of the string produced by L<generate()|/"passphrase__generate"> can
vary dependent on your settings. Below is a table of the lengths generated
using default settings.

You will need to make sure your database columns are at least this long.
If the string gets truncated, the password can I<never> be validated.

    ALGORITHM   LENGTH  EXAMPLE RFC 2307 STRING
    
    Bcrypt      67      {CRYPT}$2a$04$MjkMhQxasFQod1qq56DXCOvWu6YTWk9X.EZGnmSSIbbtyEBIAixbS
    SHA-512     117     {SSHA512}lZG4dZ5EU6dPEbJ1kBPPzEcupFloFSIJjiXCwMVxJXOy/x5qhBA5XH8FiUWj7u59onQxa97xYdqje/fwY5TDUcW1Urplf3KHMo9NO8KO47o=
    SHA-384     97      {SSHA384}SqZF5YYyk4NdjIM8YgQVfRieXDxNG0dKH4XBcM40Eblm+ribCzdyf0JV7i2xJvVHZsFSQNcuZPKtiTMzDyOU+w==
    SHA-256     73      {SSHA256}xsJHNzPlNCpOZ41OkTfQOU35ZY+nRyZFaM8lHg5U2pc0xT3DKNlGW2UTY0NPYsxU
    SHA-224     69      {SSHA224}FTHNkvKOdyX1d6f45iKLVxpaXZiHel8pfilUT1dIZ5u+WIUyhDGxLnx72X0=
    SHA-1       54      {SSHA}Qsaao/Xi/bYTRMQnpHuD3y5nj02wbdcw5Cek2y2nLs3pIlPh
    MD5         50      {SMD5}bgfLiUQWgzUm36+nBhFx62bi0xdwTp+UpEeNKDxSLfM=

=head2 Common Mistakes

Common mistakes people make when creating their own solution. If any of these 
seem familiar, you should probably be using this module

=over

=item Passwords are stored as plain text for a reason

There is never a valid reason to store a password as plain text.
Passwords should be reset and not emailed to customers when they forget.
Support people should be able to login as a user without knowing the users password.
No-one except the user should know the password - that is the point of authentication.

=item No-one will ever guess our super secret algorithm!

Unless you're a cryptography expert with many years spent studying 
super-complex maths, your algorithm is almost certainly not as secure 
as you think. Just because it's hard for you to break doesn't mean
it's difficult for a computer.

=item Our application-wide salt is "Sup3r_S3cret_L0ng_Word" - No-one will ever guess that.

This is common misunderstanding of what a salt is meant to do. The purpose of a 
salt is to make sure the same password doesn't always generate the same hash.
A fresh salt needs to be created each time you hash a password. It isn't meant 
to be a secret key.

=item We generate our random salt using C<rand>.

C<rand> isn't actually random, it's a non-unform pseudo-random number generator, 
and not suitable for cryptographic applications. Whilst this module also defaults to 
a PRNG, it is better than the one provided by C<rand>. Using a true RNG is a config
option away, but is not the default as it it could potentially block output if the
system does not have enough entropy to generate a truly random number

=item We use C<md5(pass.salt)>, and the salt is from C</dev/random>

MD5 has been broken for many years. Commodity hardware can find a 
hash collision in seconds, meaning an attacker can easily generate 
the correct MD5 hash without using the correct password.

=item We use C<sha(pass.salt)>, and the salt is from C</dev/random>

SHA isn't quite as broken as MD5, but it shares the same theoretical 
weaknesses. Even without hash collisions, it is vulnerable to brute forcing.
Modern hardware is so powerful it can try around a billion hashes a second. 
That means every 7 character password in the range [A-Za-z0-9] can be cracked 
in one hour on your average desktop computer.

=item If the only way to break the hash is to brute-force it, it's secure enough

It is unlikely that your database will be hacked and your hashes brute forced.
However, in the event that it does happen, or SHA512 is broken, using this module
gives you an easy way to change to a different algorithm, while still allowing
you to validate old passphrases

=back


=head1 KNOWN ISSUES

If you see errors like this

    Wide character in subroutine entry

or

    Input must contain only octets

The C<MD5>, C<bcrypt>, and C<SHA> algorithms can't handle characters with an ordinal
value above 255, producing errors like this if they encounter them.
It is not possible for this plugin to automagically work out the correct
encoding for a given string.

If you see errors like this, then you probably need to use the L<Encode> module
to encode your text as UTF-8 (or whatever encoding it is) before giving it 
to C<passphrase>.

Text encoding is a bag of hurt, and errors like this are probably indicitive
of deeper problems within your app's code.

You will save yourself a lot of trouble if you read up on the
L<Encode> module sooner rather than later.

For further reading on UTF-8, unicode, and text encoding in perl,
see L<http://training.perl.com/OSCON2011/index.html>


=head1 SEE ALSO

L<Dancer2>, L<Digest>, L<Crypt::Eksblowfish::Bcrypt>


=head1 ACKNOWLEDGMENTS

=over

=item James Aitken for his D1 version.

=item Sawyer X for his D2 magic.

=item Mohammad S Anwar (GH#4, typo fixes)

=item Jim Davis (GH#5)

=item Peter Mottram (GH#11)

=item Nuno Carvalho (GH#12)

=item Tom Adams (fix generate docs)

=item Jeremi M. Gosney (GH #2)

=item Sergiy Borodych (GH #3)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2018 Peter Mottram <peter@sysnix.com>.
Copyright (c) 2016 Henk van Oers <hvo.pm@xs4all.nl>.
Copyright (c) 2012-2016 James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
