#!/usr/bin/env perl

use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 113;

# "I was God once.
#  Yes, I saw. You were doing well until everyone died."
use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

# GET /shortpoll
my $shortpoll = 0;
get '/shortpoll' => sub {
  my $self = shift;
  $self->res->headers->connection('close');
  $self->on_finish(sub { $shortpoll++ });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->finish('this was short.');
} => 'shortpoll';

# GET /shortpoll/plain
my $shortpoll_plain;
get '/shortpoll/plain' => sub {
  my $self = shift;
  $self->on_finish(sub { $shortpoll_plain = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->res->headers->content_length(25);
  $self->write('this was short and plain.');
};

# GET /shortpoll/nolength
my $shortpoll_nolength;
get '/shortpoll/nolength' => sub {
  my $self = shift;
  $self->on_finish(sub { $shortpoll_nolength = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->write('this was short and had no length.');
  $self->write('');
};

# GET /longpoll
my $longpoll;
get '/longpoll' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->write_chunk('hi ');
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->write_chunk('there,', sub { shift->write_chunk(' whats up?'); });
      shift->timer('0.5' => sub { $self->finish });
    }
  );
};

# GET /longpoll/nolength
my $longpoll_nolength;
get '/longpoll/nolength' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_nolength = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->write('hi ');
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->write('there,', sub { shift->write(' what length?'); });
      shift->timer('0.5' => sub { $self->finish });
    }
  );
};

# GET /longpoll/nested
my $longpoll_nested;
get '/longpoll/nested' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_nested = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->cookie(foo => 'bar');
  $self->write_chunk(
    sub {
      shift->write_chunk('nested!', sub { shift->write_chunk('') });
    }
  );
};

# GET /longpoll/plain
my $longpoll_plain;
get '/longpoll/plain' => sub {
  my $self = shift;
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->res->headers->content_length(25);
  $self->write('hi ');
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->on_finish(sub { $longpoll_plain = 'finished!' });
      $self->write('there plain,', sub { shift->write(' whats up?') });
    }
  );
};

# GET /longpoll/delayed
my $longpoll_delayed;
get '/longpoll/delayed' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_delayed = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->write_chunk;
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->write_chunk(
        sub {
          my $self = shift;
          $self->write_chunk('how');
          $self->finish('dy!');
        }
      );
    }
  );
};

# GET /longpoll/plain/delayed
my $longpoll_plain_delayed;
get '/longpoll/plain/delayed' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_plain_delayed = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->res->headers->content_length(12);
  $self->write;
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->write(
        sub {
          my $self = shift;
          $self->write('how');
          $self->write('dy plain!');
        }
      );
    }
  );
} => 'delayed';

# GET /longpoll/nolength/delayed
my $longpoll_nolength_delayed;
get '/longpoll/nolength/delayed' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_nolength_delayed = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->write;
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->write(
        sub {
          my $self = shift;
          $self->write('how');
          $self->finish('dy nolength!');
        }
      );
    }
  );
};

# GET /longpoll/static/delayed
my $longpoll_static_delayed;
get '/longpoll/static/delayed' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_static_delayed = 'finished!' });
  Mojo::IOLoop->timer('0.5' => sub { $self->render_static('hello.txt') });
};

# GET /longpoll/static/delayed_too
my $longpoll_static_delayed_too;
get '/longpoll/static/delayed_too' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_static_delayed_too = 'finished!' });
  $self->cookie(bar => 'baz');
  $self->session(foo => 'bar');
  $self->render_later;
  Mojo::IOLoop->timer('0.5' => sub { $self->render_static('hello.txt') });
} => 'delayed_too';

# GET /longpoll/dynamic/delayed
my $longpoll_dynamic_delayed;
get '/longpoll/dynamic/delayed' => sub {
  my $self = shift;
  $self->on_finish(sub { $longpoll_dynamic_delayed = 'finished!' });
  Mojo::IOLoop->timer(
    '0.5' => sub {
      $self->res->code(201);
      $self->cookie(baz => 'yada');
      $self->res->body('Dynamic!');
      $self->rendered;
    }
  );
} => 'dynamic';

# GET /too_long
my $too_long;
get '/too_long' => sub {
  my $self = shift;
  $self->on_finish(sub { $too_long = 'finished!' });
  $self->res->code(200);
  $self->res->headers->content_type('text/plain');
  $self->res->headers->content_length(12);
  $self->write('how');
  Mojo::IOLoop->timer(
    '5' => sub {
      $self->write(
        sub {
          my $self = shift;
          $self->write('dy plain!');
        }
      );
    }
  );
};

my $t = Test::Mojo->new;

# GET /shortpoll
$t->get_ok('/shortpoll')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('this was short.');
is $t->tx->kept_alive, undef, 'connection was not kept alive';
is $t->tx->keep_alive, 0,     'connection will not be kept alive';
is $shortpoll, 1, 'finished';

# GET /shortpoll/plain
$t->get_ok('/shortpoll/plain')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('this was short and plain.');
is $t->tx->kept_alive, undef, 'connection was not kept alive';
is $t->tx->keep_alive, 1,     'connection will be kept alive';
is $shortpoll_plain, 'finished!', 'finished';

# GET /shortpoll/nolength
$t->get_ok('/shortpoll/nolength')->status_is(200)
  ->header_is(Server           => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By'   => 'Mojolicious (Perl)')
  ->header_is('Content-Length' => undef)->content_type_is('text/plain')
  ->content_is('this was short and had no length.');
is $t->tx->kept_alive, 1, 'connection was not kept alive';
is $t->tx->keep_alive, 0, 'connection will be kept alive';
is $shortpoll_nolength, 'finished!', 'finished';

# GET /longpoll
$t->get_ok('/longpoll')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('hi there, whats up?');
is $t->tx->kept_alive, undef, 'connection was kept alive';
is $t->tx->keep_alive, 1,     'connection will be kept alive';
is $longpoll, 'finished!', 'finished';

# GET /longpoll (interrupted)
$longpoll = undef;
my $port = $t->ua->test_server;
Mojo::IOLoop->connect(
  address    => 'localhost',
  port       => $port,
  on_connect => sub {
    my ($self, $id) = @_;
    $self->write($id => "GET /longpoll HTTP/1.1\x0d\x0a\x0d\x0a");
  },
  on_read => sub {
    my ($self, $id, $chunk) = @_;
    $self->drop($id);
    $self->timer('0.5', sub { Mojo::IOLoop->stop });
  }
);
Mojo::IOLoop->start;
is $longpoll, 'finished!', 'finished';

# GET /longpoll (also interrupted)
my $tx = $t->ua->build_tx(GET => '/longpoll');
my $buffer = '';
$tx->res->body(
  sub {
    my ($self, $chunk) = @_;
    $buffer .= $chunk;
    $self->error('Interrupted!') if length $buffer == 3;
  }
);
$t->ua->start($tx);
is $tx->res->code,  200,            'right status';
is $tx->res->error, 'Interrupted!', 'right error';
is $buffer, 'hi ', 'right content';

# GET /longpoll/nolength
$t->get_ok('/longpoll/nolength')->status_is(200)
  ->header_is(Server           => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By'   => 'Mojolicious (Perl)')
  ->header_is('Content-Length' => undef)->content_type_is('text/plain')
  ->content_is('hi there, what length?');
is $t->tx->keep_alive, 0, 'connection will not be kept alive';
is $longpoll_nolength, 'finished!', 'finished';

# GET /longpoll/nested
$t->get_ok('/longpoll/nested')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->header_like('Set-Cookie' => qr/foo=bar/)->content_type_is('text/plain')
  ->content_is('nested!');
is $longpoll_nested, 'finished!', 'finished';

# GET /longpoll/plain
$t->get_ok('/longpoll/plain')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('hi there plain, whats up?');
is $longpoll_plain, 'finished!', 'finished';

# GET /longpoll/delayed
$t->get_ok('/longpoll/delayed')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('howdy!');
is $longpoll_delayed, 'finished!', 'finished';

# GET /longpoll/plain/delayed
$t->get_ok('/longpoll/plain/delayed')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')->content_is('howdy plain!');
is $longpoll_plain_delayed, 'finished!', 'finished';

# GET /longpoll/nolength/delayed
$t->get_ok('/longpoll/nolength/delayed')->status_is(200)
  ->header_is(Server           => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By'   => 'Mojolicious (Perl)')
  ->header_is('Content-Length' => undef)->content_type_is('text/plain')
  ->content_is('howdy nolength!');
is $longpoll_nolength_delayed, 'finished!', 'finished';

# GET /longpoll/static/delayed
$t->get_ok('/longpoll/static/delayed')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->content_type_is('text/plain')
  ->content_is('Hello Mojo from a static file!');
is $longpoll_static_delayed, 'finished!', 'finished';

# GET /longpoll/static/delayed_too
$t->get_ok('/longpoll/static/delayed_too')->status_is(200)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->header_like('Set-Cookie' => qr/bar=baz/)
  ->header_like('Set-Cookie' => qr/mojolicious=/)
  ->content_type_is('text/plain')
  ->content_is('Hello Mojo from a static file!');
is $longpoll_static_delayed_too, 'finished!', 'finished';

# GET /longpoll/dynamic/delayed
$t->get_ok('/longpoll/dynamic/delayed')->status_is(201)
  ->header_is(Server         => 'Mojolicious (Perl)')
  ->header_is('X-Powered-By' => 'Mojolicious (Perl)')
  ->header_like('Set-Cookie' => qr/baz=yada/)->content_is('Dynamic!');
is $longpoll_dynamic_delayed, 'finished!', 'finished';

# GET /too_long (timeout)
$tx = $t->ua->keep_alive_timeout(1)->build_tx(GET => '/too_long');
$buffer = '';
$tx->res->body(
  sub {
    my ($self, $chunk) = @_;
    $buffer .= $chunk;
  }
);
$t->ua->start($tx);
is $tx->res->code, 200, 'right status';
ok !$tx->error, 'no error';
is $buffer, 'how', 'right content';
