package Biolab::Strain;
use 5.16.0;
use Moose;
use Carp;
use Data::Dumper;
use warnings;
use DateTime;



#extends 'BioLab::Base';
# This is a module to deal with plasmid




# Declare some convenient types
use Moose::Util::TypeConstraints;

# Database primary or foreign key
subtype 'Natural',
as 'Int',
where { $_ > 0 },
message { "$_ is not a positive integer!" };

enum 'bw', [qw/yes no/];
enum 'copy', [qw/high medium low single/];
class_type 'DateTimeClass', {class => 'DateTime'};


no Moose::Util::TypeConstraints;
#End of declaration!



############Definition of attributes######################

# Such as DH5a
has 'Strain_Name' =>   (   is => 'rw',
isa => 'Str',
required => 1,
);

# Such as E. coli
has 'Species' => ( is => 'rw'
isa => 'Str',
);

# This is database's primary key
has 'ID' =>     (   is => 'rw',
isa => 'Natural',
);

# Resistance profile
has 'Resistance' =>    (   is => 'rw',
isa => 'ArrayRef[Str]',
predicate => 'has_resistance',
builder => '_set_resistance',
auto_deref => 1,
);


# Usually genbenk sequence
has 'Sequence' =>    (   is => 'ro',
isa => 'Str',
);


# Which strains have the plasmid?
has 'Plasmids' => ( is => 'rw',
isa => 'ArrayRef[Str]',
predicate => 'has_carriers',
);


# Reference of the plasmid
has 'Reference' =>    (   is => 'rw',
isa => 'Str',
default => 'Reference needed',
);


# Optimal temperature to grow the cells with the plasmid.
has 'Temperature' => (  is => 'rw',
isa => 'Natural',
default => 37,
);



has 'Arrival_time' => (   is => 'rw',
isa => 'DateTimeClass',
default => sub {DateTime->now},
);



has 'Recording_time' => (  is => 'rw',
isa => 'DateTimeClass',
);


has 'Modified_time' => (  is => 'rw',
isa => 'DateTimeClass',
);


# Genotype can be very random. So leave it as a string!
has 'Genotype' =>   (   is => 'rw',
isa => 'ArrayRef[Str]',
);




# Everything else.
has 'Comments' =>(   is => 'rw',
isa => 'Str',
);



has 'Parent' => (   is => 'rw',
isa => 'Str',
predicate => 'has_parent',
weak_ref => 1,
);



has 'Daughters' => (    is => 'rw',
isa => 'ArrayRef[Str]',
predicate => 'has_daughters',
auto_deref => 1,
);

has 'Recorder' => ( is => 'rw',
isa => 'Str',
);

has 'Keeper' => ( is => 'rw',
isa => 'Str',
);

has 'Obsolete' => ( is => 'rw',
isa => 'Bool',
);


has 'Location' => (is => 'rw',
isa => 'Str',
);

############End of definition################################
sub _set_resistance {
    my $self = shift;
    my $resistance = $self->has_resistance ? {map {$_, 1} @{$self->Resistance}} : {};
    my $genotype = $self->{genotype};
    for ($genotype){
        no warnings;
        $resistance->{'kanamycin'} = 1 if /aph/;
        $resistance->{'chlorampenicol'} = 1 if /cat/;
        $resistance->{'ampicillin'} = 1 if /bla/;
    }
    #say '=' x 20;
    #say $self->name;
    #print Dumper $resistance;
    $self->Resistance([keys $resistance]);
}

1;