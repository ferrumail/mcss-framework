#!/usr/bin/env perl
#
# validate_mcss_csv.pl - MCSS CSV Controls Validator
#
# Validates:
# - Required fields present
# - Valid MCSS metric values
# - Unique control_id across files
# - Base score calculation
#
# Supports both:
# - Master CSV (no name/description, severity in English)
# - Localized CSV (with name/description)
#
# Usage: perl validate_mcss_csv.pl [options] file.csv [...]
#

use strict;
use warnings;
use utf8;
use Text::CSV;
use Getopt::Long;
use open ':std', ':encoding(UTF-8)';

my $verbose = 0;
my $calculate_scores = 0;
my $master_mode = 0;

GetOptions(
    'verbose|v'   => \$verbose,
    'scores|s'    => \$calculate_scores,
    'master|m'    => \$master_mode,
    'help|h'      => sub { usage(); exit 0; },
) or die "Error parsing options\n";

sub usage {
    print <<'EOF';
Usage: perl validate_mcss_csv.pl [options] file.csv [file.csv ...]

Options:
  -v, --verbose    Detailed output
  -s, --scores     Calculate and display MCSS scores
  -m, --master     Validate master CSV format (no name/description)
  -h, --help       Show this help

Examples:
  perl validate_mcss_csv.pl mcss_mta_postfix.csv
  perl validate_mcss_csv.pl -v -s en/controls/*.csv
  perl validate_mcss_csv.pl -m controls/mcss_controls_master.csv
EOF
}

# Valid values for each MCSS metric
my %VALID_VALUES = (
    EV => [qw(N A L P)],           # ExposureVector
    AC => [qw(L H)],               # AttackComplexity
    AR => [qw(N P)],               # AttackRequirements
    PR => [qw(N L H)],             # PrivilegesRequired
    UI => [qw(N P A)],             # UserInteraction
    VC => [qw(N L H)],             # ConfidentialityImpact
    VI => [qw(N L H)],             # IntegrityImpact
    VA => [qw(N L H)],             # AvailabilityImpact
    RC => [qw(T S M C A)],         # RemediationComplexity
    severity => [qw(Critical High Medium Low Info)],
);

# Weights for score calculation (lower = more severe)
my %WEIGHTS = (
    EV => { N => 0.0, A => 0.1, L => 0.2, P => 0.3 },
    AC => { L => 0.0, H => 0.1 },
    AR => { N => 0.0, P => 0.1 },
    PR => { N => 0.0, L => 0.1, H => 0.2 },
    UI => { N => 0.0, P => 0.1, A => 0.2 },
    VC => { H => 0.0, L => 0.1, N => 0.2 },
    VI => { H => 0.0, L => 0.1, N => 0.2 },
    VA => { H => 0.0, L => 0.1, N => 0.2 },
);

# Required columns for master CSV
my @MASTER_COLS = qw(
    control_id area component evidence_file severity
    EV AC AR PR UI VC VI VA RC
);

# Required columns for localized CSV
my @LOCALIZED_COLS = qw(
    control_id control_name description evidence_file severity
    EV AC AR PR UI VC VI VA RC
);

my $total_errors = 0;
my $total_warnings = 0;
my %all_control_ids;
my @all_controls;  # For statistics

# Process all files passed as arguments
if (@ARGV == 0) {
    # If no files specified, look for CSV in current directory
    @ARGV = glob("mcss_*.csv");
    if (@ARGV == 0) {
        die "No CSV files found. Specify files to validate.\n";
    }
}

print "=== MCSS CSV Validator ===\n";
print "Mode: " . ($master_mode ? "Master CSV" : "Auto-detect") . "\n\n";

for my $file (@ARGV) {
    validate_file($file);
}

# Final summary
print "\n" . "=" x 60 . "\n";
print "VALIDATION SUMMARY\n";
print "=" x 60 . "\n";
print "Files processed: " . scalar(@ARGV) . "\n";
print "Total controls: " . scalar(keys %all_control_ids) . "\n";
print "Total errors: $total_errors\n";
print "Total warnings: $total_warnings\n";

# Statistics if scores were calculated
if ($calculate_scores && @all_controls) {
    print "\n=== Score Statistics ===\n\n";
    
    my %by_severity;
    my $sum = 0;
    my $max = 0;
    my $min = 10;
    
    for my $c (@all_controls) {
        $by_severity{$c->{severity}}++;
        $sum += $c->{score};
        $max = $c->{score} if $c->{score} > $max;
        $min = $c->{score} if $c->{score} < $min;
    }
    
    my $total = scalar @all_controls;
    print "By Severity:\n";
    for my $sev (qw(Critical High Medium Low Info)) {
        my $count = $by_severity{$sev} // 0;
        printf "  %-10s %3d (%5.1f%%)\n", "$sev:", $count, 100*$count/$total;
    }
    
    printf "\nAverage Score: %.1f\n", $sum / $total;
    printf "Max Score: %.1f\n", $max;
    printf "Min Score: %.1f\n", $min;
    
    # Top 10 critical
    my @sorted = sort { $b->{score} <=> $a->{score} } @all_controls;
    print "\nTop 10 Critical Controls:\n";
    for my $i (0..9) {
        last unless $sorted[$i];
        printf "  %-15s %-30s %5.1f\n",
            $sorted[$i]->{id},
            substr($sorted[$i]->{name} // $sorted[$i]->{id}, 0, 30),
            $sorted[$i]->{score};
    }
}

if ($total_errors == 0 && $total_warnings == 0) {
    print "\n✓ All files are valid!\n";
    exit 0;
} elsif ($total_errors == 0) {
    print "\n⚠ Validation completed with warnings\n";
    exit 0;
} else {
    print "\n✗ Validation failed with errors\n";
    exit 1;
}

sub validate_file {
    my ($file) = @_;
    
    print "Processing: $file\n";
    
    unless (-f $file) {
        print "  ERROR: File not found\n";
        $total_errors++;
        return;
    }
    
    my $csv = Text::CSV->new({
        binary => 1,
        auto_diag => 1,
        sep_char => ',',
    });
    
    open my $fh, "<:encoding(utf8)", $file 
        or die "Cannot open $file: $!";
    
    # Read header
    my $header = $csv->getline($fh);
    unless ($header) {
        print "  ERROR: Cannot read header\n";
        $total_errors++;
        close $fh;
        return;
    }
    
    # Build column index
    my %col_index;
    for my $i (0 .. $#$header) {
        $col_index{$header->[$i]} = $i;
    }
    
    # Auto-detect format: master has 'area'/'component', localized has 'control_name'/'description'
    my $is_master = exists $col_index{area} && exists $col_index{component};
    my $is_localized = exists $col_index{control_name} && exists $col_index{description};
    
    # Override with command line option
    $is_master = 1 if $master_mode;
    
    my @required = $is_master ? @MASTER_COLS : @LOCALIZED_COLS;
    my $format = $is_master ? "master" : "localized";
    
    $verbose && print "  Format detected: $format\n";
    
    # Check required columns
    my @missing_cols;
    for my $col (@required) {
        unless (exists $col_index{$col}) {
            push @missing_cols, $col;
        }
    }
    
    if (@missing_cols) {
        print "  ERROR: Missing columns: " . join(", ", @missing_cols) . "\n";
        $total_errors++;
        close $fh;
        return;
    }
    
    $csv->column_names(@$header);
    
    my $line_num = 1;
    my $file_errors = 0;
    my $file_warnings = 0;
    my $control_count = 0;
    
    while (my $row = $csv->getline_hr($fh)) {
        $line_num++;
        my $control_id = $row->{control_id} // '';
        
        # Skip empty rows
        next if $control_id eq '';
        
        $control_count++;
        
        # Check global control_id uniqueness
        if (exists $all_control_ids{$control_id}) {
            print "  ERROR line $line_num: duplicate control_id '$control_id' " .
                  "(already in $all_control_ids{$control_id})\n";
            $file_errors++;
        }
        $all_control_ids{$control_id} = $file;
        
        # Check required fields not empty
        for my $col (@required) {
            my $val = $row->{$col} // '';
            if ($val eq '') {
                print "  ERROR line $line_num ($control_id): empty field '$col'\n";
                $file_errors++;
            }
        }
        
        # Validate metric values
        for my $metric (qw(EV AC AR PR UI VC VI VA RC severity)) {
            my $val = $row->{$metric} // '';
            next if $val eq '';
            next unless exists $VALID_VALUES{$metric};
            
            my @valid = @{$VALID_VALUES{$metric}};
            unless (grep { $_ eq $val } @valid) {
                print "  ERROR line $line_num ($control_id): " .
                      "invalid value '$val' for $metric " .
                      "(valid: " . join(", ", @valid) . ")\n";
                $file_errors++;
            }
        }
        
        # Calculate score if requested
        if ($calculate_scores) {
            my $score = calculate_base_score($row);
            my $severity = score_to_severity($score);
            
            push @all_controls, {
                id       => $control_id,
                name     => $row->{control_name} // $control_id,
                score    => $score,
                severity => $severity,
            };
            
            $verbose && printf "  ✓ %-15s score=%.1f severity=%s\n", 
                $control_id, $score, $severity;
        } else {
            $verbose && print "  ✓ $control_id\n";
        }
    }
    
    close $fh;
    
    print "  [OK] $control_count controls validated";
    print " ($file_errors errors)" if $file_errors;
    print "\n";
    
    $total_errors += $file_errors;
    $total_warnings += $file_warnings;
}

sub calculate_base_score {
    my ($row) = @_;
    
    # Exploitability = 1 - (somma pesi normalizzata)
    my $ev = $WEIGHTS{EV}{$row->{EV} // 'N'} // 0;
    my $ac = $WEIGHTS{AC}{$row->{AC} // 'L'} // 0;
    my $ar = $WEIGHTS{AR}{$row->{AR} // 'N'} // 0;
    my $pr = $WEIGHTS{PR}{$row->{PR} // 'N'} // 0;
    my $ui = $WEIGHTS{UI}{$row->{UI} // 'N'} // 0;
    
    # Max somma possibile = 0.3 + 0.1 + 0.1 + 0.2 + 0.2 = 0.9
    my $exploitability = 1 - (($ev + $ac + $ar + $pr + $ui) / 0.9);
    
    # Impact = 1 - [(1-VC) × (1-VI) × (1-VA)]
    my $vc = $WEIGHTS{VC}{$row->{VC} // 'N'} // 0.2;
    my $vi = $WEIGHTS{VI}{$row->{VI} // 'N'} // 0.2;
    my $va = $WEIGHTS{VA}{$row->{VA} // 'N'} // 0.2;
    
    # Converti in impatto (0.2 = none -> 0, 0.0 = high -> 1)
    my $vc_impact = 1 - ($vc / 0.2);
    my $vi_impact = 1 - ($vi / 0.2);
    my $va_impact = 1 - ($va / 0.2);
    
    my $impact = 1 - ((1 - $vc_impact) * (1 - $vi_impact) * (1 - $va_impact));
    
    # Base Score = 10 × (1 - (1-Exploitability) × (1-Impact))
    my $base_score = 10 * (1 - ((1 - $exploitability) * (1 - $impact)));
    
    # Arrotonda a 1 decimale
    return sprintf("%.1f", $base_score);
}

sub build_vector {
    my ($row) = @_;
    
    return sprintf("MCSS:1.0/EV:%s/AC:%s/AR:%s/PR:%s/UI:%s/VC:%s/VI:%s/VA:%s/RC:%s",
        $row->{EV} // 'N',
        $row->{AC} // 'L',
        $row->{AR} // 'N',
        $row->{PR} // 'N',
        $row->{UI} // 'N',
        $row->{VC} // 'N',
        $row->{VI} // 'N',
        $row->{VA} // 'N',
        $row->{RC} // 'M',
    );
}

sub score_to_severity {
    my ($score) = @_;
    
    return 'None'     if $score == 0;
    return 'Low'      if $score < 4.0;
    return 'Medium'   if $score < 7.0;
    return 'High'     if $score < 9.0;
    return 'Critical';
}

__END__

=head1 NAME

validate_mcss_csv.pl - MCSS CSV Controls Validator

=head1 SYNOPSIS

    perl validate_mcss_csv.pl [options] file.csv [file.csv ...]
    perl validate_mcss_csv.pl -v -s *.csv
    perl validate_mcss_csv.pl -m controls/mcss_controls_master.csv

=head1 DESCRIPTION

Validates CSV files containing MCSS (Mailserver Configuration 
Scoring System) controls, checking:

=over 4

=item * Presence of all required columns

=item * Valid values for MCSS metrics

=item * Global uniqueness of control_id

=item * Optionally, calculates MCSS Base Scores

=back

Supports two CSV formats:

=over 4

=item * B<Master CSV>: Technical data only (no name/description), with area/component columns

=item * B<Localized CSV>: Complete with control_name and description for a specific language

=back

=head1 OPTIONS

=over 4

=item B<-v, --verbose>

Detailed output with confirmation for each validated control.

=item B<-s, --scores>

Calculate and display MCSS Base Scores for each control.

=item B<-m, --master>

Force master CSV validation mode.

=item B<-h, --help>

Show help.

=back

=head1 EXIT STATUS

=over 4

=item 0 - Validation OK (possibly with warnings)

=item 1 - Validation errors

=back

=head1 AUTHOR

MCSS Framework - Mailserver Configuration Scoring System

=cut
