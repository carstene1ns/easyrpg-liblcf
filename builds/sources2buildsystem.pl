#!/bin/perl

# sources2buildsystem.pl - maintainer utility script to keep the
# source/header file list for our cmake build system organized and up-to-date.
# by carstene1ns 2018-2021, released under the MIT license

use strict;
use warnings;
use File::Find;

print "Searching for source/header files and adding them to the buildsystem...\n";

# process source directory
my @files;
find(\&wanted, "src");
@files = sort @files;

# put generated and third party files after others
my @generated = grep(/\/generated\//, @files);
my @third_party = grep(/\/third_party\//, @files);
my @others = grep(!/\/generated|third_party\//, @files);
@files = (@others, @generated, @third_party);

# split source and headers
my $regex = '(\.cpp|_flags\.h|_impl\.h|src\/[^\/]*\.h)$';
my @sources = grep( /$regex/, @files);
my @headers = grep(!/$regex/, @files);

# update cmake file
my $sources_formatted = format_files(@sources);
my $headers_formatted = format_files(@headers);
my $buildsystem_file = "CMakeLists.txt";
my $data = slurp($buildsystem_file);
$data =~ s/(?<=^set\(LCF_SOURCES\n).*?(?=\n\)$)/$sources_formatted/sm;
$data =~ s/(?<=^set\(LCF_HEADERS\n).*?(?=\n\)$)/$headers_formatted/sm;
burp($buildsystem_file, $data);

print "done.\n";

# - - - - - -

sub wanted {
	return unless -f;
	return unless /\.(cpp|h)$/;

	push @files, $File::Find::name;
}

sub format_files {
	my $formatted;
	foreach my $f (@_) {
		my $is_last = (\$f == \$_[-1]);
		$formatted .= "\t$f";
		$formatted .= "\n" if (! $is_last)
	}
	return $formatted;
}

sub slurp {
	my $file = shift;
	open my $fh, '<:encoding(UTF-8)', $file or die "Could not open file $file for reading!";
	local $/ = undef;
	my $cont = <$fh>;
	close $fh;
	return $cont;
}

sub burp {
	my $file = shift;
	my $data = shift;
	open my $fh, '>:encoding(UTF-8)', $file or die "Could not open file $file for writing!";
	print $fh $data;
	close $fh;
}
