package WormBase::API::Object::Strain;
use Moose;

with 'WormBase::API::Role::Object';
extends 'WormBase::API::Object';

=pod 

=head1 NAME

WormBase::API::Object::Strain

=head1 SYNPOSIS

Model for the Ace ?Strain class.

=head1 URL

http://wormbase.org/species/strain

=cut

#######################################
#
# CLASS METHODS
#
#######################################

# natural_isolates { }
# This method will return a data structure containing
# information on natural isolates.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/all/natural_isolates

sub natural_isolates {
    my $self   = shift;
    my $object = $self->object;

    my $dsn = $self->ace_dsn->dbh;
    my @strains = $dsn->fetch(-query => "find Strain Wild_isolate");
    my @data;
    foreach (@strains) {
      my ($lat,$lon) = $_->GPS->row if $_->GPS;
      my $place     = $_->Place;
      my $landscape = $_->Landscape;
      my $substrate = $_->Substrate;
      $substrate =~ s/_/ /g;
      $landscape =~ s/_/ /g;
      my $isolated  = $_->Isolated_by;
      my $species   = $_->Species;
      push @data,{ species     => "$species" || undef,
              place       => "$place" || undef,
              strain      => $self->_pack_obj($_),
              latitude    => "$lat" || undef,
              longitude   => "$lon" || undef,
              isolated_by => $isolated ? $self->_pack_obj($isolated,$isolated->Standard_name) : undef,
              landscape   => "$landscape" || undef,
              substrate   => "$substrate" || undef,
      };
    }
    
    return { description => 'a list of wild isolates of strains contained in WormBase',
	     data        => @data ? \@data : undef };
}


#######################################
#
# INSTANCE METHODS
#
#######################################

#######################################
#
# The Overview widget 
#
#######################################6

# name { }
# Supplied by Role

# taxonomy { }
# Supplied by Role

# genotype { }
# This method will return a data structure containing 
# the genotype of the strain as a string.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/genotype

sub genotype {
    my $self     = shift;

    my $data = $self->_get_genotype($self->object);

    return { description => 'the genotype of the strain',
	     data        => $data };
}

# genes { }
# This method will return a data structure 
# containing the genes in this strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/genes

sub genes {
    my $self   = shift;
    my $object = $self->object;
    my @genes;
    if ($object eq 'CB4856') {  # hack. duh.
    } else {
	@genes = map {
	    my $name = $_->Public_name;
	    $self->_pack_obj($_,"$name")
	} $object->Gene;
    }
    return { description => 'genes contained in the strain',
	     data        => @genes ? \@genes : undef };
}

# alleles { }
# This method will return a data structure 
# containing alleles contained in this strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/alleles

sub alleles {
    my $self   = shift;
    my $object = $self->object;

    my @alleles;
    if ($object eq 'CB4856') {  # hack. duh.
    } else {
	@alleles = map {
	    my $name = $_->Public_name;
	    $self->_pack_obj($_,"$name")
	} $object->Variation;
    }
    return { description => 'alleles contained in the strain',
	     data        => @alleles ? \@alleles : undef };
    
}

# rearrangements { }
# This method will return a data structure 
# containing rearrangements contained in this strain, if any.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/rearrangements

sub rearrangements {
    my $self   = shift;
    my $object = $self->object;

    my @rearrange = map { $self->_pack_obj($_) } $object->Rearrangement;
    return { description => 'rearrangements contained in the strain',
	     data        => @rearrange ? \@rearrange : undef };

}

# clones { }
# This method will return a data structure containing
# clones that rescue this strain (?? HOW IS THIS USED? )
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/clones

sub clones {
    my $self   = shift;
    my $object = $self->object;

    my @clone = map { $self->_pack_obj($_) } $object->Clone;
    return { description => 'clones contained in the strain',
	     data        => @clone ? \@clone : undef };

}

# transgenes { }
# This method will return a data structure containing
# transgenes carried by the requested strain
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/transgenes

sub transgenes {
    my $self   = shift;
    my $object = $self->object;

    my @transgenes = map { $self->_pack_obj($_) } $object->Transgene;
    return { description => 'transgenes carried by the strain',
	     data        => @transgenes ? \@transgenes : undef };

}


# reference_strain { }
# This method will return a data structure containing
# the reference strain of the strain in question.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/reference_strain

sub reference_strain {
    my $self   = shift;
    my $object = $self->object;
    
    my ($strain) = map { $self->_pack_obj($_) } $object->Reference_strain;
    return { description => 'reference strain for the current strain',
	     data        => $strain || undef };   
}


# mutagen { }
# This method will return a data structure containing
# the reference strain of the strain in question.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/mutagen

sub mutagen {
    my $self   = shift;
    my $object = $self->object;
    my $mutagen = $object->Mutagen;

    return { description => 'the mutagen used to generate this stain',
	     data        => "$mutagen" || undef };

}

# outcrossed { }
# This method will return a data structure containing
# the number of times a strain has been outcrossed.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/outcrossed

sub outcrossed {
    my $self   = shift;
    my $object = $self->object;
    my $outcrossed = $object->Outcrossed;
    return { description => 'extent to which the strain has been outcrossed',
	     data        => "$outcrossed" || undef };

}

# throws_males { }
# This method will return a data structure containing
# information whether the strain throws males at a higher
# than expected frequency.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/throws_males

sub throws_males {
    my $self   = shift;
    my $object = $self->object;

    my $males = $object->Males;
    my @males = map { $self->_pack_obj($_) } $object->Males;
    return { description => 'does the strain throw males at a higher than expected frequency?',
	     data        => "$males" || undef };
}


# phenotypes {}
# Supplied by Role

# phenotypes_not_observed {}
# Supplied by Role

# remarks {}
# Supplied by Role


#######################################
#
# The Origin widget 
#
#######################################6

# laboratory { }
# Supplied by Role

# made_by { }
# This method will return a data structure containing
# the person who built the strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/made_by

sub made_by {
    my $self   = shift;
    my $object = $self->object;
    my $made_by = $object->Made_by;
    my $name = $made_by->Standard_name if $made_by;
    return { description => 'the person who built the strain',
	     data        => $made_by ? $self->_pack_obj($made_by, "$name") : undef };
}

# contact { }
# This method will return a data structure containing
# the person who built the strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/contact

sub contact {
    my $self   = shift;
    my $object = $self->object;
    my $made_by = $object->Contact;
    my $name = $made_by->Standard_name if $made_by;
    return { description => 'the person who built the strain, or who to contact about it',
	     data        => $made_by ? $self->_pack_obj($made_by, "$name") : undef };
}

# date_received { }
# This method will return a data structure containing
# the date the strain was received at the CGC.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/date_received

sub date_received {
    my $self   = shift;
    my $object = $self->object;
    
    my $date = $object->CGC_received;
    $date =~ s/ 00:00:00$//;
    return { description => 'date the strain was received at the CGC',
	     data        => $date || undef,
    };
}
    
# gps_coordinates { }
# This method will return a data structure containing
# the gps coordinates from where the strain was isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/ED3083/gps_coordinates

sub gps_coordinates {
    my $self = shift;
    my $object = $self->object;
    my ($lat,$lon) = $object->GPS->row if $object->GPS;
    return { description => 'GPS coordinates of where the strain was isolated',
	     data        => { latitude    => "$lat" || undef,
			      longitude   => "$lon" || undef,
	     },
    };    
}


# place { }
# This method will return a data structure containing
# the place where the strain was isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/place

sub place {
    my $self = shift;
    my $object = $self->object;
    my $place  = $object->Place;
    return { description => 'the place where the strain was isolated',
	     data        => "$place" || undef,
    };
}

# landscape { }
# This method will return a data structure containing
# the general type of landscape where the strain was isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/landscape

sub landscape { 
    my $self   = shift;
    my $object = $self->object;
    my $landscape  = $object->Landscape;
    return { description => 'the general landscape where the strain was isolated',
	     data        => "$landscape" || undef,
    };
}

# substrate { }
# This method will return a data structure containing
# the substrate that the stain was found on.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/subtrate

sub substrate { 
    my $self   = shift;
    my $object = $self->object;
    my $substrate  = $object->Substrate;
    return { description => 'the substrate the strain was isolated on',
	     data        => "$substrate" || undef,
    };
}

# associated_organisms { }
# This method will return a data structure containing
# other organisms present when the strain was isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/associated_organisms

sub associated_organisms { 
    my $self = shift;
    my $object = $self->object;
    my @orgs  = map { "$_" } $object->Associated_organisms;
    return { description => 'the place where the strain was isolated',
	     data        => @orgs ? \@orgs : undef };
}

# life_stage { }
# This method will return a data structure containing
# the life stage the strain was in when isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/life_stage

sub life_stage { 
    my $self = shift;
    my $object = $self->object;
    my $life_stage  = $object->Life_stage;
    return { description => 'the life stage the strain was in when isolated',
	     data        => $life_stage ? $self->_pack_obj($life_stage) : undef,
    };   
}

# log_size_of_population { }
# This method will return a data structure containing
# the log size of the population.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/log_size_of_population

sub log_size_of_population {
    my $self = shift;
    my $object = $self->object;
    my $size   = $object->Log_size_of_population;
    return { description => 'the log size of the population when isolated',
	     data        => "$size" || undef,
    };
}

# sampled_by { }
# This method will return a data structure containing
# the person who sampled the strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/sampled_by

sub sampled_by {
    my $self = shift;
    my $object   = $self->object;
    my $sampled  = $object->Sampled_by;
    return { description => 'the person who sampled the strain',
	     data        => "$sampled" || undef,
    };
}

# isolated_by { }
# This method will return a data structure containing
# the person who isolated the strain.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/isolated_by

sub isolated_by {
    my $self    = shift;
    my $object  = $self->object;
    my $person  = $object->Isolated_by;
    my $name = $person->Standard_name if $person;
    return { description => 'the person who isolated the strain',
	     data        => $person ? $self->_pack_obj($person, "$name") : undef };
}

# date_isolated { }
# This method will return a data structure containing
# the date the strain was isolated.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/strain/CB1/date_isolated

sub date_isolated {
    my $self = shift;
    my $object = $self->object;
    my $date   = $object->Date;
    $date =~ s/ \d\d:\d\d:\d\d//;
    return { description => 'the date the strain was isolated',
	     data        => "$date" || undef,
    };
}






__PACKAGE__->meta->make_immutable;

1;

