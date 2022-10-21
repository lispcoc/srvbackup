#!/usr/bin/env perl

use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN {
  $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1;
  $ENV{MOJO_MODE} = 'production';
}

use Test::More tests => 51;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;

# "This concludes the part of the tour where you stay alive."
use_ok 'MojoliciousTest';

my $t = Test::Mojo->new(app => 'MojoliciousTest');

# SyntaxError::foo in production mode (syntax error in controller)
$t->get_ok('/syntax_error/foo')->status_is(500)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_like(qr/Internal Server Error/);

# Foo::syntaxerror in production mode (syntax error in template)
$t->get_ok('/foo/syntaxerror')->status_is(500)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_like(qr/Internal Server Error/);

# Exceptional::this_one_dies (action dies)
$t->get_ok('/exceptional/this_one_dies')->status_is(500)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_is("Action died: doh!\n");

# Exceptional::this_one_might_die (bridge dies)
$t->get_ok('/exceptional_too/this_one_dies')->status_is(500)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_is("Action died: double doh!\n");

# Exceptional::this_one_might_die (action dies)
$t->get_ok('/exceptional_too/this_one_dies', {'X-DoNotDie' => 1})
  ->status_is(500)->header_is(Server => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_is("Action died: doh!\n");

# Exceptional::this_one_does_not_exist (action does not exist)
$t->get_ok('/exceptional/this_one_does_not_exist')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->json_content_is({error => 'not found!'});

# Exceptional::this_one_does_not_exist (action behind bridge does not exist)
$t->get_ok('/exceptional_too/this_one_does_not_exist', {'X-DoNotDie' => 1})
  ->status_is(200)->header_is(Server => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->json_content_is({error => 'not found!'});

# Static file /hello.txt in production mode
$t->get_ok('/hello.txt')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_like(qr/Hello Mojo from a static file!/);

# Foo::bar in production mode (missing action)
$t->get_ok('/foo/baz')->status_is(404)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_like(qr/Not Found/);

# Try to access a file which is not under the web root via path
# traversal in production mode
$t->get_ok('/../../mojolicious/secret.txt')->status_is(404)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_like(qr/Not Found/);
