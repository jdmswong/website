package WormBase::API::Service::Xapian;

use base qw/Catalyst::Model/;
use Moose;

use strict;

use Catalyst::Model::Xapian::Result;
use Encode qw/from_to/;
use Search::Xapian qw/:all/;
use Storable;
use MRO::Compat;
use Time::HiRes qw/gettimeofday tv_interval/;
use Config::General;


has 'db' => (isa => 'Search::Xapian::Database', is => 'rw');
has 'qp' => (isa => 'Search::Xapian::QueryParser', is => 'rw');

has 'api' => (
    is         => 'ro',
    isa        => 'WormBase::API',
    );

has 'c' => (
    is     => 'ro',
    isa    => 'Config::General',
    );


sub search {
    my ( $class, $q, $page, $type, $page_size) = @_;
    my $t=[gettimeofday];
    $page       ||= 1;
    $page_size  ||=  20;#$class->config->{page_size};
    $class->db->reopen();

    if($type){
      $q .= " $type..$type";
    }

    my $query=$class->qp->parse_query( $q, 512|1|2 );
    my $enq       = $class->db->enquire ( $query );

    if($type =~ /Paper/){
        $enq->set_docid_order(ENQ_DESCENDING);
        $enq->set_weighting_scheme(Search::Xapian::BoolWeight->new());
    }
    my $mset      = $enq->get_mset( ($page-1)*$page_size,
                                     $page_size );
    my ($time)=tv_interval($t) =~ m/^(\d+\.\d{0,2})/;
    $time =~ s/\./\,/;
    from_to($q,'utf-8','iso-8859-1') if $class->config->{utf8_query};

    return Catalyst::Model::Xapian::Result->new({ mset=>$mset,
        search=>$class,query=>$q,query_obj=>$query,querytime=>$time,page=>$page,page_size=>$page_size });
}
 
 
=item extract_data <item> <query>

Extract data from a L<Search::Xapian::Document>. Defaults to
using Storable::thaw.

=cut

sub extract_data {
    my ( $self,$item, $query ) = @_;
    my $data=Storable::thaw( $item->get_data ); 
    return $data;
}



# input: list of ace objects
# output: list of Result objects
sub _wrap_objs {
  my $self  = shift;
  my $list  = shift;
  my $class = shift;

  my $api = $self->api;
  my $fields;
  my $f;
  if ($self->c->{'DefaultConfig'}->{sections}->{species}->{$class}){
    $f = $self->c->{'DefaultConfig'}->{sections}->{species}->{$class}->{search}->{fields};
  } else{
    $f = $self->c->{'DefaultConfig'}->{sections}->{resources}->{$class}->{search}->{fields};
  }
  push(@$fields, @$f) if $f;

  if (ref($list) eq "ARRAY") {

    # don't get config info if nothing to config
    return $list if (@$list < 1); 

    my @ret;
    foreach my $ace_obj (@$list) {
      my $object;
      if (eval{$ace_obj->class}){
        # this is faster than passing the ace_obj.  I know, weird.
        $object = $api->fetch({object => $ace_obj}) or die "$!";

      } else {
        $object = $ace_obj;
      }
      my %data;
      $data{obj_name}=$ace_obj;
      foreach my $field (@$fields) {
        my $field_data = $object->$field;     # if  $object->meta->has_method($field); # Would be nice. Have to make sure config is good now.
        $field_data = $field_data->{data};
        $data{$field} = $field_data;
      }
      push(@ret, \%data);
    }
    return \@ret;
  }else{
    my $ace_obj = $list;
    my $object;
    if (eval{$ace_obj->class}){
      # this is faster than passing the ace_obj.  I know, weird.
      $object = $api->fetch({object => $ace_obj}) or die "$!";
    } else {
      $object = $ace_obj;
    }
    my %data;
    $data{obj_name}=$ace_obj;
    foreach my $field (@$fields) {
      my $field_data = $object->$field;     # if  $object->meta->has_method($field); # Would be nice. Have to make sure config is good now.
      $field_data = $field_data->{data};
      $data{$field} = $field_data;
    }
    return \%data;
  }
}

1;