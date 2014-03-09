package Biolab::Species;
use Config::Any;

# Loading config file
my $cfg = Config::Any->load_files({files => ['Species.yml'], use_ext => 1});
our %species = %{$cfg->[0]{'Species.yml'}};


sub abbreviate {
    my ($self, $species) = @_;
    for my $key (keys %species){
        $species =~ s/$key/$species{$key}/;
    }
    return $species;
}

sub populate {
    my ($self, $species) = @_;
    for my $key (keys %species){
        $species =~ s/$species{$key}/$key/;
    }
    return $species;
}

1;