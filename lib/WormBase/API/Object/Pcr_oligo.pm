package WormBase::API::Object::Pcr_oligo;

use Moose;

with 'WormBase::API::Role::Object';
extends 'WormBase::API::Object';

has '_segment' => (
	is		 => 'ro',
	required => 1,
	lazy	 => 1,
	default	 => sub {
		my ($self) = @_;
		my $object = $self->object;
		my $class = $object->class;
		$class .= ':reagent' if $class eq 'Oligo_set';
		return $self->gff_dsn->segment($class => $object);
	},
   );

has '_oligos' => (
	is => 'ro',
	required => 1,
	lazy => 1,
	default => sub {
		my ($self) = @_;
		return $self ~~ '@Oligo';
	},
   );

has 'display_class' => (
	is => 'ro',
	required => 1,
	default => sub {
		my ($self) = @_;
		(my $class = $self ~~ 'class') =~ s/_/ /g;
		return $class;
	},
   );


#############################################
## Methods pertaining to all three classes
#############################################

sub name {
	my ($self) = @_;

	return {
		description => 'The object name of this ' . $self->display_class,
		data		=> $self->_pack_obj($self->object),
	};
}

sub canonical_parent {
	my ($self) = @_;

	return {
		description => 'Canonical parent of this ' . $self->display_class,
		data		=> $self->_pack_obj($self ~~ 'Canonical_parent'),
	};
}

sub oligos {
	my ($self) = @_;

	my @data = map {
		obj => $self->_pack_obj($_),
		sequence => $_->Sequence,
	}, @{$self->_oligos};

	return {
		description => 'Oligos of this' . $self->display_class,
		data		=> @data ? \@data : undef,
	};
}


sub overlapping_genes {
	my ($self) = @_;
	my @gene_info = map {$_->info} $self->_overlapping_genes($self->_segment);

	return {
		description => 'Overlapping genes of this ' . $self->display_class,
		data		=> @gene_info ? \@gene_info : undef,
	};
}

sub overlaps_CDS {
	my ($self) = @_;
	my $CDS = $self->_pack_objects($self ~~ '@Overlaps_CDS');

	return {
		description => 'CDS\'s that this ' . $self->display_class . ' overlaps',
		data		=> %$CDS ? $CDS : undef,
	};
}

sub overlaps_transcript {
	my ($self) = @_;
	my $transcripts = $self->_pack_objects($self ~~ '@Overlaps_Transcript');

	return {
		description => 'Transcripts that this ' . $self->display_class . ' overlaps',
		data		=> $transcripts ? \$transcripts : undef,
	};
}

sub overlaps_pseudogene {
	my ($self) = @_;
	my $pseudogenes = $self->_pack_objects($self ~~ '@Overlaps_Pseudogene');

	return {
		description => 'Pseudogenes that this ' . $self->display_class . ' overlaps',
		data		=> %$pseudogenes ? \$pseudogenes : undef,
	};
}

sub overlaps_variation {
	my ($self) = @_;
	my $variations = $self->_pack_objects($self ~~ '@Overlaps_Variation');

	return {
		description => 'Variations that this ' . $self->display_class . ' overlaps',
		data		=> %$variations ? \$variations : undef,
	};
}

# classic site note: MRC Genesevice and Open Biosystems links are invalid now
sub on_orfeome_project {
	my ($self) = @_;

	$self->name =~ /^mv_(.*)/;
	my $data = $1;

	return {
		description => 'Finding this ' . $self->display_class . ' on the ORFeome project',
		data		=> $data,
	};
}

sub remark {
	my ($self) = @_;

	return {
		description => 'Remark about this ' . $self->display_class,
		data		=> $self ~~ 'Remark',
	};
}

sub microarray_results {
	my ($self) = @_;

	my $results = $self->_pack_objects($self ~~ '@Microarray_results');
	return {
		description => 'Microarray results involving this ' . $self->display_class,
		data => %$results ? $results : undef,
	};
}

sub segment {
	my ($self) = @_;

	my %data;
	if (my $segment = $self->_segment) {
		%data = map { $_ => $segment->$_ }
		        qw(refseq abs_start abs_stop start stop length dna);
	}

	return {
		description => 'Sequence/segment data about this ' . $self->display_class,
		data		=> %data ? \%data : undef,
	};
}


########################################
## Methods pertaining to PCR_product
########################################

sub amplified {
	my ($self) = @_;

	return {
		description => 'Whether this PCR product is amplified',
		data		=> $self ~~ 'Amplified',
	};
}

sub laboratory {
	my ($self) = @_;

	return {
		description => 'Laboratory this PCR product was from',
		data		=> $self->_pack_obj($self ~~ 'From_laboratory'),
	};
}

sub SNP_loci {
	my ($self) = @_;

	my @loci = map {$self->_pack_obj($_)} @{$self ~~ '@SNP_locus'};
	return {
		description => 'SNP loci for this PCR product',
		data		=> @loci ? \@loci : undef,
	};
}

sub assay_conditions {
	my ($self) = @_;
	my $conditions = $self ~~ 'Assay_conditions';
	$conditions &&= $conditions->right;

	return {
		description => 'Assay conditions for this PCR product',
		data		=> $conditions,
	};
}

########################################
## Methods pertaining to Oligo_set
########################################

########################################
## Methods pertaining to Oligo
########################################


########################################
## Private Methods
########################################

sub _overlapping_genes {
	my ($self, @segments) = @_;
	return map { $_->features('CDS:curated') } @segments;
}


1;
