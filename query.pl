#!/usr/bin/env perl

=header
 This is the primary app to load the web interface.

=cut

use 5.16.0;
use Dancer2;
use Biolab::UserChecker;
use Data::Dumper;
use Biolab::Antibiotic;
use Biolab::Species;
use DateTime;
use Dancer2::Plugin::Database;
use Dancer::Logger qw(debug);
use MIME::Base64;

use Template;
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'environment'  => 'development';





####### The beginning of all the subs.... #############

sub get_plasmid_list {
    # This sub is to get back a plasmid list, usually from a search.
    # It also add links to self/daughters/carriers/parent.
    my %tokens = @_;
    my @test;
    
    if ($tokens{obsolete}){
        # From /obsolete
        @test = database->quick_select('Plasmid',{Obsolete => 1});
    }elsif ($tokens{user}){
        
        # Coming from /myPlasmid
        @test = database->quick_select('Plasmid',{Keeper => $tokens{user}, Obsolete => 0});
        
    }elsif ($tokens{ids} || $tokens{names}){
        
        # Coming from /mass_search
        if ($tokens{ids}){
            @test = database->quick_select('Plasmid',{ID => $tokens{ids}});
        }
        if ($tokens{names}){
            my @temp = database->quick_select('Plasmid',{Name => $tokens{names}});
            push @test, @temp;
        }
        
    }else{
        
        # For displaying all plasmids
        @test = database->quick_select('Plasmid',{Obsolete => 0});
    }
    
    # Add some links
    for my $row (@test){
        my $ID = $row->{ID};
        $row->{href} = uri_for("/plasmid/$ID");
        $row->{Resistance} = join ' ',Biolab::Antibiotic->abbreviate($row->{Resistance});
        $row->{Keeper} = ucfirst $row->{Keeper};
        
        if ($row->{Parent}){
            my $parent = database->quick_select('Plasmid',{Name => $row->{Parent}});
            my $pID = $parent->{ID} || 0;
            $row->{phref} = uri_for("/plasmid/$pID");
        }
        
        if ($row->{Accession_NO}){
            $row->{ahref} = 'http://www.ncbi.nlm.nih.gov/nuccore/'.$row->{Accession_NO};
        }
        
        if ($row->{Map}){
            $row->{Map} = uri_for("/plasmid/$ID/map");
        }
        if ($row->{Sequence}){
            $row->{Sequence} = uri_for("/plasmid/$ID/sequence");
        }
        
        if ($row->{Carriers}) {
            my @carriers = split ' ', $row->{Carriers};
            for my $c (@carriers){
                my $car_record = database->quick_select('Strain',{Name => $c});
                my $car_id = $car_record->{ID};
                $row->{C}->{$c} = uri_for("/strain/$car_id");
            }
        }
        if ($row->{Daughters}){
            my @daughters = split ' ', $row->{Daughters};
            for my $d (@daughters){
                my $dau_record = database->quick_select('Plasmid',{Name => $d});
                my $dau_id = $dau_record->{ID};
                $row->{D}->{$d} = uri_for("/plasmid/$dau_id");
            }
        }
        # Turn new line into <br>
        if ($row->{Comments}){
            $row->{Comments} =~ s/\n/<br>/;
        }
    }
    return @test;
}

sub get_strain_list {
    
    # This sub is to get back a strain list, usually from a search.
    # It also add links to self/daughters/plasmids/parent.
    
    my %tokens = @_;
    my @test;
    if ($tokens{obsolete}){
        # From /obsolete
        @test = database->quick_select('Strain',{Obsolete => 1});
        
    }elsif ($tokens{user}){
        
        # From /myStrain
        @test = database->quick_select('Strain',{Keeper => $tokens{user}, Obsolete => 0});
    }elsif ($tokens{ids} || $tokens{names}){
        
        # From /mass_search
        if ($tokens{ids}){
            @test = database->quick_select('Strain',{ID => $tokens{ids}});
        }
        if ($tokens{names}){
            my @temp = database->quick_select('Strain',{Name => $tokens{names}});
            push @test, @temp;
        }

    }
    else{
        
        # For displaying all strains.
        @test = database->quick_select('Strain',{Obsolete => 0});
    }
    
    # Add some links now
    for my $row (@test){
        my $ID = $row->{ID};
        $row->{href} = uri_for("/strain/$ID");
        $row->{Resistance} = join ' ',Biolab::Antibiotic->abbreviate($row->{Resistance});
        $row->{Keeper} = ucfirst $row->{Keeper};
        $row->{Species} = Biolab::Species->abbreviate($row->{Species});
        
        if ($row->{Parent}){
            my $parent = database->quick_select('Strain',{Name => $row->{Parent}});
            my $pID = $parent->{ID} || 0;
            $row->{phref} = uri_for("/strain/$pID");
        }
        if ($row->{Accession_NO}){
            $row->{ahref} = 'http://www.ncbi.nlm.nih.gov/nuccore/'.$row->{Accession_NO};
        }
        
        # Parse plasmids
        
        if ($row->{Plasmids}){
            for my $p (split ' ',$row->{Plasmids}){
                my $p_record = database->quick_select('Plasmid', {Name => $p});
                my $pID = $p_record->{ID} || 0;
                $row->{p}{$p} = uri_for("/plasmid/$pID");
            }
            
        }
        if ($row->{Daughters}){
            my @daughters = split ' ', $row->{Daughters};
            for my $d (@daughters){
                my $dau_record = database->quick_select('Strain',{Name => $d});
                my $dau_id = $dau_record->{ID};
                $row->{D}->{$d} = uri_for("/strain/$dau_id");
            }
        }
        
        # Turn new line into <br>
        if ($row->{Comments}){
            $row->{Comments} =~ s/\n/<br>/;
        }

    }
    return @test;
    
}

sub get_max_id {
    my $type = shift;
    # Fetch max ID from plasmid database
    my $sql = "SELECT MAX(ID) AS ID FROM $type";
    my $sth = database->prepare($sql);
    $sth->execute;
    my $max = $sth->fetchrow_hashref;
    return $max->{ID};
}

sub check_parent {
    
    # This is to check parent field.
    #   Is the parent in the database?
    #   If it is a strain, does your species match with your parent?
    
    
    my $temp = shift;
    my %tokens = %$temp;
    
    my $err;
    my $par_name;
    if ($tokens{type} eq 'Plasmid'){
        
        # Current record is a plasmid
        # If id is passed here, it means this sub is called from 'edit'
        # If id is undef, it means the sub is called from 'add'
        my $return = $tokens{id} ? uri_for("/plasmid/$tokens{id}") : uri_for('/plasmid/add');
        
        my $par_record = database->quick_select('Plasmid', {Name => $tokens{parent}});
        
        if (!$par_record) {
            # Parent is not in the database. Let's throw some errors.
            
            $err .= qq{<p>Parent plasmid: "$tokens{parent}" does not exist!</p>
                <p>Parent plasmid has to be already in the database before you can modify this entry</p>
                <p><a href="$return">Return</a></p>
            }
        }else{
            
            # Checking is okay. Now correcting the case of parent name,
            #   so that it matches the parent's record.
            # For example, the parent's real name is pET22b,
            #   and you wrote it as pet22b just because you are lazy that day.
            # So it's better to return pET22b to auto-correct the case-error.
            
            $par_name = $par_record->{Name};
        }
        
    }elsif ($tokens{type} eq 'Strain'){
        
        # If id is passed here, it means this sub is called from 'edit'
        # If id is undef, it means the sub is called from 'add'
        my $return = $tokens{id} ? uri_for("/strain/$tokens{id}") : uri_for('/strain/add');
        
        my $par_record = database->quick_select('Strain', {Name => $tokens{parent}});
        
        if ($par_record){
            
            # Parent exists
            my $par_species = $par_record->{Species};
            
            unless ($tokens{species} eq $par_species){
                
                # Parent-daughter species don't match up with each other.
                # Let's throw an error.
                
                my $par_ID = $par_record->{ID};
                my $par_uri = uri_for("/strain/$par_ID");
                $err .= qq{
                    <p>Parent strain has a different Species setting!</p>
                    <p><a href="$par_uri">Parent strain Species</a>: $par_species</p>
                    <p>Current strain Species: $tokens{species}</p>
                    <p><a href="$return">Return to current entry</a></p>
                };
            }
            
            # Checking complete, no problem so far. Return parent's name.
            # For example, the parent's real name is pET22b,
            #   and you wrote it as pet22b just because you are lazy that day.
            # So it's better to return pET22b to auto-correct the case-error..
            
            $par_name = $par_record->{Name};
        }else{
            
            # Parent record doesn't exist in the database. Throw an error.
            $err .= qq{<p>Parent strain: "$tokens{parent}" does not exist!</p>
                <p>Parent strain has to be already in the database before you can modify this entry</p>
                <p><a href="$return">Return</a></p>
            }
        }
    }else{
        # You wouln't normally get here though.
        $err .= qq{<p>Unknown type! It has either be <em>Strain or Plasmid</em></p>};
    }
    return ($err,$par_name);

}

sub update_parent {
    
    # You add a parent, and it means the parent has a new daughter.
    # This sub's job is to add the new daughter to the parent's record.
    
    my $temp = shift;
    my %tokens = %$temp;
    my $cur_record = $tokens{id} ? database->quick_select($tokens{type}, {ID => $tokens{id}}) : undef;
    my $par_record = database->quick_select($tokens{type}, {Name => $tokens{parent}});
    
    # No $token{id}? it is from add, so need to change parent's daughter field
    # Has $token{id}, but its parent field is changed from the current entry?
    #       need to update parent's daughter field too
    unless ($tokens{id} and ($tokens{parent} eq $cur_record->{Parent})){
        
        # Delete current plasmid name from original record's parent's daughter's field.... er, do you get it?
        if ($cur_record->{Parent}){
            my $ori_parent_record = database->quick_select($tokens{type}, {Name => $cur_record->{Parent}});
            
            my $ori_daughters = $ori_parent_record->{Daughters};
            $ori_daughters =~ s/\b$tokens{name}\b ?//g;
            database->quick_update($tokens{type}, {ID => $ori_parent_record->{ID}}, {Daughters => $ori_daughters});
        }
        
        # Now adding current plasmid to updated record's parent's daughter's field.
        my $par_daughters = $par_record->{Daughters};
        $par_daughters .= " $tokens{name}" unless $par_daughters =~ /\b$tokens{name}\b/;
        database->quick_update($tokens{type}, {ID => $par_record->{ID}}, {Daughters => $par_daughters});
        
    }
}

sub draw_tree {
    
    # This is to draw the family tree.
    # It draws ancestors first using sub draw_parent,
    #   then completes the tree with sub draw_daughter
    my $cur_record = shift;
    my $type = shift;
    my $cur_uri = uri_for("/$type/$cur_record->{ID}");
    
    # Add hover title with construction info
    my $uri_title = $cur_record->{Construction};
    
    my $content = qq{
        <a href="$cur_uri" title="$uri_title"><font color = blue><b>$cur_record->{Name}</b></font></a>
    };
    
    # Draw ancestors first
    my $parent_content = draw_parent($cur_record,$type);
    $parent_content =~ s{(</li></ul>)} {$content\n$1};
    $content = $parent_content;
    
    # Then draw offspring
    my $daughter_content = draw_daughter($cur_record, $type);
    
    $content =~ s{(</li>)} {$daughter_content$1};

    return $content;
}

sub draw_parent {
    
    # This sub is to draw parent part of a family tree.
    # It is only called from 'draw_tree'.
    # Note, recursive structure applied.
    
    my $cur_record = shift;
    my $type = shift;
    
    if (! $cur_record->{Parent}){
        
        # Hitting top of the family tree.
        
        return '<ul><li>
        </li></ul>';
        
    }else{
        
        my $content;
        my $par_record = database->quick_select($type,{Name => $cur_record->{Parent}});
        my $cur_uri = uri_for("/$type/$par_record->{ID}");
        my $uri_title = $par_record->{Construction};
        my $this_par_content = qq{<a href="$cur_uri" title="$uri_title">$par_record->{Name}</a>
            <ul><li>
            </li></ul>};
        
        
        my $parent_content = draw_parent($par_record,$type);
        $parent_content =~ s{(</li></ul>)} {$this_par_content\n$1};
        $content = $parent_content;
        return $content;
    }
    
}

sub draw_daughter {
    
    # This sub is to draw offspring part of a family tree.
    # It is only called from 'draw_tree'.
    
    my $cur_record = shift;
    my $type = shift;
    
    if (!($cur_record->{Daughters} =~ /\w/)){
        
        # Hitting bottom of the line.
        return '';
        
    }else{
        my $content;
        
        # Drawing this daughters
        my $this_dau_content = qq{<ul>};
        my @daughters = split ' ', $cur_record->{Daughters};
        for my $dau (@daughters){
            my $dau_record = database->quick_select($type, {Name => $dau});
            my $dau_uri = uri_for("/$type/$dau_record->{ID}");
            my $uri_title = $dau_record->{Construction};
            $this_dau_content .= qq{<li>
<a href="$dau_uri" title="$uri_title">$dau</a>
};
            # Get all daughters' content
            $this_dau_content .= draw_daughter($dau_record,$type).'</li>';
        }
        $this_dau_content .= "</ul>";
        
        $content = $this_dau_content;
        
        return $content;
        
    }
}

sub update_daughter_species {
    
    # It is not possible to change a strain's species if it has a parent.
    
    # The only way to change species is to change it
    #   from the top record of the family tree, i.e. the 'root' record.
    
    # The parent check is done from the route handler.
    
    # When the strain modified is a root record,
    #   all of its offspring will inherit the changed species.
    # And this sub does that...
    
    my $root = shift;
    my @daughters = split ' ', $root->{Daughters};
    for my $dau (@daughters){
        database->quick_update('Strain',{Name => $dau},{Species => $root->{Species}});
        my $dau_record = database->quick_select('Strain',{Name => $dau});
        $dau_record->{Daughters} and update_daughter_species($dau_record);
    }
}
####### The end of all the subs.... ##################


hook before_template => sub {
    
    # Defining some commonly used urls in the templates.
    my $tokens = shift;
    
    $tokens->{'css_url'} = request->base . 'css/style.css';
    $tokens->{'login_url'} = uri_for('/login');
    $tokens->{'add_user_url'} = uri_for('/add_user');
    $tokens->{'home'} = uri_for('/');
    $tokens->{'logout_url'} = uri_for('/logout');
    $tokens->{'plasmid'} = uri_for('/plasmid/list');
    $tokens->{'plasmid_search'} = uri_for('/plasmid/search');
    $tokens->{'plasmid_add'} = uri_for('/plasmid/add');
    $tokens->{'my_plasmids'} = uri_for('/plasmid/myPlasmids');
    $tokens->{'strain_search'} = uri_for('/strain/search');
    $tokens->{'strain'} = uri_for('/strain/list');
    $tokens->{'strain_add'} = uri_for('/strain/add');
    $tokens->{'my_strains'} = uri_for('/strain/myStrains');
    $tokens->{'mass_edit'} = uri_for('/mass_edit');
    $tokens->{'change_keeper'} = uri_for('/change_keeper');
    $tokens->{'mass_search'} = uri_for('/mass_search');
    $tokens->{'p_custom'} = uri_for('/plasmid/custom_list');
    $tokens->{'s_custom'} = uri_for('/strain/custom_list');
    
    # Setting expiry timer. In seconds.
    if (session 'logged_in'){
        my $now = time;
        my $diff = $now - session 'start';
        context->destroy_session if $diff > 3600;
    }
    
};


get '/' => sub {
    template '/layouts/main.tt';
};


# Logging in
any ['get', 'post'] => '/login' => sub {
    my $err;
    my $user;

    
    
    if ( request->method() eq "POST" ) {

        my $name = lc params->{'username'};
        
        $user = Biolab::UserChecker->new (
            name => $name,
            password => params->{'password'},
        ) or die "Can't connect to database:$!";
        
        
        
        if ( !$user->exist ) {
            $err = "Invalid username";
        }
        elsif ( !$user->valid ) {
            $err = "Invalid password";
        }
        else {
            session 'logged_in' => true;
            session user => $name;
            session 'start' => time;
            my $path = params->{path};
            params->{path} = '/';
            redirect $path || '/';
        }
    }
    # display login form
    template 'login.tt', {
        err => $err,
        path => session 'requested_path',
    };
};


# Logging out
get '/logout' => sub {
    context->destroy_session;
    redirect '/';
};


# Add users. Enable it when needed.
=disable
any ['get', 'post'] => '/add_user' => sub {
    my $err;
    if ( request->method() eq "POST" ) {
        
        my $name = params->{'username'};
        my $user = Biolab::UserChecker->new (
            name => $name,
            password => params->{'password'},
        ) or die "Can't connect to database:$!";
        
        if ($user->exist){
            $err = "$name already exists";
        }
        
        elsif ($user->name && $user->password){
            $user->add_user;
            
            return redirect '/';
        }
        else {
            $err = 'Some invalid fields happened!';
        }
        
    }
    
    
    
    
    
    template 'add_user.tt',{
        'err' => $err,
    };
    
    
};
=cut


# The Plasmid real business


prefix '/plasmid';
 
get qr{/([\d]+)} => sub {
    # This is for displaying a single record of plasmid

    my ($ID) = splat;
    
    # This is the plasmid on flat-format from database

    my $record = database->quick_select('Plasmid',{ID => $ID});
    return 'Record does not exist!' unless $record;
    
    my $resistance = Biolab::Antibiotic->abbreviate($record->{Resistance});
    my $genotype = [split ' ', $record->{Genotype}];

    my $parent = database->quick_select('Plasmid', {Name => $record->{Parent}});
    
    # All nonexisting records are directed to /0.
    # But this is almost impossible to have a parent that isn't in the database now
    
    my $pID = $parent->{ID} || 0;
    
    # Adding some urls
    
    my $map = uri_for("/plasmid/$ID/map");
    my $seq = uri_for("/plasmid/$ID/sequence");
    my $acc_url = 'http://www.ncbi.nlm.nih.gov/nuccore/'.$record->{Accession_NO};
    $record->{phref} = uri_for("/plasmid/$pID");
    
    # Parse Carriers
    
    my %strains;
    
    if ($record->{Carriers}){
        for my $carrier (split ' ', $record->{Carriers}){
            my $carrier_record = database->quick_select('Strain', {Name =>   $carrier});
            my $sID = $carrier_record->{ID} || 0;
            $strains{$carrier} = uri_for("/strain/$sID");
        }
    }
    # Parse Daughters
    
    my %daughters;
    if ($record->{Daughters}){
        for my $d (split ' ', $record->{Daughters}){
            my $d_record = database->quick_select('Plasmid', {Name => $d});
            my $dID = $d_record->{ID} || 0;
            $daughters{$d} = uri_for("plasmid/$dID");
        }
    }
    
    
    # Checking if record keeper is the logged in user.
    # If yes, shows the edit button.
    
    my $allowed = (((session 'user') eq $record->{Keeper})
                or ((session 'user') eq 'logust'))
                ? 1
                : 0;
    
    # Now do some formatting...
    
    $record->{Keeper} = ucfirst $record->{Keeper};
    $record->{Constructor} = ucfirst $record->{Constructor};
    $record->{Recorder} = ucfirst $record->{Recorder};
    $record->{Comments} =~ s/\n/<br>/g;
    my $user = session 'user';
    
    template 'show_plasmid.tt', {
        'entries' => $record,
        'allowed' => $allowed,
        'resistance' => $resistance,
        'genotype' => $genotype,
        'carriers' => \%strains,
        'daughters' => \%daughters,
        'acc_url' => $acc_url,
        'map' => $map,
        'tree' => uri_for("/tree/p_$ID"),
        "sequence" => $seq,
    };
};

get '/myPlasmids' => sub {
    # This is myPlasmids session.
    # If the user's not logged in, it will display all plasmids
    
    my $user = session 'user';
    
    # Getting the displaying columns:
    #   Either defaults, or user's p_list
    
    my @defaults = qw/ Resistance Keeper Location Temperature Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;
    
    # Getting the list
    my @test = get_plasmid_list('user' => $user);
    
    
    
    template 'plasmid_list.tt', {
        "entries" => \@test,
        "display" => \@display_fields,
        "mine" => 1,
    };

    
};


get '/:id/map' => sub {
    
    # This is to draw plasmid map
    my $ID = param('id');
    my $map = database->quick_lookup('Plasmid',{ID => $ID},'Map');
    
    # Since the map is a binary data, has to be converted for web-display
    my $img = encode_base64($map);
    my $return = uri_for("/plasmid/$ID");
    template 'plasmid_map.tt', {
        'img' => $img,
        'return' => $return,
    }
};
get '/:id/sequence' => sub {
    # This is to get the plasmid sequence.
    # Currently it doesn't recognise any particular sequence format.
    # It shows whatever it was given.
    my $ID = param('id');
    my $seq = database->quick_lookup('Plasmid',{ID => $ID},'Sequence');
    # A single line of sequence?
    return qq{<textarea cols="100" rows="40" style="border:none">$seq</textarea>};
};

post '/:id/edit' => sub {
    
    # This is to display edit page.
    
    # Should have combined with edited.
    # But I'll keep it this way as it works with no problem.
    
    # Check login status
    if ( not session('logged_in') ) {
        send_error("Not logged in", 401);
    }
    
    # Get current record for editting.
    my $ID = param "id";
    my $record = database->quick_select('Plasmid',{ID => $ID});
    
    
    template 'plasmid_edit.tt', {
        'entries' => $record,
    };
    
};

post '/:id/edited' => sub {

    my $ID = param('id');
    
    if ( not session 'logged_in' ) {
        
        # Just in case...
        session 'requested_path' => uri_for("/plasmid/$ID");
        return redirect uri_for('/login');
    }

    my $record = database->quick_select('Plasmid' , {ID => $ID});
    my $name = $record->{Name};
    
    # $par_name is set to correct the case of parent name according to parent's entry's name
    my $par_name;
    
    # Checking if parent plasmid exists and do some updates
    if (param "Parent"){
        my $argu = {parent => (param "Parent"), name => $name, type => 'Plasmid', id => $ID};
        my $err;
        ($err,$par_name) = check_parent($argu);
        return $err if $err;
        
        # No problems? do the parent update.
        update_parent($argu);
    }
    
    # Do some formatting...
    my $resistance = join ' ', Biolab::Antibiotic->populate(lc param "Resistance");
    my $genotype = join ' ', (split ' ', param "Genotype");
    my $other_names = join ' ', (split ' ', param "Other_names");
    my $map = request->upload('map');
    $map = $map ? $map->content : database->quick_lookup('Plasmid',{ID => $ID},'Map');
    
    # Do the actual update
    database->quick_update('Plasmid', {ID => $ID},
    {
        Other_names => $other_names,
        Accession_NO => (uc param "Accession_NO"),
        Temperature => (param "Temperature"),
        Obsolete => (param "Obsolete"),
        Copy_number => (lc param "Copy_number"),
        Size => (param "Size"),
        Blue_white => (param "Blue_white"),
        Keeper => (lc param "Keeper"),
        Location => (param "Location"),
        Arrival_time => (param "Arrival_time"),
        Parent => $par_name,
        Genotype => $genotype,
        Reference => (param "Reference"),
        Constructor => (param "Constructor"),
        Construction => (param "Construction"),
        Comments => (param "Comments"),
        Map => $map,
        Sequence => (param "Sequence"),
        Resistance => $resistance,
    },
    );
    my $home = uri_for ('/');
    my $edited = uri_for ("/plasmid/$ID");
    
    template 'success.tt',{
        'edited' => $edited,
        'type' => 'Plasmid',
        'action' => 'edited',
    }
};

any ['get','post'] => '/add' => sub {
    
    # Do a login check
    if ( not session 'logged_in' ) {

        session 'requested_path' => uri_for('/plasmid/add');
        return redirect uri_for ('/login');
    }
    if ( request->method() eq "POST" ) {
        # Form submitted.
        
        # Let's do a login check one more time.
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/plasmid/add');
            return redirect uri_for ('/login');
        }
        my $ID = param "ID";
        my $report;
        
        # Check if the plasmid already exists.
        my $Plasmid_Name = param "Plasmid_Name";
        my $query = database->quick_select('Plasmid',{Name => $Plasmid_Name});
        if (my $query_id = $query->{ID}){
            my $link = uri_for ("/plasmid/$query_id");
            my $return = uri_for('/plasmid/add');
            return qq{
                <p>Plasmid name: <em>$Plasmid_Name</em> already exists!</p>
                <p>It is:<a href="$link">CFS_P$query_id</a><p>
                <p><a href="$return">Return</a></p>
            };
        }
        
        
        
        # Do some formatting...
        my $resistance = join ' ', Biolab::Antibiotic->populate(lc param "Resistance");
        my $genotype = join ' ', (split ' ', param "Genotype");
        my $keeper = (lc param "Keeper") || (session 'user');
        my $arrival = param "Arrival_time";
        my $other_names = join ' ', (split ' ', param "Other_names");
        my $map = request->upload('Map');
        $arrival !~ /\d+/ and $arrival = DateTime->now->ymd('-');
        
        # Checking if parent plasmid exists
        my $par_name;
        if (param "Parent"){
            my $argu = {parent => (param "Parent"), name => $Plasmid_Name, type =>'Plasmid'};
            my $err;
            ($err,$par_name)= check_parent($argu);
            return $err if $err;
            
            # No problem? do the parent update
            
            update_parent($argu);
        }

        # Do the record insert
        database->quick_insert('Plasmid',
        {
            Name => (param "Plasmid_Name"),
            Other_names => $other_names,
            Accession_NO => (param "Accession_NO"),
            Temperature => (param "Temperature"),
            Obsolete => (param "Obsolete"),
            Copy_number => (lc param "Copy_number"),
            Size => (param "Size"),
            Blue_white => (param "Blue_white"),
            Keeper => $keeper,
            Location => (param "Location"),
            Arrival_time => $arrival,
            Parent => $par_name,
            Genotype => $genotype,
            Reference => (param "Reference"),
            Constructor => (param "Constructor"),
            Construction => (param "Construction"),
            Comments => (param "Comments"),
            Sequence => (param "Sequence"),
            Map => $map,
            Resistance => $resistance,
            Recorder => (session 'user'),
        },
        );
        
        # Display a successful page.
        my $home = uri_for ('/');
        my $added = uri_for ("/plasmid/$ID");
        
        template 'success.tt',{
            'edited' => $added,
            'type' => 'Plasmid',
            'action' => 'added',
        };
        
    }else{
        # Displaying /add page.
        
        # Getting the filled information
        my %filled = params;
        
        # Try to prefill some fields if parent is given.
        my $parent_name = $filled{ParentName};
        my $parent = {};
        if ($parent_name) {
            $parent = database->quick_select('Plasmid',{Name => $parent_name});
        }
        
        # Get the CFS_P ID.
        # Note the actual ID might be different as shown here,
        #   as someone else might add a record faster than you.
        my $ID = get_max_id('Plasmid') + 1;
        
        # Blue white is a bit tricky, so I do the math here.
        my $bw = $filled{'BlueWhite'} || $parent->{Blue_white};
        
        # Resistance mapping as always.
        
        my $resistance = (lc $filled{Resistance}) || $parent->{Resistance};
        $resistance = Biolab::Antibiotic->abbreviate($resistance) || [];
        my $res = join ' ', @$resistance;
        
        # Resistance from the database has some weird chars in it... Get rid of them!
        $res =~ s/[^a-zA-Z0-9 ]*//g;
        
        template 'add_plasmid.tt', {
            "ID" => $ID,
            "parent" => $parent_name,
            "entries" => $parent,
            "filled" => \%filled,
            "bw" => $bw,
            "resistance" => $res,
        };

    }
    
};

get '/list' => sub {
    # This is to get all plasmid as a list
    
    # Getting the columns to display
    my @defaults = qw/ Resistance Keeper Location Temperature Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;
    
    # Get the list
    my @test = get_plasmid_list();
    
    # Display the list
    template 'plasmid_list.tt', {
        "entries" => \@test,
        'display' => \@display_fields,
    };
};

any ['get','post'] => '/custom_list' => sub {
    # This is to customise what columns the plasmid list should display
    # It will push the customised info as p_list into users's table.
    
    # Do some log status check.
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/plasmid/add');
        return redirect uri_for ('/login');
    }
    if ( request->method() eq "POST" ) {
        
        # Do again log status check.
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/plasmid/add');
            return redirect uri_for ('/login');
        }
        
        my @selected = split ' ', param "chosen";
        
        # Update user's p_list
        
        database->quick_update('users', {name => session 'user'}, {p_list => join ',', @selected});
        
        template 'success.tt';
        
    }
    # Getting content
    else{
        # Note that ID and Plasmid_Name should always be displayed.
        # Getting user's current preference, if there's one. Else, use defaults
        my @defaults = qw/ Resistance Keeper Location Temperature Parent/;
        my $display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
        my @display_fields = $display_fields? split ',', $display_fields : @defaults;
        
        # Getting all fields
        my @all = sort keys %{database->quick_select('Plasmid',{ID => 1})};
        
        @all = grep {!(($_ eq 'ID') || ($_ eq 'Name'))} @all;
        @all = grep {!($_ ~~ @display_fields)} @all;
        
        # Get rid of ID and Plasmid_Name
        
        
        template 'custom_list.tt', {
            'class' => 'plasmid',
            'display' => \@display_fields,
            'all' => \@all,
        };
    }
    
};

any ['get','post'] => '/search' => sub {
    if ( request->method() eq "POST" ) {
        my %filled = params;
        
        # Delete useless keys
        delete $filled{$_} for qw/_submit _submitted/;
        
        # Delete empty keys
        for my $key (keys %filled){
            delete $filled{$key} unless $filled{$key};
        }
        
        # Do a bit of formatting
        $filled{Resistance} and $filled{Resistance} = join ' ',Biolab::Antibiotic->populate(lc $filled{Resistance});
        
        # Format the 'like' fields.
        my @likes = qw/Other_names Comments Reference Genotype Resistance Location Daughters/;
        for my $like (@likes){
            $filled{$like} and $filled{$like} = {'like' => '%'.$filled{$like}.'%'};
        }
        
        # Do the actual search
        my @matches = database->quick_select('Plasmid',{%filled, Obsolete => 0});
        
        # Formatting and adding links..
        for my $row (@matches){
            my $ID = $row->{ID};
            $row->{href} = uri_for("/plasmid/$ID");
            $row->{Resistance} = join ' ',Biolab::Antibiotic->abbreviate($row->{Resistance});
            $row->{Keeper} = ucfirst $row->{Keeper};
            
            if ($row->{Parent}){
                my $parent = database->quick_select('Plasmid',{Name => $row->{Parent}});
                my $pID = $parent->{ID} || 0;
                $row->{phref} = uri_for("/plasmid/$pID");
            }
            if ($row->{Carriers}) {
                my @carriers = split ' ', $row->{Carriers};
                for my $c (@carriers){
                    my $car_record = database->quick_select('Strain',{Name => $c});
                    my $car_id = $car_record->{ID};
                    $row->{C}->{$c} = uri_for("/strain/$car_id");
                }
            }
            if ($row->{Daughters}){
                my @daughters = split ' ', $row->{Daughters};
                for my $d (@daughters){
                    my $dau_record = database->quick_select('Plasmid',{Name => $d});
                    my $dau_id = $dau_record->{ID};
                    $row->{D}->{$d} = uri_for("/plasmid/$dau_id");
                }
            }

        }
        
        # Getting list columns to display
        
        my @defaults = qw/ Resistance Keeper Location Temperature Parent/;
        my $display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
        my @display_fields = $display_fields ? split ',', $display_fields : @defaults;

        # Display the content
        template 'plasmid_list.tt', {
            "display" => \@display_fields,
            "entries" => \@matches,
        };
    }else {
        # Displaying /search page
        template 'plasmid_search.tt';
    }
};

get '/obsolete' => sub {
    # This is the junk yard
    
    my @defaults = qw/ Resistance Keeper Location Temperature Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;

    my @test = get_plasmid_list('obsolete' => 1);
    template 'plasmid_list.tt', {
        "entries" => \@test,
        "display" => \@display_fields,
    };
};

any ['get','post'] => '/mass_add' => sub {
    # This allows entry-add in batch
    
    # Do some log status check.
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/plasmid/mass_add');
        return redirect uri_for ('/login');
    }
    
    # Define fields
    my @fields = qw/ Name Other_names Accession_NO Resistance Parent Size Copy_number Genotype Temperature Blue_white Keeper Arrival_time Constructor Construction Location Reference Comments Sequence/;
    
    if ( request->method() eq "POST" ) {
        # Check again log status.
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/plasmid/mass_add');
            return redirect uri_for ('/login');
        }
        
        # All errors go here
        my $total_err;
        
        # All successes go here
        my $success;
        
        # Gather all the data in %all
        my @data = split ',',param "data_holder";
        my %all;
        
        my $length = @fields;
        for my $cell (0..($length-1)){
            for (my $i=$cell+$length; $i<@data+$length-1; $i += $length){
                push @{$all{$data[$cell]}}, $data[$i];
            }
        }
        
        # Correct Blue_white field
        for my $bw (@{$all{Blue_white}}){
            $bw =~ s/^(y|Y).*/yes/;
            $bw =~ s/[^(yes)]//g;
        }

        
        if (! $all{Name}){
            # No plasmid name?
            return "Error, no Plasmid Name!";
        }else{
            my @parents;
            # Recording
            while (my $p = ${$all{Name}}[0]){
                my $err;
                my $parent;
                 # Check if plasmid_name starts with p
                if ($p !~ /^p/){
                    $err .= qq{<p> The record for <b>$p</b> is not recorded, because $p does not look like a plasmid name </p>};
                }
                # Check if Plasmid already exists in database
                elsif (my $id = database->quick_lookup('Plasmid',{Name => $p},'ID')){
                    my $uri = uri_for("/plasmid/$id");
                    $err .= qq{<p> The record for <b>$p</b> is not recorded, because $p already exists in the Plasmid database:<a href="$uri">CFS_P$id</a></p>};
                }else{
                    # Check if parent exists
                    if ($parent = ${$all{Parent}}[0]){
                        
                        # First check if it is in the mass_add Plasmid_Name field
                        my $exist;
                        for my $names (@{$all{Name}}){
                            if ($names =~ /\b($parent)\b/i){
                                $parent = $1;
                                $exist = 1;
                            }
                        }
                        
                        # If it's not in the mass_add, check the plasmid database
                        if (!$exist){
                            my $par_name = database->quick_lookup('Plasmid', {Name => $parent},'Name');
                            if ($par_name){
                                $parent = $par_name;
                                $exist = 1;
                            }
                        }
                        $err.= qq{<p> The record for <b>$p</b> is not recorded, because parent of $p ($parent) did not make it to the Plasmid database </p>} unless $exist;
                    }
                }
                if ($err){
                    $total_err .= $err;
                    # Get rid of this row of records
                    for my $key (keys %all){
                        shift @{$all{$key}};
                    }
                }else{
                    # So far so good, lets do the recording
                    my %data;
                    for my $key (keys %all){
                        $data{$key} = shift @{$all{$key}};
                    }
                    # Setting some defaults:
                    $data{Recorder} ||= session 'user';
                    $data{Keeper} ||= session 'user';
                    
                    # Correct parent:
                    $parent and $data{Parent} = $parent;
                    
                    # Formatting resistance field:
                    if ($data{Resistance}){
                        $data{Resistance} = join ' ', Biolab::Antibiotic->populate(lc $data{Resistance});
                    }
                    
                    # Update the database
                    database->quick_insert('Plasmid', \%data);
                    $success .= qq{<p><b>$p</b> is successfully recorded</p>};
                    
                    # Remember parents
                    if ($data{Parent}){
                        push @parents, {'name' => $p, 'parent' => $data{Parent}};
                    }
                        
                    }
                }
            # Do the parent update
            while (my $par = shift @parents){
                my $argu = {parent => $par->{parent}, name => $par->{name}, type => 'Plasmid'};
                update_parent($argu);
            }
            
        }
        
        # Display all the errors and successes
        template 'success.tt', {
            'content' => $total_err.$success,
        };
        
    }
    # Getting content
    else {
        my $fields = join ' ', @fields;
        
        template 'mass_add.tt', {
            'type' => 'plasmid',
            'entries' => $fields,
        }
    }

};

############# End of plasmid   ################
############# Start of strain  ################


prefix '/strain';

get qr{/([\d]+)} => sub {
    # This is for displaying a single strain record
    
    # Getting ID
    my ($ID) = splat;
 
    my $record = database->quick_select('Strain',{ID => $ID});
    return 'Record does not exist!' unless $record;
    
    # Do some formatting and add some links
    my $resistance = Biolab::Antibiotic->abbreviate($record->{Resistance});
    my $genotype = [split ' ', $record->{Genotype}];
    my $species = Biolab::Species->abbreviate($record->{Species});
    my $parent = database->quick_select('Strain',{Name => $record->{Parent}});
    my $pID = $parent->{ID} || 0;
    $record->{phref} = uri_for("/strain/$pID");
    
    # Parse plasmids
    
    my %plasmids;
    
    if ($record->{Plasmids}){
        for my $p (split ' ', $record->{Plasmids}){
            my $p_record = database->quick_select('Plasmid', {Name => $p});
            my $pID = $p_record->{ID} || 0;
            $plasmids{$p} = uri_for("/plasmid/$pID");
        }
    }
    
    # Parse daughters
    
    my %daughters;
    if ($record->{Daughters}){
        for my $d (split ' ', $record->{Daughters}){
            my $d_record = database->quick_select('Strain', {Name => $d});
            my $dID = $d_record->{ID} || 0;
            $daughters{$d} = uri_for("strain/$dID");
        }
    }

    
    # Checking if record keeper is the logged in user.
    # If yes, show 'edit' button
    
    my $allowed = (((session 'user') eq $record->{Keeper})
    or ((session 'user') eq 'logust'))
    ? 1
    : 0;
    
    # Formatting again
    $record->{Keeper} = ucfirst $record->{Keeper};
    $record->{Constructor} = ucfirst $record->{Constructor};
    $record->{Recorder} = ucfirst $record->{Recorder};
    $record->{Comments} =~ s/\n/<br>/g;
    $acc_url = 'http://www.ncbi.nlm.nih.gov/nuccore/'.$record->{Accession_NO};
    
    # Show the record
    template 'show_strain.tt', {
        'entries' => $record,
        'acc_url' => $acc_url,
        'allowed' => $allowed,
        'resistance' => $resistance,
        'genotype' => $genotype,
        'species' => $species,
        'plasmids' => \%plasmids,
        'daughters' => \%daughters,
        'tree' => uri_for("/tree/s_$ID"),
    };

};
 
post '/:id/edit' => sub {
    
    # Check log in status
    if ( not session 'logged_in' ) {
        send_error("Not logged in", 401);
    }
    my $ID = param 'id';
    my $record = database->quick_select('Strain', {ID => $ID});
    
    # Show the /edit page
    template 'strain_edit.tt', {
        'entries' => $record,
    };
    
};

post '/:id/edited' => sub {
    # Form submitted from /edit
    # Check log status again
    if ( not session 'logged_in' ) {
        return redirect uri_for ('/');
    }
    my $ID = param('id');
    
    # Checking the parent's species info:
    my $return = uri_for("/strain/$ID");
    
    my $species = Biolab::Species->populate(ucfirst param "Species");
    
    my $query = database->quick_select('Strain', {ID => $ID});
    my $strain_name = $query->{Name};
    
    # Checking if parent strain exists and if the species inherits
    my $par_name;
    if (param "Parent"){
        my $err;
        ($err,$par_name) = check_parent({parent => (param "Parent"), name => $strain_name, type => 'Strain', species => $species, id => $ID});
        return $err if $err;
    }
    
    # Checking Plasmids and do auto updates.
    my @plasmids = split ' ', param "Plasmids";
    my $plasmids = join ' ', @plasmids;
    
    
    unless ($plasmids eq $query->{Plasmids}){
        # Meaning there's a change in the field. Need to check first!
        my $err;
        my @queries;
        for my $p (@plasmids){
            my $p_query = database->quick_select('Plasmid', {Name => $p});
            $err .= "<p>$p doesn't exist in the Plasmid database!</p>" unless $p_query;
            push @queries, $p_query;
            
            # Correct the plasmid case
            
            $p = $p_query->{Name};
        }
        if ($err){
            $err .="<p>Please add the plasmid(s) in the Plasmid database before adding this entry.</p>";
            return qq{
                $err
                <p><a href="$return">Return</a></p>
            };
        }
        # If everything's fine, do the updates!
        my $strain_name = $query->{Name};
        
        # Delete Carrier from deleted plasmid
        my $del_plasmids = $query->{Plasmids};
        
        for my $p (@plasmids){
            $del_plasmids =~ s/$p//;
        }
        
        for my $d (split ' ', $del_plasmids) {
            my $d_query = database->quick_select('Plasmid', {Name => $d});
            my $carriers = $d_query->{Carriers};
            $carriers =~ s/\b$strain_name\b ?//;
            database->quick_update('Plasmid', {ID => ($d_query->{ID})}, {Carriers => $carriers});
        }
        
        # Now add the new ones
        
        for my $q (@queries){
            my $carriers = $q->{Carriers};
            unless ($carriers =~ /\b$strain_name\b/){
                $carriers .= " $strain_name";
                database->quick_update('Plasmid', {ID => ($q->{ID})}, {Carriers => $carriers});
            }
        }
    }
    
    #Now lets update the parent strain.
    update_parent({parent => (param "Parent"), name => $strain_name, type => 'Strain', species => $species, id => $ID});
    
    
    
    my $report;
    # Do some formatting...
    my $resistance = join ' ', Biolab::Antibiotic->populate(lc param "Resistance");
    my $genotype = join ' ', (split ' ', param "Genotype");
    my $other_names = join ' ', (split ' ', param "Other_names");

    database->quick_update('Strain', {ID => $ID},
    {
        Other_names => $other_names,
        Accession_NO => (param "Accession_NO"),
        Temperature => (param "Temperature"),
        Obsolete => (param "Obsolete"),
        Constructor => (param "Constructor"),
        Keeper => (lc param "Keeper"),
        Location => (param "Location"),
        Species => $species,
        Arrival_time => (param "Arrival_time"),
        Parent => $par_name,
        Plasmids => (param "Plasmids"),
        Genotype => $genotype,
        Reference => (param "Reference"),
        Construction => (param "Construction"),
        Comments => (param "Comments"),
        Resistance => $resistance,
        Isolated_from => (param "Isolated_from"),
        Geographic_location => (param "Geographic_location"),
    },
    );
    
    # If there's a change in species, and current strain is a root strain (no parent), and it has daughters, then do the species update on all daughters.
    if (!$par_name and $query->{Daughters} and ($query->{Species} ne $species)){
        # change $query's species field to the new one
        
        $query->{Species} = $species;
        update_daughter_species($query);
    }
    my $home = uri_for ('/');
    my $edited = uri_for ("/strain/$ID");
    template 'success.tt', {
        'edited' => $edited,
        'type' => 'Strain',
        'action' => 'edited',
    };
};

any ['get','post'] => '/add' => sub {
    # This is to add a strain entry
    
    # Checking log in status
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/strain/add');
        return redirect uri_for ('/login');
    }
    if ( request->method() eq "POST" ) {
        # Form is submitted
        
        # Let's check log status again
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/strain/add');
            return redirect uri_for ('/login');
        }
        my $ID = param "ID";
        my $report;
        my $return = uri_for ("/strain/add");
        
        # Check if the strain name already exists
        my $Strain_Name = param "Strain_Name";
        my $query = database->quick_select('Strain',{Name => $Strain_Name});
        if (my $query_id = $query->{ID}){
            my $link = uri_for ("/strain/$query_id");
            return qq{
                <p>Strain name: <em>$Strain_Name</em> already exists!</p>
                <p>It is:<a href="$link">CFS_S$query_id</a></p>
                <p><a href="$return">Return</a></p>
            };
        }
        
        # Check parent's species if the same as the current's species
        my $species = Biolab::Species->populate(ucfirst param "Species");
        
        # Checking if parent strain exists and if the species inherits
        my $par_name;
        if (param "Parent"){
            my $err;
            ($err,$par_name)= check_parent({parent => (param "Parent"), name => $Strain_Name, type => 'Strain', species =>$species});
            return $err if $err;
        }
        
        # Check if any of the plasmids not in the plasmid database
        my @plasmids = split ' ', param "Plasmids";
        my $err;
        for my $p (@plasmids){
            my $p_record = database->quick_select('Plasmid', {Name => $p});
            if ($p_record){
                # Add plasmid's carrier's field
                my $carriers = $p_record->{Carriers};
                
                # Do a simple check. Normally this won't happen since Carrier's field cannot be tempered from the Plasmid database.
                return "Unexpected error, $Strain_Name already exists as a carrier for $p" if $carriers =~ /\b$Strain_Name\b/;
                
            }else{
                $err .= "<p>$p doesn't exist in the Plasmid database!</p>";
            }
        }
        
        # If there's an error, throw it.
        if ($err){
            $err .="<p>Please add the plasmid(s) in the Plasmid database before adding this entry.</p>";
            return qq{
                $err
                <p><a href="$return">Return</a></p>
            };
        }
        # No error so far...
        # Update plasmids
        for my $p (@plasmids){
            my $p_record = database->quick_select('Plasmid', {Name => $p});
            my $carriers = $p_record->{Carriers};
            $carriers .= " $Strain_Name";
            database->quick_update('Plasmid', {ID => ($p_record->{ID})}, {Carriers => $carriers});
        }
        
        # Now lets update the parent strain
        
        update_parent({parent => (param "Parent"), name => $Strain_Name, type => 'Strain', species =>$species});
        
        
        # Do some formatting...
        my $resistance = join ' ', Biolab::Antibiotic->populate(lc param "Resistance");
        my $plasmids = join ' ', @plasmids;
        my $genotype = join ' ', (split ' ', param "Genotype");
        my $keeper = (lc param "Keeper") || (session 'user');
        my $arrival = param "Arrival_time";
        my $other_names = join ' ', (split ' ', param "Other_names");
        $arrival !~ /\d+/ and $arrival = DateTime->now->ymd('-');
        
        # Insert the new row into database
        database->quick_insert('Strain',
        {
            ID => $ID,
            Name => (param "Strain_Name"),
            Other_names => $other_names,
            Accession_NO => (param "Accession_NO"),
            Isolated_from => (param "Isolated_from"),
            Geographic_location => (param "Geographic_location"),
            Temperature => (param "Temperature"),
            Obsolete => (param "Obsolete"),
            Species => $species,
            Plasmids => $plasmids,
            Constructor => (param "Constructor"),
            Keeper => $keeper,
            Location => (param "Location"),
            Arrival_time => $arrival,
            Parent => $par_name,
            Genotype => $genotype,
            Reference => (param "Reference"),
            Construction => (param "Construction"),
            Comments => (param "Comments"),
            Resistance => $resistance,
            Recorder => (session 'user'),
        },
        );
        
        # Show a success page
        my $home = uri_for ('/');
        my $added = uri_for ("/strain/$ID");
        return qq{
            <p>Update successful.</p>
            <p>Arrivaltime:$arrival</p>
            <p><a href="$home">Home</a></p>
            <p><a href="$added">Strain added</a></p>
        };
        
    }else{
        
        # This is the 'Get' content
        
        # Getting filled info
        my %filled = params;
        
        # Parent's been filled?
        # Let's do some automatic fill in some relevant fields.
        
        my $parent_name = $filled{ParentName};
        my $parent = {};
        if ($parent_name) {

            $parent = database->quick_select('Strain',{Name => $parent_name});
        }
        
        # Get the CFS_S ID.
        my $ID = get_max_id('Strain') + 1;
        
        
        # Resistance mapping as always.
        
        my $resistance = (lc $filled{Resistance}) || $parent->{Resistance};
        $resistance = Biolab::Antibiotic->abbreviate($resistance) || [];
        my $res = join ' ', @$resistance;
        
        # Resistance from the database has some weird chars in it... Get rid of them!
        $res =~ s/[^a-zA-Z0-9 ]*//g;
        
        template 'add_strain.tt', {
            "ID" => $ID,
            "parent" => $parent_name,
            "entries" => $parent,
            "filled" => \%filled,
            "resistance" => $res,
        };
    
    }
    
};

get '/list' => sub {
    # This is to list all strains.
    
    # Getting columns to display
    my @defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;
    
    # Getting the actual list
    my @test = get_strain_list();
    template 'strain_list.tt', {
        "entries" => \@test,
        "display" => \@display_fields,
    };
};

get '/myStrains' => sub {
    
    # This is to display a list of strains kept by the user.
    # If not logged in, then show all the strains.
    
    my $user = session 'user';
    
    # Getting the columns to display
    my @defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;
    
    # Getting the actual list
    my @test = get_strain_list('user' => $user);
    template 'strain_list.tt', {
    "entries" => \@test,
    "display" => \@display_fields,
    "mine" => 1,
    };

};

any ['get','post'] => '/custom_list' => sub {
    # This is to customise what columns the plasmid list should display
    # It will push the customised info as p_list into users's table.
    
    # Do some log status check.
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/strain/custom_list');
        return redirect uri_for ('/login');
    }
    if ( request->method() eq "POST" ) {

        # Do again log status check.
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/strain/custom_list');
            return redirect uri_for ('/login');
        }
        
        my @selected = split ' ', param "chosen";
        
        # Update user's p_list
        
        database->quick_update('users', {name => session 'user'}, {s_list => join ',', @selected});
        
        template 'success.tt';
        
    }
    # Getting content
    else{
        # Note that ID and Strain_Name should always be displayed.
        # Getting user's current preference, if there's one. Else, use defaults
        my @defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
        my $display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
        my @display_fields = $display_fields? split ',', $display_fields : @defaults;
        
        # Getting all fields
        my @all = sort keys %{database->quick_select('Strain',{ID => 1})};
        
        @all = grep {!(($_ eq 'ID') || ($_ eq 'Name'))} @all;
        @all = grep {!($_ ~~ @display_fields)} @all;
        
        # Get rid of ID and Strain_Name
        
        
        template 'custom_list.tt', {
            'class' => 'strain',
            'display' => \@display_fields,
            'all' => \@all,
        };
    }
    
};

any ['get','post'] => '/search' => sub {
    # This is to search for a strain.
    
    if ( request->method() eq "POST" ) {
        
        # Getting all the filled info
        my %filled = params;
        
        # Get rid of useless keys and empty keys
        delete $filled{$_} for qw/_submit _submitted/;
        for my $key (keys %filled){
            delete $filled{$key} unless $filled{$key};
        }
        
        # Do a bit of formatting
        $filled{Resistance} and $filled{Resistance} = join ' ',Biolab::Antibiotic->populate(lc $filled{Resistance});
        $filled{Species} and $filled{Species} = Biolab::Species->populate(ucfirst $filled{Species});
        
        # Formatting the 'like' fields.
        my @likes = qw/Other_names Isolated_from Geographic_location Comments Reference Genotype Resistance Location Daughters Species Plasmids/;
        for my $like (@likes){
            $filled{$like} and $filled{$like} = {'like' => '%'.$filled{$like}.'%'};
        }
        
        # The actual search
        my @matches = database->quick_select('Strain',{%filled, Obsolete => 0});
        
        # Do some formatting and add some links
        for my $row (@matches){
            my $ID = $row->{ID};
            $row->{href} = uri_for("/strain/$ID");
            $row->{Resistance} = join ' ',Biolab::Antibiotic->abbreviate($row->{Resistance});
            $row->{Species} = Biolab::Species->abbreviate($row->{Species});
            $row->{Keeper} = ucfirst $row->{Keeper};
            
            if ($row->{Parent}){
                my $parent = database->quick_select('Strain',{Name => $row->{Parent}});
                my $pID = $parent->{ID} || 0;
                $row->{phref} = uri_for("/strain/$pID");
            }
            if ($row->{Plasmids}){
                for my $p (split ' ',$row->{Plasmids}){
                    my $p_record = database->quick_select('Plasmid', {Name => $p});
                    my $pID = $p_record->{ID} || 0;
                    $row->{p}{$p} = uri_for("/plasmid/$pID");
                }
                
            }
            if ($row->{Daughters}){
                my @daughters = split ' ', $row->{Daughters};
                for my $d (@daughters){
                    my $dau_record = database->quick_select('Strain',{Name => $d});
                    my $dau_id = $dau_record->{ID};
                    $row->{D}->{$d} = uri_for("/strain/$dau_id");
                }
            }

        }
        
        # Getting columns to display
        
        my @defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
        my $display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
        my @display_fields = $display_fields ? split ',', $display_fields : @defaults;

        
        template 'strain_list.tt', {
            "entries" => \@matches,
            "display" => \@display_fields,
        };
    }else {
        
        template 'strain_search.tt';
    }
};

get '/obsolete' => sub {
    
    # This is the junk yard
    
    my @defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
    my $display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
    my @display_fields = $display_fields ? split ',', $display_fields : @defaults;
    
    my @test = get_strain_list('obsolete' => 1);
    template 'strain_list.tt', {
        "entries" => \@test,
        "display" => \@display_fields,
    };
};

any ['get','post'] => '/mass_add' => sub {
    # Do a batch add in one go
    
    # Do some log status check.
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/strain/mass_add');
        return redirect uri_for('/login');
    }
    
    # These are all the fields to display on the page
    my @fields = qw/ Name Other_names Accession_NO Isolated_from Geographic_location Species Parent Plasmids Genotype Resistance Temperature Keeper Arrival_time Constructor Construction Location Reference Comments Sequence/;
    
    if ( request->method() eq "POST" ) {
        # Check again log status.
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/strain/mass_add');
            return redirect uri_for('/login');
        }
        
        # All the errors come here
        my $total_err;
        
        # All the success entries come here
        my $success;
        
        # All the data are stored in %all
        my @data = split ',',param "data_holder";
        my %all;
        
        for my $cell (0..(@fields-1)){
            for (my $i=$cell+@fields; $i<@data+@fields-1; $i += @fields){
                push @{$all{$data[$cell]}}, $data[$i];
            }
        }
 
        if (! $all{Name}){
            return "Error, no Strain Name!";
        }else{
            my (@plasmids,$first_fail);
            my $size = @{$all{Name}};
            # Recording
            while (my $s = ${$all{Name}}[0]){
                my $err;
                my $parent;
                # Check if Strain already exists in database
                if (my $id = database->quick_lookup('Strain',{Name => $s},'ID')){
                    my $uri = uri_for("/strain/$id");
                    $err .= qq{<p> The record for <b>$s</b> is not recorded, because $s already exists in the Strain database:<a href="$uri">CFS_S$id</a></p>};
                }else{

                    # Check if plasmids exist
                    
                    if (@plasmids = split ' ', ${$all{Plasmids}}[0]){
                        for my $plasmid (@plasmids){
                            my $p_record = database->quick_select('Plasmid', {Name => $plasmid});
                            if ($p_record){
                                my $carriers = $p_record->{Carriers};
                                
                                # Do a simple check. Normally this won't happen since Carrier's field cannot be tempered from the Plasmid database.
                                return "Unexpected error, $s already exists as a carrier for $s" if $carriers =~ /\b$s\b/;
                                $plasmid = $p_record->{Name};

                            }else{
                                $err .= "<p>Update of <b>$s</b> failed <br>$plasmid doesn't exist in the Plasmid database!</p>";
                            }

                        }
                    }
                    # Check if parent exists and species correct.
                    # Species check is tedious, given its tree like structure.
                    # Everything in the database should be ok, so the logic is:
                    #   if no parent, pass
                    #   else if parent in database, check species. If current species' field is empty, update it.
                    #       If different, call error and throw the record away.
                    #   else (since the parent might be in the add list, not yet in the database), shift and push
                    #       to the end of the arrays
                    #   If next meeting the same record, and the array's size doesn't change, stop, and throw
                    #       everything left. This is to prevent "circular reference" issue.
                    if ($parent = ${$all{Parent}}[0]){
                        my $exist;
                        
                        my $par_record = database->quick_select('Strain', {Name => $parent});
                        if ($par_record){
                            # Check if species is correct. Empty is also good, since it can inherit.
                            $exist = 1;
                            ${$all{Species}}[0] ||= $par_record->{Species};
                            ${$all{Species}}[0] = Biolab::Species->populate(ucfirst ${$all{Species}}[0]);
                            
                            if (${$all{Species}}[0] eq $par_record->{Species}){
                                $parent = $par_record->{Name};
                                
                            }else{
                                $err .= qq{
                                    <p> update for <b>$s</b> failed<br>
                                          Species setting is different from parent:<br>
                                          $s species is: ${$all{Species}}[0]<br>
                                          Parent $parent species is:
                                }.$par_record->{Species}."</p>";
                            }
                            
                            
                        }
                        # If it's not in the database, check the list
                        if (!$exist){
                            # First check if it is in the mass_add Strain_Name field
                            for my $names (@{$all{Name}}){
                                if ($names =~ /\b($parent)\b/i){
                                    $exist = 2;
                                    
                                    # Has anyone failed??
                                    if ($first_fail){
                                        if ($first_fail == $s){
                                            # So this is not the first time I meet this record
                                            if ($size == @{$all{Name}}){
                                                # All of the remaining records are bad due to some reasons. Dump them
                                                my $bad_boys = join ' ', @{$all{Name}};
                                                $err .= qq{<p>$bad_boys did not make it into the database because of parent problems. </p>};
                                                # Delete everything left
                                                %all = ();
                                            }
                                            # reset size
                                            else{
                                                $size = @{$all{Name}};
                                                $err = 1;
                                            }
                                        }else{
                                            # Need to check if $first_fail still in the list
                                            # If not, set the current one as $first_fail
                                            my $all_names = join ' ', @{$all{Name}};
                                            $first_fail = $s unless $all_names =~ /\b$first_fail\b/;
                                            $err = 1;
                                        }
                                        
                                    }
                                    # This is the first fail
                                    else{
                                        $first_fail = $s;
                                        $err = 1;
                                    }
                                }
                            }

                        }
                        
                        $err.= qq{<p> The record for <b>$s</b> is not recorded, because parent of $s ($parent) did not make it to the Strain database</p>} unless $exist;
                        
                    }

                }
                if ($err){
                    if ($err == 1){
                        # Meaning parent is in list
                        for my $key (keys %all){
                            # Put current record to the last one.
                            push @{$all{$key}}, shift @{$all{$key}};
                        }
                        
                    }else{
                        $total_err .= $err;
                        # Get rid of this row of records
                        for my $key (keys %all){
                            shift @{$all{$key}};
                        }
                    }
                }else{
                    # So far so good, lets do the recording
                    my %data;
                    for my $key (keys %all){
                        $data{$key} = shift @{$all{$key}};
                    }
                    # Setting some defaults:
                    $data{Recorder} ||= session 'user';
                    $data{Keeper} ||= session 'user';
                    
                    # Correct parent:
                    $parent and $data{Parent} = $parent;
                    
                    
                    # Update the database
                    database->quick_insert('Strain', \%data);
                    $success .= qq{<p><b>$s</b> is successfully recorded</p>};
                    
                    # Update parents
                    if ($data{Parent}){
                        my $argu = {parent => $parent, name => $s, type => 'Strain'};
                        update_parent($argu);
                    }
                    
                    # Update plasmids
                    if ($data{Plasmids}){
                        for my $plasmid (@plasmids){
                            my $p_record = database->quick_select('Plasmid', {Name => $plasmid});
                            my $carriers = $p_record->{Carriers};
                            $carriers .= " $s";
                            database->quick_update('Plasmid', {ID => ($p_record->{ID})}, {Carriers => $carriers});
                        }
                    }
                    
                }
            }
            
        }
        
        template 'success.tt', {
            'content' => $total_err.$success,
        };
        
    }
    # Getting content
    else {
        my $fields = join ' ', @fields;
        
        template 'mass_add.tt', {
            'type' => 'strain',
            'entries' => $fields,
        }
    }
    
};


############# End of strain    #################

############ Start of everything else ##########



prefix '/';

any ['get','post'] => '/mass_edit' => sub {
    # This app is to mass edit ref field of strain/plasmid databases, for example when a paper is published. In this case, you want to change ref from 'from this work' to 'blebla, 2014...'
    
    # Check log in status
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/mass_edit');
        return redirect uri_for('/login');
    }
    
    # After submission, do the update!
    if ( request->method() eq "POST" ) {
        
        my $return = uri_for ('/mass_edit');
        my $home = uri_for ('/');
        
        # Check log in status again
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/mass_edit');
            return redirect uri_for('/login');
        }
        
        my @IDs = split ' ', param "ID";
        my @plasmids = split ' ', param "Plasmid_Names";
        my @strains = split ' ', param "Strain_Names";
        
        # All requested Plasmids and Strains will be pushed in the following arrays.
        my (@p_requested, @s_requested);
        
        # All typoes go in here.
        my $err;
        
        # Processing IDs
        
        # Fetch max ID from databases
        my $p_max_id = get_max_id('Plasmid');
        my $s_max_id = get_max_id('Strain');

        if (@IDs){
            for my $CFS_id (@IDs){
                my ($id) = ($CFS_id =~ /(\d+)$/);
                
                # Checking ID type. 1 means plasmid, and 2 means strain.
                # I guess this would be faster to assign 'p' and 's' to $type.
                my $type = ($CFS_id =~ /_(P|p)/) ? 1 :
                                ($CFS_id =~ /_(S|s)/) ? 2 : undef;
                
                # Check if ID type is okay
                if (!$type){
                    $err .= qq{<p> Unknown ID type. Please begin the IDs with CFS_P or CFS_S</p>};
                }
            
                # If type = plasmid
                elsif ($type == 1) {
                    # If out of range...
                    if ($id < 1 || $id > $p_max_id){
                        $err .= qq{ <p>ERROR: $id out of range!</p>};
                    }else{
                        push @p_requested, $id;
                    }
                }
                # If type = strain
                elsif ($type == 2){
                    if ($id < 1 || $id > $s_max_id){
                        $err .= qq{ <p>ERROR: $id out of range!</p>};
                    }else{
                        push @s_requested, $id;
                    }
                    
                }
                
                
            }
        }
        
        # Processing Names
        
        if (@plasmids){
            for my $p (@plasmids){
                my $record = database->quick_select('Plasmid', {Name => $p});
                
                # Check if plasmid exists
                if (!$record){
                    $err .= qq{<p>$p does not exist!</p>};
                }else{
                    push @p_requested, $record->{ID};
                }
            }
        }
        
        if (@strains){
            for my $s (@strains){
                my $record = database->quick_select('Strain', {Name => $s});
                
                if(!$record){
                    $err .=qq{<p>$s does not exist!</p>};
                }else{
                    push @s_requested, $record->{ID};
                }
            }
        }
        
        # Check errors
        
        if ($err){
            return qq{
                $err
                <p><a href="$return">Return</a></p>
            };
        }
        
        # Everything seems to be okay now, lets update the reference!
        
        my $ref = param "Reference";
        
        # Update Plasmids
        my $sth = database->prepare("UPDATE LOW_PRIORITY Plasmid SET Reference=? WHERE ID=?");
        
        while( my $pID = shift @p_requested){
            $sth->execute($ref,$pID);
        }
        
        # Update Strains
        $sth = database->prepare("UPDATE LOW_PRIORITY Strain SET Reference=? WHERE ID=?");
        
        while( my $sID = shift @s_requested){
            $sth->execute($ref,$sID);
        }
        
        return qq{
            <p>Update successful<p>
            <p><a href="$home">Home</a></p>
        };

        
    }else{
    
        # Here is the 'get' content
    
        template 'mass_edit.tt';
    }
    
};

any ['get','post'] => '/change_keeper' => sub {
    # This is to change keeper field, like someone's leaving the lab.
    
    # Check if logged in..
    if ( not session 'logged_in' ) {
        session 'requested_path' => uri_for('/change_keeper');
        return redirect uri_for('/login');
    }
    
    
    # After submission
    if (request->method() eq "POST" ){
        
        # Check log in status again...
        if ( not session 'logged_in' ) {
            session 'requested_path' => uri_for('/change_keeper');
            return redirect uri_for('/login');
        }
        
        my $return = uri_for ('/change_keeper');
        
        my $current_keeper = session 'user';
        my $new_keeper = lc param "New_keeper";
        
        # Check if new keeper is already one of our users...
        
        my $dbuser = database->quick_select('users', {name => $new_keeper});
        
        unless ($dbuser){
            return qq{
                <p>$new_keeper does not exist in the database!</p>
                <p>Update failed!</p>
                <p><a href="$return">Return</a></p>
            };
        }
        
        # Change plasmid first...
        
        my @plasmids = database->quick_select('Plasmid', {Keeper => $current_keeper});
        my $sth = database->prepare("UPDATE LOW_PRIORITY Plasmid SET Pre_Keeper=?,Keeper=? WHERE ID=?");
        for my $p (@plasmids){
            my $pre_keeper = $p->{Pre_Keeper}.$current_keeper.'.to.'.DateTime->now->ymd('-').'|';
            my $pID = $p->{ID};
            $sth->execute($pre_keeper,$new_keeper,$pID);
        }
        
        # Then change strain...
        
        my @strains = database->quick_select('Strain', {Keeper => $current_keeper});
        $sth = database->prepare("UPDATE LOW_PRIORITY Strain SET Pre_Keeper=?,Keeper=? WHERE ID=?");
        for my $s (@strains){
            my $pre_keeper = $s->{Pre_Keeper}.$current_keeper.'.to.'.DateTime->now->ymd('-').'|';
            my $sID = $s->{ID};
            $sth->execute($pre_keeper,$new_keeper,$sID);
        }
        
        template 'success.tt';
        
    }else{
    
        template 'change_keeper.tt';
    }
};

any ['get','post'] => '/tree/:id' => sub {
    # This is to display the family trees of the id
    
    # Note the $id contains P_ or S_ information
    my $token = param "id";
    my ($type, $ID) = ($token =~ /^(\w)_(\d+)/);
    $type = ($type eq 'p') ? 'plasmid' :
                            ($type eq 's') ? 'strain' : undef;
    return "Type is wrong!" unless $type;
    
    my $cur_record = database->quick_select($type,{ID => $ID});
    
    my $content = draw_tree ($cur_record,$type);

    template 'tree.tt', {
        'css_tree' => request->base . 'css/tree.css',
        'content' => $content,
    }
};

any ['get','post'] => '/mass_search' => sub {
    # This app is to let mass-search with ID or names
    
    # After submission, do the search!
    if ( request->method() eq "POST" ) {
        
        # Getting the columns to display
        my @s_defaults = qw/ Species Plasmids Resistance Keeper Location Parent/;
        my $s_display_fields = database->quick_lookup('users', {name => session 'user'}, 's_list');
        my @s_display_fields = $s_display_fields ? split ',', $s_display_fields : @s_defaults;
        
        my @p_defaults = qw/ Resistance Keeper Location Temperature Parent/;
        my $p_display_fields = database->quick_lookup('users', {name => session 'user'}, 'p_list');
        my @p_display_fields = $p_display_fields ? split ',', $p_display_fields : @p_defaults;
        
        
        my $return = uri_for('/mass_search');
        
        my (%p_mass,%s_mass);
        
        # Getting plasmids
        my @plasmids = split ' ', param "plasmid";
        
        if (@plasmids){
            for my $p (@plasmids){
                if ($p =~ /^(?:CFS_P)?(\d+)/i){
                    push @{$p_mass{ids}}, $1;
                }else{
                    push @{$p_mass{names}}, $p;
                }
            }
        }
        
        my @plasmid_records = get_plasmid_list(%p_mass);
        # Getting strains
        my @strains = split ' ', param "strain";
        
        if (@strains){
            for my $s (@strains){
                if ($s =~ /^(?:CFS_S)?(\d+)/i){
                    push @{$s_mass{ids}}, $1;
                }else{
                    push @{$s_mass{names}}, $s;
                }
            }
        }
        my @strain_records = get_strain_list(%s_mass);
        

        
        template 'mass_list.tt', {
            'strains' => \@strain_records,
            'plasmids' => \@plasmid_records,
            's_display' => \@s_display_fields,
            'p_display' => \@p_display_fields,
        };
        
        
    }else{
        # Getting content
        template 'mass_search.tt';
    }
    
};



dance;
