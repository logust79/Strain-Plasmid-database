# A


package Biolab::UserChecker;

use 5.16.0;
use Digest::SHA qw(sha256_hex);
use Moose;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer::Logger qw(debug);
use vars qw/$VERSION/;
use Carp;

our $VERSION = '0.01';

my $DEBUG = 0;

my (%d_users);






has 'name' =>   (   is => 'rw',
                );

has 'password' => ( is => 'rw',
                );

has 'exist' =>  (   is => 'ro',
                    isa => 'Bool',
                    predicate => 'has_exist',
                    builder => '_exist',
                    lazy => 1,

                );

has 'valid' =>  (   is => 'ro',
                    isa => 'Bool',
                    builder=>'_valid',
                    lazy => 1,

                );

my %users;


sub _exist {
    my $self = shift;
    
    my $sth = database->prepare(q{SELECT name,password FROM users});
    $sth->execute() or croak "Can't execute statement";
    my $all_users = $sth->fetchall_hashref('name');
    for my $name (keys $all_users){
        $d_users{$name} = $all_users->{$name}->{password};
    }
    my $return_value = exists $d_users{$self->name} ? 1 : 0;
}

sub _valid {
    my $self = shift;
    my $name = $self->name;
    
    carp "User:$name does not exist!", return 0
        unless $self->exist;
    
    my $combo = $self->name.$self->password;
    my $user_sha = sha256_hex($combo);
    
    if ($DEBUG){
        say "password is:".$self->password;
        say "combo is:".$combo;
        say "user's name password: $user_sha";
        say "database's password: $d_users{$name}";
    }
    
    my $return_value = ($user_sha eq $d_users{$name}) ? 1 : 0;
    
    
    
}

sub add_user {
    my $self = shift;
    my $name = $self->name;
    
    carp "User: $name already exists!", return 0
        if $self->exist;
    
    my $combo = $name.$self->password;
    my $user_sha = sha256_hex($combo);
    
    if ($DEBUG){
        say 'name:'.$name;
        say 'password:'.$self->password;
        say 'pw:'.$user_sha;
    }
    
    my $sth = database->prepare("INSERT INTO users (name, password) VALUES (?,?)");
    
    
    $sth->execute($name, $user_sha) or croak "can't commit";
    
}


1;