package Biolab::Antibiotic;
use Config::Any;

# Loading config file
my $cfg = Config::Any->load_files({files => ['Antibiotic.yml'], use_ext => 1});
my $antibiotics = $cfg->[0]{'Antibiotic.yml'};

sub abbreviate {
    my ($self,$res) = @_;
    for my $key (keys %$antibiotics){
        $res =~ s/\b($key)\b/$antibiotics->{$key}/;
    }
    my @res = split / /, $res;
    return wantarray ? @res : [@res];
}

sub populate {
    my ($self,$res) = @_;
    for my $key (keys %$antibiotics){
        $res =~ s/\b$antibiotics->{$key}\b/$key/;
    }
    my @res = split / /, $res;
    return wantarray ? @res : [@res];
}

1;