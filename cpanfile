requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Simple', '1.001003';
  requires 'Test::More', '1.001003';
  requires 'Test::Exception','0.32';
};

requires 'Catmandu', '0.9202';
requires 'HTTP::OAI', '4.03';
requires 'Moo', '1.0';