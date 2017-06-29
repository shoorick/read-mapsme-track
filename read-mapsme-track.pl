#!/usr/bin/perl

=encoding utf8

=head1 NAME

read-mapsme-track.pl - Read GPS data from Maps with Me (maps.me)

=head1 SYNOPSIS

./read-mapsme-track.pl I<[options]>

=head1 OPTIONS

=over 4

=item B<-o>, B<--outtype>

Type of output data. Possible values: csv, tab.

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

use Getopt::Long;
use Pod::Usage qw( pod2usage );

my $PACK_PATTERN = 'ddddddddB';
my $CHUNK_SIZE   = length pack $PACK_PATTERN;
my $HEADER_SIZE  = 4;

# TODO Move to config
my @FIELDS = qw(
    timestamp latitude longitude altitude speed bearing
    horizontal_accuracy vertical_accuracy source
);

my %FORMAT = (
    'csv' => join(',',  ('%s') x scalar(@FIELDS) ) . "\n",
    'tab' => join("\t", ('%s') x scalar(@FIELDS) ) . "\n",
);

my %HEADER = (
    'csv' => join(',',  @FIELDS ) . "\n",
    'tab' => join("\t", @FIELDS ) . "\n",
);

my %FOOTER = (
    'csv' => '',
    'tab' => '',
);

map { $_ = '' } my ( $need_help, $need_manual, $verbose );
my $outtype = 'csv';

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

foreach my $file ( @ARGV ) {
    open my $fh, '<:raw', $file
        or die "cannot open $file for reading: $!";

    my $bytes_read = read $fh, my $header, $HEADER_SIZE;
    my $buffer = '';
    my $offset = $bytes_read;

    print $HEADER{$outtype};

    while ( $bytes_read = read $fh, $buffer, $CHUNK_SIZE ) {
        my (
            $timestamp, $latitude, $longitude, $altitude, $speed, $bearing,
            $horizontal_accuracy, $vertical_accuracy, $source
        ) = unpack $PACK_PATTERN, $buffer;

        printf $FORMAT{$outtype},
            $timestamp, $latitude, $longitude, $altitude, $speed, $bearing,
            $horizontal_accuracy, $vertical_accuracy, $source;
    }

    print $FOOTER{$outtype};
    close $fh
        or warn "close failed: $!";
}
