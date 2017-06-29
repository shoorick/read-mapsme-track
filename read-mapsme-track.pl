#!/usr/bin/perl -w

=encoding utf8

=head1 NAME

read-mapsme-track.pl - Read GPS data from Maps with Me (maps.me)

=head1 SYNOPSIS

./read-mapsme-track.pl I<[options]>

=head1 OPTIONS

=over 4

=item B<-o>, B<--outtype>

Type of output data. Possible values: csv, tab, gpx.

=item B<-?>, B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

I<Coming soon>

=head1 AUTHOR

Alexander Sapozhnikov, L<< E<lt>shoorick@cpan.orgE<gt> >>, L<< http://as.susu.ru/ >>

=cut

my $VERSION = 0.1;
#   CREATED   2017-06-29

use strict;
use FindBin;
use Getopt::Long;
use List::MoreUtils qw( zip );
use Pod::Usage qw( pod2usage );
use YAML::Tiny;

# Format row of data
sub row {
    my $template = shift or die 'No template given';
    my %data
        = ref $_[0] eq 'HASH'
        ? %{  $_[0] }
        : @_;

    $data{$1} //= '' while $template =~  /\{(\w+)\}/g;

    return $template =~ s/\{(\w+)\}/$data{$1}/gr;
}


my $config = YAML::Tiny->read("$FindBin::Bin/config.yml")->[0];
my $CHUNK_SIZE   = length pack $config->{'pack_pattern'};
my $FIELDS       = $config->{'fields'};

map { $_ = '' } my ( $need_help, $need_manual, $verbose );
my $outtype = $config->{'output_format'};

GetOptions(
    'outtype=s' => \$outtype,
    'help|?'    => \$need_help,
    'manual'    => \$need_manual,
    'verbose'   => \$verbose,
);

pod2usage(1)
    if $need_help;
pod2usage('verbose' => 2)
    if $need_manual;

my $template = $config->{'templates'}->{'row'}->{ $outtype }
    or die qq{Unknown output type "$outtype"};

print $config->{'templates'}->{'header'}->{ $outtype };

foreach my $file ( @ARGV ) {
    open my $fh, '<:raw', $file
        or die "cannot open $file for reading: $!";

    my $bytes_read = read($fh, my $header, $config->{'header_size'});
    my $buffer = '';
    my $offset = $bytes_read;

    while ( $bytes_read = read $fh, $buffer, $CHUNK_SIZE ) {
        my @data = unpack $config->{'pack_pattern'}, $buffer;

        print row(
            $config->{'templates'}->{'row'}->{ $outtype },
            zip @$FIELDS, @data
        );
    }

    close $fh
        or warn "close failed: $!";
}

print $config->{'templates'}->{'footer'}->{ $outtype };
