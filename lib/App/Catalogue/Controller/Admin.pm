package App::Catalogue::Controller::Admin;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use Catmandu::Util qw(:is);
use Furl;
use Hash::Merge qw/merge/;
use Carp;
use Exporter qw/import/;
use App::Helper;
use Data::Dumper;

our @EXPORT
    = qw/new_person search_person update_person edit_person delete_person import_person update_project edit_project delete_project update_award/;
our @EXPORT_OK
    = qw/new_department update_department edit_department delete_department/;

our %EXPORT_TAGS = (
    all        => [ @EXPORT, @EXPORT_OK ],
    person     => [@EXPORT],
    department => [@EXPORT_OK],
);

# manage persons
sub _create_id {
    my $id = h->bag->get('1')->{"latest"};
    $id++;
    h->bag->add( { _id => "1", latest => $id } );
    return $id;
}

sub new_person {
    return "AU_" . _create_id;
}

sub search_person {
    my $p = shift;

    my $hits = h->researcher->search(
        query => $p->{q},
        start => $p->{start} ||= 0,
        limit => $p->{limit}
            ||= h->config->{store}->{default_searchpage_size},
    );

    my @page_func
        = qw(next_page last_page page previous_page pages_in_spread);
    map { $hits->{$_} = $hits->$_ } @page_func;

    return $hits;
}

sub update_person {
    my $data = shift;
    croak "Error: No _id specified" unless $data->{_id};

    my $fixer = Catmandu::Fix->new(fixes => [
        'unless exists("account_status") add_field("account_status","inactive") end',
        ]);

    $data->{full_name} = $data->{last_name} . ", " . $data->{first_name};
    $data->{old_full_name} = $data->{old_last_name} . ", " . $data->{old_first_name}
        if $data->{old_last_name} && $data->{old_first_name};
    $fixer->fix($data);

    if($data->{orcid} and $data->{orcid} ne ""){
    	my $hits = h->search_publication({q => ["person=$data->{_id}"], limit => 1000});

        $hits->each(sub {
            my $hit = $_[0];
    		if($hit->{author}){
    			foreach my $author (@{$hit->{author}}){
    				if($author->{id} and $author->{id} eq $data->{_id}){
    					$author->{orcid} = $data->{orcid};
    					h->publication->add($hit);
    					h->publication->commit;
    				}
    			}
    		}
    		if($hit->{editor}){
    			foreach my $editor (@{$hit->{editor}}){
    				if($editor->{id} and $editor->{id} eq $data->{_id}){
    					$editor->{orcid} = $data->{orcid};
    					h->publication->add($hit);
    					h->publication->commit;
    				}
    			}
    		}
        });

    }

    h->researcher->add($data);
    h->researcher->commit;
}

sub edit_person {
    my $id = shift;
    return h->researcher->get($id);
}

sub delete_person {
    confess "Don't do that! Seriously.";
}

sub import_person {
    my $id = shift;

    my $appdir = h->config->{appdir};
    my $furl = Furl->new( agent => "Chrome 35.1", timeout => 10 );

    my $base_url = 'http://ekvv.uni-bielefeld.de/ws/pevz';
    my $url      = $base_url . "/PersonKerndaten.xml?persId=$id";
    my $url2     = $base_url . "/PersonKontaktdaten.xml?persId=$id";

    my $res = $furl->get($url);
    croak "Error: $res->status_line" unless $res->is_success;
    my $p1 = Catmandu->importer(
        'XML',
        file => $res->content,
        fix => ["$appdir/fixes/pevz_mapping.fix"],
        )->first;

    $res = $furl->get($url2);
    croak "Error: $res->status_line" unless $res->is_success;
    my $p2 = Catmandu->importer(
        'XML',
        file => $res->content,
        fix => ["$appdir/fixes/pevz_mapping.fix"],
        )->first;

    my $merger = Hash::Merge->new();

    return $merger->merge( $p1, $p2 );
}

# manage departments
sub _create_id_dep {
    my $bag = h->authority('department')->get('1');
    my $id  = $bag->{"latest"};
    $id++;
    $bag = h->bag->add( { _id => "1", latest => $id } );
    return $id;    # correct?
}

sub new_department {
    return _create_id_dep;
}

sub update_department {
    my $data = shift;
    return "Error: No _id specified" unless $data->{_id};

    my $old = h->authority('department')->get( $data->{_id} );
    my $merger = Hash::Merge->new();
    my $new = $merger->merge( $data, $old );

    h->authority('department')->add($new);
    h->authority('department')->commit;
}

sub edit_department {
    my $id = shift;
    return 0 unless $id;

    return h->authority('department')->get($id);
}

sub delete_department {
    my $id = shift;
    return "Error" unless $id;

    h->authority('department')->delete($id);
    h->authority('department')->commit;
}

# manage projects
#sub _create_id_proj {
#    my $bag = h->authority('project')->get('1');
#    my $id  = $bag->{"latest"};
#    $id++;
#    $bag = h->bag->add( { _id => "1", latest => $id } );
#    return $id;    # correct?
#}

sub new_project {
	return _create_id_proj;
}

sub update_project {
    my $data = shift;
    return "Error: No _id specified" unless $data->{_id};

    my $new = h->nested_params($data);

    h->project->add($new);
    h->project->commit;
}

sub edit_project {
    my $id = shift;
    return 0 unless $id;

    return h->project->get($id);
}

sub delete_project {
    my $id = shift;
    return "Error" unless $id;

    h->project->delete($id);
    h->project->commit;
}

sub update_award {
    my $data = shift;
    return "Error: No _id specified" unless $data->{_id};

    my $new = h->nested_params($data);

    my $fixer = Catmandu::Fix->new(fixes => ['person()',]);
    $fixer->fix($new);

    #h->award->add($new);
    #h->award->commit;
    return $new;
}

1;
