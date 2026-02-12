#!/usr/bin/env perl
#
# import_mcss_controls.pl - Import MCSS controls to PostgreSQL
#
# Features:
# - Create database schema if not exists
# - Import from master CSV + YAML translations (preferred)
# - Import from localized CSV files (legacy)
# - Calculate MCSS Base Score
# - Generate MCSS vector string
#
# Usage:
#   perl import_mcss_controls.pl [options] [file.csv ...]
#   perl import_mcss_controls.pl --master controls/master.csv --lang en
#

use strict;
use warnings;
use utf8;
use DBI;
use Text::CSV;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use open ':std', ':encoding(UTF-8)';

# Try to load YAML::Tiny
my $has_yaml = eval { require YAML::Tiny; 1 };

# Configuration defaults
my $db_name = 'mailserver_audit';
my $db_host = 'localhost';
my $db_port = 5432;
my $db_user = $ENV{USER} // 'postgres';
my $db_pass = '';
my $create_schema = 0;
my $truncate = 0;
my $verbose = 0;
my $dry_run = 0;

# New options for i18n
my $master_file;
my $yaml_file;
my $lang;

GetOptions(
    'database|d=s' => \$db_name,
    'host|H=s'     => \$db_host,
    'port|P=i'     => \$db_port,
    'user|U=s'     => \$db_user,
    'password|W=s' => \$db_pass,
    'create-schema|c' => \$create_schema,
    'truncate|t'   => \$truncate,
    'verbose|v'    => \$verbose,
    'dry-run|n'    => \$dry_run,
    'master=s'     => \$master_file,
    'yaml=s'       => \$yaml_file,
    'lang=s'       => \$lang,
    'help|h'       => sub { pod2usage(1); },
) or pod2usage(2);

# Score calculation weights
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

# Database schema
my $SCHEMA_SQL = <<'SQL';
-- MCSS Schema (Mailserver Configuration Scoring System)
-- Version: 1.0

-- Severity enum
DO $$ BEGIN
    CREATE TYPE mcss_severity AS ENUM ('None', 'Low', 'Medium', 'High', 'Critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Main controls table
CREATE TABLE IF NOT EXISTS mcss_controls (
    control_id          VARCHAR(30) PRIMARY KEY,
    control_name        VARCHAR(200) NOT NULL,
    description         TEXT NOT NULL,
    area                VARCHAR(50) NOT NULL,
    component           VARCHAR(50) NOT NULL,
    evidence_file       VARCHAR(200) NOT NULL,
    
    -- Exploitability metrics
    exposure_vector     CHAR(1) NOT NULL CHECK (exposure_vector IN ('N','A','L','P')),
    attack_complexity   CHAR(1) NOT NULL CHECK (attack_complexity IN ('L','H')),
    attack_requirements CHAR(1) NOT NULL CHECK (attack_requirements IN ('N','P')),
    privileges_required CHAR(1) NOT NULL CHECK (privileges_required IN ('N','L','H')),
    user_interaction    CHAR(1) NOT NULL CHECK (user_interaction IN ('N','P','A')),
    
    -- Impact metrics
    confidentiality_impact CHAR(1) NOT NULL CHECK (confidentiality_impact IN ('N','L','H')),
    integrity_impact       CHAR(1) NOT NULL CHECK (integrity_impact IN ('N','L','H')),
    availability_impact    CHAR(1) NOT NULL CHECK (availability_impact IN ('N','L','H')),
    
    -- Supplemental
    remediation_complexity CHAR(1) NOT NULL CHECK (remediation_complexity IN ('T','S','M','C','A')),
    
    -- Computed scores
    base_score          NUMERIC(3,1) NOT NULL,
    mcss_vector         VARCHAR(100) NOT NULL,
    severity            mcss_severity NOT NULL,
    
    -- Metadata
    language            VARCHAR(10) DEFAULT 'en',
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file         VARCHAR(100)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_mcss_controls_area ON mcss_controls(area);
CREATE INDEX IF NOT EXISTS idx_mcss_controls_component ON mcss_controls(component);
CREATE INDEX IF NOT EXISTS idx_mcss_controls_severity ON mcss_controls(severity);
CREATE INDEX IF NOT EXISTS idx_mcss_controls_score ON mcss_controls(base_score DESC);

-- Ranked controls view
CREATE OR REPLACE VIEW mcss_controls_ranked AS
SELECT 
    control_id,
    control_name,
    area,
    component,
    base_score,
    severity,
    mcss_vector,
    evidence_file,
    remediation_complexity,
    RANK() OVER (ORDER BY base_score DESC) as priority_rank,
    RANK() OVER (PARTITION BY area ORDER BY base_score DESC) as area_rank
FROM mcss_controls
ORDER BY base_score DESC;

-- Statistics by area view
CREATE OR REPLACE VIEW mcss_stats_by_area AS
SELECT 
    area,
    COUNT(*) as total_controls,
    COUNT(*) FILTER (WHERE severity = 'Critical') as critical_count,
    COUNT(*) FILTER (WHERE severity = 'High') as high_count,
    COUNT(*) FILTER (WHERE severity = 'Medium') as medium_count,
    COUNT(*) FILTER (WHERE severity = 'Low') as low_count,
    ROUND(AVG(base_score), 1) as avg_score,
    MAX(base_score) as max_score
FROM mcss_controls
GROUP BY area
ORDER BY avg_score DESC;

-- Severity distribution view
CREATE OR REPLACE VIEW mcss_severity_distribution AS
SELECT 
    severity,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage,
    ROUND(AVG(base_score), 1) as avg_score
FROM mcss_controls
GROUP BY severity
ORDER BY 
    CASE severity 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        WHEN 'Low' THEN 4 
        ELSE 5 
    END;

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_mcss_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mcss_controls_updated ON mcss_controls;
CREATE TRIGGER trg_mcss_controls_updated
    BEFORE UPDATE ON mcss_controls
    FOR EACH ROW
    EXECUTE FUNCTION update_mcss_timestamp();

COMMENT ON TABLE mcss_controls IS 'MCSS security controls for mailserver audit';
COMMENT ON COLUMN mcss_controls.base_score IS 'MCSS score 0.0-10.0';
COMMENT ON COLUMN mcss_controls.mcss_vector IS 'Vector string format MCSS:1.0/EV:N/AC:L/...';
SQL

# Database connection
sub connect_db {
    my $dsn = "dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port";
    
    print "Connecting to $dsn...\n" if $verbose;
    
    my $dbh = DBI->connect($dsn, $db_user, $db_pass, {
        RaiseError => 1,
        AutoCommit => 1,
        PrintError => 0,
        pg_enable_utf8 => 1,
    }) or die "Cannot connect to database: $DBI::errstr\n";
    
    return $dbh;
}

# Create schema
sub create_db_schema {
    my ($dbh) = @_;
    
    print "Creating MCSS schema...\n";
    
    if ($dry_run) {
        print "[DRY-RUN] Schema SQL:\n$SCHEMA_SQL\n";
        return;
    }
    
    $dbh->do($SCHEMA_SQL);
    print "Schema created successfully.\n";
}

# Calculate base score
sub calculate_base_score {
    my ($row) = @_;
    
    my $ev = $WEIGHTS{EV}{$row->{EV} // 'N'} // 0;
    my $ac = $WEIGHTS{AC}{$row->{AC} // 'L'} // 0;
    my $ar = $WEIGHTS{AR}{$row->{AR} // 'N'} // 0;
    my $pr = $WEIGHTS{PR}{$row->{PR} // 'N'} // 0;
    my $ui = $WEIGHTS{UI}{$row->{UI} // 'N'} // 0;
    
    my $exploitability = 1 - (($ev + $ac + $ar + $pr + $ui) / 0.9);
    
    my $vc = $WEIGHTS{VC}{$row->{VC} // 'N'} // 0.2;
    my $vi = $WEIGHTS{VI}{$row->{VI} // 'N'} // 0.2;
    my $va = $WEIGHTS{VA}{$row->{VA} // 'N'} // 0.2;
    
    my $vc_impact = 1 - ($vc / 0.2);
    my $vi_impact = 1 - ($vi / 0.2);
    my $va_impact = 1 - ($va / 0.2);
    
    my $impact = 1 - ((1 - $vc_impact) * (1 - $vi_impact) * (1 - $va_impact));
    
    my $base_score = 10 * (1 - ((1 - $exploitability) * (1 - $impact)));
    
    return sprintf("%.1f", $base_score);
}

# Build vector string
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

# Score to severity
sub score_to_severity {
    my ($score) = @_;
    
    return 'None'     if $score == 0;
    return 'Low'      if $score < 4.0;
    return 'Medium'   if $score < 7.0;
    return 'High'     if $score < 9.0;
    return 'Critical';
}

# Parse YAML file (simple parser or YAML::Tiny)
sub parse_yaml {
    my ($file) = @_;
    
    if ($has_yaml) {
        my $yaml = YAML::Tiny->read($file);
        return $yaml->[0] if $yaml;
        die "Failed to parse $file with YAML::Tiny\n";
    }
    
    # Fallback: simple parser
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";
    
    my %result;
    my $current_id;
    
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^---/ || $line =~ /^\s*#/;
        
        if ($line =~ /^controls:\s*$/) {
            $result{controls} = {};
            next;
        }
        
        if ($line =~ /^  ([A-Z][A-Z0-9]*-\d+):\s*$/) {
            $current_id = $1;
            $result{controls}{$current_id} = {};
            next;
        }
        
        # Quoted value
        if ($line =~ /^    (\w+):\s*"(.*)"\s*$/) {
            my ($key, $value) = ($1, $2);
            $value =~ s/\\"/"/g;
            $result{controls}{$current_id}{$key} = $value if $current_id;
            next;
        }
        
        # Unquoted value
        if ($line =~ /^    (\w+):\s*(.+?)\s*$/) {
            my ($key, $value) = ($1, $2);
            $result{controls}{$current_id}{$key} = $value if $current_id;
        }
    }
    
    close $fh;
    return \%result;
}

# Import from master CSV + YAML
sub import_master_with_yaml {
    my ($dbh, $master, $yaml_path, $language) = @_;
    
    print "Importing from master CSV + YAML...\n";
    print "  Master: $master\n";
    print "  YAML: $yaml_path\n";
    print "  Language: $language\n\n";
    
    # Read translations
    my $translations = parse_yaml($yaml_path);
    my $controls_l10n = $translations->{controls} || {};
    print "Translations loaded: " . scalar(keys %$controls_l10n) . " controls\n";
    
    # Read master CSV
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, "<:encoding(utf8)", $master or die "Cannot open $master: $!";
    
    my $header = $csv->getline($fh);
    $csv->column_names(@$header);
    
    # Prepare INSERT
    my $insert_sql = <<'SQL';
INSERT INTO mcss_controls (
    control_id, control_name, description, area, component, evidence_file,
    exposure_vector, attack_complexity, attack_requirements,
    privileges_required, user_interaction, confidentiality_impact,
    integrity_impact, availability_impact, remediation_complexity,
    base_score, mcss_vector, severity, language, source_file
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT (control_id) DO UPDATE SET
    control_name = EXCLUDED.control_name,
    description = EXCLUDED.description,
    area = EXCLUDED.area,
    component = EXCLUDED.component,
    evidence_file = EXCLUDED.evidence_file,
    exposure_vector = EXCLUDED.exposure_vector,
    attack_complexity = EXCLUDED.attack_complexity,
    attack_requirements = EXCLUDED.attack_requirements,
    privileges_required = EXCLUDED.privileges_required,
    user_interaction = EXCLUDED.user_interaction,
    confidentiality_impact = EXCLUDED.confidentiality_impact,
    integrity_impact = EXCLUDED.integrity_impact,
    availability_impact = EXCLUDED.availability_impact,
    remediation_complexity = EXCLUDED.remediation_complexity,
    base_score = EXCLUDED.base_score,
    mcss_vector = EXCLUDED.mcss_vector,
    severity = EXCLUDED.severity,
    language = EXCLUDED.language,
    source_file = EXCLUDED.source_file
SQL
    
    my $sth;
    $sth = $dbh->prepare($insert_sql) unless $dry_run;
    
    my $count = 0;
    my @missing;
    
    while (my $row = $csv->getline_hr($fh)) {
        my $id = $row->{control_id} // '';
        next if $id eq '';
        
        my $trans = $controls_l10n->{$id} || {};
        my $name = $trans->{name} // "[MISSING: $id]";
        my $desc = $trans->{description} // "[MISSING: $id description]";
        
        push @missing, $id unless exists $controls_l10n->{$id};
        
        my $score = calculate_base_score($row);
        my $vector = build_vector($row);
        my $severity = score_to_severity($score);
        
        if ($dry_run) {
            printf "[DRY-RUN] %s: score=%.1f severity=%s\n", $id, $score, $severity;
        } else {
            $sth->execute(
                $id, $name, $desc,
                $row->{area}, $row->{component}, $row->{evidence_file},
                $row->{EV}, $row->{AC}, $row->{AR}, $row->{PR}, $row->{UI},
                $row->{VC}, $row->{VI}, $row->{VA}, $row->{RC},
                $score, $vector, $severity, $language,
                basename($master)
            );
        }
        
        $count++;
        $verbose && printf "  ✓ %-15s score=%.1f\n", $id, $score;
    }
    
    close $fh;
    
    if (@missing) {
        print "\nWARNING: " . scalar(@missing) . " controls missing translations\n";
        $verbose && print "  " . join(', ', @missing[0..9]) . (@missing > 10 ? '...' : '') . "\n";
    }
    
    return $count;
}

# Import from localized CSV
sub import_localized_csv {
    my ($dbh, $file) = @_;
    
    print "Importing: $file\n";
    
    unless (-f $file) {
        warn "File not found: $file\n";
        return 0;
    }
    
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, "<:encoding(utf8)", $file or die "Cannot open $file: $!";
    
    my $header = $csv->getline($fh);
    $csv->column_names(@$header);
    
    # Detect area/component from filename
    my $basename = basename($file, '.csv');
    my ($area, $component) = ('Other', 'Other');
    if ($basename =~ /mcss_(\w+)_(\w+)/) {
        $area = ucfirst($1);
        $component = ucfirst($2);
    }
    
    my $insert_sql = <<'SQL';
INSERT INTO mcss_controls (
    control_id, control_name, description, area, component, evidence_file,
    exposure_vector, attack_complexity, attack_requirements,
    privileges_required, user_interaction, confidentiality_impact,
    integrity_impact, availability_impact, remediation_complexity,
    base_score, mcss_vector, severity, source_file
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT (control_id) DO UPDATE SET
    control_name = EXCLUDED.control_name,
    description = EXCLUDED.description,
    area = EXCLUDED.area,
    component = EXCLUDED.component,
    evidence_file = EXCLUDED.evidence_file,
    exposure_vector = EXCLUDED.exposure_vector,
    attack_complexity = EXCLUDED.attack_complexity,
    attack_requirements = EXCLUDED.attack_requirements,
    privileges_required = EXCLUDED.privileges_required,
    user_interaction = EXCLUDED.user_interaction,
    confidentiality_impact = EXCLUDED.confidentiality_impact,
    integrity_impact = EXCLUDED.integrity_impact,
    availability_impact = EXCLUDED.availability_impact,
    remediation_complexity = EXCLUDED.remediation_complexity,
    base_score = EXCLUDED.base_score,
    mcss_vector = EXCLUDED.mcss_vector,
    severity = EXCLUDED.severity,
    source_file = EXCLUDED.source_file
SQL
    
    my $sth;
    $sth = $dbh->prepare($insert_sql) unless $dry_run;
    
    my $count = 0;
    
    while (my $row = $csv->getline_hr($fh)) {
        my $id = $row->{control_id} // '';
        next if $id eq '';
        
        my $score = calculate_base_score($row);
        my $vector = build_vector($row);
        my $severity = score_to_severity($score);
        
        # Use area/component from CSV if present, otherwise from filename
        my $row_area = $row->{area} // $area;
        my $row_comp = $row->{component} // $component;
        
        if ($dry_run) {
            printf "[DRY-RUN] %s: score=%.1f severity=%s\n", $id, $score, $severity;
        } else {
            $sth->execute(
                $id,
                $row->{control_name} // $id,
                $row->{description} // '',
                $row_area, $row_comp,
                $row->{evidence_file} // '',
                $row->{EV}, $row->{AC}, $row->{AR}, $row->{PR}, $row->{UI},
                $row->{VC}, $row->{VI}, $row->{VA}, $row->{RC},
                $score, $vector, $severity,
                basename($file)
            );
        }
        
        $count++;
        $verbose && printf "  ✓ %s (score: %.1f)\n", $id, $score;
    }
    
    close $fh;
    print "  Imported: $count controls\n";
    
    return $count;
}

# Main
print "=== MCSS Controls Import ===\n\n";

my $dbh;

if ($dry_run) {
    print "=== DRY-RUN MODE ===\n\n";
} else {
    $dbh = connect_db();
}

if ($create_schema) {
    create_db_schema($dbh);
}

if ($truncate && !$dry_run) {
    print "Truncating mcss_controls table...\n";
    $dbh->do("TRUNCATE mcss_controls");
}

my $total = 0;

# Mode 1: Master + YAML
if ($master_file) {
    $lang //= 'en';
    $yaml_file //= "l10n/$lang.yaml";
    
    unless (-f $master_file) {
        die "Master file not found: $master_file\n";
    }
    unless (-f $yaml_file) {
        die "YAML file not found: $yaml_file\n";
    }
    
    $total = import_master_with_yaml($dbh, $master_file, $yaml_file, $lang);
}
# Mode 2: Localized CSV files
elsif (@ARGV) {
    for my $file (@ARGV) {
        $total += import_localized_csv($dbh, $file);
    }
}
# Mode 3: Auto-detect
else {
    # Try master + yaml first
    if (-f 'controls/mcss_controls_master.csv' && -f 'l10n/en.yaml') {
        print "Auto-detected master CSV + YAML mode\n";
        $total = import_master_with_yaml($dbh, 
            'controls/mcss_controls_master.csv', 
            'l10n/en.yaml', 
            'en'
        );
    }
    # Fallback to localized CSV
    else {
        my @files = glob("mcss_*.csv");
        @files = glob("*/controls/mcss_*.csv") unless @files;
        
        if (@files) {
            for my $file (@files) {
                $total += import_localized_csv($dbh, $file);
            }
        } else {
            die "No CSV files found. Specify files or use --master option.\n";
        }
    }
}

print "\n" . "=" x 50 . "\n";
print "TOTAL IMPORTED: $total controls\n";
print "=" x 50 . "\n";

# Show statistics
unless ($dry_run) {
    print "\nStatistics by area:\n";
    my $stats = $dbh->selectall_arrayref(
        "SELECT * FROM mcss_stats_by_area",
        { Slice => {} }
    );
    
    printf "%-15s %5s %4s %4s %4s %4s %6s %6s\n",
        "Area", "Tot", "Crit", "High", "Med", "Low", "Avg", "Max";
    print "-" x 65 . "\n";
    
    for my $s (@$stats) {
        printf "%-15s %5d %4d %4d %4d %4d %6.1f %6.1f\n",
            $s->{area},
            $s->{total_controls},
            $s->{critical_count},
            $s->{high_count},
            $s->{medium_count},
            $s->{low_count},
            $s->{avg_score},
            $s->{max_score};
    }
    
    $dbh->disconnect;
}

__END__

=head1 NAME

import_mcss_controls.pl - Import MCSS controls from CSV to PostgreSQL

=head1 SYNOPSIS

    # Import from master CSV + YAML translations (preferred)
    perl import_mcss_controls.pl -c --master controls/mcss_controls_master.csv --lang en
    perl import_mcss_controls.pl --master controls/mcss_controls_master.csv --yaml l10n/it.yaml
    
    # Import from localized CSV files
    perl import_mcss_controls.pl -c en/controls/*.csv
    
    # Auto-detect mode
    perl import_mcss_controls.pl -c
    
    # Dry-run
    perl import_mcss_controls.pl -n -v --master controls/mcss_controls_master.csv

=head1 OPTIONS

=over 4

=item B<-d, --database>

Database name (default: mailserver_audit)

=item B<-H, --host>

PostgreSQL host (default: localhost)

=item B<-P, --port>

PostgreSQL port (default: 5432)

=item B<-U, --user>

PostgreSQL user (default: $USER)

=item B<-W, --password>

PostgreSQL password

=item B<--master FILE>

Path to master CSV file (technical data only)

=item B<--yaml FILE>

Path to YAML translations file (default: l10n/{lang}.yaml)

=item B<--lang LANG>

Language code for translations (default: en)

=item B<-c, --create-schema>

Create database schema if not exists

=item B<-t, --truncate>

Truncate table before import

=item B<-v, --verbose>

Verbose output

=item B<-n, --dry-run>

Simulate import without database changes

=item B<-h, --help>

Show help

=back

=head1 DESCRIPTION

Imports MCSS controls from CSV files into PostgreSQL database,
automatically calculating Base Score, vector string, and severity.

Supports two modes:

=over 4

=item B<Master + YAML> (preferred)

Uses a master CSV with technical data and a YAML file with translations.
This allows easy multi-language support.

=item B<Localized CSV>

Uses pre-generated CSV files with control_name and description included.
Legacy mode for backwards compatibility.

=back

=head1 AUTHOR

MCSS Framework - Mailserver Configuration Scoring System

=cut
