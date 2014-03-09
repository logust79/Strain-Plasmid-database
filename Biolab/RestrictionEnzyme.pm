package Biolab::RestrictionEnzyme;
use Moose;
use Carp;
use Moose::Util::TypeConstraints;

# This is a common class used by other modules. It contains plasmid-common, common, comprehensive drugs.
my $common_enzymes = [qw/BamHI HindIII XbaI NdeI EcorI EcorV KpnI XhoI ScaI SacI/];
my $all_enzymes = [@$common_enzymes, qw// ];

no Moose::Util::TypeConstraints;
has 'common_enzymes' => (
is => 'ro',
isa => 'ArrayRef',
default => sub {$common_enzymes},
#auto_deref =>1,
);

has 'all_enzymes' => (
is => 'ro',
isa => 'ArrayRef',
default => sub {$all_enzymes},
);

1;