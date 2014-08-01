use File::Spec;
use strict;
use IPC::Cmd qw/run/;
use Config;
use Test::More;
use diagnostics;
use File::Basename;
use lib dirname(__FILE__);
use TestInlineSetup;
require version;

my ($example_modules_dir) = grep { -e } map {
  File::Spec->catdir(File::Spec->curdir, $_, 'modules')
} qw(eg example);

plan skip_all => "No 'example' or 'eg' directory." unless $example_modules_dir;
require Inline;
plan skip_all => "Inline version 0.64+ required for this."
  unless version->parse($Inline::VERSION) >= version->parse(0.64);

my $lib_dir  = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir(),'lib'));
my $inst_dir = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir(),$TestInlineSetup::DIR));

# loop the list of modules and try to build them.
for my $module (glob "$example_modules_dir/*") {
  chdir File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir(),$module));

  my $buffer = '';
  my $cmd = [$^X, "-I$lib_dir", 'Makefile.PL', "INSTALL_BASE=$inst_dir"];
  my @result = run(command => $cmd, verbose => 0, buffer => \$buffer);
  ok($result[0], "$module Makefile creation");
  diag $buffer unless $result[0];

  map { do_make($_) } qw(test install realclean);
}

sub do_make {
  my $target = shift;
  my $buffer = '';
  my $cmd = [$Config{make}, $target];
  my @result = run(command => $cmd, verbose => 0, buffer => \$buffer);
  ok($result[0], "make $target");
  diag $buffer unless $result[0];
}

done_testing;
