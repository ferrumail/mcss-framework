#!/usr/bin/perl
#
# build_localized_controls.pl
# Generate localized CSV files from master CSV + language YAML
#
# Usage:
#   perl build_localized_controls.pl [--lang LANG] [--all]
#
# Options:
#   --lang LANG    Generate for specific language (en, it, etc.)
#   --all          Generate for all available languages
#   --master FILE  Path to master CSV (default: controls/mcss_controls_master.csv)
#   --l10n DIR     Path to l10n directory (default: l10n/)
#   --output DIR   Base output directory (default: .)
#   --help         Show this help
#
# Examples:
#   perl build_localized_controls.pl --lang en
#   perl build_localized_controls.pl --all
#

use strict;
use warnings;
use utf8;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path);
use open ':std', ':encoding(UTF-8)';

# Try to load YAML::Tiny, fall back to simple parser
my $has_yaml_tiny = eval { require YAML::Tiny; 1 };

my $opt_lang;
my $opt_all;
my $opt_master = 'controls/mcss_controls_master.csv';
my $opt_l10n   = 'l10n';
my $opt_output = '.';
my $opt_help;

GetOptions(
    'lang=s'   => \$opt_lang,
    'all'      => \$opt_all,
    'master=s' => \$opt_master,
    'l10n=s'   => \$opt_l10n,
    'output=s' => \$opt_output,
    'help'     => \$opt_help,
) or die "Error in arguments. Use --help for usage.\n";

if ($opt_help) {
    print <<'USAGE';
Usage: perl build_localized_controls.pl [OPTIONS]

Generate localized CSV files from master CSV + language YAML files.

Options:
  --lang LANG    Generate for specific language (en, it, etc.)
  --all          Generate for all available languages in l10n/
  --master FILE  Path to master CSV (default: controls/mcss_controls_master.csv)
  --l10n DIR     Path to l10n directory (default: l10n/)
  --output DIR   Base output directory (default: .)
  --help         Show this help

Examples:
  perl build_localized_controls.pl --lang en
  perl build_localized_controls.pl --all
  perl build_localized_controls.pl --lang it --output /tmp/test

The script reads:
  - Master CSV with technical data (no translatable text)
  - YAML files with control names and descriptions per language

And produces:
  - {lang}/controls/mcss_{area}_{component}.csv for each area/component

USAGE
    exit 0;
}

die "Specify --lang LANG or --all\n" unless $opt_lang || $opt_all;

# Find available languages
my @languages;
if ($opt_all) {
    opendir my $dh, $opt_l10n or die "Cannot open $opt_l10n: $!";
    @languages = map { s/\.yaml$//r } grep { /\.yaml$/ } readdir $dh;
    closedir $dh;
    die "No YAML files found in $opt_l10n/\n" unless @languages;
} else {
    @languages = ($opt_lang);
}

print "Languages to process: " . join(', ', @languages) . "\n";

# Read master CSV
my @master_rows;
my @master_header;

open my $master_fh, '<:encoding(UTF-8)', $opt_master 
    or die "Cannot open $opt_master: $!";

my $header_line = <$master_fh>;
chomp $header_line;
@master_header = split /,/, $header_line;

while (my $line = <$master_fh>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    
    my @fields = split /,/, $line, -1;
    my %row;
    @row{@master_header} = @fields;
    push @master_rows, \%row;
}
close $master_fh;

print "Master CSV: " . scalar(@master_rows) . " controls loaded\n";

# Process each language
for my $lang (@languages) {
    print "\nProcessing language: $lang\n";
    
    my $yaml_file = "$opt_l10n/$lang.yaml";
    die "YAML file not found: $yaml_file\n" unless -f $yaml_file;
    
    # Parse YAML
    my $translations = parse_yaml($yaml_file);
    my $controls = $translations->{controls} || {};
    
    print "  Translations loaded: " . scalar(keys %$controls) . " controls\n";
    
    # Group by area/component
    my %by_file;
    for my $row (@master_rows) {
        my $area = lc($row->{area});
        my $component = lc($row->{component});
        my $filename = "mcss_${area}_${component}.csv";
        
        push @{$by_file{$filename}}, $row;
    }
    
    # Create output directory
    my $out_dir = "$opt_output/$lang/controls";
    make_path($out_dir) unless -d $out_dir;
    
    # Write localized CSVs
    my $total_written = 0;
    
    for my $filename (sort keys %by_file) {
        my $filepath = "$out_dir/$filename";
        
        open my $out_fh, '>:encoding(UTF-8)', $filepath
            or die "Cannot write $filepath: $!";
        
        # Header with name and description
        print $out_fh "control_id,control_name,description,evidence_file,severity,EV,AC,AR,PR,UI,VC,VI,VA,RC\n";
        
        for my $row (@{$by_file{$filename}}) {
            my $id = $row->{control_id};
            my $trans = $controls->{$id} || {};
            
            my $name = $trans->{name} // "[MISSING: $id name]";
            my $desc = $trans->{description} // "[MISSING: $id description]";
            
            # Escape CSV fields
            $name = csv_escape($name);
            $desc = csv_escape($desc);
            
            print $out_fh join(',',
                $id, $name, $desc,
                $row->{evidence_file}, $row->{severity},
                $row->{EV}, $row->{AC}, $row->{AR}, $row->{PR}, $row->{UI},
                $row->{VC}, $row->{VI}, $row->{VA}, $row->{RC}
            ) . "\n";
            
            $total_written++;
        }
        
        close $out_fh;
    }
    
    print "  Written: $total_written controls to " . scalar(keys %by_file) . " files in $out_dir/\n";
    
    # Check for missing translations
    my @missing;
    for my $row (@master_rows) {
        my $id = $row->{control_id};
        unless (exists $controls->{$id}) {
            push @missing, $id;
        }
    }
    
    if (@missing) {
        print "  WARNING: " . scalar(@missing) . " controls missing translations:\n";
        print "    " . join(', ', @missing[0..9]) . (@missing > 10 ? '...' : '') . "\n";
    }
}

print "\nDone.\n";

# Simple YAML parser (subset needed for our format)
sub parse_yaml {
    my ($file) = @_;
    
    if ($has_yaml_tiny) {
        my $yaml = YAML::Tiny->read($file);
        return $yaml->[0] if $yaml;
        die "Failed to parse $file with YAML::Tiny\n";
    }
    
    # Fallback: simple parser for our specific format
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";
    
    my %result;
    my $current_section;
    my $current_id;
    
    while (my $line = <$fh>) {
        chomp $line;
        
        # Skip empty lines, comments, and document markers
        next if $line =~ /^\s*$/;
        next if $line =~ /^---/;
        next if $line =~ /^\s*#/;
        
        # Top-level key (meta:, controls:)
        if ($line =~ /^(\w+):\s*$/) {
            $current_section = $1;
            $result{$current_section} = {} if $current_section eq 'controls';
            next;
        }
        
        # Control ID (2-space indent)
        # Note: some IDs contain numbers like FAIL2BAN, RFC2142
        if ($line =~ /^  ([A-Z][A-Z0-9]*-\d+):\s*$/) {
            $current_id = $1;
            $result{controls}{$current_id} = {};
            next;
        }
        
        # Control property (4-space indent) - with or without quotes
        if ($line =~ /^    (\w+):\s*"(.*)"\s*$/) {
            # Quoted value
            my ($key, $value) = ($1, $2);
            $value =~ s/\\"/"/g;  # Unescape quotes
            $result{controls}{$current_id}{$key} = $value if $current_id;
            next;
        }
        
        if ($line =~ /^    (\w+):\s*(.+?)\s*$/) {
            # Unquoted value
            my ($key, $value) = ($1, $2);
            $result{controls}{$current_id}{$key} = $value if $current_id;
            next;
        }
        
        # Meta property (2-space indent under meta)
        if ($current_section eq 'meta' && $line =~ /^  (\w+):\s*"?([^"]*)"?\s*$/) {
            $result{meta}{$1} = $2;
        }
    }
    
    close $fh;
    return \%result;
}

# Escape field for CSV (quote if contains comma, quote, or newline)
sub csv_escape {
    my ($value) = @_;
    return $value unless defined $value;
    
    if ($value =~ /[,"\n\r]/) {
        $value =~ s/"/""/g;
        return qq{"$value"};
    }
    return $value;
}
