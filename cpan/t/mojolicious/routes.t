#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 237;

# "They're not very heavy, but you don't hear me not complaining."
use_ok 'Mojolicious::Routes';
use_ok 'Mojolicious::Routes::Match';

# Routes
my $r = Mojolicious::Routes->new;

# /clean
$r->route('/clean')->to(clean => 1);

# /clean/too
$r->route('/clean/too')->to(something => 1);

# /0
$r->route('/0')->to(null => 1);

# /*/test
my $test = $r->route('/:controller/test')->to(action => 'test');

# /*/test/edit
$test->route('/edit')->to(action => 'edit')->name('test_edit');

# /*/testedit
$r->route('/:controller/testedit')->to(action => 'testedit');

# /*/test/delete/*
$test->route('/delete/(id)', id => qr/\d+/)->to(action => 'delete', id => 23);

# /test2
my $test2 = $r->bridge('/test2')->to(controller => 'test2');

# /test2 (inline)
my $test4 = $test2->bridge('/')->to(controller => 'index');

# /test2/foo
$test4->route('/foo')->to(controller => 'baz');

# /test2/bar
$test4->route('/bar')->to(controller => 'lalala');

# /test2/baz
$test2->route('/baz')->to('just#works');

# /test3
my $test3 = $r->waypoint('/test3')->to(controller => 's', action => 'l');

# /test3/edit
$test3->route('/edit')->to(action => 'edit');

# /
$r->route('/')->to(controller => 'hello', action => 'world');

# /wildcards/1/*
$r->route('/wildcards/1/(*wildcard)', wildcard => qr/(.*)/)
  ->to(controller => 'wild', action => 'card');

# /wildcards/2/*
$r->route('/wildcards/2/(*wildcard)')
  ->to(controller => 'card', action => 'wild');

# /wildcards/3/*/foo
$r->route('/wildcards/3/(*wildcard)/foo')
  ->to(controller => 'very', action => 'dangerous');

# /wildcards/4/*/foo
$r->route('/wildcards/4/*wildcard/foo')
  ->to(controller => 'somewhat', action => 'dangerous');

# /format
# /format.html
$r->route('/format')
  ->to(controller => 'hello', action => 'you', format => 'html');

# /format2.html
$r->route('/format2.html')->to(controller => 'you', action => 'hello');

# /format2.json
$r->route('/format2.json')->to(controller => 'you', action => 'hello_json');

# /format3/*.html
$r->route('/format3/:foo.html')->to(controller => 'me', action => 'bye');

# /format3/*.json
$r->route('/format3/:foo.json')->to(controller => 'me', action => 'bye_json');

# /articles
# /articles.html
# /articles/1
# /articles/1.html
# /articles/1/edit
# /articles/1/delete
my $articles = $r->waypoint('/articles')->to(
  controller => 'articles',
  action     => 'index',
  format     => 'html'
);
my $wp = $articles->waypoint('/:id')->to(
  controller => 'articles',
  action     => 'load',
  format     => 'html'
);
my $bridge = $wp->bridge->to(
  controller => 'articles',
  action     => 'load',
  format     => 'html'
);
$bridge->route('/edit')->to(controller => 'articles', action => 'edit');
$bridge->route('/delete')->to(
  controller => 'articles',
  action     => 'delete',
  format     => undef
)->name('articles_delete');

# GET /method/get
$r->route('/method/get')->via('GET')
  ->to(controller => 'method', action => 'get');

# POST /method/post
$r->route('/method/post')->via('post')
  ->to(controller => 'method', action => 'post');

# POST|GET /method/post_get
$r->route('/method/post_get')->via(qw/POST get/)
  ->to(controller => 'method', action => 'post_get');

# /simple/form
$r->route('/simple/form')->to('test-test#test');

# /edge/gift
my $edge = $r->route('/edge');
my $auth = $edge->bridge('/auth')->to('auth#check');
$auth->route('/about/')->to('pref#about');
$auth->bridge->to('album#allow')->route('/album/create/')->to('album#create');
$auth->route('/gift/')->to('gift#index')->name('gift');

# /regex/alternatives/*
$r->route('/regex/alternatives/:alternatives',
  alternatives => qr/foo|bar|baz/)
  ->to(controller => 'regex', action => 'alternatives');

# Make sure stash stays clean
my $m = Mojolicious::Routes::Match->new(get => '/clean')->match($r);
is $m->stack->[0]->{clean},     1,     'right value';
is $m->stack->[0]->{something}, undef, 'no value';
is $m->path_for, '/clean', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/clean/too')->match($r);
is $m->stack->[0]->{clean},     undef, 'no value';
is $m->stack->[0]->{something}, 1,     'right value';
is $m->path_for, '/clean/too', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Null route
$m = Mojolicious::Routes::Match->new(get => '/0')->match($r);
is $m->stack->[0]->{null}, 1, 'right value';
is $m->path_for, '/0', 'right path';

# Real world example using most features at once
$m = Mojolicious::Routes::Match->new(get => '/articles.html')->match($r);
is $m->stack->[0]->{controller}, 'articles', 'right value';
is $m->stack->[0]->{action},     'index',    'right value';
is $m->stack->[0]->{format},     'html',     'right value';
is $m->path_for, '/articles', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/articles/1.html')->match($r);
is $m->stack->[0]->{controller}, 'articles', 'right value';
is $m->stack->[0]->{action},     'load',     'right value';
is $m->stack->[0]->{id},         '1',        'right value';
is $m->stack->[0]->{format},     'html',     'right value';
is $m->path_for(format => 'html'), '/articles/1.html', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/articles/1/edit')->match($r);
is $m->stack->[1]->{controller}, 'articles', 'right value';
is $m->stack->[1]->{action},     'edit',     'right value';
is $m->stack->[1]->{format},     'html',     'right value';
is $m->path_for, '/articles/1/edit', 'right path';
is $m->path_for(format => 'html'), '/articles/1/edit.html', 'right path';
is $m->path_for('articles_delete', format => undef), '/articles/delete',
  'right path';
is $m->path_for('articles_delete'), '/articles/delete', 'right path';
is $m->path_for('articles_delete', id => 12), '/articles/12/delete',
  'right path';
is @{$m->stack}, 2, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/articles/1/delete')->match($r);
is $m->stack->[1]->{controller}, 'articles', 'right value';
is $m->stack->[1]->{action},     'delete',   'right value';
is $m->stack->[1]->{format},     undef,      'no value';
is $m->path_for, '/articles/1/delete', 'right path';
is @{$m->stack}, 2, 'right number of elements';

# Root
$m = Mojolicious::Routes::Match->new(get => '/')->match($r);
is $m->captures->{controller}, 'hello', 'right value';
is $m->captures->{action},     'world', 'right value';
is $m->stack->[0]->{controller}, 'hello', 'right value';
is $m->stack->[0]->{action},     'world', 'right value';
is $m->path_for, '/', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Path and captures
$m = Mojolicious::Routes::Match->new(get => '/foo/test/edit')->match($r);
is $m->captures->{controller}, 'foo',  'right value';
is $m->captures->{action},     'edit', 'right value';
is $m->stack->[0]->{controller}, 'foo',  'right value';
is $m->stack->[0]->{action},     'edit', 'right value';
is $m->path_for, '/foo/test/edit', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/foo/testedit')->match($r);
is $m->captures->{controller}, 'foo',      'right value';
is $m->captures->{action},     'testedit', 'right value';
is $m->stack->[0]->{controller}, 'foo',      'right value';
is $m->stack->[0]->{action},     'testedit', 'right value';
is $m->path_for, '/foo/testedit', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Optional captures in sub route with requirement
$m = Mojolicious::Routes::Match->new(get => '/bar/test/delete/22')->match($r);
is $m->captures->{controller}, 'bar',    'right value';
is $m->captures->{action},     'delete', 'right value';
is $m->captures->{id},         22,       'right value';
is $m->stack->[0]->{controller}, 'bar',    'right value';
is $m->stack->[0]->{action},     'delete', 'right value';
is $m->stack->[0]->{id},         22,       'right value';
is $m->path_for, '/bar/test/delete/22', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Defaults in sub route
$m = Mojolicious::Routes::Match->new(get => '/bar/test/delete')->match($r);
is $m->captures->{controller}, 'bar',    'right value';
is $m->captures->{action},     'delete', 'right value';
is $m->captures->{id},         23,       'right value';
is $m->stack->[0]->{controller}, 'bar',    'right value';
is $m->stack->[0]->{action},     'delete', 'right value';
is $m->stack->[0]->{id},         23,       'right value';
is $m->path_for, '/bar/test/delete', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Chained routes
$m = Mojolicious::Routes::Match->new(get => '/test2/foo')->match($r);
is $m->stack->[0]->{controller}, 'test2', 'right value';
is $m->stack->[1]->{controller}, 'index', 'right value';
is $m->stack->[2]->{controller}, 'baz',   'right value';
is $m->captures->{controller}, 'baz', 'right value';
is $m->path_for, '/test2/foo', 'right path';
is @{$m->stack}, 3, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/test2/bar')->match($r);
is $m->stack->[0]->{controller}, 'test2',  'right value';
is $m->stack->[1]->{controller}, 'index',  'right value';
is $m->stack->[2]->{controller}, 'lalala', 'right value';
is $m->captures->{controller}, 'lalala', 'right value';
is $m->path_for, '/test2/bar', 'right path';
is @{$m->stack}, 3, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/test2/baz')->match($r);
is $m->stack->[0]->{controller}, 'test2', 'right value';
is $m->stack->[1]->{controller}, 'just',  'right value';
is $m->stack->[1]->{action},     'works', 'right value';
is $m->stack->[2], undef, 'no value';
is $m->captures->{controller}, 'just', 'right value';
is $m->path_for, '/test2/baz', 'right path';
is @{$m->stack}, 2, 'right number of elements';

# Waypoints
$m = Mojolicious::Routes::Match->new(get => '/test3')->match($r);
is $m->stack->[0]->{controller}, 's', 'right value';
is $m->stack->[0]->{action},     'l', 'right value';
is $m->path_for, '/test3', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/test3/')->match($r);
is $m->stack->[0]->{controller}, 's', 'right value';
is $m->stack->[0]->{action},     'l', 'right value';
is $m->path_for, '/test3', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/test3/edit')->match($r);
is $m->stack->[0]->{controller}, 's',    'right value';
is $m->stack->[0]->{action},     'edit', 'right value';
is $m->path_for, '/test3/edit', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Named path_for
$m = Mojolicious::Routes::Match->new(get => '/test3')->match($r);
is $m->path_for, '/test3', 'right path';
is $m->path_for('test_edit', controller => 'foo'), '/foo/test/edit',
  'right path';
is $m->path_for('test_edit', {controller => 'foo'}), '/foo/test/edit',
  'right path';
is @{$m->stack}, 1, 'right number of elements';

# Wildcards
$m =
  Mojolicious::Routes::Match->new(get => '/wildcards/1/hello/there')
  ->match($r);
is $m->stack->[0]->{controller}, 'wild',        'right value';
is $m->stack->[0]->{action},     'card',        'right value';
is $m->stack->[0]->{wildcard},   'hello/there', 'right value';
is $m->path_for, '/wildcards/1/hello/there', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m =
  Mojolicious::Routes::Match->new(get => '/wildcards/2/hello/there')
  ->match($r);
is $m->stack->[0]->{controller}, 'card',        'right value';
is $m->stack->[0]->{action},     'wild',        'right value';
is $m->stack->[0]->{wildcard},   'hello/there', 'right value';
is $m->path_for, '/wildcards/2/hello/there', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m =
  Mojolicious::Routes::Match->new(get => '/wildcards/3/hello/there/foo')
  ->match($r);
is $m->stack->[0]->{controller}, 'very',        'right value';
is $m->stack->[0]->{action},     'dangerous',   'right value';
is $m->stack->[0]->{wildcard},   'hello/there', 'right value';
is $m->path_for, '/wildcards/3/hello/there/foo', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m =
  Mojolicious::Routes::Match->new(get => '/wildcards/4/hello/there/foo')
  ->match($r);
is $m->stack->[0]->{controller}, 'somewhat',    'right value';
is $m->stack->[0]->{action},     'dangerous',   'right value';
is $m->stack->[0]->{wildcard},   'hello/there', 'right value';
is $m->path_for, '/wildcards/4/hello/there/foo', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Escaped
$m =
  Mojolicious::Routes::Match->new(get => '/wildcards/1/http://www.google.com')
  ->match($r);
is $m->stack->[0]->{controller}, 'wild',                  'right value';
is $m->stack->[0]->{action},     'card',                  'right value';
is $m->stack->[0]->{wildcard},   'http://www.google.com', 'right value';
is $m->path_for, '/wildcards/1/http://www.google.com', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m =
  Mojolicious::Routes::Match->new(
  get => '/wildcards/1/http%3A%2F%2Fwww.google.com')->match($r);
is $m->stack->[0]->{controller}, 'wild',                  'right value';
is $m->stack->[0]->{action},     'card',                  'right value';
is $m->stack->[0]->{wildcard},   'http://www.google.com', 'right value';
is $m->path_for, '/wildcards/1/http://www.google.com', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Format
$m = Mojolicious::Routes::Match->new(get => '/format')->match($r);
is $m->stack->[0]->{controller}, 'hello', 'right value';
is $m->stack->[0]->{action},     'you',   'right value';
is $m->stack->[0]->{format},     'html',  'right value';
is $m->path_for, '/format', 'right path';
is $m->path_for(format => undef),  '/format',      'right path';
is $m->path_for(format => 'html'), '/format.html', 'right path';
is $m->path_for(format => 'txt'),  '/format.txt',  'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/format.html')->match($r);
is $m->stack->[0]->{controller}, 'hello', 'right value';
is $m->stack->[0]->{action},     'you',   'right value';
is $m->stack->[0]->{format},     'html',  'right value';
is $m->path_for, '/format', 'right path';
is $m->path_for(format => undef),  '/format',      'right path';
is $m->path_for(format => 'html'), '/format.html', 'right path';
is $m->path_for(format => 'txt'),  '/format.txt',  'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/format2.html')->match($r);
is $m->stack->[0]->{controller}, 'you',   'right value';
is $m->stack->[0]->{action},     'hello', 'right value';
is $m->stack->[0]->{format},     'html',  'right value';
is $m->path_for, '/format2.html', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/format2.json')->match($r);
is $m->stack->[0]->{controller}, 'you',        'right value';
is $m->stack->[0]->{action},     'hello_json', 'right value';
is $m->stack->[0]->{format},     'json',       'right value';
is $m->path_for, '/format2.json', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(GET => '/format3/baz.html')->match($r);
is $m->stack->[0]->{controller}, 'me',   'right value';
is $m->stack->[0]->{action},     'bye',  'right value';
is $m->stack->[0]->{format},     'html', 'right value';
is $m->stack->[0]->{foo},        'baz',  'right value';
is $m->path_for, '/format3/baz.html', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/format3/baz.json')->match($r);
is $m->stack->[0]->{controller}, 'me',       'right value';
is $m->stack->[0]->{action},     'bye_json', 'right value';
is $m->stack->[0]->{format},     'json',     'right value';
is $m->stack->[0]->{foo},        'baz',      'right value';
is $m->path_for, '/format3/baz.json', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Request methods
$m = Mojolicious::Routes::Match->new(get => '/method/get.html')->match($r);
is $m->stack->[0]->{controller}, 'method', 'right value';
is $m->stack->[0]->{action},     'get',    'right value';
is $m->stack->[0]->{format},     'html',   'right value';
is $m->path_for, '/method/get', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(POST => '/method/post')->match($r);
is $m->stack->[0]->{controller}, 'method', 'right value';
is $m->stack->[0]->{action},     'post',   'right value';
is $m->stack->[0]->{format},     undef,    'no value';
is $m->path_for, '/method/post', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(get => '/method/post_get')->match($r);
is $m->stack->[0]->{controller}, 'method',   'right value';
is $m->stack->[0]->{action},     'post_get', 'right value';
is $m->stack->[0]->{format},     undef,      'no value';
is $m->path_for, '/method/post_get', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(post => '/method/post_get')->match($r);
is $m->stack->[0]->{controller}, 'method',   'right value';
is $m->stack->[0]->{action},     'post_get', 'right value';
is $m->stack->[0]->{format},     undef,      'no value';
is $m->path_for, '/method/post_get', 'right path';
is @{$m->stack}, 1, 'right number of elements';
$m = Mojolicious::Routes::Match->new(delete => '/method/post_get')->match($r);
is $m->stack->[0]->{controller}, undef, 'no value';
is $m->stack->[0]->{action},     undef, 'no value';
is $m->stack->[0]->{format},     undef, 'no value';
is $m->path_for, undef, 'no path';
is @{$m->stack}, 1, 'right number of elements';

# Not found
$m = Mojolicious::Routes::Match->new(get => '/not_found')->match($r);
is $m->path_for('test_edit', controller => 'foo'), '/foo/test/edit',
  'right path';
is @{$m->stack}, 0, 'no elements';

# Simplified form
$m = Mojolicious::Routes::Match->new(get => '/simple/form')->match($r);
is $m->stack->[0]->{controller}, 'test-test', 'right value';
is $m->stack->[0]->{action},     'test',      'right value';
is $m->stack->[0]->{format},     undef,       'no value';
is $m->path_for, '/simple/form', 'right path';
is $m->path_for('current'), '/simple/form', 'right path';
is @{$m->stack}, 1, 'right number of elements';

# Special edge case with nested bridges
$m = Mojolicious::Routes::Match->new(get => '/edge/auth/gift')->match($r);
is $m->stack->[0]->{controller}, 'auth',  'right value';
is $m->stack->[0]->{action},     'check', 'right value';
is $m->stack->[0]->{format},     undef,   'no value';
is $m->stack->[1]->{controller}, 'gift',  'right value';
is $m->stack->[1]->{action},     'index', 'right value';
is $m->stack->[1]->{format},     undef,   'no value';
is $m->stack->[2], undef, 'no value';
is $m->path_for, '/edge/auth/gift', 'right path';
is $m->path_for('gift'),    '/edge/auth/gift', 'right path';
is $m->path_for('current'), '/edge/auth/gift', 'right path';
is @{$m->stack}, 2, 'right number of elements';

# Special edge case with nested bridges (regex)
$m =
  Mojolicious::Routes::Match->new(get => '/regex/alternatives/foo')
  ->match($r);
is $m->stack->[0]->{controller},   'regex',        'right value';
is $m->stack->[0]->{action},       'alternatives', 'right value';
is $m->stack->[0]->{alternatives}, 'foo',          'right value';
is $m->stack->[0]->{format},       undef,          'no value';
is $m->stack->[1], undef, 'no value';
is $m->path_for, '/regex/alternatives/foo', 'right path';
$m =
  Mojolicious::Routes::Match->new(get => '/regex/alternatives/bar')
  ->match($r);
is $m->stack->[0]->{controller},   'regex',        'right value';
is $m->stack->[0]->{action},       'alternatives', 'right value';
is $m->stack->[0]->{alternatives}, 'bar',          'right value';
is $m->stack->[0]->{format},       undef,          'no value';
is $m->stack->[1], undef, 'no value';
is $m->path_for, '/regex/alternatives/bar', 'right path';
$m =
  Mojolicious::Routes::Match->new(get => '/regex/alternatives/baz')
  ->match($r);
is $m->stack->[0]->{controller},   'regex',        'right value';
is $m->stack->[0]->{action},       'alternatives', 'right value';
is $m->stack->[0]->{alternatives}, 'baz',          'right value';
is $m->stack->[0]->{format},       undef,          'no value';
is $m->stack->[1], undef, 'no value';
is $m->path_for, '/regex/alternatives/baz', 'right path';
$m =
  Mojolicious::Routes::Match->new(get => '/regex/alternatives/yada')
  ->match($r);
is $m->stack->[0], undef, 'no value';
