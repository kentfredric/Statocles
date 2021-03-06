package Statocles::Page::File;

# ABSTRACT: A page wrapping a file (handle)

use Statocles::Base 'Class';
with 'Statocles::Page';

=attr file_path

The path to the file.

=cut

has file_path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
);

=attr fh

The file handle containing the contents of the page.

=cut

has fh => (
    is => 'ro',
    isa => FileHandle,
);

=method vars

Dies. This page has no templates and no template variables.

=cut

# XXX: This may have to be implemented in the future, to allow for some useful edge
# cases.
sub vars { die "Unimplemented" }

=method render

    my $fh = $page->render;

Return the filehandle to the file containing the content for this page.

=cut

sub render {
    my ( $self ) = @_;
    $self->site->log->debug( 'Render page: ' . $self->path );
    return $self->file_path ? $self->file_path : $self->fh;
}

1;
__END__

=head1 SYNOPSIS

    # File path
    my $page = Statocles::Page::File->new(
        path => '/path/to/page.txt',
        file_path => '/path/to/file.txt',
    );

    # Filehandle
    open my $fh, '<', '/path/to/file.txt';
    my $page = Statocles::Page::File->new(
        path => '/path/to/page.txt',
        fh => $fh,
    );

=head1 DESCRIPTION

This L<Statocles::Page> wraps a file handle in order to move files from one
L<store|Statocles::Store> to another.
