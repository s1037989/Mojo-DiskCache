package Mojo::DiskCache;
use Mojo::Base -base;

use Mojo::Home;
use Mojo::JSON 'j';
use Mojo::Util qw/b64_encode b64_decode md5_sum/;

use Storable qw/store retrieve/;

use constant DEBUG => 1;

has home => sub { Mojo::Home->new->detect };
has expire => 86_400;
has cachedir => 'cache';

sub cache {
  my ($self, $cb) = (shift, pop);
  my $cache = $self->home->child($self->cachedir)->make_path->child(md5_sum(b64_encode(j([@_]))));
  unlink $cache and DEBUG and warn "Purging stale cache\n" if -e $cache && time - ((stat($cache))[9]) > $self->expire;
  if ( -e "$cache" ) {
    warn "Fetching from cache\n" if DEBUG;
    return retrieve($cache);
  } else {
    warn "Refreshing from source\n" if DEBUG;
    local $_ = $cb->(@_);
    store $_, $cache;
    return $_;
  }
}

1;
